# CI-aware environment helpers for bash
# Source this file to get functions that work in both local and CI environments
#
# Functions:
#   _export_path <dir>  - Add directory to PATH (persists in GitHub Actions)
#   _export_env <name> <value> - Export environment variable (persists in GitHub Actions)
#
# Detects GitHub Actions via $GITHUB_ACTIONS environment variable (set by both
# GitHub Actions and nektos/act)

# Add a directory to PATH, persisting in GitHub Actions
_export_path() {
    local dir="$1"
    export PATH="$dir:$PATH"

    # In GitHub Actions, also write to GITHUB_PATH for persistence across steps
    if [[ -n "$GITHUB_ACTIONS" ]] && [[ -n "$GITHUB_PATH" ]]; then
        echo "$dir" >> "$GITHUB_PATH"
    fi
}

# Export an environment variable, persisting in GitHub Actions
_export_env() {
    local name="$1"
    local value="$2"
    export "$name=$value"

    # In GitHub Actions, also write to GITHUB_ENV for persistence across steps
    if [[ -n "$GITHUB_ACTIONS" ]] && [[ -n "$GITHUB_ENV" ]]; then
        echo "$name=$value" >> "$GITHUB_ENV"
    fi
}
