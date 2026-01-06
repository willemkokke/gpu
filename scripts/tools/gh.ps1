# Tool script for gh (GitHub CLI)
# Dot-source this file after setting $env:TOOLS_FOLDER and $env:TOOLS_VERSION_GH
#
# Requires (environment variables):
#   $env:TOOLS_FOLDER       - Base folder for tools (absolute path)
#   $env:TOOLS_VERSION_GH   - Version to install (e.g., 2.83.1)
#
# Returns (hashtable):
#   @{ Status = "installed" | "available" | "failed" }
#
# Tools made available:
#   gh
#
# Behavior:
#   - Checks if gh is already installed (early exit if yes)
#   - Prints status via Write-Tool (if available)
#   - Downloads prebuilt binary from GitHub releases
#   - Adds gh to PATH

# Validate required variables
if (-not $env:TOOLS_FOLDER -or -not $env:TOOLS_VERSION_GH) {
    Write-Error "TOOLS_FOLDER and TOOLS_VERSION_GH must be set"
    return @{ Status = "failed" }
}

$_ghDir = [System.IO.Path]::Combine($env:TOOLS_FOLDER, "gh@$env:TOOLS_VERSION_GH")

if (-not (Test-Path $_ghDir)) {
    # Print status if Write-Tool is available
    if (Get-Command Write-Tool -ErrorAction SilentlyContinue) {
        Write-Tool "gh" $env:TOOLS_VERSION_GH "installing"
    }

    # Determine platform and architecture
    $_os = if ($IsWindows -or $env:OS -eq "Windows_NT") { "Windows" } elseif ($IsMacOS) { "Darwin" } else { "Linux" }
    $_arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLower()

    switch ($_os) {
        "Darwin" {
            switch ($_arch) {
                { $_ -in "x64", "x86_64" } {
                    $_url = "https://github.com/cli/cli/releases/download/v$env:TOOLS_VERSION_GH/gh_$($env:TOOLS_VERSION_GH)_macOS_amd64.zip"
                }
                { $_ -in "arm64", "aarch64" } {
                    $_url = "https://github.com/cli/cli/releases/download/v$env:TOOLS_VERSION_GH/gh_$($env:TOOLS_VERSION_GH)_macOS_arm64.zip"
                }
                default {
                    Write-Error "Unsupported architecture: $_arch"
                    return @{ Status = "failed" }
                }
            }
        }
        "Linux" {
            switch ($_arch) {
                { $_ -in "x64", "x86_64" } {
                    $_url = "https://github.com/cli/cli/releases/download/v$env:TOOLS_VERSION_GH/gh_$($env:TOOLS_VERSION_GH)_linux_amd64.tar.gz"
                }
                { $_ -in "arm64", "aarch64" } {
                    $_url = "https://github.com/cli/cli/releases/download/v$env:TOOLS_VERSION_GH/gh_$($env:TOOLS_VERSION_GH)_linux_arm64.tar.gz"
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
                    $_url = "https://github.com/cli/cli/releases/download/v$env:TOOLS_VERSION_GH/gh_$($env:TOOLS_VERSION_GH)_windows_amd64.zip"
                }
                { $_ -in "arm64", "aarch64" } {
                    $_url = "https://github.com/cli/cli/releases/download/v$env:TOOLS_VERSION_GH/gh_$($env:TOOLS_VERSION_GH)_windows_arm64.zip"
                }
                default {
                    Write-Error "Unsupported architecture: $_arch"
                    return @{ Status = "failed" }
                }
            }
        }
    }

    # Download and extract
    New-Item -ItemType Directory -Path $_ghDir -Force | Out-Null
    $_isZip = $_url.EndsWith(".zip")
    $_tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "gh-$env:TOOLS_VERSION_GH$( if ($_isZip) { '.zip' } else { '.tar.gz' } )")
    $_tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "gh-extract-$env:TOOLS_VERSION_GH")

    try {
        Invoke-WebRequest -Uri $_url -OutFile $_tempFile -UseBasicParsing

        if ($_isZip) {
            Expand-Archive -Path $_tempFile -DestinationPath $_tempDir -Force
            # Find and copy the gh binary
            $ghBin = Get-ChildItem -Path $_tempDir -Recurse -Filter "gh*" | Where-Object { $_.Name -match "^gh(\.exe)?$" } | Select-Object -First 1
            if ($ghBin) {
                Copy-Item -Path $ghBin.FullName -Destination $_ghDir
            }
        } else {
            New-Item -ItemType Directory -Path $_tempDir -Force | Out-Null
            tar -xzf $_tempFile -C $_tempDir
            # Find and copy the gh binary
            $ghBin = Get-ChildItem -Path $_tempDir -Recurse -Filter "gh" | Select-Object -First 1
            if ($ghBin) {
                Copy-Item -Path $ghBin.FullName -Destination $_ghDir
                chmod +x "$_ghDir/gh" 2>$null
            }
        }

        $_status = "installed"
    } catch {
        Remove-Item -Path $_ghDir -Recurse -Force -ErrorAction SilentlyContinue
        $_status = "failed"
    } finally {
        Remove-Item -Path $_tempFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $_tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
} else {
    # Already installed
    if (Get-Command Write-Tool -ErrorAction SilentlyContinue) {
        Write-Tool "gh" $env:TOOLS_VERSION_GH "available"
    }
    $_status = "available"
}

# Add to PATH
if ($_status -ne "failed") {
    $PathSep = [System.IO.Path]::PathSeparator
    $env:PATH = "$_ghDir$PathSep$env:PATH"
}

# Return result
@{ Status = $_status }
