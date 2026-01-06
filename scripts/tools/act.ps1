# Tool script for act (GitHub Actions local runner)
# Dot-source this file after setting $env:TOOLS_FOLDER and $env:TOOLS_VERSION_ACT
#
# Requires (environment variables):
#   $env:TOOLS_FOLDER        - Base folder for tools (absolute path)
#   $env:TOOLS_VERSION_ACT   - Version to install (e.g., 0.2.83)
#
# Returns (hashtable):
#   @{ Status = "installed" | "available" | "skipped" | "failed" }
#
# Tools made available:
#   act
#
# Behavior:
#   - Checks if Docker is available (skips if not - act requires Docker)
#   - Checks if act is already installed (early exit if yes)
#   - Prints status via Write-Tool (if available)
#   - Downloads prebuilt binary from GitHub releases
#   - Adds act to PATH

# Validate required variables
if (-not $env:TOOLS_FOLDER -or -not $env:TOOLS_VERSION_ACT) {
    Write-Error "TOOLS_FOLDER and TOOLS_VERSION_ACT must be set"
    return @{ Status = "failed" }
}

# Check if Docker is available (act requires Docker)
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    if (Get-Command Write-Tool -ErrorAction SilentlyContinue) {
        Write-Tool "act" $env:TOOLS_VERSION_ACT "skipped"
    }
    return @{ Status = "skipped" }
}

$_actDir = [System.IO.Path]::Combine($env:TOOLS_FOLDER, "act@$env:TOOLS_VERSION_ACT")

if (-not (Test-Path $_actDir)) {
    # Print status if Write-Tool is available
    if (Get-Command Write-Tool -ErrorAction SilentlyContinue) {
        Write-Tool "act" $env:TOOLS_VERSION_ACT "installing"
    }

    # Determine platform and architecture
    $_os = if ($IsWindows -or $env:OS -eq "Windows_NT") { "Windows" } elseif ($IsMacOS) { "Darwin" } else { "Linux" }
    $_arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLower()

    switch ($_os) {
        "Darwin" {
            switch ($_arch) {
                { $_ -in "x64", "x86_64" } {
                    $_url = "https://github.com/nektos/act/releases/download/v$env:TOOLS_VERSION_ACT/act_Darwin_x86_64.tar.gz"
                }
                { $_ -in "arm64", "aarch64" } {
                    $_url = "https://github.com/nektos/act/releases/download/v$env:TOOLS_VERSION_ACT/act_Darwin_arm64.tar.gz"
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
                    $_url = "https://github.com/nektos/act/releases/download/v$env:TOOLS_VERSION_ACT/act_Linux_x86_64.tar.gz"
                }
                { $_ -in "arm64", "aarch64" } {
                    $_url = "https://github.com/nektos/act/releases/download/v$env:TOOLS_VERSION_ACT/act_Linux_arm64.tar.gz"
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
                    $_url = "https://github.com/nektos/act/releases/download/v$env:TOOLS_VERSION_ACT/act_Windows_x86_64.zip"
                }
                { $_ -in "arm64", "aarch64" } {
                    $_url = "https://github.com/nektos/act/releases/download/v$env:TOOLS_VERSION_ACT/act_Windows_arm64.zip"
                }
                default {
                    Write-Error "Unsupported architecture: $_arch"
                    return @{ Status = "failed" }
                }
            }
        }
    }

    # Download and extract
    New-Item -ItemType Directory -Path $_actDir -Force | Out-Null
    $_tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "act-$env:TOOLS_VERSION_ACT$( if ($_os -eq 'Windows') { '.zip' } else { '.tar.gz' } )")

    try {
        Invoke-WebRequest -Uri $_url -OutFile $_tempFile -UseBasicParsing

        if ($_os -eq "Windows") {
            Expand-Archive -Path $_tempFile -DestinationPath $_actDir -Force
        } else {
            tar -xzf $_tempFile -C $_actDir
            chmod +x "$_actDir/act" 2>$null
        }

        $_status = "installed"
    } catch {
        Remove-Item -Path $_actDir -Recurse -Force -ErrorAction SilentlyContinue
        $_status = "failed"
    } finally {
        Remove-Item -Path $_tempFile -Force -ErrorAction SilentlyContinue
    }
} else {
    # Already installed
    if (Get-Command Write-Tool -ErrorAction SilentlyContinue) {
        Write-Tool "act" $env:TOOLS_VERSION_ACT "available"
    }
    $_status = "available"
}

# Add to PATH
if ($_status -ne "failed" -and $_status -ne "skipped") {
    $PathSep = [System.IO.Path]::PathSeparator
    $env:PATH = "$_actDir$PathSep$env:PATH"
}

# Return result
@{ Status = $_status }
