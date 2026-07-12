#!/usr/bin/env bash
#
# smoke.sh — exercise install.sh in a throwaway target dir. No extra deps;
# portable to macOS bash 3.2 and Linux.

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd -P)"
INSTALL="$REPO/install.sh"
SKILLS_DIR="$REPO/skills"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/skills-smoke.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

# Expected set + count from the same directory-only glob install uses.
expected=0
victim=""; victim2=""; victim3=""
for d in "$SKILLS_DIR"/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  expected=$((expected+1))
  case "$expected" in
    1) victim="$name" ;;
    2) victim2="$name" ;;
    3) victim3="$name" ;;
  esac
done
[ "$expected" -ge 3 ] || fail "need >=3 skills for the collision fixtures, found $expected"

# --- 1: install links every skill, each resolves through the symlink ---------
"$INSTALL" --target "$TMP" >/dev/null
linked=0
for d in "$SKILLS_DIR"/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  [ -L "$TMP/$name" ] || fail "$name not a symlink"
  [ -r "$TMP/$name/SKILL.md" ] || fail "$name/SKILL.md not readable through link"
  linked=$((linked+1))
done
[ "$linked" -eq "$expected" ] || fail "linked $linked, expected $expected"
pass "1: installed and resolved all $expected skills"

# --- 2: second run is idempotent (exit 0, no changes) ------------------------
before="$(ls -l "$TMP")"
"$INSTALL" --target "$TMP" >/dev/null || fail "second run exited non-zero"
after="$(ls -l "$TMP")"
[ "$before" = "$after" ] || fail "second run changed the target"
pass "2: idempotent re-run"

# --- 3: real-dir collision shadowing a real skill name -----------------------
rm -f "$TMP/$victim"
mkdir -p "$TMP/$victim"
touch "$TMP/$victim/canary"
rc=0
"$INSTALL" --target "$TMP" >/dev/null || rc=$?
[ "$rc" -ne 0 ] || fail "real-dir collision should exit non-zero"
[ ! -L "$TMP/$victim" ] || fail "real dir was replaced by a symlink"
[ -f "$TMP/$victim/canary" ] || fail "real dir contents were touched"
[ -L "$TMP/$victim2" ] || fail "other skills should still be linked"
pass "3: real-dir collision skipped, dir untouched, non-zero exit"

# --- 4: foreign-symlink collision, then --force repoints ---------------------
other="$TMP/_other_source"; mkdir -p "$other"
rm -f "$TMP/$victim2"
ln -sfn "$other" "$TMP/$victim2"
rc=0
"$INSTALL" --target "$TMP" >/dev/null || rc=$?
[ "$rc" -ne 0 ] || fail "foreign-symlink collision should exit non-zero"
[ "$(readlink "$TMP/$victim2")" = "$other" ] || fail "foreign symlink was changed without --force"
# --force repoints the foreign symlink; the real dir from #3 is still an
# unresolved collision, so a non-zero exit here is expected, not a failure.
"$INSTALL" --target "$TMP" --force >/dev/null || true
[ "$(readlink "$TMP/$victim2")" = "$SKILLS_DIR/$victim2" ] || fail "--force did not repoint foreign symlink"
pass "4: foreign symlink preserved without --force, repointed with --force"

# --- 5: uninstall removes only our links; non-ours survive -------------------
# victim: real dir (from #3). victim3: a never-forced foreign symlink.
foreign3="$TMP/_other3"; mkdir -p "$foreign3"
rm -f "$TMP/$victim3"
ln -sfn "$foreign3" "$TMP/$victim3"
"$INSTALL" --uninstall --target "$TMP" >/dev/null
[ ! -e "$TMP/$victim2" ] || fail "our symlink ($victim2) not removed by uninstall"
[ -d "$TMP/$victim" ] && [ -f "$TMP/$victim/canary" ] || fail "real dir removed by uninstall"
[ "$(readlink "$TMP/$victim3")" = "$foreign3" ] || fail "foreign symlink removed by uninstall"
pass "5: uninstall removed only our links; real dir and foreign symlink survive"

# --- 6: --dry-run creates nothing (guards mkdir-under-dry-run) ---------------
NEW="$TMP/newtarget"
"$INSTALL" --dry-run --target "$NEW" >/dev/null
[ ! -e "$NEW" ] || fail "--dry-run created the target directory"
pass "6: --dry-run created nothing"

# --- 7: --dry-run predicts the real exit code (3 on collisions) --------------
# $TMP still holds $victim (real dir) and $victim3 (foreign symlink) after #5.
snapshot="$(ls -l "$TMP")"
rc=0
"$INSTALL" --dry-run --target "$TMP" >/dev/null || rc=$?
[ "$rc" -eq 3 ] || fail "--dry-run over a colliding target should exit 3, got $rc"
[ "$(ls -l "$TMP")" = "$snapshot" ] || fail "--dry-run changed the target"
pass "7: --dry-run predicts exit 3 on collisions, changes nothing"

