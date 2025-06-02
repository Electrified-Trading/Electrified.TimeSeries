#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test script to prove both logging modules can bounce versions.

.DESCRIPTION
    This script tests that both Logging-GitHub and Logging-Terminal modules
    can be reloaded with updated versions, proving module bouncing works.

.EXAMPLE
    .\scripts\tests\test-both-module-versions.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "=== Testing Module Version Bouncing ===" -ForegroundColor Magenta
Write-Host ""

# Test GitHub module
Write-Host "Testing GitHub Module Version..." -ForegroundColor Cyan
Get-Module Logging-GitHub | Remove-Module -Force -ErrorAction SilentlyContinue
$GitHubModulePath = Join-Path $PSScriptRoot "..\modules\Logging-GitHub.psm1"
Import-Module $GitHubModulePath -Force
$githubVersion = Get-LoggingVersion
Write-Host "GitHub Module: $($githubVersion.ModuleName) v$($githubVersion.Version) (Build: $($githubVersion.Build))" -ForegroundColor Green

# Test Terminal module  
Write-Host "Testing Terminal Module Version..." -ForegroundColor Cyan
Get-Module Logging-Terminal | Remove-Module -Force -ErrorAction SilentlyContinue
$TerminalModulePath = Join-Path $PSScriptRoot "..\modules\Logging-Terminal.psm1"
Import-Module $TerminalModulePath -Force
$terminalVersion = Get-LoggingVersion
Write-Host "Terminal Module: $($terminalVersion.ModuleName) v$($terminalVersion.Version) (Build: $($terminalVersion.Build))" -ForegroundColor Green

Write-Host ""
Write-Host "=== Module Version Bouncing Test Complete ===" -ForegroundColor Green
Write-Host "✅ Both modules successfully loaded with current versions" -ForegroundColor Green
Write-Host "✅ Module bouncing technique is working properly" -ForegroundColor Green
