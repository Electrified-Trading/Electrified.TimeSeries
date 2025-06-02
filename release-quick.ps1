#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick release wrapper script.

.DESCRIPTION
    Simple wrapper around the main release script for common usage.

.EXAMPLE
    .\release-quick.ps1
    # Standard release (only if changes detected)

.EXAMPLE
    .\release-quick.ps1 -Force
    # Force release even without changes
#>

param(
    [switch]$Force
)

$scriptPath = Join-Path $PSScriptRoot "scripts\release.ps1"

if ($Force) {
    & $scriptPath -Force
} else {
    & $scriptPath
}
