#!/bin/bash
# Fails when a Swift file pairs ScrollView with ForEach and no Lazy container.
#
# This is a HEURISTIC, not a proof. A BOUNDED list -- a tab strip, a breadcrumb
# bar, a fixed set of wizard steps -- is a legitimate hit, and wrapping one in a
# Lazy container is a pure loss: Lazy* defers layout and can change how a parent
# sizes its content, for a collection that cannot grow. Such files belong in the
# allowlist WITH A REASON, not fixed.
#
# Run from a directory containing the Ainkrad repos, or from inside one.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
ALLOWLIST="$DIR/virtualization-allowlist.txt"
failed=0

while IFS= read -r f; do
  grep -q 'ScrollView' "$f" || continue
  grep -q 'ForEach' "$f" || continue
  grep -qE 'LazyVStack|LazyHStack|LazyVGrid|LazyHGrid|List\(' "$f" && continue
  # Allowlist entries are matched on the path SUFFIX, so the check works whether
  # it runs from a repo root or from a directory of repos.
  skip=0
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    case "$entry" in \#*) continue ;; esac
    case "$f" in *"$entry") skip=1; break ;; esac
  done < "$ALLOWLIST"
  [ "$skip" = 1 ] && continue
  echo "::error file=$f::ScrollView + ForEach with no Lazy container. Virtualize it, or add it to $(basename "$ALLOWLIST") with a reason."
  failed=1
done < <(find . -name '*.swift' \
           -not -path '*/build/*' -not -path '*/.build/*' \
           -not -path '*/worktrees/*' -not -path '*/checkouts/*' \
           -not -path '*/DerivedData/*' -not -path '*/Tests/*')

exit $failed
