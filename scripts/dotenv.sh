#!/usr/bin/env bash
# Dotenv loader for Bash 4+ / Zsh
# Usage: source scripts/dotenv.sh path/to/.env.repo path/to/.env.local
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
#
# Requirements: bash 4+ or zsh

# Check shell compatibility
if [[ -n "${BASH_VERSION:-}" ]]; then
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        echo "Error: dotenv.sh requires bash 4+ or zsh (found bash $BASH_VERSION)" >&2
        echo "On macOS, install newer bash: brew install bash" >&2
        return 1 2>/dev/null || exit 1
    fi
fi

# Resolved values (after tilde expansion, before variable substitution)
declare -A _dotenv_resolved

# ----------------------------------------------------------------------------
# Helper functions
# ----------------------------------------------------------------------------

_dotenv_expand_tilde() {
    local value="$1"
    if [[ "$value" == "~"* ]]; then
        echo "$HOME${value:1}"
    else
        echo "$value"
    fi
}

_dotenv_set_env() {
    local key="$1"
    local value="$2"
    export "$key=$value"

    # In GitHub Actions, also write to GITHUB_ENV for persistence across steps
    if [[ -n "${GITHUB_ACTIONS:-}" ]] && [[ -n "${GITHUB_ENV:-}" ]]; then
        echo "$key=$value" >> "$GITHUB_ENV"
    fi
}

_dotenv_get_env() {
    local key="$1"
    local env_val
    env_val="$(printenv "$key" 2>/dev/null)" || true

    if [[ -n "$env_val" ]]; then
        # Expand tilde and re-export immediately
        local expanded
        expanded="$(_dotenv_expand_tilde "$env_val")"
        _dotenv_set_env "$key" "$expanded"
        echo "$expanded"
        return
    fi

    echo ""
}

