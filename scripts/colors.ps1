# Color utilities for PowerShell
# Usage: . .\scripts\colors.ps1
#
# Provides Write-Tool function for consistent tool status output.
# PowerShell's Write-Host gracefully degrades when colors aren't supported.

function Write-Tool {
    param($Name, $Version, $Status)
    if ($Status -eq "installing") {
        Write-Host "  " -NoNewline
        Write-Host "Installing" -ForegroundColor Yellow -NoNewline
        Write-Host ": " -NoNewline
        Write-Host ("{0,-10}" -f $Name) -ForegroundColor Cyan -NoNewline
        Write-Host " $Version"
    } else {
        Write-Host "  " -NoNewline
        Write-Host "Available" -ForegroundColor Green -NoNewline
        Write-Host ":  " -NoNewline
        Write-Host ("{0,-10}" -f $Name) -ForegroundColor Cyan -NoNewline
        Write-Host " $Version"
    }
}
