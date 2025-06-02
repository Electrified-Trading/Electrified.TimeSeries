#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Compare build output hashes to detect functional changes for CI/CD package publishing.

.DESCRIPTION
    This script compares build output between current code and the latest tag to determine
    if meaningful functional changes have occurred. Uses deterministic file-by-file hash
    comparison to avoid false positives from package metadata differences.

.PARAMETER ProjectPath
    Path to the .csproj file to build and compare

.PARAMETER TagName
    Specific tag to compare against (optional, defaults to latest tag)

.PARAMETER OutputDir
    Directory for build artifacts (optional, defaults to workflow-comparison)

.PARAMETER Mode
    Execution mode: 'Local' (default) for development/testing, 'CI' for GitHub Actions with structured output

.PARAMETER Debug
    Enable detailed debug logging for troubleshooting

.PARAMETER SkipGitOperations
    For testing: skip git operations and use current code as both baseline and comparison

.EXAMPLE
    # Local development testing
    .\scripts\compare-build-output.ps1 -Debug
    
.EXAMPLE
    # CI/CD mode with specific tag
    .\scripts\compare-build-output.ps1 -Mode CI -TagName "v1.2.0"

.EXAMPLE
    # Test mode without git operations
    .\scripts\compare-build-output.ps1 -SkipGitOperations -Debug

.NOTES
    Exit codes:
    0 = No changes detected (skip publishing)
    1 = Changes detected or first release (publish needed)
    2 = Configuration/environment error
#>

