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

# Import shared logging module
. (Join-Path $PSScriptRoot "Import-LoggingModule.ps1")

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
    Write-Info "Starting git-based functional change detection..."
    
    # Ensure we're in a git repository
    if (-not (Test-Path ".git")) {
        Write-Error "Not in a git repository root"
        exit 2
    }
    
    # Get target tag
    $targetTag = if ($TagName) { $TagName } else { Get-LastTag }
      if (-not $targetTag) {
        Write-Warning "No previous tags found - this appears to be the first release"
        Write-Result "PUBLISH_NEEDED (First Release)"
        exit 1  # Signal changes detected (first release)
    }
    
    Write-Info "Comparing against tag: $targetTag"
    
    # Define patterns for meaningful files (source code that affects functionality)
    $meaningfulPatterns = @(
        "source/**/*.cs",
        "source/**/*.csproj", 
        "tests/**/*.cs",
        "tests/**/*.csproj"
    )
      # Check for changes in meaningful files since the tag
    Write-Info "Checking for functional code changes..."
    
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
        Write-Warning "Functional changes detected!"
        Write-Info "Changed files since ${targetTag}:"
        foreach ($file in $changedFiles) {
            Write-Host "  📝 $file" -ForegroundColor Gray
        }
        Write-Info "📦 CI/CD will create and publish new package version"
        Write-Result "PUBLISH_NEEDED (Changes Detected)"
        exit 1  # Signal changes detected
    } else {
        Write-Success "No functional changes detected!"
        Write-Info "✅ Only non-functional files changed (docs, scripts, etc.)"
        Write-Info "🚀 CI/CD will skip package publishing to avoid duplicate versions"
        Write-Result "SKIP_PUBLISH (No Changes)"
        exit 0  # Signal no changes
    }
    
} catch {
    Write-Error "Git change detection failed: $_"
    Write-Warning "🛡️ Failing safe: assuming changes exist to prevent missed releases"
    Write-Result "PUBLISH_NEEDED (Safety Fallback)"
    exit 1  # Fail safe: assume changes exist
}
