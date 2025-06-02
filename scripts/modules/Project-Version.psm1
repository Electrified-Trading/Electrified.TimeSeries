#
# Project-Version PowerShell Module  
# Provides shared project version operations
#
# NOTE: This module expects logging functions (Write-Info, Write-Warning, etc.) 
# to be available in the caller's scope. Import a logging module before using this.
#

Set-StrictMode -Version Latest

#region Version Reading and Parsing

<#
.SYNOPSIS
    Gets the current version from a .csproj file.
.DESCRIPTION
    Reads the VersionPrefix from the specified project file.
.PARAMETER ProjectPath
    Path to the .csproj file to read.
.OUTPUTS
    String containing the version (e.g., "1.0.1").
.EXAMPLE
    $version = Get-ProjectVersion "source/Project/Project.csproj"
#>
function Get-ProjectVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )
    
    if (-not (Test-Path $ProjectPath)) {
        throw "Project file not found: $ProjectPath"
    }
    
    $content = Get-Content $ProjectPath -Raw
    if ($content -match '<VersionPrefix>([^<]+)</VersionPrefix>') {
        return $matches[1]
    }
    
    throw "Could not find VersionPrefix in $ProjectPath"
}

<#
.SYNOPSIS
    Parses a version string into component parts.
.DESCRIPTION
    Splits a semantic version string into major, minor, and patch components.
.PARAMETER Version
    The version string to parse (e.g., "1.2.3").
.OUTPUTS
    Hashtable with Major, Minor, Patch properties.
.EXAMPLE
    $parts = Get-VersionParts "1.2.3"
    # Returns @{ Major = 1; Minor = 2; Patch = 3 }
#>
function Get-VersionParts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )
    
    if ($Version -notmatch '^(\d+)\.(\d+)\.(\d+)$') {
        throw "Invalid version format: $Version (expected x.y.z)"
    }
    
    return @{
        Major = [int]$matches[1]
        Minor = [int]$matches[2] 
        Patch = [int]$matches[3]
    }
}

<#
.SYNOPSIS
    Creates a version string from component parts.
.DESCRIPTION
    Combines major, minor, and patch numbers into a version string.
.PARAMETER Major
    Major version number.
.PARAMETER Minor
    Minor version number.
.PARAMETER Patch
    Patch version number.
.OUTPUTS
    String in format "major.minor.patch".
.EXAMPLE
    $version = New-VersionString 1 2 3  # Returns "1.2.3"
#>
function New-VersionString {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Major,
        
        [Parameter(Mandatory = $true)]
        [int]$Minor,
        
        [Parameter(Mandatory = $true)]
        [int]$Patch
    )
    
    return "$Major.$Minor.$Patch"
}

<#
.SYNOPSIS
    Increments the patch version by 1.
.DESCRIPTION
    Takes a version string and returns it with the patch number incremented.
.PARAMETER Version
    The current version string.
.OUTPUTS
    String with incremented patch version.
.EXAMPLE
    $nextVersion = Step-PatchVersion "1.2.3"  # Returns "1.2.4"
#>
function Step-PatchVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )
    
    $parts = Get-VersionParts $Version
    return New-VersionString $parts.Major $parts.Minor ($parts.Patch + 1)
}

#endregion

#region Version File Operations

<#
.SYNOPSIS
    Updates the version in a .csproj file.
.DESCRIPTION
    Updates the VersionPrefix element in the specified project file.
.PARAMETER ProjectPath
    Path to the .csproj file to update.
.PARAMETER NewVersion
    The new version string to set.
.EXAMPLE
    Set-ProjectVersion "source/Project/Project.csproj" "1.2.4"
#>
function Set-ProjectVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        
        [Parameter(Mandatory = $true)]
        [string]$NewVersion
    )
    
    if (-not (Test-Path $ProjectPath)) {
        throw "Project file not found: $ProjectPath"
    }
    
    # Validate new version format
    $null = Get-VersionParts $NewVersion
    
    Write-Info "Updating project version from $(Get-ProjectVersion $ProjectPath) to $NewVersion"
    
    # Load and update XML
    $projectXml = [xml](Get-Content $ProjectPath)
    $versionPrefixNode = $projectXml.Project.PropertyGroup.VersionPrefix
    
    if (-not $versionPrefixNode) {
        throw "VersionPrefix not found in $ProjectPath"
    }
    
    $versionPrefixNode = $NewVersion
    $projectXml.Save((Resolve-Path $ProjectPath))
    
    Write-Success "Project version updated to $NewVersion"
}

<#
.SYNOPSIS
    Creates a tag name from a version string.
.DESCRIPTION
    Converts a version string to a standardized tag name format.
.PARAMETER Version
    The version string to convert.
.OUTPUTS
    String in format "v{version}" (e.g., "v1.2.3").
.EXAMPLE
    $tagName = Get-TagName "1.2.3"  # Returns "v1.2.3"
#>
function Get-TagName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )
    
    # Validate version format
    $null = Get-VersionParts $Version
    
    return "v$Version"
}

<#
.SYNOPSIS
    Validates that a project file exists and contains version information.
.DESCRIPTION
    Checks project file existence and validates it contains VersionPrefix.
.PARAMETER ProjectPath
    Path to the .csproj file to validate.
.EXAMPLE
    Assert-ProjectFile "source/Project/Project.csproj"
#>
function Assert-ProjectFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )
    
    if (-not (Test-Path $ProjectPath)) {
        throw "Project file not found: $ProjectPath"
    }
    
    # Try to read version to validate structure
    try {
        $null = Get-ProjectVersion $ProjectPath
        Write-Debug "Project file validated: $ProjectPath"
    } catch {
        throw "Invalid project file structure: $_"
    }
}

#endregion

#region Version and Module Info

<#
.SYNOPSIS
    Gets the version and build information for the Project Version module.
.DESCRIPTION
    Returns version information to help verify which version of the module is loaded.
.EXAMPLE
    Get-ProjectVersionModuleVersion
#>
function Get-ProjectVersionModuleVersion {
    return @{
        ModuleName = "Project-Version"
        Version = "1.0.0"
        Build = "2025-06-02-001"
        Features = @("Version parsing", "Project file operations", "Version incrementation", "Tag name generation")
        Description = "Shared project version operations with integrated logging"
    }
}

#endregion

#region Module Initialization

# Export module members
Export-ModuleMember -Function @(
    'Get-ProjectVersion',
    'Get-VersionParts',
    'New-VersionString',
    'Step-PatchVersion',
    'Set-ProjectVersion',
    'Get-TagName',
    'Assert-ProjectFile',
    'Get-ProjectVersionModuleVersion'
)

#endregion
