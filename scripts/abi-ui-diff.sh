#!/usr/bin/env bash
set -euo pipefail

# abi-ui-diff.sh: compares AinkradAppKitUI ABI/declaration set and swiftinterface
# Usage: scripts/abi-ui-diff.sh [BASE_REF] [HEAD_REF]

cd "$(dirname "$0")/.."

BASE_REF="${1:-HEAD}"
HEAD_REF="${2:-}"

if [[ "$BASE_REF" == "HEAD" && -z "$HEAD_REF" ]]; then
  HEAD_REF="WORKTREE"
elif [[ -z "$HEAD_REF" ]]; then
  HEAD_REF="HEAD"
fi

MODULE_NAME="${ABI_UI_DIFF_MODULE:-AinkradAppKitUI}"

normalize_swiftinterface() {
  sed -E 's/-package-name [^ ]+ //g' "$1" | sed -E 's/\/\/ swift-module-flags: .*/\/\/ swift-module-flags: normalized/'
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
    git archive "$ref" | tar -x -C "$tmpdir"
  fi

  (
    cd "$tmpdir"
    swift build -c release >/dev/null 2>&1
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

    grep -E '"(name|printedName|usr)"' "$json_out" | sort -u > "$decl_out"

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

build_and_extract "$BASE_REF" "$BASE_DECLS" "$BASE_IFACE"
build_and_extract "$HEAD_REF" "$HEAD_DECLS" "$HEAD_IFACE"

DECL_DIFF=$(diff -u "$BASE_DECLS" "$HEAD_DECLS" || true)
IFACE_DIFF=$(diff -u "$BASE_IFACE" "$HEAD_IFACE" || true)

echo "=== Declaration Diff ($BASE_REF vs $HEAD_REF) ==="
if [[ -n "$DECL_DIFF" ]]; then
  echo "$DECL_DIFF"
fi

echo "=== SwiftInterface Diff ($BASE_REF vs $HEAD_REF) ==="
if [[ -n "$IFACE_DIFF" ]]; then
  echo "$IFACE_DIFF"
fi

if [[ -n "$DECL_DIFF" || -n "$IFACE_DIFF" ]]; then
  exit 1
fi

exit 0
