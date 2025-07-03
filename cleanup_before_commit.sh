#!/bin/bash

# Cleanup script to run before commits to avoid large files
echo "🧹 Cleaning up large files before commit..."

# Flutter clean
echo "📱 Running flutter clean..."
flutter clean

# Remove build directories
echo "🔨 Removing build artifacts..."
find . -name "build" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name ".dart_tool" -type d -exec rm -rf {} + 2>/dev/null || true

# Remove large binary files
echo "🗑️  Removing large binary files..."
find . -name "*.dill" -type f -delete 2>/dev/null || true
find . -name "*.so" -type f -delete 2>/dev/null || true
find . -name "kernel_blob.bin" -type f -delete 2>/dev/null || true

# Remove iOS build artifacts
echo "🍎 Cleaning iOS artifacts..."
find ./ios -name "build" -type d -exec rm -rf {} + 2>/dev/null || true
find ./ios -name "DerivedData" -type d -exec rm -rf {} + 2>/dev/null || true

# Remove Android build artifacts
echo "🤖 Cleaning Android artifacts..."
find ./android -name "build" -type d -exec rm -rf {} + 2>/dev/null || true

# Clean up any temporary files
echo "🧽 Removing temporary files..."
find . -name ".DS_Store" -type f -delete 2>/dev/null || true
find . -name "*.tmp" -type f -delete 2>/dev/null || true
find . -name "*.temp" -type f -delete 2>/dev/null || true

echo "✅ Cleanup complete! Repository is ready for commit."

# Check for any remaining large files
echo "🔍 Checking for large files (>10MB)..."
large_files=$(find . -type f -size +10M -not -path "./.git/*" 2>/dev/null || true)
if [ -n "$large_files" ]; then
    echo "⚠️  Warning: Large files found:"
    echo "$large_files"
    echo "Consider adding these to .gitignore or use Git LFS"
else
    echo "✅ No large files detected!"
fi
