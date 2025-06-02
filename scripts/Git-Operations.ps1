#!/usr/bin/env pwsh
# This file will be moved to modules/Git-Operations.psm1
# Use: Import-Module (Join-Path $PSScriptRoot "modules\Git-Operations.psm1") -Force
Write-Warning "This Git-Operations.ps1 will be replaced by modules/Git-Operations.psm1"
Write-Warning "Please update your scripts to use the new module location"

#region Git Repository Operations

<#
.SYNOPSIS
    Gets the last/latest git tag in the repository.
.DESCRIPTION
    Retrieves the most recent git tag using git describe.
.OUTPUTS
    String containing the tag name, or $null if no tags exist.
.EXAMPLE
    $lastTag = Get-LastTag
#>
function Get-LastTag {
    try {
        $lastTag = git describe --tags --abbrev=0 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $lastTag.Trim()
        }
    } catch {
        # No tags found or other error
    }
    return $null
}

<#
.SYNOPSIS
    Tests if the current directory is a git repository root.
.DESCRIPTION
    Checks for the existence of .git directory to validate repository.
.OUTPUTS
    Boolean indicating if current location is a git repository.
.EXAMPLE
    if (-not (Test-GitRepository)) { throw "Not in git repository" }
#>
function Test-GitRepository {
    return Test-Path ".git"
}

<#
.SYNOPSIS
    Tests if a specific git tag exists.
.DESCRIPTION
    Checks if the specified tag exists in the repository.
.PARAMETER TagName
    The tag name to check for existence.
.OUTPUTS
    Boolean indicating if the tag exists.
.EXAMPLE
    if (Test-GitTag "v1.0.0") { Write-Host "Tag exists" }
#>
function Test-GitTag {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TagName
    )
    
    try {
        $existingTag = git tag -l $TagName 2>$null
        return [bool]$existingTag
    } catch {
        return $false
    }
}

<#
.SYNOPSIS
    Gets changed files since a specific tag using git patterns.
.DESCRIPTION
    Returns files that have changed since the specified tag, filtered by patterns.
.PARAMETER TagName
    The tag to compare against.
.PARAMETER IncludePatterns
    Array of file patterns to include in the search.
.OUTPUTS
    Array of changed file paths.
.EXAMPLE
    $changes = Get-ChangedFilesSinceTag "v1.0.0" @("source/**/*.cs", "tests/**/*.cs")
#>
function Get-ChangedFilesSinceTag {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TagName,
        
        [Parameter(Mandatory = $true)]
        [string[]]$IncludePatterns
    )
    
    $changedFiles = @()
    
    foreach ($pattern in $IncludePatterns) {
        $files = git diff --name-only "$TagName...HEAD" -- $pattern 2>$null
        
        if ($files -and $files.Trim()) {
            $changedFiles += $files -split "`n" | Where-Object { $_.Trim() }
        }
    }
    
    return $changedFiles | Sort-Object -Unique
}

#endregion

#region Git Worktree Operations

<#
.SYNOPSIS
    Creates a temporary git worktree for isolated operations.
.DESCRIPTION
    Creates a worktree at the specified path for the given tag/commit.
.PARAMETER WorktreePath
    The path where the worktree should be created.
.PARAMETER TagOrCommit
    The tag or commit to checkout in the worktree.
.EXAMPLE
    New-GitWorktree ".git/.wt/v1.0.0" "v1.0.0"
#>
function New-GitWorktree {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorktreePath,
        
        [Parameter(Mandatory = $true)]
        [string]$TagOrCommit
    )
    
    # Ensure base directory exists
    $baseDir = Split-Path $WorktreePath -Parent
    if (-not (Test-Path $baseDir)) {
        New-Item -ItemType Directory -Path $baseDir -Force | Out-Null
    }
    
    # Remove existing worktree if it exists
    if (Test-Path $WorktreePath) {
        git worktree remove $WorktreePath --force 2>$null | Out-Null
    }
    
    # Create new worktree
    git worktree add $WorktreePath $TagOrCommit --quiet 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create worktree for $TagOrCommit at $WorktreePath"
    }
}

<#
.SYNOPSIS
    Removes a git worktree safely.
.DESCRIPTION
    Removes the specified worktree with proper error handling.
.PARAMETER WorktreePath
    The path of the worktree to remove.
.EXAMPLE
    Remove-GitWorktree ".git/.wt/v1.0.0"
#>
function Remove-GitWorktree {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorktreePath
    )
    
    if (Test-Path $WorktreePath) {
        git worktree remove $WorktreePath --force 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to remove worktree at $WorktreePath - manual cleanup may be needed"
        }
    }
}

#endregion

# Export functions for dot-sourcing
if ($MyInvocation.InvocationName -eq '.') {
    # Being dot-sourced, functions are automatically available
    Write-Debug "Git-Operations module loaded via dot-sourcing"
}
