# Tool script for uv (Python package manager)
# Dot-source this file after setting $env:TOOLS_FOLDER and $env:TOOLS_VERSION_UV
#
# Requires (environment variables):
#   $env:TOOLS_FOLDER       - Base folder for tools (absolute path)
#   $env:TOOLS_VERSION_UV   - Version to install (e.g., 0.5.14)
#
# Returns (hashtable):
#   @{ Status = "installed" | "available" | "failed" }
#
# Behavior:
#   - Checks if tool is already installed (early exit if yes)
#   - Prints status via Write-Tool (if available)
#   - Downloads and installs tool if missing
#   - Adds tool to PATH

# Validate required variables
if (-not $env:TOOLS_FOLDER -or -not $env:TOOLS_VERSION_UV) {
    Write-Error "TOOLS_FOLDER and TOOLS_VERSION_UV must be set"
    return @{ Status = "failed" }
}

$_uvDir = [System.IO.Path]::Combine($env:TOOLS_FOLDER, "uv@$env:TOOLS_VERSION_UV")

if (-not (Test-Path $_uvDir)) {
    # Print status if Write-Tool is available
    if (Get-Command Write-Tool -ErrorAction SilentlyContinue) {
        Write-Tool "uv" $env:TOOLS_VERSION_UV "installing"
    }

    # Install uv
    $env:UV_INSTALL_DIR = $_uvDir
    $env:UV_UNMANAGED_INSTALL = "1"

    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        # Windows: use PowerShell installer
        irm "https://astral.sh/uv/$env:TOOLS_VERSION_UV/install.ps1" | iex *>&1 | Out-Null
    } else {
        # macOS/Linux: use shell installer via sh
        sh -c "curl -LsSf https://astral.sh/uv/$env:TOOLS_VERSION_UV/install.sh | sh" 2>&1 | Out-Null
    }

    Remove-Item Env:\UV_UNMANAGED_INSTALL -ErrorAction SilentlyContinue

    $_status = if (Test-Path $_uvDir) { "installed" } else { "failed" }
} else {
    # Already installed
    if (Get-Command Write-Tool -ErrorAction SilentlyContinue) {
        Write-Tool "uv" $env:TOOLS_VERSION_UV "available"
    }
    $_status = "available"
}

# Add to PATH (uv binary is directly in install dir)
if ($_status -ne "failed") {
    $PathSep = [System.IO.Path]::PathSeparator
    $env:PATH = "$_uvDir$PathSep$env:PATH"
}

# Return result
@{ Status = $_status }