# --- 8: --project alone defaults under cwd, not $HOME ------------------------
proj="$TMP/proj"; mkdir -p "$proj"
out="$(cd "$proj" && "$INSTALL" --project --dry-run 2>&1)"
echo "$out" | grep -q "Installing into $proj/.agents/skills" \
  || fail "--project alone did not default to ./.agents/skills"
[ ! -e "$proj/.agents" ] || fail "--project --dry-run created a directory"
pass "8: --project alone defaults to ./.agents/skills"

# --- third-party sources (hermetic fixture) ----------------------------------
# install.sh resolves sources relative to its own dir, so a self-contained copy
# in a fixture tree exercises third-party discovery without needing the real
# submodule checked out. Layout:
#   fixture/install.sh
#   fixture/skills/first-skill/SKILL.md        (first-party)
#   fixture/skills/dup/SKILL.md                (first-party, name clash)
#   fixture/3rdparty/acme/cat/nested-skill/SKILL.md   (manifest, deep nesting)
#   fixture/3rdparty/acme/cat/hidden-skill/SKILL.md   (present, NOT in manifest)
#   fixture/3rdparty/acme/cat/dup/SKILL.md            (manifest, clashes w/ above)
#   fixture/3rdparty/acme/cat/gone-skill              (in manifest, no SKILL.md)
#   fixture/3rdparty/acme/escape-skill/SKILL.md       (reachable only via `..`)
#   fixture/3rdparty/acme.manifest
FIX="$TMP/fixture"
mk_skill() { mkdir -p "$1"; printf -- '---\nname: %s\n---\nbody\n' "$(basename "$1")" > "$1/SKILL.md"; }
mkdir -p "$FIX/skills" "$FIX/3rdparty/acme/cat"
cp "$INSTALL" "$FIX/install.sh"
FINST="$FIX/install.sh"
mk_skill "$FIX/skills/first-skill"
mk_skill "$FIX/skills/dup"
mk_skill "$FIX/3rdparty/acme/cat/nested-skill"
mk_skill "$FIX/3rdparty/acme/cat/hidden-skill"
mk_skill "$FIX/3rdparty/acme/cat/dup"
mk_skill "$FIX/3rdparty/acme/escape-skill"     # real dir, but only reachable via `..`
mkdir -p "$FIX/3rdparty/acme/cat/gone-skill"   # listed in manifest but no SKILL.md
cat > "$FIX/3rdparty/acme.manifest" <<'EOF'
# curated third-party skills
cat/nested-skill
  cat/dup          # clashes with first-party dup; first-party must win
cat/gone-skill     # missing SKILL.md; must be warned + skipped, not fatal
cat/../escape-skill  # `..` escape; must be rejected even though it resolves
EOF

# --- 9: --list groups curated (by name) vs undeclared third-party (by path) ---
lst="$("$FINST" --list)"
# Curated third-party + first-party appear in the default section (2-sp indent).
echo "$lst" | grep -Eq "^  nested-skill[[:space:]]+3rdparty/acme$" \
  || fail "--list did not show curated nested-skill under 3rdparty/acme"
echo "$lst" | grep -Eq "^  dup[[:space:]]+skills$" \
  || fail "--list did not resolve dup to the first-party source"
# An un-manifested skill must NOT be listed as installed-by-default...
echo "$lst" | grep -Eq "^  hidden-skill[[:space:]]" \
  && fail "--list showed an un-curated skill as installed-by-default"
# ...but MUST be offered as installable by its exact path.
echo "$lst" | grep -q "3rdparty/acme/cat/hidden-skill" \
  || fail "--list did not offer the un-curated skill by path"
pass "9: --list groups curated-by-name vs undeclared-by-path"

# --- 10: install links first-party + manifest skills; curation + nesting hold -
FT="$TMP/fixture-target"
"$FINST" --target "$FT" >/dev/null 2>"$TMP/fx.err" || true
[ -L "$FT/first-skill" ]  || fail "first-party skill not linked from fixture"
[ -L "$FT/nested-skill" ] && [ -r "$FT/nested-skill/SKILL.md" ] \
  || fail "deep-nested third-party skill did not resolve through the link"
[ "$(readlink "$FT/nested-skill")" = "$FIX/3rdparty/acme/cat/nested-skill" ] \
  || fail "nested-skill link points at the wrong path"
[ ! -e "$FT/hidden-skill" ] || fail "un-manifested skill leaked into the target"
[ ! -e "$FT/gone-skill" ]   || fail "manifest entry with no SKILL.md was linked"
[ ! -e "$FT/escape-skill" ] || fail "manifest entry with '..' escaped the submodule and linked"
[ "$(readlink "$FT/dup")" = "$FIX/skills/dup" ] \
  || fail "cross-source name clash: first-party dup did not win"
