# Workflow Guide

## Overview

This repository uses a **simple, modular** GitHub Actions approach that follows the decision matrix in [`PACKAGE-PUBLISHING-LOGIC.md`](../../PACKAGE-PUBLISHING-LOGIC.md).

## Design Principles

1. **Keep It Simple** - No over-engineering or unnecessary abstraction
2. **Modular Without Complexity** - Reusable workflows for common tasks
3. **Clear Naming** - Descriptive but not overly verbose names
4. **Smart Publishing** - Only publish when there are actual changes

## Workflow Architecture

### Core Workflows

#### 1. `publish.yml` (Main Orchestrator)
- **Triggers**: Push to any branch, tags, PRs
- **Purpose**: Orchestrates the entire CI/CD pipeline
- **Logic**: Follows the decision matrix for when to publish packages

#### 2. `build-test.yml` (Reusable)
- **Purpose**: Build and test the .NET project
- **Inputs**: Configuration (Debug/Release), whether to run tests
- **Outputs**: Build success, test results
- **Used by**: Main publish workflow and any other workflows needing build/test

#### 3. `change-detection.yml` (Reusable)
- **Purpose**: Detect if functional changes exist using PowerShell scripts
- **Logic**: Compares current build output against previous successful build
- **Outputs**: Whether changes exist, comparison details
- **Used by**: Main publish workflow to decide whether to publish

## Publishing Decision Matrix

Based on [`PACKAGE-PUBLISHING-LOGIC.md`](../../PACKAGE-PUBLISHING-LOGIC.md):

| Trigger | Scenario | Action |
|---------|----------|--------|
| **Tag Push** | Any tag (e.g., `v1.2.3`) | Always publish Release + Debug packages |
| **Branch Push** | With detected changes | Publish Debug preview package |
| **Branch Push** | No changes detected | Skip publishing, show summary |
| **Pull Request** | Any PR | Build + test only, no publishing |

## Package Versioning Strategy

### Tag Releases
- **Release Package**: Uses tag version (e.g., `v1.2.3` → `1.2.3`)
- **Debug Package**: Same version with `-debug` suffix (e.g., `1.2.3-debug`)

### Branch Previews
- **Preview Package**: Base version + branch + timestamp suffix
- **Example**: `1.0.1-feature-auth-20250602-1430`

## File Structure

```
.github/workflows/
├── WORKFLOW-GUIDE.md           # This guide
├── publish.yml                 # Main orchestrator workflow
├── build-test.yml             # Reusable build and test
└── change-detection.yml       # Reusable change detection
```

## Workflow Inputs/Outputs

### `build-test.yml` (Reusable)
**Inputs:**
- `configuration`: Build configuration (Debug/Release)
- `run-tests`: Whether to run tests (default: true)
- `dotnet-version`: .NET version (default: '9.0.x')

**Outputs:**
- `build-successful`: Whether build succeeded
- `test-successful`: Whether tests passed

### `change-detection.yml` (Reusable)
**Inputs:**
- `project-path`: Path to .csproj file
- `comparison-script`: PowerShell script for comparison
- `dotnet-version`: .NET version (default: '9.0.x')

**Outputs:**
- `has-changes`: Whether functional changes detected
- `comparison-details`: Human-readable comparison result
- `previous-reference`: Git reference used for comparison

## Key Features

### Smart Change Detection
- Uses PowerShell scripts in `/scripts/` folder
- Compares build output content manifests
- Prevents duplicate preview packages
- Works with git history and tags

### Intelligent Publishing
- **Tags**: Always publish (stable releases)
- **Branches**: Only publish if changes detected
- **PRs**: Never publish (validation only)

### Artifact Management
- Upload packages as GitHub artifacts
- 30-day retention for investigation
- Both .nupkg and .snupkg (symbols) packages

### Summary Reporting
- Clear GitHub Step Summary for each run
- Shows publishing decisions and reasoning
- Displays package versions and strategies

## Local Testing

Before pushing workflows, test locally:

```powershell
# Test build
dotnet restore
dotnet build --configuration Release

# Test change detection
.\scripts\compare-build-output.ps1 -ProjectPath "source\Electrified.TimeSeries\Electrified.TimeSeries.csproj"

# Test package creation
dotnet pack --configuration Release --output test-output
```

## Troubleshooting

### Common Issues

1. **Change detection fails**: Check PowerShell script permissions
2. **Package publish fails**: Verify `GITHUB_TOKEN` has package write permissions
3. **Version conflicts**: Ensure tag versions match project version prefix

### Debug Steps

1. Check workflow run logs in GitHub Actions tab
2. Download artifacts to inspect package contents
3. Review Step Summary for publishing decisions
4. Test PowerShell scripts locally with same inputs

## Maintenance

### Adding New Workflows
1. Follow the modular pattern
2. Use reusable workflows where possible
3. Update this guide with new workflows
4. Test thoroughly before merging

### Modifying Existing Workflows
1. Ensure backward compatibility
2. Test with various trigger scenarios
3. Update documentation if behavior changes
4. Verify publishing logic still follows decision matrix

---

## Philosophy

This workflow system prioritizes **simplicity** and **reliability** over features. Every workflow serves a clear purpose and follows predictable patterns. The modular design allows reuse without over-engineering.

The goal is to have workflows that "just work" and are easy to understand, debug, and maintain.
