#!/usr/bin/env bash
#
# install.sh — symlink the skills in this repo into one or more skill
# directories (default: ~/.agents/skills), or remove them again.
#
# Portability contract: targets stock macOS bash 3.2 and Linux. No bash-4
# features (associative arrays, mapfile/readarray, ${var,,}); no GNU-only
# tools (realpath, readlink -f). Symlinks are created with absolute targets
# so `readlink` returns the exact text we wrote, which we compare literally.
# Run as `./install.sh` or `bash install.sh` — not `sh install.sh` (bash-isms)
# and not via PATH or a symlink to this file (the resolver assumes $0's dir).
#
# NOTE: never use `((n++))` — under `set -e` it aborts when the pre-increment
# value is 0. Use `n=$((n+1))`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
SKILLS_DIR="$SCRIPT_DIR/skills"

usage() {
  cat <<'EOF'
Usage: ./install.sh [options] [skill...]

Symlink skills from this repo into one or more skill directories.
With no skill names, all skills under skills/ are installed.

Targets (combined; default is ~/.agents/skills when none is given):
  --target DIR    Install into DIR (repeatable).
  --agents        Shorthand for ~/.agents/skills   (./.agents/skills with --project).
  --claude        Shorthand for ~/.claude/skills    (./.claude/skills with --project).
  --both          --agents and --claude.
  --project       Resolve --agents/--claude under the current directory, not $HOME.

Actions / modifiers:
  --uninstall     Remove this repo's symlinks from the targets instead of creating them.
  --dry-run       Print planned actions; change nothing.
  --force         Replace a plain-file collision and repoint a foreign symlink.
                  Never touches a real directory.
  --list          List available skills and exit.
  -h, --help      Show this help and exit.

Examples:
  ./install.sh                        # all skills -> ~/.agents/skills
  ./install.sh --both                 # all skills -> ~/.agents/skills and ~/.claude/skills
  ./install.sh ship make-commits --claude
  ./install.sh --project --both       # into ./.agents/skills and ./.claude/skills
  ./install.sh --uninstall --both
EOF
}