grep -q "gone-skill" "$TMP/fx.err" || fail "missing SKILL.md was not warned about"
grep -q "two sources" "$TMP/fx.err" || fail "cross-source clash was not warned about"
grep -q "escape-skill" "$TMP/fx.err" || fail "'..' manifest entry was not warned about"
pass "10: curation, deep nesting, missing-entry skip, '..' rejection, first-party-wins all hold"

# --- 10b: --dry-run over a third-party source plans the link but writes nothing
DR="$TMP/fixture-dryrun"
drout="$("$FINST" --dry-run --target "$DR" 2>/dev/null)"
[ ! -e "$DR" ] || fail "--dry-run created the target for a third-party source"
echo "$drout" | grep -q "nested-skill (dry-run)" \
  || fail "--dry-run did not plan the third-party skill link"
pass "10b: --dry-run plans a third-party link and creates nothing"

# --- 11: a manifest skill installs/uninstalls by name like any other ---------
UT="$TMP/fixture-uninstall"
"$FINST" nested-skill --target "$UT" >/dev/null 2>&1
[ -L "$UT/nested-skill" ] || fail "could not install a third-party skill by name"
[ ! -e "$UT/first-skill" ] || fail "installing one skill by name pulled in others"
"$FINST" --uninstall --target "$UT" >/dev/null 2>&1
[ ! -e "$UT/nested-skill" ] || fail "uninstall did not remove the third-party link"
pass "11: third-party skill installs by name and uninstalls cleanly"

# --- 12: the shipped manifests resolve against their real submodules ----------
# The tests above are hermetic (fixture only). This one guards the actual
# committed 3rdparty/*.manifest files: a typo or an upstream reorg after
# `git submodule update --remote` would otherwise degrade silently to a
# skipped skill. Gated on the submodule being checked out, so a submodule-less
# CI run skips rather than fails.
real_validated=0
reallst="$("$INSTALL" --list 2>/dev/null)"
for mf in "$REPO"/3rdparty/*.manifest; do
  [ -f "$mf" ] || continue
  vendor="$(basename "$mf" .manifest)"
  sub="$REPO/3rdparty/$vendor"
  if [ ! -e "$sub/.git" ]; then
    echo "SKIP: real '$vendor' manifest (submodule not checked out)"
    continue
  fi
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -n "$line" ] || continue
    [ -f "$sub/$line/SKILL.md" ] \
      || fail "real '$vendor' manifest lists '$line' but its SKILL.md is missing (typo or upstream reorg?)"
    name="$(basename "$line")"
    echo "$reallst" | grep -Eq "^  $name[[:space:]]+3rdparty/$vendor$" \
      || fail "real manifest skill '$name' did not resolve in --list from 3rdparty/$vendor"
  done < "$mf"
  real_validated=1
done
[ "$real_validated" -eq 1 ] \
  && pass "12: shipped third-party manifest(s) resolve against their submodules"

# --- 13: an undeclared third-party skill installs/uninstalls by exact path ----
# hidden-skill is present in the acme source but not in the manifest, so it is
# only reachable by naming its path.
PT="$TMP/fixture-bypath"
"$FINST" 3rdparty/acme/cat/hidden-skill --target "$PT" >/dev/null
[ -L "$PT/hidden-skill" ] && [ -r "$PT/hidden-skill/SKILL.md" ] \
  || fail "install-by-path did not link the undeclared skill"
[ "$(readlink "$PT/hidden-skill")" = "$FIX/3rdparty/acme/cat/hidden-skill" ] \
  || fail "install-by-path linked the wrong source"
[ "$(ls "$PT")" = "hidden-skill" ] || fail "install-by-path pulled in more than the named skill"
"$FINST" --uninstall 3rdparty/acme/cat/hidden-skill --target "$PT" >/dev/null
[ ! -e "$PT/hidden-skill" ] || fail "uninstall-by-path did not remove the link"
pass "13: undeclared third-party skill installs and uninstalls by exact path"

# --- 14: install-by-path rejects unsafe / non-skill targets ------------------
rc=0; "$FINST" /etc/hostname --target "$TMP/rej1" 2>/dev/null || rc=$?
[ "$rc" -eq 2 ] || fail "a path outside skills/ and 3rdparty/ was not rejected"
[ ! -e "$TMP/rej1" ] || fail "a rejected path still created its target dir"
rc=0; "$FINST" 3rdparty/acme/cat --target "$TMP/rej2" 2>/dev/null || rc=$?
[ "$rc" -eq 2 ] || fail "a path with no SKILL.md was not rejected"
rc=0; "$FINST" 3rdparty/acme/cat/../escape-skill --target "$TMP/rej3" 2>/dev/null || rc=$?
[ "$rc" -eq 2 ] || fail "a path containing '..' was not rejected"
pass "14: install-by-path rejects outside-repo, non-skill, and '..' paths"

echo "ALL SMOKE ASSERTIONS PASSED ($expected first-party skills + third-party fixture)"
