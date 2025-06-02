#
# Logging-GitHub PowerShell Module
# Provides GitHub Actions workflow command logging
#

# Enable UTF-8 output for GitHub Actions
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

#region Core Logging Functions

<#
.SYNOPSIS
    Writes an informational message using GitHub Actions notice format.
.DESCRIPTION
    Outputs a message using the ::notice:: workflow command for GitHub Actions.
.PARAMETER Message
    The message to write to the GitHub Actions log.
.EXAMPLE
    Write-Info "Processing build output comparison..."
#>
function Write-Info {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    Write-Host "::notice::$Message"
}

<#
.SYNOPSIS
    Writes a success message using GitHub Actions notice format.
.DESCRIPTION
    Outputs a success message using the ::notice:: workflow command with success indicator.
.PARAMETER Message
    The success message to write to the GitHub Actions log.
.EXAMPLE
    Write-Success "Build completed successfully"
#>
function Write-Success {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    Write-Host "::notice::✅ $Message"
}

<#
.SYNOPSIS
    Writes a warning message using GitHub Actions warning format.
.DESCRIPTION
    Outputs a warning message using the ::warning:: workflow command.
.PARAMETER Message
    The warning message to write to the GitHub Actions log.
.EXAMPLE
    Write-Warning "No previous tags found - assuming first release"
#>
function Write-Warning {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    Write-Host "::warning::$Message"
}

<#
.SYNOPSIS
    Writes an error message using GitHub Actions error format.
.DESCRIPTION
    Outputs an error message using the ::error:: workflow command.
.PARAMETER Message
    The error message to write to the GitHub Actions log.
.EXAMPLE
    Write-Error "Build failed with exit code 1"
#>
function Write-Error {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    Write-Host "::error::$Message"
}

<#
.SYNOPSIS
    Writes a result message using GitHub Actions notice format with result indicator.
.DESCRIPTION
    Outputs a final result message with a result indicator emoji.
.PARAMETER Message
    The result message to write to the GitHub Actions log.
.EXAMPLE
    Write-Result "PUBLISH_NEEDED (Changes Detected)"
#>
function Write-Result {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    Write-Host "::notice::🎯 RESULT: $Message"
}

<#
.SYNOPSIS
    Writes a debug message using GitHub Actions debug format.
.DESCRIPTION
    Outputs a debug message using the ::debug:: workflow command.
    Debug messages are only visible when ACTIONS_STEP_DEBUG is set to true.
.PARAMETER Message
    The debug message to write to the GitHub Actions log.
.EXAMPLE
    Write-Debug "Variable value: $someVariable"
#>
function Write-Debug {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    Write-Host "::debug::$Message"
}

#endregion

#region Grouping and Organization

<#
.SYNOPSIS
    Creates a collapsible log group in GitHub Actions.
.DESCRIPTION
    Executes a script block within a GitHub Actions log group using ::group:: and ::endgroup:: commands.
.PARAMETER Title
    The title for the log group.
.PARAMETER ScriptBlock
    The script block to execute within the group.
.EXAMPLE
    Write-Group "Build Operations" {
        Write-Info "Building current version..."
        # ... build commands ...
    }
#>
function Write-Group {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )
    
    Write-Host "::group::$Title"
    try {
        & $ScriptBlock
    } finally {
        Write-Host "::endgroup::"
    }
}

#endregion

#region Output and Summary Functions

<#
.SYNOPSIS
    Sets a GitHub Actions step output.
.DESCRIPTION
    Sets an output variable that can be used by subsequent steps in the workflow.
.PARAMETER Name
    The name of the output variable.
.PARAMETER Value
    The value to set for the output variable.
.EXAMPLE
    Set-ActionOutput "has_changes" "true"
#>
function Set-ActionOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Value
    )
      Write-Host "$Name=$Value" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
    Write-Info "Set output: $Name=$Value"
}

<#
.SYNOPSIS
    Adds content to the GitHub Actions step summary.
.DESCRIPTION
    Appends content to the step summary that will be displayed in the workflow run summary.
.PARAMETER Content
    The content to add to the step summary (supports Markdown).
.EXAMPLE
    Add-ActionSummary "## Build Comparison Result`n`n**Status:** Changes detected"
#>
function Add-ActionSummary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
      if ($env:GITHUB_STEP_SUMMARY) {
        $Content | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append
        Write-Debug "Added content to step summary"
    } else {
        Write-Debug "GITHUB_STEP_SUMMARY not available - skipping summary addition"
    }
}

#endregion

#region Version and Diagnostics

<#
.SYNOPSIS
    Gets the version and build information for the GitHub Actions logging module.
.DESCRIPTION
    Returns version information to help verify which version of the module is loaded.
.EXAMPLE
    Get-LoggingVersion
#>
function Get-LoggingVersion {
    return @{
        ModuleName = "Logging-GitHub"
        Version = "2.1.0"
        Build = "2025-06-02-002"
        Features = @("GitHub Actions workflow commands", "Step outputs", "Step summary")
        Description = "GitHub Actions logging with clean Write-* interface"
    }
}

#endregion

#region Module Initialization

# Export module members
Export-ModuleMember -Function @(
    'Write-Info',
    'Write-Success', 
    'Write-Warning',
    'Write-Error',
    'Write-Result',
    'Write-Group',
    'Write-Debug',
    'Set-ActionOutput',
    'Add-ActionSummary',
    'Get-LoggingVersion'
)

#endregion
