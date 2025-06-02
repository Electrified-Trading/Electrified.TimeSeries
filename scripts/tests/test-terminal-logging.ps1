#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test script for the Terminal logging module.

.DESCRIPTION
    This script tests all functions in the Logging-Terminal module to ensure
    they produce the correct colored terminal output for local development.

.EXAMPLE
    .\scripts\tests\test-terminal-logging.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Import the Terminal logging module
$ModulePath = Join-Path $PSScriptRoot "..\modules\Logging-Terminal.psm1"
if (-not (Test-Path $ModulePath)) {
    Write-Error "Terminal logging module not found at: $ModulePath"
    exit 1
}

Import-Module $ModulePath -Force

Write-Host "=== Testing Terminal Logging Module ===" -ForegroundColor Magenta
Write-Host ""

# First, check the module version to ensure we have the right one loaded
Write-Host "Checking module version..." -ForegroundColor Cyan
$version = Get-LoggingVersion
$version | Format-Table -AutoSize
Write-Host ""

Write-Host "Testing Write-Info..." -ForegroundColor White
Write-Info "This is an informational message"

Write-Host "`nTesting Write-Success..." -ForegroundColor White
Write-Success "Operation completed successfully"

Write-Host "`nTesting Write-Warning..." -ForegroundColor White
Write-Warning "This is a warning message"

Write-Host "`nTesting Write-Error..." -ForegroundColor White
Write-Error "This is an error message"

Write-Host "`nTesting Write-Result..." -ForegroundColor White
Write-Result "PUBLISH_NEEDED (Changes Detected)"

Write-Host "`nTesting Write-Debug..." -ForegroundColor White
Write-Debug "This is debug information"

Write-Host "`nTesting Write-Group..." -ForegroundColor White
Write-Group "Test Group" {
    Write-Info "Inside the group"
    Write-Success "Group operation successful"
}

Write-Host "`nTesting Set-ActionOutput..." -ForegroundColor White
Set-ActionOutput "test_key" "test_value"

Write-Host "`nTesting Add-ActionSummary..." -ForegroundColor White
Add-ActionSummary "## Test Summary`n`nThis is a test summary with **bold** text."

Write-Host "`n=== Terminal Logging Module Test Complete ===" -ForegroundColor Green
Write-Host "All functions tested successfully! Check the colors and formatting above." -ForegroundColor Green
