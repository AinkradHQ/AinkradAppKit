#!/bin/bash
# design-lint.sh — design rules + allow syntax (Epic 2 task 2.1)
# DESIGN_LINT_VERSION=1

set -o pipefail

[ -n "${BASH_VERSION:-}" ] || { echo "design-lint: must run under bash" >&2; exit 2; }

SELF_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF_TEST_FILE="$SELF_TEST_DIR/design-lint-selftest.sh"

COLORS="red|blue|green|orange|yellow|pink|purple|gray|grey|black|white|cyan|mint|teal|indigo|brown"

rule_names=(
  "font-size"
  "padding-literal"
  "spacing-literal"
  "radius-literal"
  "hex-color"
  "raw-color"
  "raw-control"
  "opacity-literal"
  "frame-literal"
  "chamfer-literal"
  "motion-literal"
)

rule_scopes=(
  "Sources"
  "Sources"
  "Sources"
  "Sources"
  "Sources"
  "Sources"
  "Sources"
  "Sources"
  "Sources"
  "Sources"
  "Sources"
)

rule_patterns=(
  "\\.system\\(size:|systemFont\\(ofSize:|\\.custom\\(\"[^\"]*\", *size:"
  "\\.padding\\(([^)]*, *)?-?[0-9]"
  "spacing: *-?([1-9]|0\\.[0-9]*[1-9])"
  "(cornerRadius|radius): *[0-9]|\\.cornerRadius\\( *[0-9]"
  "Color\\(hex:|NSColor\\(hex:|0x[0-9A-Fa-f]{6}([^0-9A-Fa-f]|$)|#[0-9A-Fa-f]{6}"
  "Color\\((red|white|hue|\\.sRGB|\\.displayP3|nsColor):|Color\\.(${COLORS})([^A-Za-z0-9_]|$)|\\.(foregroundStyle|foregroundColor|fill|stroke|background|tint|border)\\(\\.(${COLORS})\\)"
  "(^|[^A-Za-z0-9_])(Button|Toggle|TextField|SecureField|Picker)[[:space:]]*[({\[]|\\.(sheet|popover|contextMenu)[[:space:]]*[({\[]"
  "\\.opacity\\(([^)]*[^0-9A-Za-z_.])?0?\\.[0-9]*[1-9]"
  "\\.frame\\(([^)]*, *)?(width|height|minWidth|maxWidth|minHeight|maxHeight|idealWidth|idealHeight): *-?([1-9]|0\\.[0-9]*[1-9])"
  "ChamferShape\\( *cut: *([^,)]*[^A-Za-z0-9_.])?[0-9]|\\.cornerBrackets\\([^)]*(length|inset): *-?[0-9]"
  "\\.(easeIn|easeOut|easeInOut|linear|spring|interactiveSpring|interpolatingSpring|snappy|smooth|bouncy|timingCurve)\\([^)]*(duration|response|dampingFraction|blendDuration|bounce|extraBounce|stiffness|damping): *[0-9.]|\\.(delay|speed)\\( *[0-9.]"
)

MODE="default"
LIST_RULE=""
SELF_TEST=0
LIST_ALLOWS=0

while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE="check" ;;
    --rebaseline) MODE="rebaseline" ;;
    --check-raise) MODE="check-raise"; RAISE_REF="$2"; shift ;;
    --list) MODE="list"; LIST_RULE="$2"; shift ;;
    --list-allows) MODE="list-allows" ;;
    --self-test) SELF_TEST=1 ;;
    *) echo "design-lint: unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "design-lint: not a git repository" >&2; exit 2; }
cd "$repo_root" || exit 2

[ -d "Sources" ] || { echo "design-lint: not a repo root (no Sources/)" >&2; exit 2; }