_dotenv_parse_value() {
    local raw="$1"
    local value=""

    # Check for quoted values
    if [[ "$raw" =~ ^\"(.*)\"[[:space:]]*(#.*)?$ ]]; then
        # Double-quoted value (quotes stripped, allows substitution later)
        if [[ -n "${BASH_VERSION:-}" ]]; then
            value="${BASH_REMATCH[1]}"
        else
            value="${match[1]}"
        fi
    elif [[ "$raw" =~ ^\'(.*)\'[[:space:]]*(#.*)?$ ]]; then
        # Single-quoted value (literal, no substitution - mark with prefix)
        if [[ -n "${BASH_VERSION:-}" ]]; then
            value="__DOTENV_LITERAL__${BASH_REMATCH[1]}"
        else
            value="__DOTENV_LITERAL__${match[1]}"
        fi
    else
        # Unquoted: strip inline comments and trailing whitespace
        value="${raw%%#*}"
        # Strip trailing whitespace
        value="${value%"${value##*[![:space:]]}"}"
    fi

    echo "$value"
}

_dotenv_process_value() {
    local key="$1"
    local raw_value="$2"

    # Check if key exists in environment first
    local env_val
    env_val="$(_dotenv_get_env "$key")"

    if [[ -n "$env_val" ]]; then
        # Use expanded env value (already exported by _dotenv_get_env)
        _dotenv_resolved[$key]="$env_val"
    else
        # Parse and expand file value
        local value
        value="$(_dotenv_expand_tilde "$raw_value")"
        value="$(_dotenv_parse_value "$value")"
        _dotenv_resolved[$key]="$value"
    fi
}

# ----------------------------------------------------------------------------
# Phase 1: Load files
# ----------------------------------------------------------------------------

_dotenv_load_file() {
    local file="$1"
    local key raw_value  # Declare outside loop (zsh quirk)
    [[ -f "$file" ]] || return 0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and full-line comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        # Parse KEY=VALUE
        if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*) ]]; then
            if [[ -n "${BASH_VERSION:-}" ]]; then
                key="${BASH_REMATCH[1]}"
                raw_value="${BASH_REMATCH[2]}"
            else
                key="${match[1]}"
                raw_value="${match[2]}"
            fi

            _dotenv_process_value "$key" "$raw_value"
        fi
    done < "$file"
}

# ----------------------------------------------------------------------------
# Phase 2: Variable substitution
# ----------------------------------------------------------------------------

_dotenv_lookup() {
    local var_name="$1"

    # Look up from resolved values (already tilde-expanded)
    if [[ -n "${_dotenv_resolved[$var_name]+x}" ]]; then
        echo "${_dotenv_resolved[$var_name]}"
        return
    fi

    # Not found - return empty string
    echo ""
}

_dotenv_substitute() {
    local input="$1"
    local result=""
    local i=0
    local len=${#input}
    local char next_char rest var_name var_value  # Declare outside loop (zsh quirk)

    while (( i < len )); do
        char="${input:$i:1}"
        next_char="${input:$((i+1)):1}"

        if [[ "$char" == "\\" && "$next_char" == "\$" ]]; then
            # Escaped dollar sign - use placeholder to prevent further substitution
            result+="__DOTENV_ESCAPED_DOLLAR__"
            (( i += 2 ))
        elif [[ "$char" == "\$" ]]; then
            if [[ "$next_char" == "{" ]]; then
                # ${VAR} syntax - find closing brace
                rest="${input:$((i+2))}"
                if [[ "$rest" =~ ^([A-Za-z_][A-Za-z0-9_]*)\}(.*) ]]; then
                    if [[ -n "${BASH_VERSION:-}" ]]; then
                        var_name="${BASH_REMATCH[1]}"
                    else
                        var_name="${match[1]}"
                    fi
                    var_value="$(_dotenv_lookup "$var_name")"
                    result+="$var_value"
                    (( i += 2 + ${#var_name} + 1 ))  # Skip ${, name, }
                else
                    # Invalid syntax, keep as-is
                    result+="\${"
                    (( i += 2 ))
                fi
            else
                # $VAR syntax - read identifier
                rest="${input:$((i+1))}"
                if [[ "$rest" =~ ^([A-Za-z_][A-Za-z0-9_]*)(.*) ]]; then
                    if [[ -n "${BASH_VERSION:-}" ]]; then
                        var_name="${BASH_REMATCH[1]}"
                    else
                        var_name="${match[1]}"
                    fi
                    var_value="$(_dotenv_lookup "$var_name")"
                    result+="$var_value"
                    (( i += 1 + ${#var_name} ))  # Skip $ and name
                else
                    # Just a lone $, keep it
                    result+="\$"
                    (( i += 1 ))
                fi
            fi
        else
            result+="$char"
            (( i += 1 ))
        fi
    done

    echo "$result"
}

# ----------------------------------------------------------------------------
# Main execution
# ----------------------------------------------------------------------------

# Phase 1: Load all files (later files override earlier)
for _dotenv_file in "$@"; do
    _dotenv_load_file "$_dotenv_file"
done

# Phase 2: Substitute variables until stable, then export
# Get array keys (bash vs zsh syntax)
if [[ -n "${BASH_VERSION:-}" ]]; then
    eval '_dotenv_keys=("${!_dotenv_resolved[@]}")'
else
    _dotenv_keys=("${(@k)_dotenv_resolved}")
fi

for _dotenv_key in "${_dotenv_keys[@]}"; do
    _dotenv_value="${_dotenv_resolved[$_dotenv_key]}"

    # Check for literal marker (from single-quoted values) - no substitution
    if [[ "$_dotenv_value" == "__DOTENV_LITERAL__"* ]]; then
        _dotenv_value="${_dotenv_value#__DOTENV_LITERAL__}"
    else
        # Loop until no more substitutions
        _dotenv_prev=""
        while [[ "$_dotenv_value" != "$_dotenv_prev" ]]; do
            _dotenv_prev="$_dotenv_value"
            _dotenv_value="$(_dotenv_substitute "$_dotenv_value")"
        done
        # Replace escaped dollar placeholder with actual dollar sign
        _dotenv_value="${_dotenv_value//__DOTENV_ESCAPED_DOLLAR__/\$}"
    fi

    # Update the stored value (for other vars to reference)
    _dotenv_resolved[$_dotenv_key]="$_dotenv_value"

    # Export
    _dotenv_set_env "$_dotenv_key" "$_dotenv_value"
done

# Cleanup
unset _dotenv_file _dotenv_key _dotenv_value _dotenv_prev _dotenv_keys
unset _dotenv_resolved
unset -f _dotenv_expand_tilde _dotenv_set_env _dotenv_get_env _dotenv_parse_value
unset -f _dotenv_process_value _dotenv_load_file _dotenv_lookup _dotenv_substitute
