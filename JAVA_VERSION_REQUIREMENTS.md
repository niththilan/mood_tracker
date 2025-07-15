# Java Version Requirements for Mood Tracker

## Current Requirements
- **Java Version**: 21 (LTS)
- **Gradle Version**: 8.4 (auto-handled by Flutter)
- **Flutter Version**: Latest stable

## Java Installation Paths

### macOS (using Temurin/Eclipse Adoptium)
```bash
export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home
```

### Windows (using Temurin/Eclipse Adoptium)
```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-21.0.2.13-hotspot"
```

## Verification Commands
```bash
# Check Java version
java -version

# Check JAVA_HOME
echo $JAVA_HOME

# Check if Gradle works
cd android && ./gradlew --version
```

## Troubleshooting
1. **Build fails**: Ensure Java 21 is installed and JAVA_HOME is set correctly
2. **IDE errors**: Restart VS Code after changing Java version
3. **Gradle errors**: Run `./gradlew clean` in the android directory

## Notes
- Java 24+ is not yet supported by the current Gradle version
- Java 11, 17, and 21 are all compatible options
- The build scripts automatically set the correct Java version
