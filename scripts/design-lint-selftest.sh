# design-lint-selftest.sh — self-test fixtures and runner for design-lint.sh
# Sourced by design-lint.sh --self-test

run_self_test() {
  echo "Running self-test..."
  
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

  cat > Sources/CommentSkip.swift <<'EOF'
/// COMMENT-MUST-NOT-COUNT font-size .font(.system(size: 99))
/// COMMENT-MUST-NOT-COUNT hex-color project stored `#FF0000`
/// COMMENT-MUST-NOT-COUNT chamfer There were two — `ChamferShape(cut: 6)`
   /// COMMENT-MUST-NOT-COUNT raw-control Button("X") {}
// COMMENT-MUST-NOT-COUNT raw-color Theme surface, not `Color.gray`
// COMMENT-MUST-NOT-COUNT opacity .opacity(0.5)
// COMMENT-MUST-NOT-COUNT frame .frame(width: 99)
// COMMENT-MUST-NOT-COUNT motion .delay(0.1)
// COMMENT-MUST-NOT-COUNT radius .cornerRadius(12)
// COMMENT-MUST-NOT-COUNT padding .padding(8)
// COMMENT-MUST-NOT-COUNT spacing spacing: 8
/* COMMENT-MUST-NOT-COUNT raw-control Toggle("X", isOn: .constant(true)) */
/* COMMENT-MUST-NOT-COUNT opacity .opacity(0.7) */
 * COMMENT-MUST-NOT-COUNT frame .frame(height: 50)
 * COMMENT-MUST-NOT-COUNT motion .spring(response: 0.5)
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
    local file_allows=()
    local lineno=0
    while IFS= read -r line; do
      lineno=$((lineno + 1))
      [ $lineno -gt 10 ] && break
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

  # Bugs 1+2 regression: exercise the REAL grep+awk engine (not the loop
  # above) on these fixtures. (1) No comment-only fixture line may be
  # listed or counted — covers ///, //, /* and * prefixes. (2) Every
  # --list line must be <file>:<line>: shaped, never <rule>:0:.
  local real_script="$SELF_TEST_DIR/design-lint.sh"
  local r
  for r in "${rule_names[@]}"; do
    local out
    out=$(bash "$real_script" --list "$r" 2>/dev/null || true)
    if echo "$out" | grep -q "COMMENT-MUST-NOT-COUNT"; then
      echo "FAIL: --list $r leaks comment lines" >&2
      failed=1
    fi
    while IFS= read -r l; do
      [ -z "$l" ] && continue
      case "$l" in
        Sources/*:[1-9]*:*) ;;
        *) echo "FAIL: --list $r bad shape: $l" >&2; failed=1 ;;
      esac
      case "$l" in
        "$r":*) echo "FAIL: --list $r prints rule instead of file: $l" >&2; failed=1 ;;
      esac
      case "$l" in
        *:0:*) echo "FAIL: --list $r prints lineno 0: $l" >&2; failed=1 ;;
      esac
    done <<< "$out"
  done
  if ! bash "$real_script" --list raw-control 2>/dev/null | grep -q 'Sources/Rule7.swift:.*Button'; then
    echo "FAIL: --list raw-control misses the real Rule7 Button hit" >&2
    failed=1
  fi

  cd - >/dev/null
  rm -rf "$tmpdir"
  
  [ $failed -eq 0 ] && echo "self-test: PASS" || echo "self-test: FAIL" >&2
  return $failed
}