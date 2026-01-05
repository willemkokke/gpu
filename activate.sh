#!/usr/bin/env bash
# Source this file: source activate.sh

# Get repository root directory (works when sourced)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env files (.env.repo first, then .env.local which overrides)
source "$REPO_DIR/scripts/dotenv.sh" "$REPO_DIR/.env.repo" "$REPO_DIR/.env.local"

# Load CI-aware environment helpers (for GITHUB_PATH/GITHUB_ENV support)
source "$REPO_DIR/scripts/cienv.sh"

# Export REPO_DIR for future use
_export_env REPO_DIR "$REPO_DIR"

# Expand TOOLS_FOLDER to full path and export
# First expand ~ to $HOME if present
if [[ "$TOOLS_FOLDER" == "~"* ]]; then
    TOOLS_FOLDER="$HOME${TOOLS_FOLDER:1}"
fi
# Then make relative paths absolute
if [[ "$TOOLS_FOLDER" = /* ]]; then
    _export_env TOOLS_FOLDER "$TOOLS_FOLDER"
else
    _export_env TOOLS_FOLDER "$REPO_DIR/$TOOLS_FOLDER"
fi

# Load color utilities
source "$REPO_DIR/scripts/colors.sh"

echo ""
printf "${_bold}Activating development environment at:${_reset} ${_cyan}%s${_reset}\n" "$REPO_DIR"
echo ""
echo "Tools:"

# Setup uv
source "$REPO_DIR/scripts/tools/uv.sh"
if [[ "$SETUP_STATUS" == "failed" ]]; then
    echo "  Error: Failed to setup uv" >&2
fi

# Setup cmake
source "$REPO_DIR/scripts/tools/cmake.sh"
if [[ "$SETUP_STATUS" == "failed" ]]; then
    echo "  Error: Failed to setup cmake" >&2
fi

# Setup ninja
source "$REPO_DIR/scripts/tools/ninja.sh"
if [[ "$SETUP_STATUS" == "failed" ]]; then
    echo "  Error: Failed to setup ninja" >&2
fi

# Setup emscripten
source "$REPO_DIR/scripts/tools/emscripten.sh"
if [[ "$SETUP_STATUS" == "failed" ]]; then
    echo "  Error: Failed to setup emscripten" >&2
fi

# Setup act (optional - requires Docker)
source "$REPO_DIR/scripts/tools/act.sh"
if [[ "$SETUP_STATUS" == "failed" ]]; then
    echo "  Error: Failed to setup act" >&2
fi

echo ""

# Sync Python dependencies
uv sync

echo "Environment activated."

# Cleanup internal variables and functions
unset SETUP_STATUS _bold _green _yellow _cyan _reset
unset -f _print_tool _export_path _export_env
