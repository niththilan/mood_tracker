# Theme Management Feature

This document describes the new light/dark mode toggle functionality added to the MoodFlow app.

## Overview

The app now supports three theme modes:
- **System**: Follows the device's system settings (default)
- **Light**: Always uses light theme
- **Dark**: Always uses dark theme

## Features

### 1. Theme Service
- `lib/services/theme_service.dart`: Manages theme state and persistence
- Uses `SharedPreferences` to remember user's theme choice
- Provides `ChangeNotifier` functionality for reactive UI updates

### 2. Profile Page Integration
- Theme settings section added to the Profile page
- Visual theme selector with icons and descriptions
- Immediate theme switching with smooth animations

### 3. Quick Theme Toggle
- Theme toggle button in the main app bar (top-right area)
- Quick access modal for theme switching
- Shows current theme mode with appropriate icons

## How to Use

### For Users:
1. **Via Profile Page**: 
   - Tap the menu (⋮) in the top-right corner
   - Select "Profile"
   - Scroll down to "Theme Settings"
   - Choose your preferred theme mode

2. **Via Quick Toggle**:
   - Tap the theme icon in the app bar (shows current theme icon)
   - Select from the modal popup

### For Developers:

#### Using ThemeService:
```dart
// Get current theme mode
final themeService = Provider.of<ThemeService>(context);
final currentMode = themeService.themeMode;

// Change theme mode
await themeService.setThemeMode(ThemeMode.dark);

// Listen to theme changes
Consumer<ThemeService>(
  builder: (context, themeService, child) {
    return Text('Current theme: ${themeService.themeModeString}');
  },
)
```

#### Adding Theme Toggle Widget:
```dart
// Compact version (for app bars)
ThemeToggleWidget(isCompact: true)

// Full floating action button version
ThemeToggleWidget()
```

## Implementation Details

### Theme Persistence
- Theme choice is saved to `SharedPreferences` with key `'theme_mode'`
- Values: 0 = System, 1 = Light, 2 = Dark
- Automatically loads saved preference on app startup

### Provider Integration
- Uses `provider` package for state management
- `ChangeNotifierProvider` wraps the entire app in `main.dart`
- All widgets can access theme state reactively

### UI Components
- Theme options show appropriate icons (brightness, sun, moon)
- Selected theme is highlighted with primary color
- Smooth animations for theme transitions
- Follows Material Design 3 guidelines

## Files Modified/Added

### New Files:
- `lib/services/theme_service.dart` - Theme state management
- `lib/widgets/theme_toggle_widget.dart` - Quick theme toggle UI
- `THEME_FEATURE.md` - This documentation

### Modified Files:
- `lib/main.dart` - Provider integration and theme toggle in app bar
- `lib/profile_page.dart` - Theme settings section
- `pubspec.yaml` - Added `provider: ^6.1.2` dependency

## Testing

The theme switching works immediately and persists between app sessions. Test by:
1. Changing theme mode and observing immediate UI changes
2. Restarting the app to verify persistence
3. Testing all three modes (System, Light, Dark)
4. Verifying the icons update correctly

## Future Enhancements

Potential improvements could include:
- Custom theme colors/palettes
- Automatic dark mode based on time of day
- Theme scheduling
- Accent color customization
