# Dotenv test runner for PowerShell
# Usage: pwsh scripts/tests/dotenv-test.ps1
#
# This test runner avoids spawning child processes to work around Docker/Rosetta
# emulation issues. Instead, it tracks vars set by dotenv and cleans them up
# after each test.

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Fixtures = Join-Path $ScriptDir "fixtures"
$Dotenv = Join-Path $ScriptDir ".." "dotenv.ps1"

$script:pass = 0
$script:fail = 0

# Track environment variables set during tests for cleanup
$script:testVars = @()

function Assert-Eq {
    param($Name, $Expected, $Actual)
    # Normalize null to empty string for comparison
    $exp = if ($null -eq $Expected) { "" } else { $Expected }
    $act = if ($null -eq $Actual) { "" } else { $Actual }
    if ($exp -eq $act) {
        Write-Host "  " -NoNewline
        Write-Host "PASS" -ForegroundColor Green -NoNewline
        Write-Host " $Name"
        $script:pass++
    } else {
        Write-Host "  " -NoNewline
        Write-Host "FAIL" -ForegroundColor Red -NoNewline
        Write-Host " $Name"
        Write-Host "       expected: '$exp'"
        Write-Host "       actual:   '$act'"
        $script:fail++
    }
}

# Clean up environment variables set by a test
function Clear-TestEnv {
    param([string[]]$VarNames)
    foreach ($name in $VarNames) {
        [Environment]::SetEnvironmentVariable($name, $null, 'Process')
    }
}

function Run-Test {
    param($TestName, [scriptblock]$TestBlock)
    Write-Host "Test: " -NoNewline
    Write-Host $TestName -ForegroundColor Cyan
    & $TestBlock
    Write-Host ""
}

# ============================================================================
# Test 1: Basic Parsing
# ============================================================================
function Test-Basic {
    . $Dotenv "$Fixtures/basic.env"
    Assert-Eq "SIMPLE" "value" $env:SIMPLE
    Assert-Eq "SPACES_AROUND" "value with spaces" $env:SPACES_AROUND
    Assert-Eq "EMPTY" "" $env:EMPTY
    Clear-TestEnv @("SIMPLE", "SPACES_AROUND", "EMPTY")
}

# ============================================================================
# Test 2: Comments
# ============================================================================
function Test-Comments {
    . $Dotenv "$Fixtures/comments.env"
    Assert-Eq "KEY (inline comment stripped)" "value" $env:KEY
    Assert-Eq "HASH_IN_QUOTES" "value # not a comment" $env:HASH_IN_QUOTES
    Assert-Eq "HASH_IN_SINGLE" "value # not a comment" $env:HASH_IN_SINGLE
    Clear-TestEnv @("KEY", "HASH_IN_QUOTES", "HASH_IN_SINGLE")
}

# ============================================================================
# Test 3: Quoted Values
# ============================================================================
function Test-Quotes {
    . $Dotenv "$Fixtures/quotes.env"
    Assert-Eq "DOUBLE" "double quoted" $env:DOUBLE
    Assert-Eq "SINGLE" "single quoted" $env:SINGLE
    Assert-Eq "UNQUOTED" "unquoted value" $env:UNQUOTED
    Assert-Eq "MIXED" "has 'single' inside" $env:MIXED
    Assert-Eq "EMPTY_DOUBLE" "" $env:EMPTY_DOUBLE
    Assert-Eq "EMPTY_SINGLE" "" $env:EMPTY_SINGLE
    Clear-TestEnv @("DOUBLE", "SINGLE", "UNQUOTED", "MIXED", "EMPTY_DOUBLE", "EMPTY_SINGLE")
}

# ============================================================================
# Test 4: Variable Substitution - Basic
# ============================================================================
function Test-SubstitutionBasic {
    . $Dotenv "$Fixtures/substitution-basic.env"
    Assert-Eq "BASE" "hello" $env:BASE
    Assert-Eq "REF_BRACE (`${BASE})" "hello" $env:REF_BRACE
    Assert-Eq "REF_DOLLAR (`$BASE)" "hello" $env:REF_DOLLAR
    Assert-Eq "CHAINED" "hello-world" $env:CHAINED
    Clear-TestEnv @("BASE", "REF_BRACE", "REF_DOLLAR", "CHAINED")
}

