# Source this file: . .\activate.ps1

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load .env files (.env first, then .env.local which overrides)
. "$RepoDir\scripts\dotenv.ps1" "$RepoDir\.env" "$RepoDir\.env.local"

# Export REPO_DIR for future use
$env:REPO_DIR = $RepoDir

# Expand TOOLS_FOLDER to full path and export
# First expand ~ to home directory if present (USERPROFILE on Windows, HOME on Unix)
if ($env:TOOLS_FOLDER.StartsWith('~')) {
    $HomeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
    $env:TOOLS_FOLDER = $env:TOOLS_FOLDER -replace '^~', $HomeDir
}
# Then make relative paths absolute
if ([System.IO.Path]::IsPathRooted($env:TOOLS_FOLDER)) {
    # Already absolute, keep as-is
} else {
    $env:TOOLS_FOLDER = [System.IO.Path]::Combine($RepoDir, $env:TOOLS_FOLDER)
}

# Load color utilities
. "$RepoDir/scripts/colors.ps1"

Write-Host ""
Write-Host "Activating development environment at: " -NoNewline
Write-Host $RepoDir -ForegroundColor Cyan
Write-Host ""
Write-Host "Tools:"

# Setup uv
$uvResult = . "$RepoDir/scripts/tools/uv.ps1"
if ($uvResult.Status -eq "failed") {
    Write-Host "  Error: Failed to setup uv" -ForegroundColor Red
}

# Setup cmake
$cmakeResult = . "$RepoDir/scripts/tools/cmake.ps1"
if ($cmakeResult.Status -eq "failed") {
    Write-Host "  Error: Failed to setup cmake" -ForegroundColor Red
}

# Setup ninja
$ninjaResult = . "$RepoDir/scripts/tools/ninja.ps1"
if ($ninjaResult.Status -eq "failed") {
    Write-Host "  Error: Failed to setup ninja" -ForegroundColor Red
}

# Setup emscripten
$emsdkResult = . "$RepoDir/scripts/tools/emscripten.ps1"
if ($emsdkResult.Status -eq "failed") {
    Write-Host "  Error: Failed to setup emscripten" -ForegroundColor Red
}

# Setup act (optional - requires Docker)
$actResult = . "$RepoDir/scripts/tools/act.ps1"
if ($actResult.Status -eq "failed") {
    Write-Host "  Error: Failed to setup act" -ForegroundColor Red
}

# Setup gh (GitHub CLI)
$ghResult = . "$RepoDir/scripts/tools/gh.ps1"
if ($ghResult.Status -eq "failed") {
    Write-Host "  Error: Failed to setup gh" -ForegroundColor Red
}

Write-Host ""

# Sync Python dependencies
uv sync

Write-Host "Environment activated."

# Cleanup internal variables and functions
Remove-Variable RepoDir, uvResult, cmakeResult, ninjaResult, emsdkResult, actResult, ghResult, HomeDir -ErrorAction SilentlyContinue
Remove-Item Function:\Write-Tool
