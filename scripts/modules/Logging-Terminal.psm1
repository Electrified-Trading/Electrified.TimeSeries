#
# Logging-Terminal PowerShell Module
# Provides colorized terminal logging for local development
#

# Enable UTF-8 output for GitHub Actions
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

#region Core Logging Functions

<#
.SYNOPSIS
    Writes an informational message with terminal colors.
.DESCRIPTION
    Outputs an informational message with cyan color and info icon.
.PARAMETER Message
    The message to write to the terminal.
.EXAMPLE
    Write-ActionInfo "Processing build output comparison..."
#>
function Write-Info {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    Write-Host "[info]" -ForegroundColor Cyan -NoNewline
    Write-Host " $Message"
}

<#
.SYNOPSIS
    Writes a success message with terminal colors.
.DESCRIPTION
    Outputs a success message with green color and checkmark icon.
.PARAMETER Message
    The success message to write to the terminal.
.EXAMPLE
    Write-Success "Build completed successfully"
#>
function Write-Success {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    Write-Host "[info]" -ForegroundColor Cyan -NoNewline
    Write-Host " " -NoNewline
    Write-Host "✅ $Message" -ForegroundColor Green
}

<#
.SYNOPSIS
    Writes a warning message with terminal colors.
.DESCRIPTION
    Outputs a warning message with yellow color and warning icon.
.PARAMETER Message
    The warning message to write to the terminal.
.EXAMPLE
    Write-Warning "No previous tags found - assuming first release"
#>
function Write-Warning {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "[warn]" -ForegroundColor Yellow -NoNewline
    Write-Host " " -NoNewline
    Write-Host $Message -ForegroundColor Yellow
}

<#
.SYNOPSIS
    Writes an error message with terminal colors.
.DESCRIPTION
    Outputs an error message with red color and error icon.
.PARAMETER Message
    The error message to write to the terminal.
.EXAMPLE
    Write-Error "Build failed with exit code 1"
#>
function Write-Error {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    Write-Host "[err!]" -ForegroundColor White -BackgroundColor DarkRed -NoNewline
    Write-Host "" -NoNewline
    Write-Host " " -NoNewline
    Write-Host $Message -ForegroundColor Red
}

<#
.SYNOPSIS
    Writes a result message with terminal colors and highlighting.
.DESCRIPTION
    Outputs a final result message with background highlighting and result indicator.
.PARAMETER Message
    The result message to write to the terminal.
.EXAMPLE
    Write-Result "PUBLISH_NEEDED (Changes Detected)"
#>
function Write-Result {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    Write-Host ""
    Write-Host "🎯 RESULT: $Message" -ForegroundColor White -BackgroundColor DarkBlue -NoNewline
    Write-Host ""
    Write-Host ""
}

<#
.SYNOPSIS
    Writes a debug message with terminal colors.
.DESCRIPTION
    Outputs a debug message with gray color and debug icon.
.PARAMETER Message
    The debug message to write to the terminal.
.EXAMPLE
    Write-Debug "Variable value: $someVariable"
#>
function Write-Debug {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "[debg]" -ForegroundColor Magenta -NoNewline
    Write-Host " $Message"
}

#endregion

#region Grouping and Organization

<#
.SYNOPSIS
    Creates a visual log group in the terminal.
.DESCRIPTION
    Executes a script block within a visually grouped section using terminal formatting.
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

    $lineLength = [Math]::Max($Title.Length + 3, 40)
    $line = "─" * $lineLength
    Write-Host ""
    Write-Host "📂 $Title" -ForegroundColor Gray
    Write-Host $line -ForegroundColor DarkGray
    
    try {
        & $ScriptBlock
    } finally {
        Write-Host $line -ForegroundColor DarkGray
        Write-Host ""
    }
}

#endregion

#region Output and Summary Functions

<#
.SYNOPSIS
    Simulates setting an output for local development.
.DESCRIPTION
    In terminal mode, this just displays what would be set as output.
.PARAMETER Name
    The name of the output variable.
.PARAMETER Value
    The value that would be set for the output variable.
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
    
    Write-Host "🔧 Output: $Name=$Value" -ForegroundColor Magenta
}

<#
.SYNOPSIS
    Displays summary content in the terminal.
.DESCRIPTION
    In terminal mode, this displays the summary content with formatting.
.PARAMETER Content
    The content to display as summary.
.EXAMPLE
    Add-ActionSummary "## Build Comparison Result`n`n**Status:** Changes detected"
#>
function Add-ActionSummary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host ""
    Write-Host "📋 SUMMARY: . . . . . . . . . . . . . . ." -ForegroundColor White -BackgroundColor DarkGreen -NoNewline
    Write-Host ""
    Write-Host $Content -ForegroundColor Gray
    Write-Host ""
}

#endregion

#region Version Information

<#
.SYNOPSIS
    Gets the version of the Logging-Terminal module.
.DESCRIPTION
    Returns the version information for this logging module.
.OUTPUTS
    Hashtable containing module version and information
.EXAMPLE
    Get-LoggingVersion
#>
function Get-LoggingVersion {
    return @{
        ModuleName = "Logging-Terminal"
        Version = "2.1.0"
        Build = "2025-06-02-002"
        Features = @("Colorized terminal output", "Emoji indicators", "Visual grouping")
        Description = "Production-ready terminal logging with clean Write-* interface"
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