list_skills() {
  # Directory-only glob, basenames, sorted. Matches the set install operates on.
  local d
  for d in "$SKILLS_DIR"/*/; do
    [ -d "$d" ] || continue
    basename "$d"
  done
}

# --- parse arguments ---------------------------------------------------------

targets=()
skills=()
want_agents=0
want_claude=0
project=0
uninstall=0
dry_run=0
force=0

while [ $# -gt 0 ]; do
  case "$1" in
    --target)
      [ $# -ge 2 ] || { echo "error: --target needs a directory" >&2; exit 2; }
      targets+=("$2")
      shift 2
      ;;
    --target=*)
      targets+=("${1#*=}")
      shift
      ;;
    --agents) want_agents=1; shift ;;
    --claude) want_claude=1; shift ;;
    --both) want_agents=1; want_claude=1; shift ;;
    --project) project=1; shift ;;
    --uninstall) uninstall=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    --force) force=1; shift ;;
    --list) list_skills; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; while [ $# -gt 0 ]; do skills+=("$1"); shift; done ;;
    -*) echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) skills+=("$1"); shift ;;
  esac
done

# --- resolve targets ---------------------------------------------------------

base="$HOME"
[ "$project" -eq 1 ] && base="$PWD"
[ "$want_agents" -eq 1 ] && targets+=("$base/.agents/skills")
[ "$want_claude" -eq 1 ] && targets+=("$base/.claude/skills")

# Default when nothing was requested.
[ "${#targets[@]}" -eq 0 ] && targets=("$HOME/.agents/skills")

# Dedup targets (preserve order; bash 3.2 has no associative arrays).
deduped=()
for t in "${targets[@]}"; do
  seen=0
  for d in "${deduped[@]:-}"; do
    [ "$d" = "$t" ] && { seen=1; break; }
  done
  [ "$seen" -eq 0 ] && deduped+=("$t")
done
targets=("${deduped[@]}")

# --- resolve skills ----------------------------------------------------------

if [ "${#skills[@]}" -eq 0 ]; then
  # All skills. read-loop keeps this bash-3.2 safe (no mapfile).
  while IFS= read -r name; do
    skills+=("$name")
  done < <(list_skills)
else
  for name in "${skills[@]}"; do
    if [ ! -d "$SKILLS_DIR/$name" ]; then
      echo "error: no such skill: $name" >&2
      echo "available:" >&2
      list_skills | sed 's/^/  /' >&2
      exit 2
    fi
  done
fi

if [ "${#skills[@]}" -eq 0 ]; then
  echo "error: no skills found under $SKILLS_DIR" >&2
  exit 1
fi

# --- act ---------------------------------------------------------------------

collisions=0

do_install_one() {
  local name="$1" target="$2"
  local src="$SKILLS_DIR/$name"
  local dst="$target/$name"

  if [ -L "$dst" ]; then
    local cur
    cur="$(readlink "$dst")"
    if [ "$cur" = "$src" ]; then
      echo "  ok       $name"
      return 0
    fi
    case "$cur" in
      "$SKILLS_DIR"/*)
        # Our own link, pointing at a different/stale path — heal it.
        if [ "$dry_run" -eq 1 ]; then
          echo "  relink   $name (dry-run)"
        else
          ln -sfn "$src" "$dst"
          echo "  relinked $name"
        fi
        return 0
        ;;
      *)
        # Foreign symlink — a deliberate install by someone else.
        if [ "$force" -eq 1 ]; then
          if [ "$dry_run" -eq 1 ]; then
            echo "  relink   $name (foreign, --force, dry-run)"
          else
            ln -sfn "$src" "$dst"
            echo "  relinked $name (was foreign)"
          fi
          return 0
        fi
        echo "  SKIP     $name (symlink to another source: $cur)"
        collisions=$((collisions+1))
        return 0
        ;;
    esac
  elif [ -d "$dst" ]; then
    echo "  SKIP     $name (real directory, not a symlink — left untouched)"
    collisions=$((collisions+1))
    return 0
  elif [ -e "$dst" ]; then
    # Plain file.
    if [ "$force" -eq 1 ]; then
      if [ "$dry_run" -eq 1 ]; then
        echo "  link     $name (replacing file, --force, dry-run)"
      else
        rm -f "$dst"
        ln -sfn "$src" "$dst"
        echo "  linked   $name (replaced file)"
      fi
      return 0
    fi
    echo "  SKIP     $name (a file exists here — use --force to replace)"
    collisions=$((collisions+1))
    return 0
  else
    if [ "$dry_run" -eq 1 ]; then
      echo "  link     $name (dry-run)"
    else
      ln -sfn "$src" "$dst"
      echo "  linked   $name"
    fi
    return 0
  fi
}

do_uninstall_one() {
  local name="$1" target="$2"
  local src="$SKILLS_DIR/$name"
  local dst="$target/$name"

  if [ ! -L "$dst" ]; then
    [ -e "$dst" ] && echo "  keep     $name (not a symlink — left untouched)"
    return 0
  fi
  local cur
  cur="$(readlink "$dst")"
  case "$cur" in
    "$SKILLS_DIR"/*)
      if [ "$dry_run" -eq 1 ]; then
        echo "  remove   $name (dry-run)"
      else
        rm -f "$dst"
        echo "  removed  $name"
      fi
      ;;
    *)
      echo "  keep     $name (symlink to another source: $cur)"
      ;;
  esac
}

for target in "${targets[@]}"; do
  if [ "$uninstall" -eq 1 ]; then
    echo "Uninstalling from $target"
    for name in "${skills[@]}"; do
      do_uninstall_one "$name" "$target"
    done
  else
    # Create the target only for a real install.
    if [ "$dry_run" -eq 0 ]; then
      mkdir -p "$target"
    fi
    echo "Installing into $target"
    for name in "${skills[@]}"; do
      do_install_one "$name" "$target"
    done
  fi
done

if [ "$uninstall" -eq 0 ] && [ "$dry_run" -eq 0 ] && [ "$collisions" -gt 0 ]; then
  echo "" >&2
  echo "$collisions skill(s) skipped due to collisions (see SKIP above)." >&2
  exit 3
fi

exit 0
