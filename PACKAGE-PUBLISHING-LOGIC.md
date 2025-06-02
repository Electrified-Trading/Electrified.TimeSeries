# GitHub Actions Package Publishing Logic Script

## Overview
This document describes the expected behavior of our GitHub Actions workflow for intelligent NuGet package publishing based on functional change detection.

## The Decision Matrix

### Condition 1: **Tag Push** (e.g., `v1.2.0`)
**When:** A git tag matching `v*` is pushed to the repository

**Expected Behavior:**
- ✅ **Always build and publish** the package
- 🏷️ Use the tag version (e.g., `1.2.0` from `v1.2.0`) 
- 📦 Create both Release and Debug configurations
- 🚀 Publish to GitHub Packages immediately
- ⏭️ **Skip change detection** entirely (tags represent intentional releases)

**Rationale:** Tags are explicit release markers, so we always want to publish them regardless of changes.

---

### Condition 2: **Branch Push** (main, develop, feature/*, hotfix/*)
**When:** Code is pushed to any branch (but not a tag)

**Expected Behavior:** Run intelligent change detection

#### Sub-condition 2A: **No Previous Tags Exist**
- ✅ **Build and publish** preview package
- 📝 Log: "First release detected - no previous tags found"
- 📦 Create preview package with version suffix (e.g., `1.0.0-main-202506011530`)

#### Sub-condition 2B: **Functional Changes Detected**
**How we detect:** Compare build output zip hashes between current code and previous successful publish

**Expected Result:**
- ✅ **Build and publish** preview package
- 📝 Log: "🔄 Functional changes detected between current code and previous publish"
- 📝 Log: "📦 CI/CD will create and publish new package version"
- 📊 Show hash comparison details
- 📦 Create preview package with version suffix

#### Sub-condition 2C: **No Functional Changes Detected**
**How we detect:** Build output zip hashes are identical to previous successful publish

**Expected Result:**
- ⏭️ **Skip building and publishing** entirely
- 📝 Log: "✅ No functional changes detected between current code and previous publish"
- 📝 Log: "🚀 CI/CD will skip package publishing to avoid duplicate versions"
- 💾 **Still run tests** (always validate code)
- 🎯 **Result:** `SKIP_PUBLISH (No Changes)`

---

### Condition 3: **Pull Request**
**When:** A pull request is opened/updated

**Expected Behavior:**
- ✅ **Always build and test** (validate the code)
- ⏭️ **Never publish** packages (even if changes detected)
- 📝 Log: "Pull request detected - building and testing only"

---

## Technical Implementation Details

### Change Detection Algorithm
```
1. Get reference point for comparison (latest successful publish OR latest git tag as fallback)
2. Build current code → create zip of bin/Debug output
3. Checkout reference point → build that code → create zip of bin/Debug output  
4. Compare SHA256 hashes of the two zip files
5. If hashes match → No Changes → Skip Publishing
6. If hashes differ → Changes Detected → Publish Package
```

### Error Handling (Fail-Safe)
**When:** Script encounters any error during comparison

**Expected Behavior:**
- ⚠️ Log the error details
- 📝 Log: "🛡️ Failing safe: assuming changes exist to prevent missed releases"
- ✅ **Default to publishing** (never risk missing a real change)
- 🎯 **Result:** `PUBLISH_NEEDED (Safety Fallback)`

---

## Example Scenarios

### Scenario 1: Non-Package Documentation Update
```
Action: Push to main with only workflow/script documentation changes
Detection: Build outputs identical → No functional changes
Result: Skip publishing (saves CI resources, prevents noise)
Note: README.md changes would actually trigger publish if embedded in package
```

### Scenario 2: Bug Fix
```
Action: Push to main with C# code changes
Detection: Build outputs differ → Functional changes detected  
Result: Publish new preview package
```

### Scenario 3: Version Bump Only
```
Action: Push to main changing only version in .csproj
Detection: Build outputs identical → No functional changes
Result: Skip publishing (version bump without code changes)
```

### Scenario 4: New Release
```
Action: Push tag v1.2.0
Detection: Skipped (tags always publish)
Result: Publish official release packages (Release + Debug configs)
```

