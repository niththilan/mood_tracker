# APK Build Guide

This guide ensures reliable APK builds for the Mood Tracker app and prevents common build issues.

## 🚀 Quick Start

### Option 1: Using the Build Script (Recommended)
```bash
# Make script executable (first time only)
chmod +x build_apk.sh

# Run the build script
./build_apk.sh
```

### Option 2: Using VS Code Task
1. Open Command Palette (`Cmd+Shift+P` on Mac, `Ctrl+Shift+P` on Windows)
2. Type "Tasks: Run Task"
3. Select "Build APK (Release)"

### Option 3: Manual Build
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release --split-per-abi
```

## 📁 Output Locations

After a successful build, APK files will be available in:

### Primary Location
```
./android/app/build/outputs/flutter-apk/
├── app-release.apk (Universal APK - recommended)
├── app-arm64-v8a-release.apk (64-bit ARM)
├── app-armeabi-v7a-release.apk (32-bit ARM)
└── app-x86_64-release.apk (64-bit Intel)
```

### Convenient Copy Location
```
./build/apk/
└── (All APK files copied here for easy access)
```

## 🛠️ Troubleshooting

### Issue: "Flutter couldn't find APK file"
**Solution**: This is usually a false error. Check the output directories listed above.

### Issue: "Gradle build failed"
**Solutions**:
1. Run `flutter clean` and try again
2. Check Android SDK installation
3. Verify `ANDROID_HOME` environment variable is set
4. Make sure you have enough disk space (>5GB recommended)

### Issue: "Out of memory during build"
**Solution**: The `gradle.properties` file has been configured with sufficient memory allocation.

### Issue: "Build takes too long"
**Solution**: The build scripts include optimizations like parallel processing and caching.

## 📋 Build Configuration

### Gradle Properties
The following settings in `android/gradle.properties` prevent common issues:
- Increased JVM heap size for large projects
- Enabled parallel processing
- Configured proper caching
- Set Flutter SDK versions

### Android Build Configuration
The `android/app/build.gradle.kts` file includes:
- APK output path configuration
- Proper variant handling
- Minification settings

## 🎯 Best Practices

1. **Always use the build script** - It handles edge cases and provides better error reporting
2. **Check both output directories** - APK files might be in either location
3. **Use `app-release.apk` for distribution** - This is the universal APK that works on all devices
4. **Test on different devices** - Use architecture-specific APKs for testing performance

## 📱 Installation

### For Testing
1. Enable "Unknown Sources" in Android Settings → Security
2. Transfer APK to device
3. Open APK file to install

### For Distribution
- Use `app-release.apk` for direct distribution
- Upload to Google Play Store using the same file

## 🔧 Advanced Options

### Build Debug APK
```bash
flutter build apk --debug
```

### Build with Obfuscation
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### Build App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

## 📞 Support

If you encounter issues not covered here:
1. Check the Flutter documentation
2. Run `flutter doctor` to diagnose environment issues
3. Look for error messages in the build output
4. Check the GitHub issues for similar problems

## 🔄 Automated Builds

For CI/CD, use the build script:
```yaml
# Example GitHub Actions step
- name: Build APK
  run: |
    chmod +x build_apk.sh
    ./build_apk.sh
```

## 📝 Notes

- The build process typically takes 2-5 minutes
- APK size is usually around 20-30MB
- The script creates a `build/apk` directory for convenience
- All APK variants are built simultaneously for flexibility
