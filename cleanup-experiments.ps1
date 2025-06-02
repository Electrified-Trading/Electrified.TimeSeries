#!/usr/bin/env pwsh
# Cleanup script to remove experimental test files and directories
# This will clean up all the test artifacts created during development
# while preserving the working solution files

Write-Host "🧹 Cleaning up experimental files and directories..." -ForegroundColor Yellow

# Test directories to remove
$testDirectories = @(
    "test-output",
    "workflow-comparison", 
    "zip-test-output",
    "binary-comparison",
    "hash-test-output",
    "no-changes-test",
    "workflow-build-comparison"
)

# Test scripts to remove
$testScripts = @(
    "test-hash-investigation.ps1",
    "test-simple.ps1",
    "scripts\test-package-hash.ps1",
    "scripts\compare-clean-packages.ps1",
    "scripts\compare-clean-packages-v2.ps1",
    "scripts\compare-package-changes.ps1",
    "scripts\test-no-changes.ps1",
    "scripts\test-zip-hash.ps1",
    "scripts\compare-build-output-deterministic.ps1",
    "scripts\compare-build-output-v3.ps1"
)

# Remove test directories
foreach ($dir in $testDirectories) {
    if (Test-Path $dir) {
        Write-Host "  🗑️  Removing directory: $dir" -ForegroundColor Gray
        Remove-Item -Path $dir -Recurse -Force
    }
}

# Remove test scripts
foreach ($script in $testScripts) {
    if (Test-Path $script) {
        Write-Host "  🗑️  Removing script: $script" -ForegroundColor Gray
        Remove-Item -Path $script -Force
    }
}

Write-Host ""
Write-Host "✅ Cleanup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Preserved files:" -ForegroundColor Cyan
Write-Host "  • scripts\compare-build-output-v4.ps1 (working solution)" -ForegroundColor White
Write-Host "  • scripts\git-change-detection.ps1 (utility)" -ForegroundColor White
Write-Host "  • scripts\release.ps1 (existing workflow)" -ForegroundColor White
Write-Host "  • PACKAGE-PUBLISHING-LOGIC.md (documentation)" -ForegroundColor White
Write-Host "  • .github\workflows\publish.yml (main workflow)" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Ready for final implementation!" -ForegroundColor Green
