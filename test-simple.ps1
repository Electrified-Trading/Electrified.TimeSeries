Write-Host "🧪 Simple Package Hash Test" -ForegroundColor Cyan

# Get the latest tag
$latestTag = git describe --tags --abbrev=0 2>$null
Write-Host "Latest tag: $latestTag" -ForegroundColor Green

# Clean and prepare
if (Test-Path "test-output") {
    Remove-Item "test-output" -Recurse -Force
}
New-Item -ItemType Directory -Path "test-output" -Force | Out-Null

# Build current version
Write-Host "Building current version..." -ForegroundColor Yellow
dotnet clean --verbosity quiet
dotnet restore --verbosity quiet
dotnet build source/Electrified.TimeSeries/Electrified.TimeSeries.csproj --configuration Debug --verbosity quiet

# Create package
$timestamp = Get-Date -Format 'yyyyMMddHHmm'
dotnet pack source/Electrified.TimeSeries/Electrified.TimeSeries.csproj `
    --configuration Debug `
    --no-build `
    --output test-output `
    --version-suffix "test-$timestamp" `
    --verbosity quiet

# Find package and show hash
$package = Get-ChildItem "test-output/*.nupkg" | Where-Object { $_.Name -notlike "*.symbols.*" } | Select-Object -First 1
if ($package) {
    $hash = Get-FileHash $package.FullName -Algorithm SHA256
    Write-Host "Package: $($package.Name)" -ForegroundColor Green
    Write-Host "Hash: $($hash.Hash)" -ForegroundColor Green
} else {
    Write-Host "No package found!" -ForegroundColor Red
}
