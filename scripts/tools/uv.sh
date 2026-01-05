# Tool script for uv (Python package manager)
# Source this file after setting TOOLS_FOLDER and TOOLS_VERSION_UV
#
# Requires (environment variables):
#   TOOLS_FOLDER        - Base folder for tools (absolute path)
#   TOOLS_VERSION_UV    - Version to install (e.g., 0.5.14)
#   TOOLS_PYTHON313     - Python 3.13 version to install (e.g., 3.13)
#
# Provides (after sourcing):
#   SETUP_STATUS        - "installed" | "available" | "failed"
#
# Behavior:
#   - Checks if tool is already installed (early exit if yes)
#   - Prints status via _print_tool (if available)
#   - Downloads and installs tool if missing
#   - Installs Python 3.13 via uv if TOOLS_PYTHON313 is set
#   - Adds tool to PATH

# Validate required variables
if [[ -z "$TOOLS_FOLDER" ]] || [[ -z "$TOOLS_VERSION_UV" ]]; then
    echo "Error: TOOLS_FOLDER and TOOLS_VERSION_UV must be set" >&2
    SETUP_STATUS="failed"
    return 1
fi

_uv_dir="$TOOLS_FOLDER/uv@$TOOLS_VERSION_UV"

if [[ ! -d "$_uv_dir" ]]; then
    # Print status if _print_tool is available
    type _print_tool &>/dev/null && _print_tool "uv" "$TOOLS_VERSION_UV" "installing"

    # Install uv (must export vars for the installer subshell to see them)
    export UV_INSTALL_DIR="$_uv_dir"
    export UV_UNMANAGED_INSTALL="1"
    curl -LsSf "https://astral.sh/uv/$TOOLS_VERSION_UV/install.sh" | sh >/dev/null 2>&1
    unset UV_UNMANAGED_INSTALL

    if [[ -d "$_uv_dir" ]]; then
        SETUP_STATUS="installed"
    else
        SETUP_STATUS="failed"
    fi
else
    type _print_tool &>/dev/null && _print_tool "uv" "$TOOLS_VERSION_UV" "available"
    SETUP_STATUS="available"
fi

# Add to PATH (uv binary is directly in install dir)
if [[ "$SETUP_STATUS" != "failed" ]]; then
    _export_path "$_uv_dir"
fi

# Install Python 3.13 if TOOLS_PYTHON313 is set
if [[ "$SETUP_STATUS" != "failed" ]] && [[ -n "$TOOLS_PYTHON313" ]]; then
    # Check if Python is already installed
    _python_installed=$("$_uv_dir/uv" python list --only-installed 2>/dev/null | grep -c "cpython-$TOOLS_PYTHON313" || true)
    if [[ "$_python_installed" -eq 0 ]]; then
        "$_uv_dir/uv" python install "$TOOLS_PYTHON313" >/dev/null 2>&1
    fi
    # Get installed Python version for display
    _python_ver=$("$_uv_dir/uv" python list --only-installed 2>/dev/null | grep "cpython-$TOOLS_PYTHON313" | head -1 | awk '{print $1}' | sed 's/cpython-//')
    if [[ -n "$_python_ver" ]]; then
        type _print_tool &>/dev/null && _print_tool "python" "$_python_ver" "$SETUP_STATUS"
    fi
    unset _python_installed _python_ver
fi

unset _uv_dir
