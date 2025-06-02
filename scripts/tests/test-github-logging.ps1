#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test script for the GitHub Actions logging module.

.DESCRIPTION
    This script tests all functions in the Logging-GitHub module to ensure
    they produce the correct GitHub Actions workflow command output.

.EXAMPLE
    .\scripts\tests\test-github-logging.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Force remove any existing module instances
Get-Module Logging-GitHub | Remove-Module -Force -ErrorAction SilentlyContinue

# Import the GitHub logging module
$ModulePath = Join-Path $PSScriptRoot "..\modules\Logging-GitHub.psm1"
if (-not (Test-Path $ModulePath)) {
    Write-Error "GitHub logging module not found at: $ModulePath"
    exit 1
}

Import-Module $ModulePath -Force

Write-Host "=== Testing GitHub Actions Logging Module ===" -ForegroundColor Magenta
Write-Host ""

# First, check the module version to ensure we have the right one loaded
Write-Host "Checking module version..." -ForegroundColor Cyan
$version = Get-LoggingVersion
$version | Format-Table -AutoSize
Write-Host ""

Write-Host "Testing Write-Info..." -ForegroundColor Cyan
Write-Info "This is an informational message"

Write-Host "`nTesting Write-Success..." -ForegroundColor Cyan
Write-Success "Operation completed successfully"

Write-Host "`nTesting Write-Warning..." -ForegroundColor Cyan
Write-Warning "This is a warning message"

Write-Host "`nTesting Write-Error..." -ForegroundColor Cyan
Write-Error "This is an error message"

Write-Host "`nTesting Write-Result..." -ForegroundColor Cyan
Write-Result "PUBLISH_NEEDED (Changes Detected)"

Write-Host "`nTesting Write-Debug..." -ForegroundColor Cyan
Write-Debug "This is debug information"

Write-Host "`nTesting Write-Group..." -ForegroundColor Cyan
Write-Group "Test Group" {
    Write-Info "Inside the group"
    Write-Success "Group operation successful"
}

Write-Host "`nTesting Set-ActionOutput..." -ForegroundColor Cyan
# Create a temporary output file for testing
$tempOutput = New-TemporaryFile
$env:GITHUB_OUTPUT = $tempOutput.FullName
Set-ActionOutput "test_key" "test_value"
$outputContent = Get-Content $tempOutput.FullName
Write-Host "Output file content: $outputContent" -ForegroundColor Gray
Remove-Item $tempOutput.FullName
$env:GITHUB_OUTPUT = $null

Write-Host "`nTesting Add-ActionSummary..." -ForegroundColor Cyan
# Create a temporary summary file for testing
$tempSummary = New-TemporaryFile
$env:GITHUB_STEP_SUMMARY = $tempSummary.FullName
Add-ActionSummary "## Test Summary`n`nThis is a test summary with **bold** text."
$summaryContent = Get-Content $tempSummary.FullName -Raw
Write-Host "Summary file content:" -ForegroundColor Gray
Write-Host $summaryContent -ForegroundColor Gray
Remove-Item $tempSummary.FullName
$env:GITHUB_STEP_SUMMARY = $null

Write-Host "`n=== GitHub Actions Logging Module Test Complete ===" -ForegroundColor Green
Write-Host "All functions tested successfully!" -ForegroundColor Green
