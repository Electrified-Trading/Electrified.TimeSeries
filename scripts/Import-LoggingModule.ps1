#
# Smart Logging Module Loader
# Detects environment and loads appropriate logging module
# Usage: . $PSScriptRoot\Import-LoggingModule.ps1
#

# Determine the correct module path relative to this script
$ModulesPath = Join-Path $PSScriptRoot "modules"

if ($env:GITHUB_ACTIONS -eq "true") {
    # Load GitHub Actions logging module
    $LoggingModule = Join-Path $ModulesPath "Logging-GitHub.psm1"
} else {
    # Load Terminal logging module for local development
    $LoggingModule = Join-Path $ModulesPath "Logging-Terminal.psm1"
}

Import-Module $LoggingModule -Force
Remove-Variable LoggingModule
