# Tool script for act (GitHub Actions local runner)
# Source this file after setting TOOLS_FOLDER and TOOLS_VERSION_ACT
#
# Requires (environment variables):
#   TOOLS_FOLDER         - Base folder for tools (absolute path)
#   TOOLS_VERSION_ACT    - Version to install (e.g., 0.2.83)
#
# Provides (after sourcing):
#   SETUP_STATUS        - "installed" | "available" | "skipped" | "failed"
#
# Tools made available:
#   act
#
# Behavior:
#   - Checks if Docker is available (skips if not - act requires Docker)
#   - Checks if act is already installed (early exit if yes)
#   - Prints status via _print_tool (if available)
#   - Downloads prebuilt binary from GitHub releases
#   - Adds act to PATH

# Validate required variables
if [[ -z "$TOOLS_FOLDER" ]] || [[ -z "$TOOLS_VERSION_ACT" ]]; then
    echo "Error: TOOLS_FOLDER and TOOLS_VERSION_ACT must be set" >&2
    SETUP_STATUS="failed"
    return 1
fi

# Check if Docker is available (act requires Docker)
if ! command -v docker &>/dev/null; then
    type _print_tool &>/dev/null && _print_tool "act" "$TOOLS_VERSION_ACT" "skipped"
    SETUP_STATUS="skipped"
    return 0
fi

_act_dir="$TOOLS_FOLDER/act@$TOOLS_VERSION_ACT"

if [[ ! -d "$_act_dir" ]]; then
    # Print status if _print_tool is available
    type _print_tool &>/dev/null && _print_tool "act" "$TOOLS_VERSION_ACT" "installing"

    # Determine platform and architecture
    _os="$(uname -s)"
    _arch="$(uname -m)"

    case "$_os" in
        Darwin)
            case "$_arch" in
                x86_64)
                    _url="https://github.com/nektos/act/releases/download/v${TOOLS_VERSION_ACT}/act_Darwin_x86_64.tar.gz"
                    ;;
                arm64)
                    _url="https://github.com/nektos/act/releases/download/v${TOOLS_VERSION_ACT}/act_Darwin_arm64.tar.gz"
                    ;;
                *)
                    echo "Error: Unsupported architecture: $_arch" >&2
                    SETUP_STATUS="failed"
                    unset _act_dir _os _arch
                    return 1
                    ;;
            esac
            ;;
        Linux)
            case "$_arch" in
                x86_64)
                    _url="https://github.com/nektos/act/releases/download/v${TOOLS_VERSION_ACT}/act_Linux_x86_64.tar.gz"
                    ;;
                aarch64|arm64)
                    _url="https://github.com/nektos/act/releases/download/v${TOOLS_VERSION_ACT}/act_Linux_arm64.tar.gz"
                    ;;
                *)
                    echo "Error: Unsupported architecture: $_arch" >&2
                    SETUP_STATUS="failed"
                    unset _act_dir _os _arch
                    return 1
                    ;;
            esac
            ;;
        *)
            echo "Error: Unsupported OS: $_os" >&2
            SETUP_STATUS="failed"
            unset _act_dir _os _arch
            return 1
            ;;
    esac

    # Download and extract
    mkdir -p "$_act_dir"
    if curl -fsSL "$_url" | tar -xz -C "$_act_dir" 2>/dev/null; then
        chmod +x "$_act_dir/act"
        SETUP_STATUS="installed"
    else
        rm -rf "$_act_dir"
        SETUP_STATUS="failed"
    fi

    unset _url _os _arch
else
    type _print_tool &>/dev/null && _print_tool "act" "$TOOLS_VERSION_ACT" "available"
    SETUP_STATUS="available"
fi

# Add to PATH
if [[ "$SETUP_STATUS" != "failed" ]] && [[ "$SETUP_STATUS" != "skipped" ]]; then
    _export_path "$_act_dir"
fi

unset _act_dir
