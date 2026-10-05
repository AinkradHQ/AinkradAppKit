#!/usr/bin/env bash
set -euo pipefail

# abi-ui-diff.sh: compares AinkradAppKitUI ABI/declaration set and swiftinterface
# Usage: scripts/abi-ui-diff.sh <base> [head]
#   <base> defaults to HEAD; [head] defaults to WORKTREE when <base> is HEAD,
#   otherwise to HEAD. Pass WORKTREE explicitly as head to diff worktree state
#   (e.g. scripts/abi-ui-diff.sh HEAD WORKTREE).
#
# How it works: builds the module at each ref, runs swift-api-digester, and
# extracts the SET of `usr` values from each JSON (position-independent, so a
# purely additive change reports no removals). Prints REMOVED symbols (in base,
# not in head), ADDED symbols (in head, not in base), then the swiftinterface
# diff.
#
# Exit codes:
#   0 = no change (no added/removed symbols, no swiftinterface diff)
#   3 = additions only (no removed symbols, but added symbols and/or
#       swiftinterface diff present)
#   1 = at least one REMOVED symbol (breaking API change)
#   2 = tool failure (build/digester/usage error)

cd "$(dirname "$0")/.."

BASE_REF="${1:-HEAD}"
HEAD_REF="${2:-}"

if [[ "$BASE_REF" == "HEAD" && -z "$HEAD_REF" ]]; then
  HEAD_REF="WORKTREE"
elif [[ -z "$HEAD_REF" ]]; then
  HEAD_REF="HEAD"
fi

echo "=== ABI UI Diff: $BASE_REF vs $HEAD_REF ==="

resolve_commit() {
  git rev-parse --verify "$1^{commit}" 2>/dev/null || true
}

BASE_COMMIT="$(resolve_commit "$BASE_REF")"
if [[ "$HEAD_REF" == "WORKTREE" ]]; then
  HEAD_COMMIT="$(resolve_commit HEAD)"
  if [[ -n "$BASE_COMMIT" && "$BASE_COMMIT" == "$HEAD_COMMIT" ]] \
    && git diff --quiet && git diff --cached --quiet; then
    echo "WARNING: base and head resolve to the same commit ($BASE_COMMIT); WORKTREE is clean"
  fi
else
  HEAD_COMMIT="$(resolve_commit "$HEAD_REF")"
  if [[ -n "$BASE_COMMIT" && -n "$HEAD_COMMIT" && "$BASE_COMMIT" == "$HEAD_COMMIT" ]]; then
    echo "WARNING: base and head resolve to the same commit ($BASE_COMMIT)"
  fi
fi

MODULE_NAME="${ABI_UI_DIFF_MODULE:-AinkradAppKitUI}"

normalize_swiftinterface() {
  sed -E 's/-package-name [^ ]+ //g' "$1" | sed -E 's/\/\/ swift-module-flags: .*/\/\/ swift-module-flags: normalized/'
}

extract_usrs() {
  local json="$1"
  local out="$2"
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$json" > "$out" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path) as f:
    data = json.load(f)

usrs = set()

def walk(node):
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "usr" and isinstance(value, str):
                usrs.add(value)
            else:
                walk(value)
    elif isinstance(node, list):
        for value in node:
            walk(value)

walk(data)
for usr in sorted(usrs):
    print(usr)
PY
  elif command -v jq >/dev/null 2>&1; then
    jq -r '.. | objects | .usr? // empty' "$json" > "$out"
  else
    echo "Error: need python3 or jq to extract usr symbols" >&2
    return 1
  fi
  sort -u -o "$out" "$out"
}

build_and_extract() {
  local ref="$1"
  local decl_out="$2"
  local iface_out="$3"
  local tmpdir

  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  if [[ "$ref" == "WORKTREE" ]]; then
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --exclude='.build' --exclude='.git' ./ "$tmpdir/"
    else
      cp -R . "$tmpdir/"
      rm -rf "$tmpdir/.build" "$tmpdir/.git"
    fi
  else
    if ! git archive "$ref" | tar -x -C "$tmpdir"; then
      echo "Error: failed to archive ref $ref" >&2
      return 1
    fi
  fi

  (
    cd "$tmpdir"
    if ! swift build -c release >/dev/null 2>&1; then
      echo "Error: swift build failed for ref $ref" >&2
      exit 1
    fi
    local bin_path
    bin_path=$(swift build -c release --show-bin-path)

    local json_out="$tmpdir/appkitui.json"
    if ! xcrun swift-api-digester -dump-sdk -abi -module "$MODULE_NAME" \
      -o "$json_out" -I "$bin_path" \
      -sdk "$(xcrun --show-sdk-path)" >/dev/null 2>&1; then
      echo "Error: swift-api-digester failed for ref $ref and module $MODULE_NAME" >&2
      exit 1
    fi

    if [[ ! -f "$json_out" || ! -s "$json_out" ]]; then
      echo "Error: swift-api-digester produced no output for ref $ref and module $MODULE_NAME" >&2
      exit 1
    fi

    if ! extract_usrs "$json_out" "$decl_out"; then
      echo "Error: failed to extract usr symbols for ref $ref" >&2
      exit 1
    fi

    local ifaces=()
    while IFS= read -r -d '' f; do
      ifaces+=("$f")
    done < <(find .build -path "*/Release/*" -name "${MODULE_NAME}.swiftinterface" -print0 2>/dev/null)

    if [[ ${#ifaces[@]} -ne 1 ]]; then
      echo "Error: Expected exactly 1 release ${MODULE_NAME}.swiftinterface for ref $ref, found ${#ifaces[@]}" >&2
      exit 1
    fi

    normalize_swiftinterface "${ifaces[0]}" > "$iface_out"
  )
}

BASE_DECLS=$(mktemp)
HEAD_DECLS=$(mktemp)
BASE_IFACE=$(mktemp)
HEAD_IFACE=$(mktemp)
trap 'rm -f "$BASE_DECLS" "$HEAD_DECLS" "$BASE_IFACE" "$HEAD_IFACE"' EXIT

if ! build_and_extract "$BASE_REF" "$BASE_DECLS" "$BASE_IFACE"; then
  exit 2
fi
if ! build_and_extract "$HEAD_REF" "$HEAD_DECLS" "$HEAD_IFACE"; then
  exit 2
fi

REMOVED=$(comm -23 "$BASE_DECLS" "$HEAD_DECLS" || true)
ADDED=$(comm -13 "$BASE_DECLS" "$HEAD_DECLS" || true)
IFACE_DIFF=$(diff -u "$BASE_IFACE" "$HEAD_IFACE" || true)

echo "--- REMOVED symbols (in $BASE_REF, not in $HEAD_REF) ---"
if [[ -n "$REMOVED" ]]; then
  echo "$REMOVED"
else
  echo "(none)"
fi

echo "--- ADDED symbols (in $HEAD_REF, not in $BASE_REF) ---"
if [[ -n "$ADDED" ]]; then
  echo "$ADDED"
else
  echo "(none)"
fi

echo "=== SwiftInterface Diff ($BASE_REF vs $HEAD_REF) ==="
if [[ -n "$IFACE_DIFF" ]]; then
  echo "$IFACE_DIFF"
fi

if [[ -n "$REMOVED" ]]; then
  exit 1
fi

if [[ -n "$ADDED" || -n "$IFACE_DIFF" ]]; then
  exit 3
fi

exit 0
