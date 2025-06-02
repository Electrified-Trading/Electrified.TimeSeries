#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Compare build output hashes to detect functional changes for CI/CD package publishing.

.DESCRIPTION
    This script compares build output (zip archives) between current code and the latest tag
    to determine if meaningful functional changes have occurred. Uses deterministic zip-based
    comparison to avoid false positives from package metadata differences.

.PARAMETER ProjectPath
    Path to the .csproj file to build and compare

.PARAMETER TagName
    Specific tag to compare against (optional, defaults to latest tag)

.PARAMETER OutputDir
    Directory for build artifacts (optional, defaults to workflow-comparison)

.EXAMPLE
    .\scripts\compare-build-output-v4.ps1
    
.EXAMPLE
    .\scripts\compare-build-output-v4.ps1 -ProjectPath "src/MyProject.csproj" -TagName "v1.2.0"
#>

param(
    [string]$ProjectPath = "source/Electrified.TimeSeries/Electrified.TimeSeries.csproj",
    [string]$TagName = "",
    [string]$OutputDir = "workflow-comparison"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Enable UTF-8 output for GitHub Actions
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# GitHub Actions specific logging functions
function Write-ActionInfo($Message) {
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-ActionSuccess($Message) {
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-ActionWarning($Message) {
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-ActionError($Message) {
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-ActionResult($Message, $Color = "White") {
    Write-Host ""
    Write-Host "RESULT: $Message" -ForegroundColor $Color -BackgroundColor Black
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

function Build-AndHashOutput($BuildPath, $Description = "build") {
    Write-ActionInfo "Building and hashing $Description output..."
    
    # Clean and create build directory
    if (Test-Path $BuildPath) {
        Remove-Item $BuildPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $BuildPath | Out-Null
    
    # Build the project with deterministic settings
    Write-Host "  Building..." -NoNewline
    $env:CI = "true"  # Enable ContinuousIntegrationBuild
    dotnet build $ProjectPath --configuration Debug --verbosity quiet | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed for $Description"
    }
    Write-Host " Done" -ForegroundColor Green
    
    # Find build output directory
    $projectDir = Split-Path $ProjectPath -Parent
    $binDebugPath = Join-Path $projectDir "bin\Debug"
    
    if (-not (Test-Path $binDebugPath)) {
        throw "Build output directory not found: $binDebugPath"
    }
    
    # Get all files to include (exclude packages and volatile metadata)
    $filesToHash = Get-ChildItem -Path $binDebugPath -Recurse -File | Where-Object {
        $_.Extension -notin @('.nupkg', '.snupkg') -and
        $_.Name -notmatch '\.(symbols\.)?nupkg$' -and
        $_.Name -ne 'project.nuget.cache'
    }
    
    if ($filesToHash.Count -eq 0) {
        throw "No files found to hash in build output directory"
    }
    
    Write-ActionInfo "Hashing $($filesToHash.Count) files for comparison:"
      # Create content hash manifest
    $contentHashes = @{}
    foreach ($file in $filesToHash) {
        $relativePath = $file.FullName.Substring($binDebugPath.Length + 1)
        $fileHash = Get-FileHash $file.FullName -Algorithm SHA256
        $contentHashes[$relativePath] = $fileHash.Hash
        Write-Host "    $relativePath : $($fileHash.Hash.Substring(0,8))..." -ForegroundColor Gray
    }
    
    # Create combined hash from all file hashes (sorted for determinism)
    $sortedHashes = $contentHashes.GetEnumerator() | Sort-Object Key | ForEach-Object { "$($_.Key):$($_.Value)" }
    $combinedHashInput = $sortedHashes -join "|"
    $combinedHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($combinedHashInput))
    $combinedHashString = [System.BitConverter]::ToString($combinedHash).Replace("-", "")
    
    # Save manifest to file
    $manifestPath = Join-Path $BuildPath "content-manifest.json"
    $manifest = @{
        CombinedHash = $combinedHashString
        FileHashes = $contentHashes
        BuildDescription = $Description
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    }
    $manifest | ConvertTo-Json -Depth 3 | Set-Content $manifestPath
    
    Write-ActionInfo "Combined content hash: $($combinedHashString.Substring(0,16))..."
    Write-ActionInfo "Manifest saved: $(Split-Path $manifestPath -Leaf)"
    
    return @{
        ManifestPath = $manifestPath
        CombinedHash = $combinedHashString
        FileHashes = $contentHashes
        FileCount = $filesToHash.Count
    }
}

function Build-TaggedOutput($Tag, $BuildPath) {
    Write-ActionInfo "Building output from tag $Tag..."
    
    # Save current state
    $currentBranch = git branch --show-current 2>$null
    $hasUncommittedChanges = $null -ne (git status --porcelain 2>$null)
    
    if ($hasUncommittedChanges) {
        Write-ActionInfo "Stashing uncommitted changes..."
        git stash push -m "Auto-stash for build comparison" | Out-Null
    }
    
    try {
        # Checkout the tag
        Write-ActionInfo "Checking out tag $Tag..."
        git checkout $Tag --quiet 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to checkout tag $Tag"
        }
        
        # Build and hash the tagged version
        $taggedResult = Build-AndHashOutput $BuildPath "tagged ($Tag)"
        return $taggedResult
    }
    finally {
        # Restore original state
        Write-ActionInfo "Restoring original git state..."
        if ($currentBranch) {
            git checkout $currentBranch --quiet 2>$null
        }
        
        if ($hasUncommittedChanges) {
            git stash pop --quiet 2>$null
        }
    }
}

function Compare-ContentHashes($CurrentResult, $TaggedResult) {
    Write-ActionInfo "Comparing build content hashes..."
    
    $currentHash = $CurrentResult.CombinedHash
    $taggedHash = $TaggedResult.CombinedHash
    
    Write-Host "  Current:  $($currentHash.Substring(0,16))... ($($CurrentResult.FileCount) files)" -ForegroundColor Gray
    Write-Host "  Tagged:   $($taggedHash.Substring(0,16))... ($($TaggedResult.FileCount) files)" -ForegroundColor Gray
    
    # Compare individual file hashes to identify what changed
    $changedFiles = @()
    $currentFiles = $CurrentResult.FileHashes
    $taggedFiles = $TaggedResult.FileHashes
    
    # Find changed or new files
    foreach ($file in $currentFiles.Keys) {
        if (-not $taggedFiles.ContainsKey($file)) {
            $changedFiles += "NEW: $file"
        } elseif ($currentFiles[$file] -ne $taggedFiles[$file]) {
            $changedFiles += "CHANGED: $file"
        }
    }
    
    # Find removed files
    foreach ($file in $taggedFiles.Keys) {
        if (-not $currentFiles.ContainsKey($file)) {
            $changedFiles += "REMOVED: $file"
        }
    }
    
    if ($changedFiles.Count -gt 0) {
        Write-ActionInfo "File changes detected:"
        foreach ($change in $changedFiles) {
            Write-Host "    $change" -ForegroundColor Yellow
        }
    }
    
    return @{
        Identical = $currentHash -eq $taggedHash
        CurrentHash = $currentHash
        TaggedHash = $taggedHash
        CurrentFileCount = $CurrentResult.FileCount
        TaggedFileCount = $TaggedResult.FileCount
        ChangedFiles = $changedFiles
    }
}

# Main execution
try {
    Write-ActionInfo "Starting functional change detection via build output comparison..."
    Write-ActionInfo "Project: $ProjectPath"
    
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
      # Create output directories
    $currentOutputPath = Join-Path $OutputDir "current"
    $taggedOutputPath = Join-Path $OutputDir "tagged"
    
    # Build current output
    $currentResult = Build-AndHashOutput $currentOutputPath "current"
    
    # Build tagged output
    $taggedResult = Build-TaggedOutput $targetTag $taggedOutputPath
    
    Write-ActionSuccess "Built and analyzed both versions:"
    Write-Host "  Current: $($currentResult.FileCount) files" -ForegroundColor Gray
    Write-Host "  Tagged:  $($taggedResult.FileCount) files" -ForegroundColor Gray
    
    # Compare hashes
    $comparison = Compare-ContentHashes $currentResult $taggedResult
    
    if ($comparison.Identical) {
        Write-ActionSuccess "Build outputs are identical!"
        Write-ActionInfo "No functional changes detected between current code and $targetTag"
        Write-ActionInfo "CI/CD will skip package publishing to avoid duplicate versions"
        Write-ActionResult "SKIP_PUBLISH (No Changes)" "Green"
        exit 0  # Signal no changes
    } else {
        Write-ActionWarning "Build outputs differ!"
        Write-ActionInfo "Functional changes detected between current code and $targetTag"
        
        if ($comparison.CurrentFileCount -ne $comparison.TaggedFileCount) {
            $fileDiff = $comparison.CurrentFileCount - $comparison.TaggedFileCount
            $fileDirection = if ($fileDiff -gt 0) { "more" } else { "fewer" }
            Write-ActionInfo "File count difference: $([Math]::Abs($fileDiff)) $fileDirection files"
        }
        
        Write-ActionInfo "CI/CD will create and publish new package version"
        Write-ActionResult "PUBLISH_NEEDED (Changes Detected)" "Yellow"
        exit 1  # Signal changes detected
    }
    
} catch {
    Write-ActionError "Build comparison failed: $_"
    Write-ActionWarning "Failing safe: assuming changes exist to prevent missed releases"
    Write-ActionResult "PUBLISH_NEEDED (Safety Fallback)" "Red"
    exit 1  # Fail safe: assume changes exist
}
