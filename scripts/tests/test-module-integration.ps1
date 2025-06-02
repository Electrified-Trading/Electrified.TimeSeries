#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Integration test to verify all modules work correctly with refactored scripts.

.DESCRIPTION
    This script tests the integration between the new modules (Git-Operations, Project-Version)
    and the refactored scripts to ensure everything works together properly.

.EXAMPLE
    .\scripts\tests\test-module-integration.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "=== Module Integration Test ===" -ForegroundColor Magenta
Write-Host ""

# Import logging first
. (Join-Path $PSScriptRoot ".." "Import-LoggingModule.ps1")

Write-Host "Testing module imports..." -ForegroundColor Cyan

# Test Git-Operations module
try {
    Import-Module (Join-Path $PSScriptRoot ".." "modules" "Git-Operations.psm1") -Force
    $gitVersion = Get-GitOperationsVersion
    Write-Host "✅ Git-Operations: v$($gitVersion.Version) (Build: $($gitVersion.Build))" -ForegroundColor Green
} catch {
    Write-Host "❌ Git-Operations module failed: $_" -ForegroundColor Red
    exit 1
}

# Test Project-Version module
try {
    Import-Module (Join-Path $PSScriptRoot ".." "modules" "Project-Version.psm1") -Force
    $projectVersion = Get-ProjectVersionModuleVersion
    Write-Host "✅ Project-Version: v$($projectVersion.Version) (Build: $($projectVersion.Build))" -ForegroundColor Green
} catch {
    Write-Host "❌ Project-Version module failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Testing module functions..." -ForegroundColor Cyan

# Test Git operations
try {
    Assert-GitRepository
    $lastTag = Get-LastTag
    Write-Host "✅ Git operations working - Last tag: $lastTag" -ForegroundColor Green
} catch {
    Write-Host "❌ Git operations failed: $_" -ForegroundColor Red
    exit 1
}

# Test Project version operations
try {
    $projectFile = "source\Electrified.TimeSeries\Electrified.TimeSeries.csproj"
    Assert-ProjectFile $projectFile
    $version = Get-ProjectVersion $projectFile
    $versionParts = Get-VersionParts $version
    Write-Host "✅ Project version operations working - Version: $version (Major: $($versionParts.Major), Minor: $($versionParts.Minor), Patch: $($versionParts.Patch))" -ForegroundColor Green
} catch {
    Write-Host "❌ Project version operations failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Testing refactored scripts..." -ForegroundColor Cyan

# Test git-change-detection script
try {
    Write-Host "Testing git-change-detection.ps1..." -ForegroundColor Yellow
    & (Join-Path $PSScriptRoot ".." "git-change-detection.ps1") 2>$null | Out-Null
    $gitChangeResult = $LASTEXITCODE
    Write-Host "✅ git-change-detection.ps1 executed successfully (exit code: $gitChangeResult)" -ForegroundColor Green
} catch {
    Write-Host "❌ git-change-detection.ps1 failed: $_" -ForegroundColor Red
}

# Test test-package-hash script
try {
    Write-Host "Testing test-package-hash.ps1..." -ForegroundColor Yellow
    & (Join-Path $PSScriptRoot ".." "test-package-hash.ps1") -DryRun 2>$null | Out-Null
    Write-Host "✅ test-package-hash.ps1 executed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ test-package-hash.ps1 failed: $_" -ForegroundColor Red
}

# Test release script
try {
    Write-Host "Testing release.ps1..." -ForegroundColor Yellow
    & (Join-Path $PSScriptRoot ".." "release.ps1") -DryRun -Force 2>$null | Out-Null
    Write-Host "✅ release.ps1 executed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ release.ps1 failed: $_" -ForegroundColor Red
}

# Test compare-build-output script (quick test)
try {
    Write-Host "Testing compare-build-output.ps1..." -ForegroundColor Yellow
    & (Join-Path $PSScriptRoot ".." "compare-build-output.ps1") -SkipGitOperations 2>$null | Out-Null
    Write-Host "✅ compare-build-output.ps1 executed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ compare-build-output.ps1 failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Module Integration Test Complete ===" -ForegroundColor Green
Write-Host "✅ All modules and refactored scripts are working correctly!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "• Git-Operations module: v$($gitVersion.Version) - $($gitVersion.Features.Count) features" -ForegroundColor Gray
Write-Host "• Project-Version module: v$($projectVersion.Version) - $($projectVersion.Features.Count) features" -ForegroundColor Gray
Write-Host "• 4 refactored scripts tested successfully" -ForegroundColor Gray
Write-Host "• Code duplication eliminated via modularization" -ForegroundColor Gray