param(
    [string]$ProjectPath = "source/Electrified.TimeSeries/Electrified.TimeSeries.csproj",
    [string]$TagName = "",
    [string]$OutputDir = "workflow-comparison",
    [ValidateSet("Local", "CI")]
    [string]$Mode = "Local",
    [switch]$Debug = $false,
    [switch]$SkipGitOperations = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Import shared logging module
. (Join-Path $PSScriptRoot "Import-LoggingModule.ps1")

# Import Git operations module
Import-Module (Join-Path $PSScriptRoot "modules" "Git-Operations.psm1") -Force

# Determine if we're in CI mode
$IsCI = $Mode -eq "CI" -or $env:GITHUB_ACTIONS -eq "true"

function Write-DetailedProgress($Activity, $Status = "In Progress") {
    if (-not $IsCI) {
        Write-Host "  $Activity" -NoNewline
        if ($Status -eq "Done") {
            Write-Host " Done" -ForegroundColor Green
        }
    } else {
        #Write-Info "$Activity"
    }
}

function Build-AndHashOutput($BuildPath, $Description = "build") {
    Write-Info "Building and hashing $Description output..."
    
    # Clean and create build directory
    if (Test-Path $BuildPath) {
        Remove-Item $BuildPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $BuildPath | Out-Null
      # Build the project with deterministic settings
    Write-DetailedProgress "Building..."
    $env:CI = "true"  # Enable ContinuousIntegrationBuild
    dotnet build $ProjectPath --configuration Debug --verbosity quiet | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed for $Description"
    }

    Write-DetailedProgress "" "Done"
    
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
      Write-Info "Hashing $($filesToHash.Count) files for comparison:"

    # Create content hash manifest with NORMALIZED relative paths
    $contentHashes = @{}
    foreach ($file in $filesToHash) {
        # Use only the filename for the key to ensure consistency between builds
        # This normalizes paths between current working directory and worktree
        $normalizedKey = $file.Name
        $fileHash = Get-FileHash $file.FullName -Algorithm SHA256
        $contentHashes[$normalizedKey] = $fileHash.Hash
        
        if (-not $IsCI) {
            Write-Host "    $normalizedKey : $($fileHash.Hash.Substring(0,8))..." -ForegroundColor Gray
        }
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
      Write-Info "Combined content hash: $($combinedHashString.Substring(0,16))..."
    Write-Debug "Manifest saved: $(Split-Path $manifestPath -Leaf)"
    
    return @{
        ManifestPath = $manifestPath
        CombinedHash = $combinedHashString
        FileHashes = $contentHashes
        FileCount = $filesToHash.Count
    }
}

function Build-TaggedOutput($Tag, $BuildPath) {
    if ($SkipGitOperations) {
        Write-Warning "TESTING MODE: Skipping git operations, using current code as 'tagged' version"
        return Build-AndHashOutput $BuildPath "current-as-tagged (testing)"
    }

    Write-Info "Building output from tag $Tag using worktree..."
    
    # Use clean tag name for worktree path: .git/.wt/v1.0.1
    $worktreePath = Join-Path (Get-Location) ".git/.wt/$Tag"
    $originalLocation = Get-Location
    
    try {
        # Create worktree using Git-Operations module
        New-GitWorktree $worktreePath $Tag
        
        if ($Debug) {
            Write-Debug "Worktree created successfully at: $worktreePath"
            Write-Debug "Switching to worktree directory for build"
        }

        # Change to worktree directory and build
        Push-Location $worktreePath
        
        # Build the tagged version in the worktree
        $taggedResult = Build-AndHashOutput $BuildPath "tagged ($Tag)"
        
        if ($Debug) {
            Write-Debug "Tagged build completed in worktree"
            Write-Debug "taggedResult type: $($taggedResult.GetType().Name)"
            Write-Debug "taggedResult.CombinedHash exists: $($null -ne $taggedResult.CombinedHash)"
        }

        return $taggedResult
        
    } finally {
        # Always restore location first
        if ((Get-Location).Path -ne $originalLocation.Path) {
            Pop-Location
        }

        # Clean up worktree using Git-Operations module
        Remove-GitWorktree $worktreePath
    }
}

function Compare-ContentHashes($CurrentResult, $TaggedResult) {
    Write-Info "Comparing build content hashes..."
      $currentHash = $CurrentResult.CombinedHash
    $taggedHash = $TaggedResult.CombinedHash
    
    if (-not $IsCI) {
        Write-Host "  Current:  $($currentHash.Substring(0,16))... ($($CurrentResult.FileCount) files)" -ForegroundColor Gray
        Write-Host "  Tagged:   $($taggedHash.Substring(0,16))... ($($TaggedResult.FileCount) files)" -ForegroundColor Gray
    } else {
        Write-Info "Current hash: $($currentHash.Substring(0,16))... ($($CurrentResult.FileCount) files)"
        Write-Info "Tagged hash: $($taggedHash.Substring(0,16))... ($($TaggedResult.FileCount) files)"
    }
    
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
        Write-Info "File changes detected:"
        foreach ($change in $changedFiles) {
            if (-not $IsCI) {
                Write-Host "    $change" -ForegroundColor Yellow
            } else {
                Write-Info "  $change"
            }
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

# Main execution with error handling and structured output
function Invoke-MainExecution {
    try {
        Write-Info "Starting functional change detection via build output comparison..."
        Write-Info "Mode: $Mode | Project: $ProjectPath"
        
        # Ensure we're in a git repository
        Assert-GitRepository
        
        # Validate project file
        if (-not (Test-Path $ProjectPath)) {
            Write-Error "Project file not found: $ProjectPath"
            
            if ($IsCI) {
                return 2  # Configuration error in CI mode
            } else {
                exit 2  # Configuration error in Local mode
            }
        }
        
        # Get target tag
        $targetTag = if ($TagName) { $TagName } else { Get-LastTag }
          if (-not $targetTag) {
            Write-Warning "No previous tags found - this appears to be the first release"
            Write-Result "PUBLISH_NEEDED (First Release)"
            
            if ($IsCI) {
                return 1  # Signal changes detected (first release) in CI mode
            } else {
                exit 1  # Signal changes detected (first release) in Local mode
            }
        }
        
        Write-Info "Comparing against tag: $targetTag"
          # Phase 1: Environment & Git Setup
        Write-Group "🔧 Environment & Git Setup" {
            Write-Success "Environment setup complete"
        }
        
        # Phase 2: Build Operations
        Write-Group "🔨 Build Operations" {
            Write-Info "Building current version..."
            Write-Info "Building tagged version ($targetTag)..."
            Write-Success "Build operations initiated"
        }
        
        # Build current output
        $currentResult = Build-AndHashOutput (Join-Path $OutputDir "current") "current"
        
        # Build tagged output
        $taggedResult = Build-TaggedOutput $targetTag (Join-Path $OutputDir "tagged")
        
        if($Debug) {
            Write-Debug "After Build-TaggedOutput call:"
            Write-Debug "taggedResult type: $($taggedResult.GetType().Name)"
            Write-Debug "taggedResult is array: $($taggedResult -is [array])"
            if ($taggedResult -is [array]) {
                Write-Debug "Array has $($taggedResult.Count) elements"
                Write-Debug "First element type: $($taggedResult[0].GetType().Name)"
                Write-Debug "First element has CombinedHash: $($null -ne $taggedResult[0].CombinedHash)"
            } else {
                Write-Debug "Has CombinedHash: $($null -ne $taggedResult.CombinedHash)"
            }
        }

        Write-Success "Built and analyzed both versions:"
        if (-not $IsCI) {
            Write-Host "  Current: $($currentResult.FileCount) files" -ForegroundColor Gray
            Write-Host "  Tagged:  $($taggedResult.FileCount) files" -ForegroundColor Gray
        }
        
        # Phase 3: Hash Comparison & Decision
        Write-Group "🔍 Hash Comparison & Decision" {
            # Compare hashes
            $comparison = Compare-ContentHashes $currentResult $taggedResult
              if ($comparison.Identical) {
                Write-Info "Build outputs are SAME"
                Write-Info "No functional changes detected between current code and $targetTag"
                Write-Info "CI/CD will skip package publishing to avoid duplicate versions"
                Write-Result "SKIP_PUBLISH (No Changes)"
                
                if ($IsCI) {
                    return 0  # Signal no changes in CI mode
                } else {
                    exit 0  # Signal no changes in Local mode
                }
            } else {
                Write-Info "Build outputs are DIFFERENT"
                Write-Info "Functional changes detected between current code and $targetTag"
                
                if ($comparison.CurrentFileCount -ne $comparison.TaggedFileCount) {
                    $fileDiff = $comparison.CurrentFileCount - $comparison.TaggedFileCount
                    $fileDirection = if ($fileDiff -gt 0) { "more" } else { "fewer" }
                    Write-Info "File count difference: $([Math]::Abs($fileDiff)) $fileDirection files"
                }
                
                Write-Info "CI/CD will create and publish new package version"
                Write-Result "PUBLISH_NEEDED (Changes Detected)"
                
                if ($IsCI) {
                    return 1  # Signal changes detected in CI mode
                } else {
                    exit 1  # Signal changes detected in Local mode
                }
            }
        }
          } catch {
        if($Debug) { 
            Write-Error "Debug mode: re-throwing exception for investigation"
            throw $_ 
        }
        Write-Error "Build comparison failed: $_"
        Write-Warning "Failing safe: assuming changes exist to prevent missed releases"
        Write-Result "PUBLISH_NEEDED (Safety Fallback)"
        
        if ($IsCI) {
            return 1  # Fail safe: assume changes exist in CI mode
        } else {
            exit 1  # Fail safe: assume changes exist in Local mode
        }
    }
}

# Execute main function
if ($IsCI) {
    # In CI mode, capture return value and set outputs for GitHub Actions
    $result = Invoke-MainExecution
      # Set GitHub Actions outputs based on result
    if ($result -eq 0) {
        Set-ActionOutput "has_changes" "false"
    } else {
        Set-ActionOutput "has_changes" "true"
    }
    
    # Always exit 0 in CI mode to let workflow continue
    exit 0
} else {
    # In Local mode, let function handle exit directly
    Invoke-MainExecution
}
