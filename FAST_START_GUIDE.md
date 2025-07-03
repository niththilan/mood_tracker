# MoodFlow - Fast Development Setup 🚀

## Quick Start (Optimized for Speed)

### 🏃‍♂️ Super Fast Development
```bash
./quick_start.sh
```
This script:
- ✅ Automatically finds available port
- ✅ Runs in profile mode (fast + debugging)
- ✅ Optimized compilation flags
- ✅ Auto-reload enabled

### 🏗️ Production Build
```bash
./build_prod.sh
```
This script:
- ✅ Creates optimized production build
- ✅ Tree-shakes unused code
- ✅ Serves on local HTTP server
- ✅ Ready for deployment

## Performance Optimizations Applied

### 🎯 Startup Time Improvements
1. **Reduced Animation Durations**: Cut from 600-800ms to 100-200ms
2. **Deferred Heavy Operations**: Mood history loads after UI renders
3. **Profile Mode**: Faster than debug, with hot reload
4. **Microtask Scheduling**: UI renders immediately, data loads asynchronously

### 🔧 Development Speed
- **Hot Reload**: Instant updates during development
- **Automatic Port Detection**: No more port conflicts
- **Tree Shaking**: Smaller bundle sizes
- **Source Maps**: Better debugging in production

## Available URLs
- **Development**: `http://localhost:3001` (or next available port)
- **Production**: `http://localhost:4000` (or next available port)

## Troubleshooting

### Port Already in Use
The scripts automatically find available ports, but you can manually kill processes:
```bash
pkill -f "flutter run"
pkill -f "http.server"
```

### Slow Startup
1. Use `./quick_start.sh` instead of manual `flutter run`
2. Clear Flutter cache: `flutter clean && flutter pub get`
3. Use profile mode for development

### Build Issues
```bash
flutter doctor
flutter clean
flutter pub get
./build_prod.sh
```
