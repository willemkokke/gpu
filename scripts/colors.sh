#!/usr/bin/env bash
# Color utilities for Bash/Zsh
# Usage: source scripts/colors.sh
#
# Provides color variables and _print_tool function for consistent output.
# Colors are empty when terminal doesn't support them.

if [[ -t 1 ]] && [[ "${TERM:-dumb}" != "dumb" ]]; then
    _bold='\033[1m'
    _green='\033[0;32m'
    _yellow='\033[0;33m'
    _cyan='\033[0;36m'
    _reset='\033[0m'
else
    _bold=''
    _green=''
    _yellow=''
    _cyan=''
    _reset=''
fi

# Function to print tool status
_print_tool() {
    local name="$1"
    local ver="$2"
    local state="$3"
    if [[ "$state" == "installing" ]]; then
        printf "  ${_yellow}Installing${_reset}: ${_cyan}%-10s${_reset} %s\n" "$name" "$ver"
    else
        printf "  ${_green}Available${_reset}:  ${_cyan}%-10s${_reset} %s\n" "$name" "$ver"
    fi
}
