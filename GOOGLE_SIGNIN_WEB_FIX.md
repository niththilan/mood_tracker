# Google Sign-In Web Configuration Fix

## Changes Made to Fix Web Google Sign-In

### 1. **Updated GoogleAuthService for Web Compatibility**

**File:** `lib/services/google_auth_service.dart`

**Key Changes:**
- Replaced `dart:io` Platform with `flutter/foundation.dart` kIsWeb
- Added web-specific Google Sign-In flow
- Configured GoogleSignIn with proper web client ID
- Added fallback to Supabase OAuth for web
- Enhanced error handling and logging

**Before:**
```dart
import 'dart:io';
// Platform.isIOS, Platform.isAndroid (doesn't work on web)
```

**After:**
```dart
import 'package:flutter/foundation.dart' show kIsWeb;
// kIsWeb (works on all platforms)
```

### 2. **Updated Web Index.html**

**File:** `web/index.html`

**Added:**
```html
<!-- Google Sign-In SDK for Web -->
<script src="https://accounts.google.com/gsi/client" async defer></script>
<meta name="google-signin-client_id" content="631111437135-rmre7e09akna4ln09ha33vnvnmee9gu9.apps.googleusercontent.com">
```

### 3. **Updated Netlify Configuration**

**File:** `netlify.toml`

**Added CSP headers for Google:**
```toml
Content-Security-Policy = "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://accounts.google.com https://apis.google.com; style-src 'self' 'unsafe-inline' https://accounts.google.com; img-src 'self' data: https:; font-src 'self' https://fonts.gstatic.com; connect-src 'self' https://*.supabase.co wss://*.supabase.co https://accounts.google.com https://oauth2.googleapis.com https://www.googleapis.com; frame-src https://accounts.google.com;"
```

### 4. **Initialized Google Sign-In in Main**

**File:** `lib/main.dart`

**Added:**
```dart
// Initialize Google Sign-In for web
await GoogleAuthService.initializeForWeb();
```

## How the Web Flow Works Now

1. **Web Detection**: Uses `kIsWeb` instead of Platform checks
2. **Google Sign-In Web Flow**: 
   - Uses GoogleSignIn package with web client ID
   - Falls back to Supabase OAuth if GoogleSignIn fails
3. **ID Token Exchange**: Exchanges Google ID token with Supabase
4. **Session Management**: Proper sign-out handling for web

## Testing on Web

### Local Testing:
```bash
flutter build web --release
cd build/web
python3 -m http.server 8080
# Visit http://localhost:8080
```

### Production Testing:
Deploy to Netlify and test Google Sign-In

## Common Web Issues and Solutions

### Issue 1: "Unauthorized JavaScript origin"
**Solution:** Add your domain to Google Cloud Console:
- Go to Google Cloud Console > APIs & Credentials
- Edit OAuth 2.0 Client ID
- Add `https://your-netlify-domain.netlify.app` to Authorized JavaScript origins

### Issue 2: "Invalid request origin"
**Solution:** Ensure your Netlify domain is added to Supabase:
- Go to Supabase Dashboard > Authentication > URL Configuration
- Add your Netlify domain to Site URL and Redirect URLs

### Issue 3: CSP Errors
**Solution:** The CSP headers in netlify.toml now include Google domains

### Issue 4: CORS Errors
**Solution:** Supabase should handle CORS automatically, but ensure your domain is in the allowed origins

## Debugging Web Google Sign-In

1. **Check Browser Console**: Look for detailed error messages
2. **Network Tab**: Check if Google API calls are being made
3. **Application Tab**: Check if Google Sign-In library is loaded
4. **Supabase Logs**: Check authentication logs in Supabase dashboard

## Production Checklist

- [ ] Google Cloud Console has your Netlify domain in authorized origins
- [ ] Supabase has your Netlify domain in URL configuration  
- [ ] netlify.toml includes Google domains in CSP
- [ ] Build includes the updated GoogleAuthService
- [ ] Environment variables are set in Netlify dashboard

## What Should Work Now

✅ **Web Google Sign-In Flow**
✅ **Fallback to Supabase OAuth**
✅ **Proper session management**
✅ **Cross-platform compatibility**
✅ **Enhanced error handling**
✅ **CSP compliance**

Your Google Sign-In should now work properly on the web version deployed to Netlify!
