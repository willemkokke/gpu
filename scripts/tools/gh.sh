# Tool script for gh (GitHub CLI)
# Source this file after setting TOOLS_FOLDER and TOOLS_VERSION_GH
#
# Requires (environment variables):
#   TOOLS_FOLDER         - Base folder for tools (absolute path)
#   TOOLS_VERSION_GH     - Version to install (e.g., 2.83.1)
#
# Provides (after sourcing):
#   SETUP_STATUS        - "installed" | "available" | "failed"
#
# Tools made available:
#   gh
#
# Behavior:
#   - Checks if gh is already installed (early exit if yes)
#   - Prints status via _print_tool (if available)
#   - Downloads prebuilt binary from GitHub releases
#   - Adds gh to PATH

# Validate required variables
if [[ -z "$TOOLS_FOLDER" ]] || [[ -z "$TOOLS_VERSION_GH" ]]; then
    echo "Error: TOOLS_FOLDER and TOOLS_VERSION_GH must be set" >&2
    SETUP_STATUS="failed"
    return 1
fi

_gh_dir="$TOOLS_FOLDER/gh@$TOOLS_VERSION_GH"

if [[ ! -d "$_gh_dir" ]]; then
    # Print status if _print_tool is available
    type _print_tool &>/dev/null && _print_tool "gh" "$TOOLS_VERSION_GH" "installing"

    # Determine platform and architecture
    _os="$(uname -s)"
    _arch="$(uname -m)"

    case "$_os" in
        Darwin)
            case "$_arch" in
                x86_64)
                    _url="https://github.com/cli/cli/releases/download/v${TOOLS_VERSION_GH}/gh_${TOOLS_VERSION_GH}_macOS_amd64.zip"
                    _format="zip"
                    ;;
                arm64)
                    _url="https://github.com/cli/cli/releases/download/v${TOOLS_VERSION_GH}/gh_${TOOLS_VERSION_GH}_macOS_arm64.zip"
                    _format="zip"
                    ;;
                *)
                    echo "Error: Unsupported architecture: $_arch" >&2
                    SETUP_STATUS="failed"
                    unset _gh_dir _os _arch
                    return 1
                    ;;
            esac
            ;;
        Linux)
            case "$_arch" in
                x86_64)
                    _url="https://github.com/cli/cli/releases/download/v${TOOLS_VERSION_GH}/gh_${TOOLS_VERSION_GH}_linux_amd64.tar.gz"
                    _format="tar.gz"
                    ;;
                aarch64|arm64)
                    _url="https://github.com/cli/cli/releases/download/v${TOOLS_VERSION_GH}/gh_${TOOLS_VERSION_GH}_linux_arm64.tar.gz"
                    _format="tar.gz"
                    ;;
                *)
                    echo "Error: Unsupported architecture: $_arch" >&2
                    SETUP_STATUS="failed"
                    unset _gh_dir _os _arch
                    return 1
                    ;;
            esac
            ;;
        *)
            echo "Error: Unsupported OS: $_os" >&2
            SETUP_STATUS="failed"
            unset _gh_dir _os _arch
            return 1
            ;;
    esac

    # Download and extract
    mkdir -p "$_gh_dir"
    _temp_file=$(mktemp)

    if curl -fsSL "$_url" -o "$_temp_file" 2>/dev/null; then
        if [[ "$_format" == "zip" ]]; then
            # Unzip and move contents from nested directory
            _temp_dir=$(mktemp -d)
            unzip -q "$_temp_file" -d "$_temp_dir"
            mv "$_temp_dir"/gh_*/bin/gh "$_gh_dir/"
            rm -rf "$_temp_dir"
        else
            # Extract tar.gz and move contents from nested directory
            _temp_dir=$(mktemp -d)
            tar -xzf "$_temp_file" -C "$_temp_dir"
            mv "$_temp_dir"/gh_*/bin/gh "$_gh_dir/"
            rm -rf "$_temp_dir"
        fi
        chmod +x "$_gh_dir/gh"
        SETUP_STATUS="installed"
    else
        rm -rf "$_gh_dir"
        SETUP_STATUS="failed"
    fi

    rm -f "$_temp_file"
    unset _url _format _os _arch _temp_file _temp_dir
else
    type _print_tool &>/dev/null && _print_tool "gh" "$TOOLS_VERSION_GH" "available"
    SETUP_STATUS="available"
fi

# Add to PATH
if [[ "$SETUP_STATUS" != "failed" ]]; then
    _export_path "$_gh_dir"
fi

unset _gh_dir
