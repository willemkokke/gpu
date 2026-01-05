# Tool script for CMake (cross-platform build system)
# Dot-source this file after setting $env:TOOLS_FOLDER and $env:TOOLS_VERSION_CMAKE
#
# Requires (environment variables):
#   $env:TOOLS_FOLDER        - Base folder for tools (absolute path)
#   $env:TOOLS_VERSION_CMAKE - Version to install (e.g., 4.2.1)
#
# Returns (hashtable):
#   @{ Status = "installed" | "available" | "failed" }
#
# Tools made available:
#   cmake, ctest, cpack
#
# Behavior:
#   - Checks if cmake is already installed (early exit if yes)
#   - Prints status via Write-Tool (if available)
#   - Downloads prebuilt binary from GitHub releases
#   - Adds cmake to PATH

# Validate required variables
if (-not $env:TOOLS_FOLDER -or -not $env:TOOLS_VERSION_CMAKE) {
    Write-Error "TOOLS_FOLDER and TOOLS_VERSION_CMAKE must be set"
    return @{ Status = "failed" }
}

$_cmakeDir = [System.IO.Path]::Combine($env:TOOLS_FOLDER, "cmake@$env:TOOLS_VERSION_CMAKE")

if (-not (Test-Path $_cmakeDir)) {
    # Print status if Write-Tool is available
    if (Get-Command Write-Tool -ErrorAction SilentlyContinue) {
        Write-Tool "cmake" $env:TOOLS_VERSION_CMAKE "installing"
    }

    # Determine platform and architecture
    $_os = if ($IsWindows -or $env:OS -eq "Windows_NT") { "Windows" } elseif ($IsMacOS) { "Darwin" } else { "Linux" }
    $_arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLower()

    switch ($_os) {
        "Darwin" {
            $_url = "https://github.com/Kitware/CMake/releases/download/v$env:TOOLS_VERSION_CMAKE/cmake-$env:TOOLS_VERSION_CMAKE-macos-universal.tar.gz"
            $_binSubdir = "CMake.app/Contents/bin"
        }
        "Linux" {
            switch ($_arch) {
                { $_ -in "x64", "x86_64" } {
                    $_url = "https://github.com/Kitware/CMake/releases/download/v$env:TOOLS_VERSION_CMAKE/cmake-$env:TOOLS_VERSION_CMAKE-linux-x86_64.tar.gz"
                }
                { $_ -in "arm64", "aarch64" } {
                    $_url = "https://github.com/Kitware/CMake/releases/download/v$env:TOOLS_VERSION_CMAKE/cmake-$env:TOOLS_VERSION_CMAKE-linux-aarch64.tar.gz"
                }
                default {
                    Write-Error "Unsupported architecture: $_arch"
                    return @{ Status = "failed" }
                }
            }
            $_binSubdir = "bin"
        }
        "Windows" {
            switch ($_arch) {
                { $_ -in "x64", "x86_64" } {
                    $_url = "https://github.com/Kitware/CMake/releases/download/v$env:TOOLS_VERSION_CMAKE/cmake-$env:TOOLS_VERSION_CMAKE-windows-x86_64.zip"
                }
                { $_ -in "arm64", "aarch64" } {
                    $_url = "https://github.com/Kitware/CMake/releases/download/v$env:TOOLS_VERSION_CMAKE/cmake-$env:TOOLS_VERSION_CMAKE-windows-arm64.zip"
                }
                default {
                    Write-Error "Unsupported architecture: $_arch"
                    return @{ Status = "failed" }
                }
            }
            $_binSubdir = "bin"
        }
    }

    # Download and extract
    New-Item -ItemType Directory -Path $_cmakeDir -Force | Out-Null
    $_tempFile = [System.IO.Path]::GetTempFileName()

    try {
        if ($_os -eq "Windows") {
            $_tempFile = $_tempFile -replace '\.tmp$', '.zip'
            Invoke-WebRequest -Uri $_url -OutFile $_tempFile -UseBasicParsing
            Expand-Archive -Path $_tempFile -DestinationPath $_cmakeDir -Force
            # Move contents up from nested directory
            $_nested = Get-ChildItem -Path $_cmakeDir -Directory | Select-Object -First 1
            if ($_nested) {
                Get-ChildItem -Path $_nested.FullName | Move-Item -Destination $_cmakeDir -Force
                Remove-Item -Path $_nested.FullName -Recurse -Force
            }
        } else {
            # Use curl and tar for macOS/Linux
            $null = bash -c "curl -fsSL '$_url' | tar -xz -C '$_cmakeDir' --strip-components=1" 2>&1
        }
        $_status = if (Test-Path "$_cmakeDir/$_binSubdir/cmake*") { "installed" } else { "failed" }
    } catch {
        Remove-Item -Path $_cmakeDir -Recurse -Force -ErrorAction SilentlyContinue
        $_status = "failed"
    } finally {
        Remove-Item -Path $_tempFile -Force -ErrorAction SilentlyContinue
    }
} else {
    # Already installed
    if (Get-Command Write-Tool -ErrorAction SilentlyContinue) {
        Write-Tool "cmake" $env:TOOLS_VERSION_CMAKE "available"
    }
    $_status = "available"
}

# Add to PATH
if ($_status -ne "failed") {
    $PathSep = [System.IO.Path]::PathSeparator
    # Determine bin directory based on OS
    if (Test-Path "$_cmakeDir/CMake.app") {
        $env:PATH = "$_cmakeDir/CMake.app/Contents/bin$PathSep$env:PATH"
    } else {
        $env:PATH = "$_cmakeDir/bin$PathSep$env:PATH"
    }
}

# Return result
@{ Status = $_status }
