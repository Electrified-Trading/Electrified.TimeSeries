#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates a release tag and bumps version for the next release.

.DESCRIPTION
    This script:
    1. Checks if there are code changes since the last tag
    2. Creates a release tag from the current VersionPrefix
    3. Pushes the tag to trigger GitHub Actions publishing
    4. Bumps the patch version for the next release
    5. Commits and pushes the version bump

.PARAMETER Force
    Skip the change detection and force a release even if no changes detected.

.PARAMETER DryRun
    Show what would be done without actually making changes.

.EXAMPLE
    .\scripts\release.ps1
    
.EXAMPLE
    .\scripts\release.ps1 -Force
    
.EXAMPLE
    .\scripts\release.ps1 -DryRun
#>

param(
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Ensure we're in the repo root
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot

try {
    Write-Host "🔍 Analyzing repository for release..." -ForegroundColor Cyan

    # Get the current version from the project file
    $projectFile = "source\Electrified.TimeSeries\Electrified.TimeSeries.csproj"
    if (-not (Test-Path $projectFile)) {
        throw "Project file not found: $projectFile"
    }

    $projectXml = [xml](Get-Content $projectFile)
    $versionPrefixNode = $projectXml.Project.PropertyGroup.VersionPrefix
    if (-not $versionPrefixNode) {
        throw "VersionPrefix not found in $projectFile"
    }

    $currentVersion = $versionPrefixNode
    Write-Host "📦 Current version: $currentVersion" -ForegroundColor Green

    # Parse version components
    if ($currentVersion -notmatch '^(\d+)\.(\d+)\.(\d+)$') {
        throw "Invalid version format: $currentVersion (expected x.y.z)"
    }
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]

    # Check if tag already exists
    $tagName = "v$currentVersion"
    $existingTag = git tag -l $tagName 2>$null
    if ($existingTag -and -not $Force) {
        throw "Tag $tagName already exists. Use -Force to override or bump the version first."
    }

    # Get the latest tag to check for changes
    $latestTag = git describe --tags --abbrev=0 2>$null
    if ($latestTag) {
        Write-Host "🏷️  Latest tag: $latestTag" -ForegroundColor Yellow
          # Check for changes since last tag (exclude version bumps and build artifacts)
        $changes = git diff --name-only "$latestTag..HEAD" -- . ':!*.csproj' ':!scripts/release.ps1' ':!change-log/' ':!*.md' ':!bin/' ':!obj/' ':!test-output/'
        if (-not $changes -and -not $Force) {
            Write-Host "⚠️  No code changes detected since ${latestTag}" -ForegroundColor Yellow
            Write-Host "   Only documentation, build artifacts, or version files have changed" -ForegroundColor Gray
            Write-Host "   Use -Force to create a release anyway" -ForegroundColor Gray
            Write-Host ""
            Write-Host "💡 To make a meaningful release:" -ForegroundColor Cyan
            Write-Host "   1. Make code changes in source/ or tests/" -ForegroundColor Gray
            Write-Host "   2. Commit your changes" -ForegroundColor Gray
            Write-Host "   3. Run this script again" -ForegroundColor Gray
            return
        }
          if ($changes) {
            Write-Host "📝 Changes since ${latestTag}:" -ForegroundColor Green
            $changes | ForEach-Object { Write-Host "   • $_" -ForegroundColor Gray }
        }
    } else {
        Write-Host "🆕 No previous tags found - this will be the first release" -ForegroundColor Yellow
    }

    # Calculate next version
    $nextPatch = $patch + 1
    $nextVersion = "$major.$minor.$nextPatch"
    
    Write-Host ""
    Write-Host "📋 Release Plan:" -ForegroundColor Cyan
    Write-Host "   • Create tag: $tagName" -ForegroundColor White
    Write-Host "   • Bump version to: $nextVersion" -ForegroundColor White
    
    if ($DryRun) {
        Write-Host ""
        Write-Host "🔍 DRY RUN - No changes will be made" -ForegroundColor Yellow
        return
    }

    # Confirm release
    if (-not $Force) {
        Write-Host ""
        $confirm = Read-Host "Continue with release? (y/N)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "❌ Release cancelled" -ForegroundColor Red
            return
        }
    }

    Write-Host ""
    Write-Host "🚀 Creating release..." -ForegroundColor Cyan

    # Ensure working directory is clean
    $status = git status --porcelain
    if ($status) {
        throw "Working directory is not clean. Please commit or stash changes first."
    }

    # Create and push the release tag
    Write-Host "🏷️  Creating tag $tagName..." -ForegroundColor Green
    git tag -a $tagName -m "Release $currentVersion"
    
    Write-Host "📤 Pushing tag to trigger release build..." -ForegroundColor Green
    git push origin $tagName

    # Update version for next release
    Write-Host "⬆️  Bumping version to $nextVersion..." -ForegroundColor Green
    $projectXml.Project.PropertyGroup.VersionPrefix = $nextVersion
    $projectXml.Save((Resolve-Path $projectFile))

    # Commit version bump
    git add $projectFile
    git commit -m "Bump version to $nextVersion"
    git push origin main

    Write-Host ""
    Write-Host "✅ Release completed successfully!" -ForegroundColor Green
    Write-Host "   • Tagged: $tagName" -ForegroundColor Gray
    Write-Host "   • Next version: $nextVersion" -ForegroundColor Gray
    Write-Host "   • GitHub Actions will build and publish the release packages" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔗 Monitor the release: https://github.com/Electrified-Trading/Electrified.TimeSeries/actions" -ForegroundColor Cyan

} catch {
    Write-Host ""
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
