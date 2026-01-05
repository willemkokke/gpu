#!/usr/bin/env zsh
# Dotenv test runner for Zsh (or Bash 4+)
# Usage: zsh scripts/tests/dotenv-test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
FIXTURES="$SCRIPT_DIR/fixtures"
DOTENV="$SCRIPT_DIR/../dotenv.sh"

# Colors (only if terminal supports them)
if [[ -t 1 ]] && [[ "${TERM:-dumb}" != "dumb" ]]; then
    _green='\033[0;32m'
    _red='\033[0;31m'
    _cyan='\033[0;36m'
    _reset='\033[0m'
else
    _green=''
    _red=''
    _cyan=''
    _reset=''
fi

# Use temp files for counters (subshells can't modify parent variables)
_pass_file=$(mktemp)
_fail_file=$(mktemp)
echo "0" > "$_pass_file"
echo "0" > "$_fail_file"

assert_eq() {
    local name="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        printf "  ${_green}PASS${_reset} %s\n" "$name"
        echo $(( $(cat "$_pass_file") + 1 )) > "$_pass_file"
    else
        printf "  ${_red}FAIL${_reset} %s\n" "$name"
        printf "       expected: '%s'\n" "$expected"
        printf "       actual:   '%s'\n" "$actual"
        echo $(( $(cat "$_fail_file") + 1 )) > "$_fail_file"
    fi
}

# Run test in subshell to isolate environment
run_test() {
    local test_name="$1"
    shift
    printf "${_cyan}Test: %s${_reset}\n" "$test_name"
    "$@"
    echo ""
}

# ============================================================================
# Test 1: Basic Parsing
# ============================================================================
test_basic() {
    (
        source "$DOTENV" "$FIXTURES/basic.env"
        assert_eq "SIMPLE" "value" "$SIMPLE"
        assert_eq "SPACES_AROUND" "value with spaces" "$SPACES_AROUND"
        assert_eq "EMPTY" "" "$EMPTY"
    )
}

# ============================================================================
# Test 2: Comments
# ============================================================================
test_comments() {
    (
        source "$DOTENV" "$FIXTURES/comments.env"
        assert_eq "KEY (inline comment stripped)" "value" "$KEY"
        assert_eq "HASH_IN_QUOTES" "value # not a comment" "$HASH_IN_QUOTES"
        assert_eq "HASH_IN_SINGLE" "value # not a comment" "$HASH_IN_SINGLE"
    )
}

# ============================================================================
# Test 3: Quoted Values
# ============================================================================
test_quotes() {
    (
        source "$DOTENV" "$FIXTURES/quotes.env"
        assert_eq "DOUBLE" "double quoted" "$DOUBLE"
        assert_eq "SINGLE" "single quoted" "$SINGLE"
        assert_eq "UNQUOTED" "unquoted value" "$UNQUOTED"
        assert_eq "MIXED" "has 'single' inside" "$MIXED"
        assert_eq "EMPTY_DOUBLE" "" "$EMPTY_DOUBLE"
        assert_eq "EMPTY_SINGLE" "" "$EMPTY_SINGLE"
    )
}

# ============================================================================
# Test 4: Variable Substitution - Basic
# ============================================================================
test_substitution_basic() {
    (
        source "$DOTENV" "$FIXTURES/substitution-basic.env"
        assert_eq "BASE" "hello" "$BASE"
        assert_eq "REF_BRACE (\${BASE})" "hello" "$REF_BRACE"
        assert_eq "REF_DOLLAR (\$BASE)" "hello" "$REF_DOLLAR"
        assert_eq "CHAINED" "hello-world" "$CHAINED"
    )
}

# ============================================================================
# Test 5: Variable Substitution - Underscores
# ============================================================================
test_substitution_underscore() {
    (
        source "$DOTENV" "$FIXTURES/substitution-underscore.env"
        assert_eq "VAR_ONE" "first" "$VAR_ONE"
        assert_eq "VAR_TWO" "second" "$VAR_TWO"
        assert_eq "USCORE_REF_BRACE (\${VAR_ONE})" "first" "$USCORE_REF_BRACE"
        assert_eq "USCORE_REF_DOLLAR (\$VAR_ONE)" "first" "$USCORE_REF_DOLLAR"
        assert_eq "COMBINED" "first_second" "$COMBINED"
    )
}

# ============================================================================
# Test 6: Single Quotes Prevent Substitution
# ============================================================================
test_substitution_escape() {
    (
        source "$DOTENV" "$FIXTURES/substitution-escape.env"
        assert_eq "ESCAPE_BASE" "hello" "$ESCAPE_BASE"
        assert_eq "LITERAL_SINGLE (single quotes)" "\$ESCAPE_BASE" "$LITERAL_SINGLE"
        assert_eq "LITERAL_BRACE_SINGLE (single quotes)" "\${ESCAPE_BASE}" "$LITERAL_BRACE_SINGLE"
        assert_eq "EXPANDED_DOUBLE (double quotes)" "hello" "$EXPANDED_DOUBLE"
        assert_eq "BACKSLASH (escaped)" "\$ESCAPE_BASE" "$BACKSLASH"
    )
}

