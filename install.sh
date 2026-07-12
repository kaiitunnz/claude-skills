#!/usr/bin/env bash
#
# install.sh — symlink the skills in this repo into one or more skill
# directories (default: ~/.agents/skills), or remove them again.
#
# Sources: first-party skills live flat under skills/ (one dir per skill).
# Third-party sources are git submodules under 3rdparty/, each curated by a
# sibling 3rdparty/<vendor>.manifest that lists the skill directories (paths
# relative to the submodule) to expose. Every source resolves to the same
# flat name -> directory map; from there install/uninstall is identical.
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
THIRDPARTY_DIR="$SCRIPT_DIR/3rdparty"

TAB="$(printf '\t')"

usage() {
  cat <<'EOF'
Usage: ./install.sh [options] [skill...]

Symlink skills from this repo into one or more skill directories.
With no skill names, all skills (first-party + curated third-party) are installed.

First-party skills live under skills/. Third-party skills come from git
submodules under 3rdparty/, curated by 3rdparty/<vendor>.manifest files.

Targets (combined; default is ~/.agents/skills when none is given):
  --target DIR    Install into DIR (repeatable).
  --agents        Shorthand for ~/.agents/skills   (./.agents/skills with --project).
  --claude        Shorthand for ~/.claude/skills    (./.claude/skills with --project).
  --both          --agents and --claude.
  --project       Resolve preset and default targets under the current
                  directory, not $HOME (so --project alone -> ./.agents/skills).

Actions / modifiers:
  --uninstall     Remove this repo's symlinks from the targets instead of creating them.
  --dry-run       Print planned actions; change nothing. Exits non-zero if a
                  real run would hit collisions, so it previews the outcome.
  --force         Replace a plain-file collision and repoint a foreign symlink.
                  Never touches a real directory.
  --list          List available skills (with their source) and exit.
  -h, --help      Show this help and exit.

Examples:
  ./install.sh                        # all skills -> ~/.agents/skills
  ./install.sh --both                 # all skills -> ~/.agents/skills and ~/.claude/skills
  ./install.sh ship make-commits --claude
  ./install.sh handoff teach --both   # third-party skills by name
  ./install.sh --project --both       # into ./.agents/skills and ./.claude/skills
  ./install.sh --uninstall --both
EOF
}

# --- source registry ---------------------------------------------------------
#
# REGISTRY holds one "name<TAB>absolute-src-dir" line per installable skill.
# First-party wins on a name clash; a duplicate from another source is warned
# and ignored so a foreign skill can't shadow a first-party one.

REGISTRY=""

resolve_src() {
  # Echo the src dir registered for a name, or nothing.
  # Here-string (not a pipe) so the read-loop's EOF status can't propagate
  # through pipefail into the caller's `existing="$(resolve_src ...)"`.
  local name="$1" n p out=""
  while IFS="$TAB" read -r n p; do
    [ "$n" = "$name" ] && { out="$p"; break; }
  done <<< "$REGISTRY"
  printf '%s' "$out"
}

registry_add() {
  # $1 = skill name, $2 = absolute src dir. First definition wins.
  local name="$1" src="$2" existing
  existing="$(resolve_src "$name")"
  if [ -n "$existing" ]; then
    [ "$existing" = "$src" ] && return 0
    echo "warning: skill '$name' offered by two sources; keeping $existing, ignoring $src" >&2
    return 0
  fi
  REGISTRY="${REGISTRY}${name}${TAB}${src}
"
}

