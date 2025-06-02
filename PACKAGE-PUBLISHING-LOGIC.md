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

## Current Implementation Status

### ✅ Completed Components
- **Build Output Comparison Script** (`compare-build-output-v3.ps1`)
- **Deterministic Build Settings** (added to .csproj)
- **Zip-based Hash Comparison** (proven to work for detecting changes)
- **GitHub Actions Integration** (workflow updated)

### 🔧 Script Details
- **Location:** `scripts/compare-build-output-v3.ps1`
- **Inputs:** Project path, optional tag name, output directory
- **Outputs:** Exit code 0 (no changes) or 1 (changes detected)
- **Logging:** Detailed GitHub Actions compatible logging with emojis
- **Error Handling:** Fail-safe approach (publish on errors)

### 📊 Exit Codes
- **0:** No functional changes detected → Skip publishing
- **1:** Changes detected OR first release OR error → Publish package
- **2:** Fatal error (not in git repo, etc.)

This system provides intelligent, cost-effective package publishing while maintaining safety and clarity.
