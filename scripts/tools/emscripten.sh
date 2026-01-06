# Tool script for Emscripten SDK (WebAssembly compiler toolchain)
# Source this file after setting TOOLS_FOLDER and TOOLS_VERSION_EMSDK
#
# Requires (environment variables):
#   TOOLS_FOLDER         - Base folder for tools (absolute path)
#   TOOLS_VERSION_EMSDK  - Version to install (e.g., 4.0.9)
#
# Provides (after sourcing):
#   SETUP_STATUS        - "installed" | "available" | "failed"
#
# Tools made available:
#   emcc, em++, emar, emranlib, emmake, emcmake, emrun, emsdk
#   node (from emsdk bundled version)
#
# Behavior:
#   - Checks if emsdk is already installed (early exit if yes)
#   - Prints status via _print_tool (if available)
#   - Clones emsdk repo and installs specified version if missing
#   - Sources emsdk_env.sh to set PATH and other env vars
#   - Adds node from emsdk to PATH (Python is managed by uv)

# Validate required variables
if [[ -z "$TOOLS_FOLDER" ]] || [[ -z "$TOOLS_VERSION_EMSDK" ]]; then
    echo "Error: TOOLS_FOLDER and TOOLS_VERSION_EMSDK must be set" >&2
    SETUP_STATUS="failed"
    return 1
fi

_emsdk_dir="$TOOLS_FOLDER/emsdk@$TOOLS_VERSION_EMSDK"

if [[ ! -d "$_emsdk_dir" ]]; then
    # Clone emsdk repository
    git clone --depth 1 https://github.com/emscripten-core/emsdk.git "$_emsdk_dir" >/dev/null 2>&1

    if [[ -d "$_emsdk_dir" ]]; then
        # Install and activate the specified version
        (
            cd "$_emsdk_dir"
            ./emsdk install "$TOOLS_VERSION_EMSDK" >/dev/null 2>&1
            ./emsdk activate "$TOOLS_VERSION_EMSDK" >/dev/null 2>&1
        )

        if [[ -f "$_emsdk_dir/emsdk_env.sh" ]]; then
            SETUP_STATUS="installed"
        else
            SETUP_STATUS="failed"
        fi
    else
        SETUP_STATUS="failed"
    fi
else
    SETUP_STATUS="available"
fi

# Source emsdk_env.sh to set up PATH and environment variables
# This handles all the complexity of emcc, em++, emar, etc.
if [[ "$SETUP_STATUS" != "failed" ]] && [[ -f "$_emsdk_dir/emsdk_env.sh" ]]; then
    # Capture PATH before sourcing
    _path_before="$PATH"
    source "$_emsdk_dir/emsdk_env.sh" >/dev/null 2>&1

    # In GitHub Actions, write new PATH entries to GITHUB_PATH
    if [[ -n "$GITHUB_ACTIONS" ]] && [[ -n "$GITHUB_PATH" ]]; then
        # Extract new entries added by emsdk_env.sh
        _new_path="${PATH%%:$_path_before}"
        IFS=':' read -ra _path_entries <<< "$_new_path"
        for _entry in "${_path_entries[@]}"; do
            [[ -n "$_entry" ]] && echo "$_entry" >> "$GITHUB_PATH"
        done
        unset _new_path _path_entries _entry

        # Also export EMSDK environment variables
        [[ -n "$EMSDK" ]] && echo "EMSDK=$EMSDK" >> "$GITHUB_ENV"
        [[ -n "$EMSDK_NODE" ]] && echo "EMSDK_NODE=$EMSDK_NODE" >> "$GITHUB_ENV"
        [[ -n "$EMSDK_PYTHON" ]] && echo "EMSDK_PYTHON=$EMSDK_PYTHON" >> "$GITHUB_ENV"
        [[ -n "$EM_CONFIG" ]] && echo "EM_CONFIG=$EM_CONFIG" >> "$GITHUB_ENV"
    fi
    unset _path_before
fi

# Add node from emsdk to PATH (Python is managed by uv, not emsdk)
if [[ "$SETUP_STATUS" != "failed" ]]; then
    if [[ -n "$EMSDK_NODE" ]] && [[ -f "$EMSDK_NODE" ]]; then
        _node_dir="$(dirname "$EMSDK_NODE")"
        _export_path "$_node_dir"
        _node_ver="$("$EMSDK_NODE" --version 2>/dev/null | tr -d 'v')"
        type _print_tool &>/dev/null && _print_tool "node" "$_node_ver" "$SETUP_STATUS"
        unset _node_dir _node_ver
    fi
fi

# Print emscripten status last
type _print_tool &>/dev/null && _print_tool "emscripten" "$TOOLS_VERSION_EMSDK" "$SETUP_STATUS"

unset _emsdk_dir