# ============================================================================
# Test 7: Non-existent Variables
# ============================================================================
test_substitution_missing() {
    (
        source "$DOTENV" "$FIXTURES/substitution-missing.env"
        assert_eq "MISSING" "" "$MISSING"
        assert_eq "MISSING_BRACE" "" "$MISSING_BRACE"
        assert_eq "PARTIAL" "prefix--suffix" "$PARTIAL"
    )
}

# ============================================================================
# Test 8: Tilde Expansion
# ============================================================================
test_tilde() {
    (
        source "$DOTENV" "$FIXTURES/tilde.env"
        assert_eq "HOME_PATH" "$HOME/folder" "$HOME_PATH"
        assert_eq "SUBPATH" "$HOME/.config/app" "$SUBPATH"
        assert_eq "NOT_TILDE (middle ~)" "not~tilde" "$NOT_TILDE"
    )
}

# ============================================================================
# Test 9: Override Behavior - Two Files
# ============================================================================
test_override() {
    (
        source "$DOTENV" "$FIXTURES/override-base.env" "$FIXTURES/override-local.env"
        assert_eq "SHARED (local wins)" "from-local" "$SHARED"
        assert_eq "BASE_ONLY" "base-value" "$BASE_ONLY"
        assert_eq "LOCAL_ONLY" "local-value" "$LOCAL_ONLY"
        assert_eq "TO_OVERRIDE" "overridden" "$TO_OVERRIDE"
    )
}

# ============================================================================
# Test 10: Environment Variables Never Overwritten
# ============================================================================
test_env_priority() {
    (
        # Save original PATH
        original_path="$PATH"
        # Set a custom var before loading
        export CUSTOM="from-env"

        source "$DOTENV" "$FIXTURES/env-priority.env"

        assert_eq "PATH (not overwritten)" "$original_path" "$PATH"
        assert_eq "CUSTOM (env wins)" "from-env" "$CUSTOM"
    )
}

# ============================================================================
# Test 11: Cross-file Variable References
# ============================================================================
test_cross_ref() {
    (
        source "$DOTENV" "$FIXTURES/cross-ref-base.env" "$FIXTURES/cross-ref-local.env"
        assert_eq "BASE_VAR" "base-value" "$BASE_VAR"
        assert_eq "DERIVED (uses BASE_VAR)" "base-value-extended" "$DERIVED"
    )
}

# ============================================================================
# Test 12: Recursive/Chained Substitution
# ============================================================================
test_chained() {
    (
        source "$DOTENV" "$FIXTURES/chained.env"
        assert_eq "A" "1" "$A"
        assert_eq "B (\$A\$A)" "11" "$B"
        assert_eq "C (\${B}\${B})" "1111" "$C"
    )
}

# ============================================================================
# Test 13: Env Var Substitution (CI scenario)
# When an env var is set (e.g., TOOLS_FOLDER=~/.tools from CI), other vars
# that reference it should use the env value, not the .env file value.
# ============================================================================
test_env_substitution() {
    (
        # Simulate CI environment: TOOLS_FOLDER set with tilde
        export TOOLS_FOLDER="~/.tools"

        source "$DOTENV" "$FIXTURES/env-substitution.env"

        # TOOLS_FOLDER should be env value (not .tools from file), with tilde expanded
        assert_eq "TOOLS_FOLDER (from env, tilde expanded)" "$HOME/.tools" "$TOOLS_FOLDER"
        # UV_CACHE_DIR should use the expanded env value
        assert_eq "UV_CACHE_DIR (uses env TOOLS_FOLDER)" "$HOME/.tools/uv/cache" "$UV_CACHE_DIR"
        assert_eq "UV_PYTHON_DIR (uses env TOOLS_FOLDER)" "$HOME/.tools/uv/python" "$UV_PYTHON_DIR"
    )
}

# ============================================================================
# Run all tests
# ============================================================================
echo ""
echo "Running dotenv.sh tests..."
echo ""

run_test "Basic Parsing" test_basic
run_test "Comments" test_comments
run_test "Quoted Values" test_quotes
run_test "Variable Substitution - Basic" test_substitution_basic
run_test "Variable Substitution - Underscores" test_substitution_underscore
run_test "Single Quotes Prevent Substitution" test_substitution_escape
run_test "Non-existent Variables" test_substitution_missing
run_test "Tilde Expansion" test_tilde
run_test "Override Behavior" test_override
run_test "Environment Variables Never Overwritten" test_env_priority
run_test "Cross-file Variable References" test_cross_ref
run_test "Recursive/Chained Substitution" test_chained
run_test "Env Var Substitution (CI scenario)" test_env_substitution

# Summary
pass=$(cat "$_pass_file")
fail=$(cat "$_fail_file")
rm -f "$_pass_file" "$_fail_file"

echo "============================================"
printf "Results: ${_green}%d passed${_reset}, ${_red}%d failed${_reset}\n" "$pass" "$fail"
echo "============================================"

if [[ $fail -gt 0 ]]; then
    exit 1
fi
