# Dotenv loader for PowerShell
# Usage: . .\scripts\dotenv.ps1 path/to/.env.repo path/to/.env.local
#
# Features:
# - Two-phase loading: collect values, then substitute variables
# - Later files override earlier files
# - Pre-existing environment variables take precedence (with tilde expansion)
# - Supports $VAR and ${VAR} substitution
# - Single quotes prevent substitution: '$VAR' stays literal
# - Backslash escapes: \$VAR stays literal
# - Supports # comments (full line and end of line)
# - Supports single and double quoted values
# - Expands ~ to $HOME (at start of value only)
# - Non-existent variables become empty string

param(
    [Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Files
)

# Resolved values (after tilde expansion, before variable substitution)
$script:_dotenv_resolved = @{}

# ----------------------------------------------------------------------------
# Helper functions
# ----------------------------------------------------------------------------
function _dotenv_parse_value {
    param([string]$raw)

    # Check for quoted values
    if ($raw -match '^"(.*)"(\s*#.*)?$') {
        # Double-quoted value (quotes stripped, allows substitution later)
        return $matches[1]
    }
    elseif ($raw -match "^'(.*)'(\s*#.*)?$") {
        # Single-quoted value (literal, no substitution - mark with prefix)
        return "__DOTENV_LITERAL__$($matches[1])"
    }
    else {
        # Unquoted: strip inline comments and trailing whitespace
        $value = ($raw -split '#')[0].TrimEnd()
        return $value
    }
}

# ----------------------------------------------------------------------------
# Phase 1: Load files
# ----------------------------------------------------------------------------

function _dotenv_load_file {
    param([string]$file)

    if (-not (Test-Path $file)) { return }

    Get-Content $file | ForEach-Object {
        $line = $_

        # Skip empty lines and full-line comments
        if ([string]::IsNullOrWhiteSpace($line) -or $line -match '^\s*#') { return }

        # Parse KEY=VALUE
        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
            $key = $matches[1]
            $rawValue = $matches[2]

            # Check if key exists in environment first
            $envVal = _dotenv_get_env $key

            if ($envVal -ne "") {
                # Use expanded env value (already exported by _dotenv_get_env)
                $script:_dotenv_resolved[$key] = $envVal
            }
            else {
                # Parse and expand file value
                $value = _dotenv_expand_tilde $rawValue
                $value = _dotenv_parse_value $value
                $script:_dotenv_resolved[$key] = $value
            }
        }
    }
}

# ----------------------------------------------------------------------------
# Phase 2: Variable substitution
# ----------------------------------------------------------------------------
function _dotenv_lookup {
    param([string]$varName)

    # Look up from resolved values (already tilde-expanded)
    if ($script:_dotenv_resolved.ContainsKey($varName)) {
        return $script:_dotenv_resolved[$varName]
    }

    # Not found - return empty string
    return ""
}

function _dotenv_substitute {
    param([string]$inputStr)

    # Handle null/empty input
    if ([string]::IsNullOrEmpty($inputStr)) {
        return ""
    }

    $result = ""
    $i = 0
    $len = $inputStr.Length

    while ($i -lt $len) {
        $char = $inputStr[$i]
        $nextChar = if ($i + 1 -lt $len) { $inputStr[$i + 1] } else { $null }

        if ($char -eq '\' -and $nextChar -eq '$') {
            # Escaped dollar sign - use placeholder to prevent further substitution
            $result += "__DOTENV_ESCAPED_DOLLAR__"
            $i += 2
        }
        elseif ($char -eq '$') {
            if ($nextChar -eq '{') {
                # ${VAR} syntax - find closing brace
                $rest = $inputStr.Substring($i + 2)
                if ($rest -match '^([A-Za-z_][A-Za-z0-9_]*)\}(.*)$') {
                    $varName = $matches[1]
                    $varValue = _dotenv_lookup $varName
                    $result += $varValue
                    $i += 2 + $varName.Length + 1  # Skip ${, name, }
                }
                else {
                    # Invalid syntax, keep as-is
                    $result += '${'
                    $i += 2
                }
            }
            else {
                # $VAR syntax - read identifier
                $rest = $inputStr.Substring($i + 1)
                if ($rest -match '^([A-Za-z_][A-Za-z0-9_]*)(.*)$') {
                    $varName = $matches[1]
                    $varValue = _dotenv_lookup $varName
                    $result += $varValue
                    $i += 1 + $varName.Length  # Skip $ and name
                }
                else {
                    # Just a lone $, keep it
                    $result += '$'
                    $i += 1
                }
            }
        }
        else {
            $result += $char
            $i += 1
        }
    }

    return $result
}

function _dotenv_expand_tilde {
    param([string]$value)

    # Handle null/empty input
    if ([string]::IsNullOrEmpty($value)) {
        return ""
    }

    if ($value.StartsWith('~')) {
        $homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
        return $value -replace '^~', $homeDir
    }
    return $value
}

function _dotenv_set_env {
    param([string]$key, [string]$value)

    [Environment]::SetEnvironmentVariable($key, $value, 'Process')

    # In GitHub Actions, also write to GITHUB_ENV for persistence across steps
    if ($env:GITHUB_ACTIONS -and $env:GITHUB_ENV) {
        Add-Content -Path $env:GITHUB_ENV -Value "$key=$value"
    }
}

function _dotenv_get_env {
    param([string]$key)

    $envVal = [Environment]::GetEnvironmentVariable($key, 'Process')
    if ($null -ne $envVal -and $envVal -ne "") {
        # Expand tilde and re-export immediately
        $expanded = _dotenv_expand_tilde $envVal
        _dotenv_set_env $key $expanded
        return $expanded
    }
    return ""
}

# ----------------------------------------------------------------------------
# Main execution
# ----------------------------------------------------------------------------

# Phase 1: Load all files (later files override earlier)
foreach ($file in $Files) {
    _dotenv_load_file $file
}

# Phase 2: Substitute variables until stable, then export
foreach ($key in @($script:_dotenv_resolved.Keys)) {
    $value = $script:_dotenv_resolved[$key]

    # Handle null/empty values
    if ([string]::IsNullOrEmpty($value)) {
        $value = ""
    }
    # Check for literal marker (from single-quoted values) - no substitution
    elseif ($value.StartsWith("__DOTENV_LITERAL__")) {
        $value = $value.Substring("__DOTENV_LITERAL__".Length)
    }
    else {
        # Loop until no more substitutions
        $prev = ""
        while ($value -ne $prev) {
            $prev = $value
            $value = _dotenv_substitute $value
        }
        # Replace escaped dollar placeholder with actual dollar sign
        $value = $value -replace "__DOTENV_ESCAPED_DOLLAR__", '$'
    }

    # Update the stored value (for other vars to reference)
    $script:_dotenv_resolved[$key] = $value

    # Export
    _dotenv_set_env $key $value
}

# Cleanup
Remove-Variable -Name '_dotenv_resolved' -Scope Script -ErrorAction SilentlyContinue
Remove-Item -Path Function:\_dotenv_expand_tilde -ErrorAction SilentlyContinue
Remove-Item -Path Function:\_dotenv_set_env -ErrorAction SilentlyContinue
Remove-Item -Path Function:\_dotenv_get_env -ErrorAction SilentlyContinue
Remove-Item -Path Function:\_dotenv_parse_value -ErrorAction SilentlyContinue
Remove-Item -Path Function:\_dotenv_load_file -ErrorAction SilentlyContinue
Remove-Item -Path Function:\_dotenv_lookup -ErrorAction SilentlyContinue
Remove-Item -Path Function:\_dotenv_substitute -ErrorAction SilentlyContinue
