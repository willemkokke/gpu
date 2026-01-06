# Tool script for CMake (cross-platform build system)
# Source this file after setting TOOLS_FOLDER and TOOLS_VERSION_CMAKE
#
# Requires (environment variables):
#   TOOLS_FOLDER         - Base folder for tools (absolute path)
#   TOOLS_VERSION_CMAKE  - Version to install (e.g., 4.2.1)
#
# Provides (after sourcing):
#   SETUP_STATUS        - "installed" | "available" | "failed"
#
# Tools made available:
#   cmake, ctest, cpack
#
# Behavior:
#   - Checks if cmake is already installed (early exit if yes)
#   - Prints status via _print_tool (if available)
#   - Downloads prebuilt binary from GitHub releases
#   - Adds cmake to PATH

# Validate required variables
if [[ -z "$TOOLS_FOLDER" ]] || [[ -z "$TOOLS_VERSION_CMAKE" ]]; then
    echo "Error: TOOLS_FOLDER and TOOLS_VERSION_CMAKE must be set" >&2
    SETUP_STATUS="failed"
    return 1
fi

_cmake_dir="$TOOLS_FOLDER/cmake@$TOOLS_VERSION_CMAKE"

if [[ ! -d "$_cmake_dir" ]]; then
    # Print status if _print_tool is available
    type _print_tool &>/dev/null && _print_tool "cmake" "$TOOLS_VERSION_CMAKE" "installing"

    # Determine platform and architecture
    _os="$(uname -s)"
    _arch="$(uname -m)"

    case "$_os" in
        Darwin)
            _url="https://github.com/Kitware/CMake/releases/download/v${TOOLS_VERSION_CMAKE}/cmake-${TOOLS_VERSION_CMAKE}-macos-universal.tar.gz"
            _strip=1  # Strip top-level directory
            _bin_subdir="CMake.app/Contents/bin"
            ;;
        Linux)
            case "$_arch" in
                x86_64)
                    _url="https://github.com/Kitware/CMake/releases/download/v${TOOLS_VERSION_CMAKE}/cmake-${TOOLS_VERSION_CMAKE}-linux-x86_64.tar.gz"
                    ;;
                aarch64|arm64)
                    _url="https://github.com/Kitware/CMake/releases/download/v${TOOLS_VERSION_CMAKE}/cmake-${TOOLS_VERSION_CMAKE}-linux-aarch64.tar.gz"
                    ;;
                *)
                    echo "Error: Unsupported architecture: $_arch" >&2
                    SETUP_STATUS="failed"
                    unset _cmake_dir _os _arch
                    return 1
                    ;;
            esac
            _strip=1
            _bin_subdir="bin"
            ;;
        *)
            echo "Error: Unsupported OS: $_os" >&2
            SETUP_STATUS="failed"
            unset _cmake_dir _os _arch
            return 1
            ;;
    esac

    # Download and extract
    mkdir -p "$_cmake_dir"
    if curl -fsSL "$_url" | tar -xz -C "$_cmake_dir" --strip-components=$_strip 2>/dev/null; then
        SETUP_STATUS="installed"
    else
        rm -rf "$_cmake_dir"
        SETUP_STATUS="failed"
    fi

    unset _url _strip _bin_subdir _os _arch
else
    type _print_tool &>/dev/null && _print_tool "cmake" "$TOOLS_VERSION_CMAKE" "available"
    SETUP_STATUS="available"
fi

# Add to PATH
if [[ "$SETUP_STATUS" != "failed" ]]; then
    # Determine bin directory based on OS
    if [[ -d "$_cmake_dir/CMake.app" ]]; then
        _export_path "$_cmake_dir/CMake.app/Contents/bin"
    else
        _export_path "$_cmake_dir/bin"
    fi
fi

unset _cmake_dir