---

## Benefits of This Approach

1. **🎯 Accurate Change Detection** - Only publishes when functional code actually changes
2. **💰 Cost Efficiency** - Saves CI/CD resources by skipping unnecessary builds
3. **📦 Clean Package History** - Prevents duplicate/noise packages in the feed
4. **🛡️ Safety First** - Always publishes on errors or uncertainty
5. **🏷️ Respects Release Process** - Tags always publish (explicit releases)
6. **🔍 Clear Visibility** - Detailed logging shows exactly why decisions were made

This creates an intelligent publishing system that balances automation efficiency with release safety.

## Current Implementation Status ✅ **PRODUCTION READY**

### ✅ Completed Components
- **Build Output Comparison Script** (`compare-build-output.ps1`) - **FULLY IMPLEMENTED**
- **Deterministic Build Settings** (added to .csproj) - **FULLY IMPLEMENTED**  
- **File-by-File Hash Comparison** (proven reliable for change detection) - **FULLY IMPLEMENTED**
- **GitHub Actions Integration** (workflow updated) - **FULLY IMPLEMENTED**
- **Worktree-Based Isolation** (no working directory interference) - **FULLY IMPLEMENTED**
- **Dual Mode Operation** (Local + CI modes) - **FULLY IMPLEMENTED**

### 🔧 Script Details
- **Location:** `scripts/compare-build-output.ps1`
- **Modes:** Local (development/testing) and CI (GitHub Actions)
- **Inputs:** Project path, optional tag name, output directory, execution mode
- **Outputs:** Exit code 0 (no changes) or 1 (changes detected)
- **Logging:** Mode-aware output (colored local vs GitHub Actions structured)
- **Error Handling:** Fail-safe approach with detailed debugging options

### 📊 Exit Codes & Results
- **0:** No functional changes detected → Skip publishing → `SKIP_PUBLISH (No Changes)`
- **1:** Changes detected OR first release → Publish package → `PUBLISH_NEEDED (Changes Detected)`
- **2:** Configuration error (not in git repo, etc.) → `Configuration Error`

### 🎯 Key Features Proven Working
- ✅ **"No Changes" Detection:** Successfully identifies identical builds and skips publishing
- ✅ **"Changes Detected" Flow:** Correctly detects when .dll files change and triggers publishing
- ✅ **Worktree Isolation:** Builds tagged versions without affecting working directory
- ✅ **Normalized File Comparison:** Uses filename-only keys for consistent hash comparison
- ✅ **GitHub Actions Integration:** Provides structured output for CI consumption
- ✅ **Local Development Support:** Rich colored output and debug mode for troubleshooting

---

## Testing & Validation

### ✅ Verified Scenarios

**Local Development Testing:**
```powershell
# Test with debug output and current changes
.\scripts\compare-build-output.ps1 -Debug

# Test CI mode locally  
.\scripts\compare-build-output.ps1 -Mode CI -Debug

# Test without git operations (for controlled testing)
.\scripts\compare-build-output.ps1 -SkipGitOperations -Debug
```

**Proven Test Cases:**
- ✅ **No Changes Scenario:** Comparing against `test-current-state` tag shows identical hashes → Exit 0
- ✅ **Changes Detected Scenario:** Current code vs tagged code shows different hashes → Exit 1
- ✅ **Worktree Isolation:** Tagged builds don't interfere with working directory
- ✅ **Error Recovery:** Script handles missing tags, build failures, and cleanup issues gracefully
- ✅ **GitHub Actions Output:** Structured logging works correctly in CI mode

### 🚀 Production Deployment

The system is ready for production use with the following components in place:

1. **Enhanced Script:** `scripts/compare-build-output.ps1` with modular design
2. **Updated Workflow:** `.github/workflows/publish.yml` with CI mode integration  
3. **Project Configuration:** Deterministic build settings in `.csproj`
4. **Documentation:** Complete specification and usage examples
5. **Error Handling:** Fail-safe approach with detailed logging

**Next Steps for Production:**
- Deploy to main branch and monitor first few CI runs
- Observe GitHub Actions logs for proper structured output
- Verify package publication skips and approvals work as expected
