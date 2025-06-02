#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test script to validate package hash comparison logic locally.

.DESCRIPTION
    This script builds NuGet packages and compares their hashes to determine if 
    meaningful changes have occurred since the last tag.

.PARAMETER DryRun
    Show what would happen without making any changes

.EXAMPLE
    .\scripts\test-package-hash.ps1
    
.EXAMPLE
    .\scripts\test-package-hash.ps1 -DryRun
#>

param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Import shared logging module
. (Join-Path $PSScriptRoot "Import-LoggingModule.ps1")

# Configuration
$ProjectPath = "source/Electrified.TimeSeries/Electrified.TimeSeries.csproj"
$TestOutputPath = "test-output"

function Get-ProjectVersion {
    $content = Get-Content $ProjectPath -Raw
    if ($content -match '<VersionPrefix>([^<]+)</VersionPrefix>') {
        return $matches[1]
    }
    throw "Could not find VersionPrefix in $ProjectPath"
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

function Build-CurrentPackage($Version, $OutputPath) {
    Write-Info "Building current package version $Version..."
    
    # Clean previous builds
    if (Test-Path $OutputPath) {
        Remove-Item $OutputPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
    
    # Build and pack
    dotnet build $ProjectPath --configuration Debug --verbosity quiet
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
    
    dotnet pack $ProjectPath `
        --configuration Debug `
        --no-build `
        --output $OutputPath `
        --verbosity quiet `
        --version-suffix "test-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Pack failed"
    }
      # Return the main package file (not symbols)
    $packageFiles = @(Get-ChildItem $OutputPath -Filter "*.nupkg" | Where-Object { -not $_.Name.Contains(".symbols.") })
    if ($packageFiles.Count -eq 0) {
        throw "No package file found in $OutputPath"
    }
    
    return $packageFiles[0].FullName
}

function Build-TaggedPackage($Tag, $OutputPath) {
    Write-Info "Building tagged package for comparison: $Tag..."
    
    $tempDir = Join-Path $env:TEMP "electrified-tag-build-$(Get-Random)"
    
    try {        # Create temp directory and clone the tag
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        Push-Location $tempDir
        
        Write-Info "Cloning tag $Tag to temporary directory..."
        git clone --depth 1 --branch $Tag --quiet "https://github.com/Electrified-Trading/Electrified.TimeSeries.git" . 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to clone tag $Tag"
        }
        
        # Build the tagged version
        dotnet restore --verbosity quiet
        dotnet build $ProjectPath --configuration Debug --verbosity quiet
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to build tagged version"
        }
        
        # Pack the tagged version
        dotnet pack $ProjectPath `
            --configuration Debug `
            --no-build `
            --output $OutputPath `
            --verbosity quiet `
            --version-suffix "tagged-$(Get-Date -Format 'yyyyMMddHHmmss')"
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to pack tagged version"
        }
          # Return the main package file (not symbols)
        $packageFiles = @(Get-ChildItem $OutputPath -Filter "*.nupkg" | Where-Object { -not $_.Name.Contains(".symbols.") })
        if ($packageFiles.Count -eq 0) {
            throw "No tagged package file found in $OutputPath"
        }
        
        return $packageFiles[0].FullName
        
    } finally {
        Pop-Location
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Compare-PackageHashes($CurrentPackage, $TaggedPackage) {
    Write-Info "Comparing package hashes..."
    
    $currentHash = Get-FileHash $CurrentPackage -Algorithm SHA256
    $taggedHash = Get-FileHash $TaggedPackage -Algorithm SHA256
    
    Write-Host "  Current:  $($currentHash.Hash)" -ForegroundColor Gray
    Write-Host "  Tagged:   $($taggedHash.Hash)" -ForegroundColor Gray
    
    return $currentHash.Hash -eq $taggedHash.Hash
}

# Main execution
try {
    Write-Info "Starting package hash comparison test..."
    
    # Ensure we're in a git repository
    if (-not (Test-Path ".git")) {
        throw "Not in a git repository root"
    }
    
    # Get current version and last tag
    $currentVersion = Get-ProjectVersion
    $lastTag = Get-LastTag
    
    Write-Info "Current version: $currentVersion"
    
    if (-not $lastTag) {
        Write-Warning "No previous tags found - this would be the first release"
        Write-Info "In a real scenario, this would trigger package creation"
        exit 0
    }
    
    Write-Info "Last tag: $lastTag"
    
    if ($DryRun) {
        Write-Info "DRY RUN - Would build and compare packages"
        Write-Info "Current working tree vs $lastTag"
        exit 0
    }
    
    # Create output directories
    $currentOutputPath = Join-Path $TestOutputPath "current"
    $taggedOutputPath = Join-Path $TestOutputPath "tagged"
    
    # Build both packages
    $currentPackage = Build-CurrentPackage $currentVersion $currentOutputPath
    $taggedPackage = Build-TaggedPackage $lastTag $taggedOutputPath
    
    Write-Success "Built packages:"
    Write-Host "  Current: $currentPackage" -ForegroundColor Gray
    Write-Host "  Tagged:  $taggedPackage" -ForegroundColor Gray
    
    # Compare hashes
    $identical = Compare-PackageHashes $currentPackage $taggedPackage
    
    if ($identical) {
        Write-Success "Package contents are identical!"
        Write-Info "✅ No package publication needed - no functional changes detected"
        Write-Info "This prevents duplicate packages for version bumps, docs, etc."
    } else {
        Write-Warning "Package contents differ!"
        Write-Info "📦 Package publication would be triggered - functional changes detected"
    }
    
    Write-Info ""
    Write-Info "Test packages created in: $TestOutputPath"
    Write-Info "You can inspect them to verify the comparison logic"
    
} catch {
    Write-Error "Test failed: $_"
    exit 1
}