build_registry() {
  local d name mf vendor line src

  # First-party: every immediate subdirectory of skills/.
  for d in "$SKILLS_DIR"/*/; do
    [ -d "$d" ] || continue
    registry_add "$(basename "$d")" "${d%/}"
  done

  # Third-party: each 3rdparty/<vendor>.manifest lists skill dirs (relative to
  # the 3rdparty/<vendor>/ submodule) to expose.
  [ -d "$THIRDPARTY_DIR" ] || return 0
  for mf in "$THIRDPARTY_DIR"/*.manifest; do
    [ -f "$mf" ] || continue
    vendor="$(basename "$mf" .manifest)"
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line%%#*}"                                   # strip comments
      line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      [ -n "$line" ] || continue
      src="$THIRDPARTY_DIR/$vendor/$line"
      if [ ! -f "$src/SKILL.md" ]; then
        echo "warning: $vendor manifest lists '$line' but $src/SKILL.md is missing" >&2
        echo "         (run: git submodule update --init 3rdparty/$vendor)" >&2
        continue
      fi
      registry_add "$(basename "$line")" "$src"
    done < "$mf"
  done
  return 0
}

all_names() {
  local n p acc=""
  while IFS="$TAB" read -r n p; do
    [ -n "$n" ] && acc="${acc}${n}
"
  done <<< "$REGISTRY"
  printf '%s' "$acc" | sort
}

list_skills() {
  # name + source root label, aligned, sorted by name.
  local name src label
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    src="$(resolve_src "$name")"
    case "$src" in
      "$SKILLS_DIR"/*) label="skills" ;;
      "$THIRDPARTY_DIR"/*) label="3rdparty/$(printf '%s' "${src#$THIRDPARTY_DIR/}" | cut -d/ -f1)" ;;
      *) label="?" ;;
    esac
    printf '%-26s %s\n' "$name" "$label"
  done <<< "$(all_names)"
  return 0
}

is_our_src() {
  # True if a symlink target is one we manage (under skills/ or 3rdparty/).
  case "$1" in
    "$SKILLS_DIR"/*|"$THIRDPARTY_DIR"/*) return 0 ;;
    *) return 1 ;;
  esac
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
do_list=0

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
    --list) do_list=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; while [ $# -gt 0 ]; do skills+=("$1"); shift; done ;;
    -*) echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) skills+=("$1"); shift ;;
  esac
done

# --- build the source registry (needed by --list and skill resolution) -------

build_registry

if [ "$do_list" -eq 1 ]; then
  list_skills
  exit 0
fi

# --- resolve targets ---------------------------------------------------------

base="$HOME"
[ "$project" -eq 1 ] && base="$PWD"
[ "$want_agents" -eq 1 ] && targets+=("$base/.agents/skills")
[ "$want_claude" -eq 1 ] && targets+=("$base/.claude/skills")

# Default when nothing was requested (honors --project via $base).
[ "${#targets[@]}" -eq 0 ] && targets=("$base/.agents/skills")

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
  # All registered skills. read-loop keeps this bash-3.2 safe (no mapfile).
  while IFS= read -r name; do
    skills+=("$name")
  done < <(all_names)
else
  for name in "${skills[@]}"; do
    if [ -z "$(resolve_src "$name")" ]; then
      echo "error: no such skill: $name" >&2
      echo "available:" >&2
      list_skills | sed 's/^/  /' >&2
      exit 2
    fi
  done
fi

if [ "${#skills[@]}" -eq 0 ]; then
  echo "error: no skills found (looked under $SKILLS_DIR and $THIRDPARTY_DIR)" >&2
  exit 1
fi

# --- act ---------------------------------------------------------------------

collisions=0

do_install_one() {
  local name="$1" target="$2"
  local src dst
  src="$(resolve_src "$name")"
  dst="$target/$name"

  if [ -L "$dst" ]; then
    local cur
    cur="$(readlink "$dst")"
    if [ "$cur" = "$src" ]; then
      echo "  ok       $name"
      return 0
    fi
    if is_our_src "$cur"; then
      # Our own link, pointing at a different/stale path — heal it.
      if [ "$dry_run" -eq 1 ]; then
        echo "  relink   $name (dry-run)"
      else
        ln -sfn "$src" "$dst"
        echo "  relinked $name"
      fi
      return 0
    fi
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
  local dst="$target/$name"

  if [ ! -L "$dst" ]; then
    [ -e "$dst" ] && echo "  keep     $name (not a symlink — left untouched)"
    return 0
  fi
  local cur
  cur="$(readlink "$dst")"
  if is_our_src "$cur"; then
    if [ "$dry_run" -eq 1 ]; then
      echo "  remove   $name (dry-run)"
    else
      rm -f "$dst"
      echo "  removed  $name"
    fi
  else
    echo "  keep     $name (symlink to another source: $cur)"
  fi
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

if [ "$uninstall" -eq 0 ] && [ "$collisions" -gt 0 ]; then
  echo "" >&2
  if [ "$dry_run" -eq 1 ]; then
    echo "$collisions skill(s) would be skipped due to collisions (see SKIP above)." >&2
  else
    echo "$collisions skill(s) skipped due to collisions (see SKIP above)." >&2
  fi
  exit 3
fi

exit 0
