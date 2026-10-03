#!/bin/bash
# guardrails-sync.sh — distribute the canonical guardrails files to every sibling repo.
#
# Canonical source: AinkradAppKit (this repo). Each sibling keeps its own copies
# at the same relative paths so it lints offline in a fresh clone.
# Epic 2 task 2.4a. Never branches, commits or pushes — it only copies files
# and, in --check mode, reports drift.
#
# Usage:
#   scripts/guardrails-sync.sh [--check]
#   GUARDRAILS_ROOT=<dir> scripts/guardrails-sync.sh [--check]
#
# GUARDRAILS_ROOT overrides the sibling root (the directory that holds the
# checkouts). Default is the parent of this AinkradAppKit checkout, which is
# the Repositories/ directory in the standard layout. The override exists so
# the script can be tested against a scratch root without touching the real
# checkouts.

[ -n "${BASH_VERSION:-}" ] || { echo "guardrails-sync: must run under bash" >&2; exit 2; }
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPKIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIBLINGS="${GUARDRAILS_ROOT:-$(dirname "$APPKIT_ROOT")}"

# The canonical set, defined once. Every mode below derives from this array.
FILES=(
  "scripts/design-lint.sh"
  "scripts/design-lint-awk.awk"
  "scripts/design-lint-baseline.sh"
  "scripts/design-lint-selftest.sh"
  "scripts/design-lint-selftest-ratchet.sh"
  "scripts/git-hooks/pre-push"
  "scripts/guardrails.mk"
  ".swift-format"
)

# Sync destinations relative to the sibling root: the 11 sibling repos plus
# the template embedded in AinkradKit. AinkradKit therefore appears twice —
# once as a repo root, once as its embedded template — for 12 destinations.
TARGETS=(
  "Ainkrad"
  "AinkradKit"
  "AinkradLeyline"
  "AinkradLore"
  "AinkradPluginTemplate"
  "AinkradQuest"
  "AinkradRaven"
  "AinkradRune"
  "AinkradThrall"
  "AinkradWhisper"
  "GitMage"
  "AinkradKit/Sources/ainkrad/Resources/Template"
)

# Scaffolder tokens (Epic 2 §2): ainkrad new rewrites these in every text file
# it copies, so they must never ship in a canonical guardrails file.
TOKENS=(
  "TemplatePlugin"
  "MyPluginEntryPoint"
  "MyApp"
  "myplugin"
  "My Plugin"
  "puzzlepiece.extension"
)

MODE="sync"
while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE="check" ;;
    *) echo "guardrails-sync: unknown option: $1 (usage: guardrails-sync.sh [--check])" >&2; exit 2 ;;
  esac
  shift
done

# Refuse if any canonical file contains a scaffolder token. Fixed-string grep:
# several tokens contain spaces or dots that must not be read as regex.
check_tokens() {
  local f
  for f in "${FILES[@]}"; do
    [ -f "$APPKIT_ROOT/$f" ] || { echo "guardrails-sync: refused: canonical file missing: $f" >&2; return 1; }
    local t
    for t in "${TOKENS[@]}"; do
      if grep -F -q "$t" "$APPKIT_ROOT/$f"; then
        echo "guardrails-sync: refused: canonical $f contains scaffolder token '$t'" >&2
        return 1
      fi
    done
  done
  return 0
}

sha() {
  shasum -a 256 "$1" | cut -d' ' -f1
}

next_step_sync() {
  if [ "$1" = "AinkradKit/Sources/ainkrad/Resources/Template" ]; then
    echo "  next: $1: embedded template — consumed via ainkrad new; nothing to commit here"
  else
    echo "  next: $1: wire Makefile (include scripts/guardrails.mk last), add the repo's §4 allows, run make lint-rebaseline"
  fi
}

next_step_check_clean() {
  if [ "$1" = "AinkradKit/Sources/ainkrad/Resources/Template" ]; then
    echo "  next: $1: clean — nothing to do (embedded template)"
  else
    echo "  next: $1: clean — wire Makefile (include scripts/guardrails.mk last), add the repo's §4 allows, run make lint-rebaseline"
  fi
}

check_tokens || exit 1

if [ "$MODE" = "sync" ]; then
  "$SCRIPT_DIR/design-lint.sh" --self-test >/dev/null 2>&1 || {
    echo "guardrails-sync: refused: design-lint.sh --self-test failed" >&2
    exit 1
  }

  expected=$((${#TARGETS[@]} * ${#FILES[@]}))
  synced=0
  skipped=0
  t=0
  while [ $t -lt ${#TARGETS[@]} ]; do
    target="${TARGETS[$t]}"
    if [ ! -d "$SIBLINGS/$target" ]; then
      echo "missing repo: $target — skipped" >&2
      skipped=$((skipped + 1))
      next_step_sync "$target"
      t=$((t + 1))
      continue
    fi
    i=0
    while [ $i -lt ${#FILES[@]} ]; do
      f="${FILES[$i]}"
      src="$APPKIT_ROOT/$f"
      dest="$SIBLINGS/$target/$f"
      mkdir -p "$(dirname "$dest")" || { echo "guardrails-sync: cannot create $(dirname "$dest")" >&2; exit 1; }
      cp -p "$src" "$dest" || { echo "guardrails-sync: copy failed: $f -> $target" >&2; exit 1; }
      [ "$(sha "$src")" = "$(sha "$dest")" ] || { echo "guardrails-sync: verify failed: $target/$f differs after copy" >&2; exit 1; }
      if [ -x "$src" ] && [ ! -x "$dest" ]; then
        echo "guardrails-sync: verify failed: $target/$f is not executable" >&2
        exit 1
      fi
      synced=$((synced + 1))
      i=$((i + 1))
    done
    next_step_sync "$target"
    t=$((t + 1))
  done

  echo "synced $synced/$expected"
  [ $synced -gt 0 ] || { echo "guardrails-sync: synced nothing — refusing to report success" >&2; exit 1; }
  [ $synced -eq $expected ] || exit 1
  exit 0
fi

# --check: read-only drift report. A missing sibling repo is reported and
# skipped (it does not fail the check); a missing or differing file does.
drift=0
t=0
while [ $t -lt ${#TARGETS[@]} ]; do
  target="${TARGETS[$t]}"
  if [ ! -d "$SIBLINGS/$target" ]; then
    echo "missing repo: $target — skipped" >&2
    t=$((t + 1))
    continue
  fi
  target_drift=0
  i=0
  while [ $i -lt ${#FILES[@]} ]; do
    f="${FILES[$i]}"
    src="$APPKIT_ROOT/$f"
    dest="$SIBLINGS/$target/$f"
    if [ ! -f "$dest" ]; then
      echo "drift: $target/$f: missing"
      drift=$((drift + 1))
      target_drift=$((target_drift + 1))
    elif [ "$(sha "$src")" != "$(sha "$dest")" ]; then
      echo "drift: $target/$f: differs"
      drift=$((drift + 1))
      target_drift=$((target_drift + 1))
    elif [ -x "$src" ] && [ ! -x "$dest" ]; then
      echo "drift: $target/$f: not executable"
      drift=$((drift + 1))
      target_drift=$((target_drift + 1))
    fi
    i=$((i + 1))
  done
  if [ $target_drift -gt 0 ]; then
    echo "  next: $target: run AinkradAppKit/scripts/guardrails-sync.sh to re-sync"
  else
    next_step_check_clean "$target"
  fi
  t=$((t + 1))
done

if [ $drift -gt 0 ]; then
  echo "drift: $drift file(s) differ" >&2
  exit 1
fi
echo "guardrails-sync: clean"
exit 0
