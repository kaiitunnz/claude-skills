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

echo "ALL SMOKE ASSERTIONS PASSED ($expected skills)"
