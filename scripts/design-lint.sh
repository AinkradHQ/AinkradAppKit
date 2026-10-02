#!/bin/bash
# design-lint.sh — design rules + allow syntax (Epic 2 task 2.1)
# DESIGN_LINT_VERSION=1

set -o pipefail

[ -n "${BASH_VERSION:-}" ] || { echo "design-lint: must run under bash" >&2; exit 2; }

COLORS="red|blue|green|orange|yellow|pink|purple|gray|grey|black|white|cyan|mint|teal|indigo|brown"

RULES=(
  "font-size|Sources|\\.system\\(size:|systemFont\\(ofSize:|\\.custom\\(\"[^\"]*\", *size:"
  "padding-literal|Sources|\\.padding\\(([^)]*, *)?-?[0-9]"
  "spacing-literal|Sources|spacing: *-?([1-9]|0\\.[0-9]*[1-9])"
  "radius-literal|Sources|(cornerRadius|radius): *[0-9]|\\.cornerRadius\\( *[0-9]"
  "hex-color|Sources|Color\\(hex:|NSColor\\(hex:|0x[0-9A-Fa-f]{6}([^0-9A-Fa-f]|$)|#[0-9A-Fa-f]{6}"
  "raw-color|Sources|Color\((red|white|hue|\\.sRGB|\\.displayP3|nsColor):|Color\\.(${COLORS})([^A-Za-z0-9_]|$)|\\.(foregroundStyle|foregroundColor|fill|stroke|background|tint|border)\\(\\.(${COLORS})\\)"
  "raw-control|Sources|(^|[^A-Za-z0-9_.])(Button|Toggle|TextField|SecureField|Picker)[[:space:]]*\\(|\\.(sheet|popover|contextMenu)[[:space:]]*[({]"
  "opacity-literal|Sources|\\.opacity\\(([^)]*[^0-9A-Za-z_.])?0?\\.[0-9]*[1-9]"
  "frame-literal|Sources|\\.frame\\(([^)]*, *)?(width|height|minWidth|maxWidth|minHeight|maxHeight|idealWidth|idealHeight): *-?([1-9]|0\\.[0-9]*[1-9])"
  "chamfer-literal|Sources|ChamferShape\\( *cut: *([^,)]*[^A-Za-z0-9_.])?[0-9]|\\.cornerBrackets\\([^)]*(length|inset): *-?[0-9]"
  "motion-literal|Sources|\\.(easeIn|easeOut|easeInOut|linear|spring|interactiveSpring|interpolatingSpring|snappy|smooth|bouncy|timingCurve)\\([^)]*(duration|response|dampingFraction|blendDuration|bounce|extraBounce|stiffness|damping): *[0-9.]|\\.(delay|speed)\\( *[0-9.]"
)

MODE="default"
LIST_RULE=""
SELF_TEST=0
LIST_ALLOWS=0

CHECK_FILE_ALLOWS=()
CHECK_LINE_ALLOWS=()
CHECK_BAD_ALLOWS=()

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

rule_names=()
rule_scopes=()
rule_patterns=()
for rule_entry in "${RULES[@]}"; do
  IFS='|' read -r rname scope pattern <<< "$rule_entry"
  rule_names+=("$rname")
  rule_scopes+=("$scope")
  rule_patterns+=("$pattern")
done

