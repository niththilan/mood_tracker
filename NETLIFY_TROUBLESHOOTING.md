# Netlify Deployment Troubleshooting Guide

## Common Issues and Solutions

### 1. 404 Error - Page Not Found

**Symptoms:** You get a 404 error when visiting your Netlify site
**Causes:** 
- Build failed
- Wrong publish directory
- Missing redirects configuration

**Solutions:**

#### Check Build Logs
1. Go to your Netlify dashboard
2. Click on your site
3. Go to "Deploys" tab
4. Click on the latest deploy
5. Check the build logs for errors

#### Verify Build Settings
Make sure your site settings have:
- **Build command:** `flutter clean && flutter pub get && flutter build web --release`
- **Publish directory:** `build/web`
- **Base directory:** (leave empty)

#### Check Flutter Version
In your Netlify environment variables, you might want to set:
- `FLUTTER_VERSION`: `3.32.4` (or your Flutter version)

### 2. Build Failing

**Common Flutter web build issues:**

#### Missing Dependencies
```bash
flutter pub get
```

#### Web Support Not Enabled
```bash
flutter config --enable-web
flutter create --platforms web .
```

#### Dependency Conflicts
Some packages might not support web. Check your `pubspec.yaml` for web compatibility.

### 3. Environment Variables

Add these in Netlify dashboard under Site Settings > Environment Variables:

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GOOGLE_CLIENT_ID=your_google_web_client_id
```

### 4. Testing Build Locally

Before deploying, test your build locally:

```bash
# Clean and build
flutter clean
flutter pub get
flutter build web --release

# Test locally
cd build/web
python3 -m http.server 8080
# Visit http://localhost:8080
```

### 5. Debugging Steps

1. **Check if Flutter web build works locally**
2. **Verify netlify.toml configuration**
3. **Check Netlify build logs**
4. **Verify environment variables**
5. **Test with a simple Flutter web app first**

### 6. Alternative Deployment Methods

If you continue having issues, try these alternatives:

#### Manual Deployment
1. Build locally: `flutter build web --release`
2. Go to Netlify dashboard
3. Drag and drop the `build/web` folder to deploy

#### Different Build Commands
Try these build commands in your netlify.toml:

```toml
# Option 1: Simple build
command = "flutter build web --release"

# Option 2: With clean
command = "flutter clean && flutter pub get && flutter build web --release"

# Option 3: With verbose output
command = "flutter clean && flutter pub get && flutter build web --release --verbose"
```

### 7. Contact Support

If all else fails:
1. Check Netlify community forums
2. Share your build logs
3. Verify your Flutter version supports web builds
4. Consider using GitHub Actions for building and Netlify for hosting

## Current Configuration Status

✅ Your Flutter app builds successfully locally
✅ Web files are generated in `build/web`
✅ Index.html exists and looks correct
✅ netlify.toml is configured properly

The issue is likely in the Netlify build environment or configuration.
