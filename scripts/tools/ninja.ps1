# Tool script for Ninja (fast build system)
# Dot-source this file after setting $env:TOOLS_FOLDER and $env:TOOLS_VERSION_NINJA
#
# Requires (environment variables):
#   $env:TOOLS_FOLDER        - Base folder for tools (absolute path)
#   $env:TOOLS_VERSION_NINJA - Version to install (e.g., 1.13.2)
#
# Returns (hashtable):
#   @{ Status = "installed" | "available" | "failed" }
#
# Tools made available:
#   ninja
#
# Behavior:
#   - Checks if ninja is already installed (early exit if yes)
#   - Prints status via Write-Tool (if available)
#   - Downloads prebuilt binary from GitHub releases
#   - Adds ninja to PATH

# Validate required variables
if (-not $env:TOOLS_FOLDER -or -not $env:TOOLS_VERSION_NINJA) {
    Write-Error "TOOLS_FOLDER and TOOLS_VERSION_NINJA must be set"
    return @{ Status = "failed" }
}

$_ninjaDir = [System.IO.Path]::Combine($env:TOOLS_FOLDER, "ninja@$env:TOOLS_VERSION_NINJA")

if (-not (Test-Path $_ninjaDir)) {
    # Print status if Write-Tool is available
    if (Get-Command Write-Tool -ErrorAction SilentlyContinue) {
        Write-Tool "ninja" $env:TOOLS_VERSION_NINJA "installing"
    }

    # Determine platform and architecture
    $_os = if ($IsWindows -or $env:OS -eq "Windows_NT") { "Windows" } elseif ($IsMacOS) { "Darwin" } else { "Linux" }
    $_arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLower()

    switch ($_os) {
        "Darwin" {
            $_url = "https://github.com/ninja-build/ninja/releases/download/v$env:TOOLS_VERSION_NINJA/ninja-mac.zip"
        }
        "Linux" {
            switch ($_arch) {
                { $_ -in "x64", "x86_64" } {
                    $_url = "https://github.com/ninja-build/ninja/releases/download/v$env:TOOLS_VERSION_NINJA/ninja-linux.zip"
                }
                { $_ -in "arm64", "aarch64" } {
                    $_url = "https://github.com/ninja-build/ninja/releases/download/v$env:TOOLS_VERSION_NINJA/ninja-linux-aarch64.zip"
                }
                default {
                    Write-Error "Unsupported architecture: $_arch"
                    return @{ Status = "failed" }
                }
            }
        }
        "Windows" {
            switch ($_arch) {
                { $_ -in "x64", "x86_64" } {
                    $_url = "https://github.com/ninja-build/ninja/releases/download/v$env:TOOLS_VERSION_NINJA/ninja-win.zip"
                }
                { $_ -in "arm64", "aarch64" } {
                    $_url = "https://github.com/ninja-build/ninja/releases/download/v$env:TOOLS_VERSION_NINJA/ninja-winarm64.zip"
                }
                default {
                    Write-Error "Unsupported architecture: $_arch"
                    return @{ Status = "failed" }
                }
            }
        }
    }

    # Download and extract
    New-Item -ItemType Directory -Path $_ninjaDir -Force | Out-Null
    $_tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "ninja-$env:TOOLS_VERSION_NINJA.zip")

    try {
        Invoke-WebRequest -Uri $_url -OutFile $_tempFile -UseBasicParsing
        Expand-Archive -Path $_tempFile -DestinationPath $_ninjaDir -Force

        # Make executable on Unix
        if ($_os -ne "Windows") {
            chmod +x "$_ninjaDir/ninja" 2>$null
        }

        $_status = if (Test-Path "$_ninjaDir/ninja*") { "installed" } else { "failed" }
    } catch {
        Remove-Item -Path $_ninjaDir -Recurse -Force -ErrorAction SilentlyContinue
        $_status = "failed"
    } finally {
        Remove-Item -Path $_tempFile -Force -ErrorAction SilentlyContinue
    }
} else {
    # Already installed
    if (Get-Command Write-Tool -ErrorAction SilentlyContinue) {
        Write-Tool "ninja" $env:TOOLS_VERSION_NINJA "available"
    }
    $_status = "available"
}

# Add to PATH (ninja binary is directly in install dir)
if ($_status -ne "failed") {
    $PathSep = [System.IO.Path]::PathSeparator
    $env:PATH = "$_ninjaDir$PathSep$env:PATH"
}

# Return result
@{ Status = $_status }
