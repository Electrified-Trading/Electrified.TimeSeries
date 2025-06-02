#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Final verification test for the modularized logging system.

.DESCRIPTION
    This script tests the complete logging system to ensure everything works correctly.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "=== Final Verification Test ===" -ForegroundColor Cyan

try {
    # Test import
    Write-Host "Testing import..." -ForegroundColor Yellow
    . (Join-Path $PSScriptRoot ".." "Import-LoggingModule.ps1")
    Write-Info "✅ Import successful!"
    
    # Test version info
    Write-Host "Testing version info..." -ForegroundColor Yellow
    $vers = Get-LoggingVersion
    Write-Host "Module: $($vers.ModuleName) v$($vers.Version)" -ForegroundColor Green
    Write-Host "Build: $($vers.Build)" -ForegroundColor Gray
    Write-Host "Description: $($vers.Description)" -ForegroundColor Gray
      # Test all functions
    Write-Host "Testing all logging functions..." -ForegroundColor Yellow
    Write-Info "Testing Write-Info"
    Write-Success "Testing Write-Success"
    Write-Warning "Testing Write-Warning"
    Write-Debug "Testing Write-Debug"
    Write-Result "Testing Write-Result"
    
    Write-Group "Testing Write-Group" {
        Write-Info "Content inside group"
    }
    
    Write-Host "=== All Tests Passed! ===" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Test failed: $_" -ForegroundColor Red
    exit 1
}
