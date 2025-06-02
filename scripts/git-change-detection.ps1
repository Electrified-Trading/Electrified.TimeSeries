#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Alternative approach: Use git diff to detect meaningful changes without building.

.DESCRIPTION
    This script uses git to detect if any meaningful source code files have changed
    since the last tag, avoiding the need to build and compare outputs.

.PARAMETER ProjectPath
    Path to the .csproj file (optional, for validation)

.PARAMETER TagName
    Specific tag to compare against (optional, defaults to latest tag)

.EXAMPLE
    .\scripts\git-change-detection.ps1
#>

param(
    [string]$ProjectPath = "source/Electrified.TimeSeries/Electrified.TimeSeries.csproj",
    [string]$TagName = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# GitHub Actions specific logging functions
function Write-ActionInfo($Message) {
    Write-Host "🔍 $Message" -ForegroundColor Cyan
}

function Write-ActionSuccess($Message) {
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-ActionWarning($Message) {
    Write-Host "⚠️ $Message" -ForegroundColor Yellow
}

function Write-ActionResult($Message, $Color = "White") {
    Write-Host ""
    Write-Host "🎯 RESULT: $Message" -ForegroundColor $Color -BackgroundColor Black
    Write-Host ""
}

function Get-LastTag {
    try {
        $lastTag = git describe --tags --abbrev=0 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $lastTag.Trim()
        }
    } catch {
        # No tags found
    }
    return $null
}

# Main execution
try {
    Write-ActionInfo "Starting git-based functional change detection..."
    
    # Ensure we're in a git repository
    if (-not (Test-Path ".git")) {
        Write-ActionError "Not in a git repository root"
        exit 2
    }
    
    # Get target tag
    $targetTag = if ($TagName) { $TagName } else { Get-LastTag }
    
    if (-not $targetTag) {
        Write-ActionWarning "No previous tags found - this appears to be the first release"
        Write-ActionResult "PUBLISH_NEEDED (First Release)" "Green"
        exit 1  # Signal changes detected (first release)
    }
    
    Write-ActionInfo "Comparing against tag: $targetTag"
    
    # Define patterns for meaningful files (source code that affects functionality)
    $meaningfulPatterns = @(
        "source/**/*.cs",
        "source/**/*.csproj", 
        "tests/**/*.cs",
        "tests/**/*.csproj"
    )
    
    # Check for changes in meaningful files since the tag
    Write-ActionInfo "Checking for functional code changes..."
    
    $hasChanges = $false
    $changedFiles = @()
    
    foreach ($pattern in $meaningfulPatterns) {
        # Use git diff to find changed files matching the pattern
        $files = git diff --name-only "$targetTag...HEAD" -- $pattern 2>$null
        
        if ($files -and $files.Trim()) {
            $changedFiles += $files -split "`n" | Where-Object { $_.Trim() }
            $hasChanges = $true
        }
    }
    
    if ($hasChanges) {
        Write-ActionWarning "Functional changes detected!"
        Write-ActionInfo "Changed files since $targetTag:"
        foreach ($file in $changedFiles) {
            Write-Host "  📝 $file" -ForegroundColor Gray
        }
        Write-ActionInfo "📦 CI/CD will create and publish new package version"
        Write-ActionResult "PUBLISH_NEEDED (Changes Detected)" "Yellow"
        exit 1  # Signal changes detected
    } else {
        Write-ActionSuccess "No functional changes detected!"
        Write-ActionInfo "✅ Only non-functional files changed (docs, scripts, etc.)"
        Write-ActionInfo "🚀 CI/CD will skip package publishing to avoid duplicate versions"
        Write-ActionResult "SKIP_PUBLISH (No Changes)" "Green"
        exit 0  # Signal no changes
    }
    
} catch {
    Write-ActionError "Git change detection failed: $_"
    Write-ActionWarning "🛡️ Failing safe: assuming changes exist to prevent missed releases"
    Write-ActionResult "PUBLISH_NEEDED (Safety Fallback)" "Red"
    exit 1  # Fail safe: assume changes exist
}