collect_files() {
  local tracked_only="$1"
  local files=()
  if [ "$tracked_only" = "1" ]; then
    while IFS= read -r -d '' f; do
      case "$f" in Sources/*.swift|Tests/*.swift) files+=("$f") ;; esac
    done < <(git ls-files -z)
  else
    while IFS= read -r -d '' f; do
      case "$f" in Sources/*.swift|Tests/*.swift) files+=("$f") ;; esac
    done < <(git ls-files -z -co --exclude-standard -- Sources Tests)
  fi
  [ ${#files[@]} -gt 0 ] || { echo "design-lint: no Swift files found" >&2; exit 2; }
  printf '%s\n' "${files[@]}"
}

is_comment_line() {
  local line="$1"
  local trimmed="${line%%[![:space:]]*}"
  local rest="${line#"${trimmed}"}"
  case "$rest" in
    //*) return 0 ;;
    "/*"*) return 0 ;;
    "*"*) return 0 ;;
  esac
  return 1
}

[ $SELF_TEST -eq 1 ] && { source "$SELF_TEST_FILE"; run_self_test; exit $?; }

run_lint() {
  local tracked_only="$1"
  local files=()
  while IFS= read -r f; do files+=("$f"); done < <(collect_files "$tracked_only")
  
  local counts=()
  local allowed_counts=()
  local i=0
  while [ $i -lt ${#rule_names[@]} ]; do
    counts+=("0")
    allowed_counts+=("0")
    i=$((i + 1))
  done
  
  local bad_allows=()
  local file_allows=()
  local line_allows=()
  
  for file in "${files[@]}"; do
    local fa=()
    local lineno=0
    while IFS= read -r line && [ $lineno -lt 10 ]; do
      lineno=$((lineno + 1))
      if [[ "$line" =~ //[[:space:]]*design-lint:[[:space:]]*allow-file[[:space:]]+([^[:space:]]+)[[:space:]]+(.+) ]]; then
        local rule_list="${BASH_REMATCH[1]}" reason="${BASH_REMATCH[2]}"
        IFS=',' read -ra rules <<< "$rule_list"
        for rule in "${rules[@]}"; do
          rule=$(echo "$rule" | xargs)
          local found=0
          local i=0
          while [ $i -lt ${#rule_names[@]} ]; do
            [ "${rule_names[$i]}" = "$rule" ] && found=1 && break
            i=$((i + 1))
          done
          if [ $found -eq 1 ]; then
            fa+=("$rule")
          else
            bad_allows+=("bad allow: $file:$lineno (unknown rule: $rule)")
          fi
        done
        [ -z "${reason// }" ] && bad_allows+=("bad allow: $file:$lineno (empty reason)")
      fi
    done < "$file"
    file_allows+=("$file|${fa[*]}")
    
    lineno=0
    while IFS= read -r line; do
      lineno=$((lineno + 1))
      if [[ "$line" =~ //[[:space:]]*design-lint:[[:space:]]*allow[[:space:]]+([^[:space:]]+)[[:space:]]+(.+) ]]; then
        local rule_list="${BASH_REMATCH[1]}" reason="${BASH_REMATCH[2]}"
        IFS=',' read -ra rules <<< "$rule_list"
        local la=()
        for rule in "${rules[@]}"; do
          rule=$(echo "$rule" | xargs)
          local found=0
          local i=0
          while [ $i -lt ${#rule_names[@]} ]; do
            [ "${rule_names[$i]}" = "$rule" ] && found=1 && break
            i=$((i + 1))
          done
          if [ $found -eq 1 ]; then
            la+=("$rule")
          else
            bad_allows+=("bad allow: $file:$lineno (unknown rule: $rule)")
          fi
        done
        [ -z "${reason// }" ] && bad_allows+=("bad allow: $file:$lineno (empty reason)")
        if [ ${#la[@]} -gt 0 ]; then
          line_allows+=("$file:$lineno|${la[*]}")
        fi
      fi
    done < "$file"
  done
  
  local ri=0
  while [ $ri -lt ${#rule_names[@]} ]; do
    local rname="${rule_names[$ri]}"
    local scope="${rule_scopes[$ri]}"
    local pattern="${rule_patterns[$ri]}"
    
    local grep_files=()
    for file in "${files[@]}"; do
      [ "$scope" = "Sources" ] && [[ "$file" != Sources/* ]] && continue
      grep_files+=("$file")
    done
    
    if [ ${#grep_files[@]} -eq 0 ]; then
      ri=$((ri + 1))
      continue
    fi
    
    local grep_pattern="${pattern//\\\\/\\}"
    local grep_out
    grep_out=$(grep -nHE "$grep_pattern" "${grep_files[@]}" 2>/dev/null || true)
    
    local count=0
    local allowed=0
    
    if [ -n "$grep_out" ]; then
      local line_allows_str=$(IFS=$'\x01'; echo "${line_allows[*]}")
      local file_allows_str=$(IFS=$'\x01'; echo "${file_allows[*]}")
      
      local awk_out
      if [ "$MODE" = "list" ]; then
        AWK_RULE="$grep_pattern" AWK_RNAME="$rname" AWK_MODE="$MODE" AWK_LIST_RULE="$LIST_RULE" \
        awk -v line_allows="$line_allows_str" -v file_allows="$file_allows_str" '
        BEGIN {
          split(line_allows, line_allows_arr, "\x01")
          split(file_allows, file_allows_arr, "\x01")
          rule = ENVIRON["AWK_RULE"]
          rname = ENVIRON["AWK_RNAME"]
          mode = ENVIRON["AWK_MODE"]
          list_rule = ENVIRON["AWK_LIST_RULE"]
        }
        {
          file = FILENAME
          line = $0
          lineno = FNR
          
          trimmed = line
          sub(/^[[:space:]]*/, "", trimmed)
          if (trimmed ~ /^\/\// || trimmed ~ /^\/\*/ || trimmed ~ /^\*/) next
          
          if (line ~ rule) {
            allowed = 0
            for (i in line_allows_arr) {
              split(line_allows_arr[i], parts, "|")
              if (parts[1] == file && parts[2] == lineno) {
                split(parts[3], rules, " ")
                for (j in rules) {
                  if (rules[j] == rname) {
                    allowed = 1
                    break
                  }
                }
              }
              if (allowed) break
            }
            
            if (!allowed) {
              for (i in file_allows_arr) {
                split(file_allows_arr[i], parts, "|")
                if (parts[1] == file) {
                  split(parts[2], rules, " ")
                  for (j in rules) {
                    if (rules[j] == rname) {
                      allowed = 1
                      break
                    }
                  }
                }
                if (allowed) break
              }
            }
            
            if (mode == "list" && list_rule == rname) {
              suffix = allowed ? " [allowed]" : ""
              print file ":" lineno ": " line suffix
            }
          }
        }' "${grep_files[@]}" 2>/dev/null || true
        ri=$((ri + 1))
        continue
      fi
      
      awk_out=$(AWK_RULE="$grep_pattern" AWK_RNAME="$rname" AWK_MODE="$MODE" AWK_LIST_RULE="$LIST_RULE" \
        awk -v line_allows="$line_allows_str" -v file_allows="$file_allows_str" '
        BEGIN {
          split(line_allows, line_allows_arr, "\x01")
          split(file_allows, file_allows_arr, "\x01")
          rule = ENVIRON["AWK_RULE"]
          rname = ENVIRON["AWK_RNAME"]
          mode = ENVIRON["AWK_MODE"]
          list_rule = ENVIRON["AWK_LIST_RULE"]
          count = 0
          allowed_count = 0
        }
        {
          file = FILENAME
          line = $0
          lineno = FNR
          
          trimmed = line
          sub(/^[[:space:]]*/, "", trimmed)
          if (trimmed ~ /^\/\// || trimmed ~ /^\/\*/ || trimmed ~ /^\*/) next
          
          if (line ~ rule) {
            allowed = 0
            for (i in line_allows_arr) {
              split(line_allows_arr[i], parts, "|")
              if (parts[1] == file && parts[2] == lineno) {
                split(parts[3], rules, " ")
                for (j in rules) {
                  if (rules[j] == rname) {
                    allowed = 1
                    break
                  }
                }
              }
              if (allowed) break
            }
            
            if (!allowed) {
              for (i in file_allows_arr) {
                split(file_allows_arr[i], parts, "|")
                if (parts[1] == file) {
                  split(parts[2], rules, " ")
                  for (j in rules) {
                    if (rules[j] == rname) {
                      allowed = 1
                      break
                    }
                  }
                }
                if (allowed) break
              }
            }
            
            if (mode == "list" && list_rule == rname) {
              suffix = allowed ? " [allowed]" : ""
              print file ":" lineno ": " line suffix
            }
            
            if (allowed) allowed_count++
            else count++
          }
        }
        END {
          print "COUNT:" count
          print "ALLOWED:" allowed_count
        }' "${grep_files[@]}" 2>/dev/null || true)
      
      local count=$(echo "$awk_out" | grep "^COUNT:" | cut -d: -f2)
      local allowed=$(echo "$awk_out" | grep "^ALLOWED:" | cut -d: -f2)
      
      counts[$ri]="${count:-0}"
      allowed_counts[$ri]="${allowed:-0}"
    else
      counts[$ri]="0"
      allowed_counts[$ri]="0"
    fi
    
    ri=$((ri + 1))
  done
  
  for ba in "${bad_allows[@]}"; do echo "$ba" >&2; done
  
  if [ "$MODE" = "list-allows" ]; then
    for entry in "${file_allows[@]}"; do
      local efile="${entry%%|*}"
      local erules="${entry#*|}"
      for rule in $erules; do
        echo "$efile:1: allow-file $rule"
      done
    done
    for entry in "${line_allows[@]}"; do
      local efile="${entry%%|*}"
      local erest="${entry#*|}"
      local elineno="${erest%%|*}"
      local erules="${erest#*|}"
      for rule in $erules; do
        echo "$efile:$elineno: allow $rule"
      done
    done
    return
  fi
  
  if [ "$MODE" = "list" ]; then return; fi
  
  local repo_name=$(basename "$repo_root")
  local total_files=${#files[@]}
  local source_files=0
  for f in "${files[@]}"; do [[ "$f" == Sources/* ]] && source_files=$((source_files + 1)); done
  
  echo "design-lint v1 · $repo_name · $source_files sources · $total_files files"
  printf "%-18s %6s %6s %6s\n" "rule" "count" "base" "allowed"
  
  local failed=0
  local ri=0
  while [ $ri -lt ${#rule_names[@]} ]; do
    local rname="${rule_names[$ri]}"
    local count=${counts[$ri]:-0}
    local allowed=${allowed_counts[$ri]:-0}
    local base=0 status="ok"
    
    if [ "$MODE" = "default" ]; then
      printf "%-18s %6d %6d %6d  %s\n" "$rname" "$count" "$base" "$allowed" "$status"
    else
      printf "%-18s %6d %6d %6d  %s\n" "$rname" "$count" "$base" "$allowed" "$status"
      [ $count -gt 0 ] && [ "$MODE" = "check" ] && failed=1
    fi
    ri=$((ri + 1))
  done
  
  if [ "$MODE" = "check" ] && [ $failed -eq 1 ]; then
    echo "design-lint: FAIL — rules over baseline" >&2
    exit 1
  fi
}

if [ "$MODE" = "default" ]; then
  run_lint 0
elif [ "$MODE" = "check" ]; then
  run_lint 1
elif [ "$MODE" = "list" ] || [ "$MODE" = "list-allows" ]; then
  run_lint 0
else
  echo "design-lint: mode $MODE not implemented in task 2.1" >&2
  exit 2
fi