# ============================================================================
# Test 5: Variable Substitution - Underscores
# ============================================================================
function Test-SubstitutionUnderscore {
    . $Dotenv "$Fixtures/substitution-underscore.env"
    Assert-Eq "VAR_ONE" "first" $env:VAR_ONE
    Assert-Eq "VAR_TWO" "second" $env:VAR_TWO
    Assert-Eq "USCORE_REF_BRACE (`${VAR_ONE})" "first" $env:USCORE_REF_BRACE
    Assert-Eq "USCORE_REF_DOLLAR (`$VAR_ONE)" "first" $env:USCORE_REF_DOLLAR
    Assert-Eq "COMBINED" "first_second" $env:COMBINED
    Clear-TestEnv @("VAR_ONE", "VAR_TWO", "USCORE_REF_BRACE", "USCORE_REF_DOLLAR", "COMBINED")
}

# ============================================================================
# Test 6: Single Quotes Prevent Substitution
# ============================================================================
function Test-SubstitutionEscape {
    . $Dotenv "$Fixtures/substitution-escape.env"
    Assert-Eq "ESCAPE_BASE" "hello" $env:ESCAPE_BASE
    Assert-Eq "LITERAL_SINGLE (single quotes)" "`$ESCAPE_BASE" $env:LITERAL_SINGLE
    Assert-Eq "LITERAL_BRACE_SINGLE (single quotes)" "`${ESCAPE_BASE}" $env:LITERAL_BRACE_SINGLE
    Assert-Eq "EXPANDED_DOUBLE (double quotes)" "hello" $env:EXPANDED_DOUBLE
    Assert-Eq "BACKSLASH (escaped)" "`$ESCAPE_BASE" $env:BACKSLASH
    Clear-TestEnv @("ESCAPE_BASE", "LITERAL_SINGLE", "LITERAL_BRACE_SINGLE", "EXPANDED_DOUBLE", "BACKSLASH")
}

# ============================================================================
# Test 7: Non-existent Variables
# ============================================================================
function Test-SubstitutionMissing {
    . $Dotenv "$Fixtures/substitution-missing.env"
    Assert-Eq "MISSING" "" $env:MISSING
    Assert-Eq "MISSING_BRACE" "" $env:MISSING_BRACE
    Assert-Eq "PARTIAL" "prefix--suffix" $env:PARTIAL
    Clear-TestEnv @("MISSING", "MISSING_BRACE", "PARTIAL")
}

# ============================================================================
# Test 8: Tilde Expansion
# ============================================================================
function Test-Tilde {
    $homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
    . $Dotenv "$Fixtures/tilde.env"
    Assert-Eq "HOME_PATH" "$homeDir/folder" $env:HOME_PATH
    Assert-Eq "SUBPATH" "$homeDir/.config/app" $env:SUBPATH
    Assert-Eq "NOT_TILDE (middle ~)" "not~tilde" $env:NOT_TILDE
    Clear-TestEnv @("HOME_PATH", "SUBPATH", "NOT_TILDE")
}

# ============================================================================
# Test 9: Override Behavior - Two Files
# ============================================================================
function Test-Override {
    . $Dotenv "$Fixtures/override-base.env" "$Fixtures/override-local.env"
    Assert-Eq "SHARED (local wins)" "from-local" $env:SHARED
    Assert-Eq "BASE_ONLY" "base-value" $env:BASE_ONLY
    Assert-Eq "LOCAL_ONLY" "local-value" $env:LOCAL_ONLY
    Assert-Eq "TO_OVERRIDE" "overridden" $env:TO_OVERRIDE
    Clear-TestEnv @("SHARED", "BASE_ONLY", "LOCAL_ONLY", "TO_OVERRIDE")
}

