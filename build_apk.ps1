# Mood Tracker APK Build Script for Windows
# PowerShell version of the build script

Write-Host "🚀 Starting Mood Tracker APK Build Process..." -ForegroundColor Blue

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if we're in the correct directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Error "pubspec.yaml not found! Please run this script from the project root directory."
    exit 1
}

# Step 1: Clean previous builds
Write-Status "Cleaning previous builds..."
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter clean failed!"
    exit 1
}

# Step 2: Get dependencies
Write-Status "Getting Flutter dependencies..."
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter pub get failed!"
    exit 1
}

# Step 3: Build APK
Write-Status "Building APK (this may take a few minutes)..."
flutter build apk --release --split-per-abi --verbose

# Check if the main build command was successful
if ($LASTEXITCODE -eq 0) {
    Write-Success "APK build completed successfully!"
} else {
    Write-Warning "Build command returned non-zero exit code, but checking for APK files..."
}

# Step 4: Verify APK files exist
Write-Status "Verifying APK files..."

$APK_DIR = ".\android\app\build\outputs\flutter-apk"
$FALLBACK_APK_DIR = ".\android\app\build\outputs\apk\release"

if (Test-Path $APK_DIR) {
    $APK_FILES = Get-ChildItem -Path $APK_DIR -Name "*.apk"
    if ($APK_FILES) {
        Write-Success "APK files found in $APK_DIR:"
        foreach ($apk in $APK_FILES) {
            $size = (Get-Item (Join-Path $APK_DIR $apk)).Length
            $sizeKB = [Math]::Round($size / 1024 / 1024, 2)
            Write-Host "  📱 $apk ($sizeKB MB)"
        }
    }
} elseif (Test-Path $FALLBACK_APK_DIR) {
    $APK_FILES = Get-ChildItem -Path $FALLBACK_APK_DIR -Name "*.apk"
    if ($APK_FILES) {
        Write-Success "APK files found in $FALLBACK_APK_DIR:"
        foreach ($apk in $APK_FILES) {
            $size = (Get-Item (Join-Path $FALLBACK_APK_DIR $apk)).Length
            $sizeKB = [Math]::Round($size / 1024 / 1024, 2)
            Write-Host "  📱 $apk ($sizeKB MB)"
        }
    }
} else {
    Write-Error "No APK output directory found!"
    exit 1
}

# Step 5: Copy APK to convenient location
Write-Status "Copying APK files to project root for easy access..."
if (-not (Test-Path ".\build\apk")) {
    New-Item -ItemType Directory -Path ".\build\apk" -Force
}

# Copy all APK files to build/apk directory
if (Test-Path $APK_DIR) {
    Copy-Item "$APK_DIR\*.apk" ".\build\apk\" -ErrorAction SilentlyContinue
}

if (Test-Path $FALLBACK_APK_DIR) {
    Copy-Item "$FALLBACK_APK_DIR\*.apk" ".\build\apk\" -ErrorAction SilentlyContinue
}

# Show final results
if (Test-Path ".\build\apk\*.apk") {
    Write-Success "APK files copied to .\build\apk\"
    Write-Success "Build completed successfully! 🎉"
    Write-Host ""
    Write-Host "📦 Available APK files:"
    Get-ChildItem -Path ".\build\apk\*.apk" | ForEach-Object {
        $sizeKB = [Math]::Round($_.Length / 1024 / 1024, 2)
        Write-Host "  $($_.Name) ($sizeKB MB)"
    }
    Write-Host ""
    Write-Host "💡 Recommended APK for distribution: app-release.apk"
} else {
    Write-Error "No APK files could be copied!"
    exit 1
}

# Step 6: Show install instructions
Write-Host ""
Write-Status "To install the APK on your device:"
Write-Host "  1. Enable 'Unknown Sources' in your Android device settings"
Write-Host "  2. Transfer the APK file to your device"
Write-Host "  3. Open the APK file on your device to install"
Write-Host ""
Write-Status "For Google Play Store upload, use: app-release.apk"