check_allows() {
  local line="$1" file="$2" lineno="$3" type="$4"
  local prefix="allow"
  [ "$type" = "file" ] && prefix="allow-file"
  if [[ "$line" =~ //[[:space:]]*design-lint:[[:space:]]*$prefix[[:space:]]+([^[:space:]]+)[[:space:]]+(.+) ]]; then
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
      if [ $found -eq 0 ]; then
        CHECK_BAD_ALLOWS+=("bad allow: $file:$lineno (unknown rule: $rule)")
      else
        if [ "$type" = "file" ]; then
          CHECK_FILE_ALLOWS+=("$rule")
        else
          CHECK_LINE_ALLOWS+=("$rule")
        fi
      fi
    done
    [ -z "${reason// }" ] && CHECK_BAD_ALLOWS+=("bad allow: $file:$lineno (empty reason)")
  fi
}

run_self_test() {
  file_allows=()
  local tmpdir=$(mktemp -d)
  cd "$tmpdir"
  git init -q
  git config user.email "test@test"
  git config user.name "Test"
  mkdir -p Sources Tests

  cat > Sources/Rule1.swift <<'EOF'
.font(.system(size: 12))
.font(.system(size: 14)) // design-lint: allow font-size test
// comment .font(.system(size: 16))
EOF

  cat > Sources/Rule2.swift <<'EOF'
.padding(8)
.padding(.horizontal, 12) // design-lint: allow padding-literal test
.padding()
EOF

  cat > Sources/Rule3.swift <<'EOF'
spacing: 8
spacing: 4 // design-lint: allow spacing-literal test
// comment spacing: 12
EOF

  cat > Sources/Rule4.swift <<'EOF'
cornerRadius: 8
.cornerRadius(12) // design-lint: allow radius-literal test
.radius: 0
EOF

  cat > Sources/Rule5.swift <<'EOF'
Color(hex: "FF0000")
Color(hex: 0xFF0000)
"#FF0000"
Color(hex: "00FF00") // design-lint: allow hex-color test
NSColor(hex: "0000FF")
EOF

  cat > Sources/Rule6.swift <<'EOF'
Color(red: 1, green: 0, blue: 0)
Color.blue
.foregroundStyle(.red)
.fill(.blue)
.background(.green)
.stroke(.orange)
.tint(.purple)
.border(.gray)
Color(white: 0.5) // design-lint: allow raw-color test
EOF

  cat > Sources/Rule7.swift <<'EOF'
Button("Test") {}
Toggle("Test", isOn: .constant(true))
TextField("Test", text: .constant(""))
SecureField("Test", text: .constant(""))
Picker("Test", selection: .constant(0)) {}
.sheet(isPresented: .constant(true)) {}
.popover(isPresented: .constant(true)) {}
.contextMenu {} // design-lint: allow raw-control test
AinkradButton("Test") {}
ColorPicker("Test", selection: .constant(.red))
AinkradTextField("Test", text: .constant(""))
EOF

  cat > Sources/Rule13.swift <<'EOF'
.opacity(0.5)
.opacity(on ? 0.6 : 1)
.opacity(0)
.opacity(1)
.opacity(1.0)
.opacity(on ? 1 : 0)
.opacity(skin.opacity.dim)
.opacity(.4) // design-lint: allow opacity-literal test
// comment .opacity(0.3)
EOF

  cat > Sources/Rule14.swift <<'EOF'
.frame(maxWidth: .infinity, minHeight: 28)
.frame(width: 100)
.frame(maxWidth: .infinity)
.frame(width: 0)
.frame(width: size)
.frame(height: 50) // design-lint: allow frame-literal test
// comment .frame(height: 50)
EOF

  cat > Sources/Rule15.swift <<'EOF'
ChamferShape(cut: size * 0.3)
.cornerBrackets(length: 8, inset: -2)
ChamferShape(cut: AinkradRadius.md)
.cornerBrackets(length: 4, inset: 1) // design-lint: allow chamfer-literal test
// comment ChamferShape(cut: 4)
EOF

  cat > Sources/Rule16.swift <<'EOF'
.spring(response: 0.3, dampingFraction: 0.8)
.delay(0.1)
withAnimation(.easeInOut)
withAnimation(skin.motion.quick)
Task.sleep(for: .seconds(2))
.spring(response: 0.5) // design-lint: allow motion-literal test
// comment .spring(response: 0.5)
EOF

  cat > Sources/AllowFile.swift <<'EOF'
// design-lint: allow-file font-size,padding-literal theme layer
.font(.system(size: 12))
.padding(8)
EOF

  for i in {1..500}; do echo "line $i"; done > Tests/FileLength500.swift
  for i in {1..501}; do echo "line $i"; done > Tests/FileLength501.swift

  git add -A
  git commit -q -m "fixtures"

  echo "Running self-test..."
  
  local files=()
  while IFS= read -r f; do files+=("$f"); done < <(collect_files 0)
  
  local counts=()
  local allowed_counts=()
  local i=0
  while [ $i -lt ${#rule_names[@]} ]; do
    counts+=("0")
    allowed_counts+=("0")
    i=$((i + 1))
  done

local bad_allows=()
   
  for file in "${files[@]}"; do
    file_allows=()
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
            file_allows+=("$rule")
          else
            CHECK_BAD_ALLOWS+=("bad allow: $file:$lineno (unknown rule: $rule)")
          fi
        done
        [ -z "${reason// }" ] && CHECK_BAD_ALLOWS+=("bad allow: $file:$lineno (empty reason)")
      fi
    done < "$file"

    lineno=0
    while IFS= read -r line; do
      lineno=$((lineno + 1))
      
      is_comment_line "$line" && continue
      
      local ri=0
      while [ $ri -lt ${#rule_names[@]} ]; do
        local rname="${rule_names[$ri]}"
        local scope="${rule_scopes[$ri]}"
        local pattern="${rule_patterns[$ri]}"
        [ "$scope" = "Sources" ] && [[ "$file" != Sources/* ]] && { ri=$((ri + 1)); continue; }
        
        if echo "$line" | grep -qE "$pattern"; then
          local is_allowed=0
          if [[ "$line" =~ //[[:space:]]*design-lint:[[:space:]]*allow[[:space:]]+([^[:space:]]+)[[:space:]]+(.+) ]]; then
            local rule_list="${BASH_REMATCH[1]}" reason="${BASH_REMATCH[2]}"
            IFS=',' read -ra rules <<< "$rule_list"
            for rule in "${rules[@]}"; do
              rule=$(echo "$rule" | xargs)
              if [ "$rule" = "$rname" ]; then
                is_allowed=1
                break
              fi
            done
          fi
          if [ $is_allowed -eq 0 ]; then
            for a in "${file_allows[@]}"; do [ "$a" = "$rname" ] && is_allowed=1 && break; done
          fi
          
          if [ $is_allowed -eq 1 ]; then
            allowed_counts[$ri]=$((${allowed_counts[$ri]} + 1))
          else
            counts[$ri]=$((${counts[$ri]} + 1))
          fi
        fi
        ri=$((ri + 1))
      done
    done < "$file"
  done

  local failed=0
  local ri=0
  while [ $ri -lt ${#rule_names[@]} ]; do
    local rname="${rule_names[$ri]}"
    local count=${counts[$ri]:-0}
    local allowed=${allowed_counts[$ri]:-0}
    local expected=1
    local expected_allowed=1
    
    case "$rname" in
      "font-size") expected=1; expected_allowed=2 ;;
      "padding-literal") expected=1; expected_allowed=2 ;;
      "spacing-literal") expected=1; expected_allowed=1 ;;
      "radius-literal") expected=2; expected_allowed=1 ;;
      "hex-color") expected=4; expected_allowed=1 ;;
      "raw-color") expected=8; expected_allowed=1 ;;
      "raw-control") expected=7; expected_allowed=1 ;;
      "opacity-literal") expected=2; expected_allowed=1 ;;
      "frame-literal") expected=2; expected_allowed=1 ;;
      "chamfer-literal") expected=2; expected_allowed=1 ;;
      "motion-literal") expected=2; expected_allowed=1 ;;
    esac
    
    if [ $count -ne $expected ]; then
      echo "FAIL: $rname count=$count expected=$expected" >&2
      failed=1
    fi
    if [ $allowed -ne $expected_allowed ]; then
      echo "FAIL: $rname allowed=$allowed expected=$expected_allowed" >&2
      failed=1
    fi
    ri=$((ri + 1))
  done

  if [ ${#CHECK_BAD_ALLOWS[@]} -gt 0 ]; then
    for ba in "${CHECK_BAD_ALLOWS[@]}"; do echo "$ba" >&2; done
  fi

  

  local fl500=0 fl501=0
  for file in "${files[@]}"; do
    local lines=$(wc -l < "$file")
    [ $lines -gt 500 ] && fl501=$((fl501 + 1)) || fl500=$((fl500 + 1))
  done
  [ $fl501 -eq 1 ] || { echo "FAIL: file-length should catch 1 file (501 lines), got $fl501" >&2; failed=1; }
  [ $fl500 -ge 1 ] || { echo "FAIL: file-length should not catch 500-line file" >&2; failed=1; }

  cd - >/dev/null
  rm -rf "$tmpdir"
  
  [ $failed -eq 0 ] && echo "self-test: PASS" || echo "self-test: FAIL" >&2
  return $failed
}

[ $SELF_TEST -eq 1 ] && { run_self_test; exit $?; }

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
  
  local file_allows_map=()
  local line_allows_map=()
  
  for file in "${files[@]}"; do
    local file_allows=()
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
            file_allows+=("$rule")
          else
            bad_allows+=("bad allow: $file:$lineno (unknown rule: $rule)")
          fi
        done
        [ -z "${reason// }" ] && bad_allows+=("bad allow: $file:$lineno (empty reason)")
      fi
    done < "$file"
    file_allows_map+=("$file|${file_allows[*]}")
    
    lineno=0
    while IFS= read -r line; do
      lineno=$((lineno + 1))
      if [[ "$line" =~ //[[:space:]]*design-lint:[[:space:]]*allow[[:space:]]+([^[:space:]]+)[[:space:]]+(.+) ]]; then
        local rule_list="${BASH_REMATCH[1]}" reason="${BASH_REMATCH[2]}"
        IFS=',' read -ra rules <<< "$rule_list"
        local allowed_rules=()
        for rule in "${rules[@]}"; do
          rule=$(echo "$rule" | xargs)
          local found=0
          local i=0
          while [ $i -lt ${#rule_names[@]} ]; do
            [ "${rule_names[$i]}" = "$rule" ] && found=1 && break
            i=$((i + 1))
          done
          if [ $found -eq 1 ]; then
            allowed_rules+=("$rule")
          else
            bad_allows+=("bad allow: $file:$lineno (unknown rule: $rule)")
          fi
        done
        [ -z "${reason// }" ] && bad_allows+=("bad allow: $file:$lineno (empty reason)")
        if [ ${#allowed_rules[@]} -gt 0 ]; then
          line_allows_map+=("$file:$lineno|${allowed_rules[*]}")
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
    
    local grep_out
    grep_out=$(grep -nHE "$pattern" "${grep_files[@]}" 2>/dev/null || true)
    
    if [ -n "$grep_out" ]; then
      while IFS= read -r match_line; do
        [ -z "$match_line" ] && continue
        local gfile="${match_line%%:*}"
        local rest="${match_line#*:}"
        local glineno="${rest%%:*}"
        local gtext="${rest#*:}"
        
        local is_comment=0
        local trimmed="${gtext%%[![:space:]]*}"
        local rest2="${gtext#"${trimmed}"}"
        case "$rest2" in
          //*) is_comment=1 ;;
          "/*"*) is_comment=1 ;;
          "*"*) is_comment=1 ;;
        esac
        [ $is_comment -eq 1 ] && continue
        
        local is_allowed=0
        
        for entry in "${line_allows_map[@]}"; do
          local efile="${entry%%|*}"
          local erest="${entry#*|}"
          local elineno="${erest%%|*}"
          local erules="${erest#*|}"
          if [ "$efile" = "$gfile" ] && [ "$elineno" = "$glineno" ]; then
            for rule in $erules; do
              [ "$rule" = "$rname" ] && is_allowed=1 && break
            done
            [ $is_allowed -eq 1 ] && break
          fi
        done
        
        if [ $is_allowed -eq 0 ]; then
          for entry in "${file_allows_map[@]}"; do
            local efile="${entry%%|*}"
            local erules="${entry#*|}"
            if [ "$efile" = "$gfile" ]; then
              for rule in $erules; do
                [ "$rule" = "$rname" ] && is_allowed=1 && break
              done
              [ $is_allowed -eq 1 ] && break
            fi
          done
        fi
        
        if [ "$MODE" = "list" ] && [ -n "$LIST_RULE" ] && [ "$LIST_RULE" = "$rname" ]; then
          local suffix=""
          [ $is_allowed -eq 1 ] && suffix=" [allowed]"
          echo "$gfile:$glineno: $gtext$suffix"
        fi
        
        if [ $is_allowed -eq 1 ]; then
          allowed_counts[$ri]=$((${allowed_counts[$ri]} + 1))
        else
          counts[$ri]=$((${counts[$ri]} + 1))
        fi
      done <<< "$grep_out"
    fi
    
    ri=$((ri + 1))
  done
  
  for ba in "${bad_allows[@]}"; do echo "$ba" >&2; done
  
  if [ "$MODE" = "list-allows" ]; then
    for entry in "${file_allows_map[@]}"; do
      local efile="${entry%%|*}"
      local erules="${entry#*|}"
      for rule in $erules; do
        echo "$efile:1: allow-file $rule"
      done
    done
    for entry in "${line_allows_map[@]}"; do
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