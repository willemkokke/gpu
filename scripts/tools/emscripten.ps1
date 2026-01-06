# Tool script for Emscripten SDK (WebAssembly compiler toolchain)
# Dot-source this file after setting $env:TOOLS_FOLDER and $env:TOOLS_VERSION_EMSDK
#
# Requires (environment variables):
#   $env:TOOLS_FOLDER        - Base folder for tools (absolute path)
#   $env:TOOLS_VERSION_EMSDK - Version to install (e.g., 4.0.9)
#
# Returns (hashtable):
#   @{ Status = "installed" | "available" | "failed" }
#
# Tools made available:
#   emcc, em++, emar, emranlib, emmake, emcmake, emrun, emsdk
#   python, node (from emsdk bundled versions)
#
# Behavior:
#   - Checks if emsdk is already installed (early exit if yes)
#   - Prints status via Write-Tool (if available)
#   - Clones emsdk repo and installs specified version if missing
#   - Sources emsdk_env to set PATH and other env vars
#   - Adds python and node from emsdk to PATH

# Validate required variables
if (-not $env:TOOLS_FOLDER -or -not $env:TOOLS_VERSION_EMSDK) {
    Write-Error "TOOLS_FOLDER and TOOLS_VERSION_EMSDK must be set"
    return @{ Status = "failed" }
}

$_emsdkDir = [System.IO.Path]::Combine($env:TOOLS_FOLDER, "emsdk@$env:TOOLS_VERSION_EMSDK")

if (-not (Test-Path $_emsdkDir)) {
    # Clone emsdk repository
    git clone --depth 1 https://github.com/emscripten-core/emsdk.git "$_emsdkDir" 2>&1 | Out-Null

    if (Test-Path $_emsdkDir) {
        # Install and activate the specified version
        Push-Location $_emsdkDir
        try {
            if ($IsWindows -or $env:OS -eq "Windows_NT") {
                # Windows: use batch scripts
                & cmd /c "emsdk.bat install $env:TOOLS_VERSION_EMSDK" 2>&1 | Out-Null
                & cmd /c "emsdk.bat activate $env:TOOLS_VERSION_EMSDK" 2>&1 | Out-Null
            } else {
                # macOS/Linux: use shell scripts
                bash -c "./emsdk install $env:TOOLS_VERSION_EMSDK" 2>&1 | Out-Null
                bash -c "./emsdk activate $env:TOOLS_VERSION_EMSDK" 2>&1 | Out-Null
            }
        } finally {
            Pop-Location
        }

        $_status = if (Test-Path "$_emsdkDir/emsdk_env.sh") { "installed" } else { "failed" }
    } else {
        $_status = "failed"
    }
} else {
    $_status = "available"
}

# Source emsdk_env to set up PATH and environment variables
if ($_status -ne "failed") {
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        # Windows: parse emsdk_env.bat output or use the .ps1 if available
        $envScript = [System.IO.Path]::Combine($_emsdkDir, "emsdk_env.ps1")
        if (Test-Path $envScript) {
            . $envScript 2>&1 | Out-Null
        } else {
            # Fallback: manually add to PATH
            $upstreamDir = [System.IO.Path]::Combine($_emsdkDir, "upstream", "emscripten")
            if (Test-Path $upstreamDir) {
                $PathSep = [System.IO.Path]::PathSeparator
                $env:PATH = "$upstreamDir$PathSep$_emsdkDir$PathSep$env:PATH"
            }
        }
    } else {
        # macOS/Linux: source emsdk_env.sh and capture env changes
        $envScript = [System.IO.Path]::Combine($_emsdkDir, "emsdk_env.sh")
        if (Test-Path $envScript) {
            # Run bash to source the script and output env vars
            $envOutput = bash -c "source '$envScript' >/dev/null 2>&1 && env"
            foreach ($line in $envOutput -split "`n") {
                if ($line -match '^([^=]+)=(.*)$') {
                    $varName = $matches[1]
                    $varValue = $matches[2]
                    # Only set emsdk-related vars and PATH
                    if ($varName -eq 'PATH' -or $varName -like 'EMSDK*' -or $varName -eq 'EM_CONFIG') {
                        [Environment]::SetEnvironmentVariable($varName, $varValue, 'Process')
                    }
                }
            }
        }
    }
}

# Add python and node from emsdk to PATH and print their versions (before emscripten)
if ($_status -ne "failed") {
    $PathSep = [System.IO.Path]::PathSeparator

    if ($env:EMSDK_PYTHON -and (Test-Path $env:EMSDK_PYTHON)) {
        $_pythonDir = Split-Path -Parent $env:EMSDK_PYTHON
        $env:PATH = "$_pythonDir$PathSep$env:PATH"
        $_pythonVer = ((& $env:EMSDK_PYTHON --version 2>$null) -split ' ')[1]
        if (Get-Command Write-Tool -ErrorAction SilentlyContinue) {
            Write-Tool "python" $_pythonVer $_status
        }
    }

    if ($env:EMSDK_NODE -and (Test-Path $env:EMSDK_NODE)) {
        $_nodeDir = Split-Path -Parent $env:EMSDK_NODE
        $env:PATH = "$_nodeDir$PathSep$env:PATH"
        $_nodeVer = (& $env:EMSDK_NODE --version 2>$null) -replace '^v', ''
        if (Get-Command Write-Tool -ErrorAction SilentlyContinue) {
            Write-Tool "node" $_nodeVer $_status
        }
    }
}

# Print emscripten status last
if (Get-Command Write-Tool -ErrorAction SilentlyContinue) {
    Write-Tool "emscripten" $env:TOOLS_VERSION_EMSDK $_status
}

# Return result
@{ Status = $_status }
