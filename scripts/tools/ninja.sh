# Tool script for Ninja (fast build system)
# Source this file after setting TOOLS_FOLDER and TOOLS_VERSION_NINJA
#
# Requires (environment variables):
#   TOOLS_FOLDER         - Base folder for tools (absolute path)
#   TOOLS_VERSION_NINJA  - Version to install (e.g., 1.13.2)
#
# Provides (after sourcing):
#   SETUP_STATUS        - "installed" | "available" | "failed"
#
# Tools made available:
#   ninja
#
# Behavior:
#   - Checks if ninja is already installed (early exit if yes)
#   - Prints status via _print_tool (if available)
#   - Downloads prebuilt binary from GitHub releases
#   - Adds ninja to PATH

# Validate required variables
if [[ -z "$TOOLS_FOLDER" ]] || [[ -z "$TOOLS_VERSION_NINJA" ]]; then
    echo "Error: TOOLS_FOLDER and TOOLS_VERSION_NINJA must be set" >&2
    SETUP_STATUS="failed"
    return 1
fi

_ninja_dir="$TOOLS_FOLDER/ninja@$TOOLS_VERSION_NINJA"

if [[ ! -d "$_ninja_dir" ]]; then
    # Print status if _print_tool is available
    type _print_tool &>/dev/null && _print_tool "ninja" "$TOOLS_VERSION_NINJA" "installing"

    # Determine platform and architecture
    _os="$(uname -s)"
    _arch="$(uname -m)"

    case "$_os" in
        Darwin)
            # Ninja provides universal binary for macOS
            _url="https://github.com/ninja-build/ninja/releases/download/v${TOOLS_VERSION_NINJA}/ninja-mac.zip"
            ;;
        Linux)
            case "$_arch" in
                x86_64)
                    _url="https://github.com/ninja-build/ninja/releases/download/v${TOOLS_VERSION_NINJA}/ninja-linux.zip"
                    ;;
                aarch64|arm64)
                    _url="https://github.com/ninja-build/ninja/releases/download/v${TOOLS_VERSION_NINJA}/ninja-linux-aarch64.zip"
                    ;;
                *)
                    echo "Error: Unsupported architecture: $_arch" >&2
                    SETUP_STATUS="failed"
                    unset _ninja_dir _os _arch
                    return 1
                    ;;
            esac
            ;;
        *)
            echo "Error: Unsupported OS: $_os" >&2
            SETUP_STATUS="failed"
            unset _ninja_dir _os _arch
            return 1
            ;;
    esac

    # Download and extract (ninja releases are .zip files with just the binary inside)
    mkdir -p "$_ninja_dir"
    _temp_zip=$(mktemp)
    if curl -fsSL "$_url" -o "$_temp_zip" && unzip -q "$_temp_zip" -d "$_ninja_dir" 2>/dev/null; then
        chmod +x "$_ninja_dir/ninja"
        SETUP_STATUS="installed"
    else
        rm -rf "$_ninja_dir"
        SETUP_STATUS="failed"
    fi
    rm -f "$_temp_zip"

    unset _url _temp_zip _os _arch
else
    type _print_tool &>/dev/null && _print_tool "ninja" "$TOOLS_VERSION_NINJA" "available"
    SETUP_STATUS="available"
fi

# Add to PATH (ninja binary is directly in install dir)
if [[ "$SETUP_STATUS" != "failed" ]]; then
    _export_path "$_ninja_dir"
fi

unset _ninja_dir
