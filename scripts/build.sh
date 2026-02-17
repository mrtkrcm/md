#!/bin/bash
set -e

# Navigate to the package directory
cd mdviewer

# Build the project
echo "Building mdviewer..."
swift build -c release

# Run tests
echo "Running tests..."
swift test
