# Electrified.TimeSeries

A time series library for financial data processing and analysis.

## Features

- Strongly-typed time series data structures (`Bar<TData>`, `OHLC`, etc.)
- Chronological ordering enforcement with validation
- Async enumerable support for streaming data
- Extensible parsing and conversion utilities
- Built with modern C# 9+ features

## Installation

### From GitHub Packages

```bash
dotnet add package Electrified.TimeSeries --source https://nuget.pkg.github.com/Electrified-Trading/index.json
```

### From Source

```bash
git clone https://github.com/Electrified-Trading/Electrified.TimeSeries.git
cd Electrified.TimeSeries
dotnet build
```

## CI/CD Pipeline

This repository uses GitHub Actions for automated building and publishing:

- **Preview Packages**: Published on every push to any branch with version format `1.0.0-preview.YYYYMMDD.shaXXXXXXX`
- **Release Packages**: Published when tags are pushed (e.g., `v1.0.0` → `1.0.0`)
- **Package Registry**: GitHub Packages at `https://nuget.pkg.github.com/Electrified-Trading/index.json`

## Contributing

Please follow the coding guidelines in `.github/copilot-instructions.md` when contributing to this project.