# ============================================================================
# Test 10: Environment Variables Never Overwritten
# ============================================================================
function Test-EnvPriority {
    $originalPath = $env:PATH
    $env:CUSTOM = 'from-env'
    . $Dotenv "$Fixtures/env-priority.env"
    Assert-Eq "PATH (not overwritten)" $true ($env:PATH -eq $originalPath)
    Assert-Eq "CUSTOM (env wins)" "from-env" $env:CUSTOM
    Clear-TestEnv @("CUSTOM")
}

# ============================================================================
# Test 11: Cross-file Variable References
# ============================================================================
function Test-CrossRef {
    . $Dotenv "$Fixtures/cross-ref-base.env" "$Fixtures/cross-ref-local.env"
    Assert-Eq "BASE_VAR" "base-value" $env:BASE_VAR
    Assert-Eq "DERIVED (uses BASE_VAR)" "base-value-extended" $env:DERIVED
    Clear-TestEnv @("BASE_VAR", "DERIVED")
}

# ============================================================================
# Test 12: Recursive/Chained Substitution
# ============================================================================
function Test-Chained {
    . $Dotenv "$Fixtures/chained.env"
    Assert-Eq "A" "1" $env:A
    Assert-Eq "B (`$A`$A)" "11" $env:B
    Assert-Eq "C (`${B}`${B})" "1111" $env:C
    Clear-TestEnv @("A", "B", "C")
}

# ============================================================================
# Test 13: Env Var Substitution (CI scenario)
# When an env var is set (e.g., TOOLS_FOLDER=~/.tools from CI), other vars
# that reference it should use the env value, not the .env file value.
# ============================================================================
function Test-EnvSubstitution {
    $homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
    # Simulate CI environment: TOOLS_FOLDER set with tilde
    $env:TOOLS_FOLDER = "~/.tools"

    . $Dotenv "$Fixtures/env-substitution.env"

    # TOOLS_FOLDER should be env value (not .tools from file), with tilde expanded
    Assert-Eq "TOOLS_FOLDER (from env, tilde expanded)" "$homeDir/.tools" $env:TOOLS_FOLDER
    # UV_CACHE_DIR should use the expanded env value
    Assert-Eq "UV_CACHE_DIR (uses env TOOLS_FOLDER)" "$homeDir/.tools/uv/cache" $env:UV_CACHE_DIR
    Assert-Eq "UV_PYTHON_DIR (uses env TOOLS_FOLDER)" "$homeDir/.tools/uv/python" $env:UV_PYTHON_DIR
    Clear-TestEnv @("TOOLS_FOLDER", "UV_CACHE_DIR", "UV_PYTHON_DIR")
}

# ============================================================================
# Run all tests
# ============================================================================
Write-Host ""
Write-Host "Running dotenv.ps1 tests..."
Write-Host ""

Run-Test "Basic Parsing" { Test-Basic }
Run-Test "Comments" { Test-Comments }
Run-Test "Quoted Values" { Test-Quotes }
Run-Test "Variable Substitution - Basic" { Test-SubstitutionBasic }
Run-Test "Variable Substitution - Underscores" { Test-SubstitutionUnderscore }
Run-Test "Single Quotes Prevent Substitution" { Test-SubstitutionEscape }
Run-Test "Non-existent Variables" { Test-SubstitutionMissing }
Run-Test "Tilde Expansion" { Test-Tilde }
Run-Test "Override Behavior" { Test-Override }
Run-Test "Environment Variables Never Overwritten" { Test-EnvPriority }
Run-Test "Cross-file Variable References" { Test-CrossRef }
Run-Test "Recursive/Chained Substitution" { Test-Chained }
Run-Test "Env Var Substitution (CI scenario)" { Test-EnvSubstitution }

# Summary
Write-Host "============================================"
Write-Host "Results: " -NoNewline
Write-Host "$script:pass passed" -ForegroundColor Green -NoNewline
Write-Host ", " -NoNewline
Write-Host "$script:fail failed" -ForegroundColor Red
Write-Host "============================================"

if ($script:fail -gt 0) {
    exit 1
}
