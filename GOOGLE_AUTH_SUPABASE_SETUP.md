# Google Authentication with Supabase - Setup Guide

## 🔧 Changes Made

### 1. Simplified Google Authentication Service
- **Removed**: Complex custom Google Identity Services implementation 
- **Added**: Proper Supabase OAuth integration for web
- **Improved**: Mobile authentication flow using Google Sign-In plugin + Supabase ID tokens

### 2. Key Changes in `google_auth_service.dart`:

#### Web Authentication (kIsWeb = true)
```dart
// Now uses Supabase's built-in OAuth
final response = await _supabase.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: SupabaseConfig.getRedirectUrl(),
  authScreenLaunchMode: LaunchMode.platformDefault,
);
```

#### Mobile Authentication (iOS/Android)
```dart
// Simplified flow: Google Sign-In → ID Token → Supabase
final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

final AuthResponse response = await _supabase.auth.signInWithIdToken(
  provider: OAuthProvider.google,
  idToken: googleAuth.idToken!,
  accessToken: googleAuth.accessToken,
);
```

### 3. Updated Supabase Configuration
- **Simplified**: Redirect URL handling 
- **Fixed**: Localhost development URLs
- **Improved**: Dynamic port detection for development

## 🚀 Required Supabase Dashboard Configuration

### 1. Enable Google OAuth Provider
1. Go to **Supabase Dashboard** → **Authentication** → **Providers**
2. Enable **Google** provider
3. Add your credentials:
   - **Client ID**: `631111437135-iuippmjn73ur1g4thacjmr5lq3k315t0.apps.googleusercontent.com`
   - **Client Secret**: `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`

### 2. Configure Redirect URLs
Add these URLs to your **Site URL** and **Redirect URLs**:

**For Development:**
- `http://localhost:3000`
- `http://localhost:8080` 
- `http://127.0.0.1:3000`
- `http://127.0.0.1:8080`

**For Production:**
- `https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback`
- Your production domain URL

**For Mobile:**
- `com.moodtracker.app://auth`

## 🌐 Google Cloud Console Configuration

### Required OAuth 2.0 Client IDs:
1. **Web Client**: `631111437135-iuippmjn73ur1g4thacjmr5lq3k315t0.apps.googleusercontent.com`
2. **Android Client**: `631111437135-76ojbi40r925em3sinj9igoel5f4do1i.apps.googleusercontent.com`  
3. **iOS Client**: `631111437135-5iajfi8mlc0olt9bla8tqhic6sior22j.apps.googleusercontent.com`

### Authorized Redirect URIs (Web Client):
```
https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback
http://localhost:3000
http://localhost:8080
http://127.0.0.1:3000
http://127.0.0.1:8080
```

### Authorized Origins:
```
http://localhost:3000
http://localhost:8080
http://127.0.0.1:3000
http://127.0.0.1:8080
https://xxasezacvotitccxnpaa.supabase.co
```

## 📱 Testing the Implementation

### Web Testing:
1. Run: `flutter run -d web-server --web-port 3000`
2. Open: `http://localhost:3000`
3. Click "Sign in with Google"
4. Should redirect to Google OAuth consent screen
5. After consent, redirects back to your app with authentication complete

### Mobile Testing:
1. Run: `flutter run -d <device>`
2. Ensure Google Play Services installed (Android)
3. Test Google Sign-In flow
4. Should open Google account picker → authenticate → return to app

## 🔍 Debugging Tips

### Web Issues:
- **Popup blocked**: Enable popups for localhost
- **Redirect loop**: Check Supabase redirect URLs match exactly
- **CORS errors**: Verify origins in Google Console

### Mobile Issues:
- **Android**: Check SHA-1 certificate is registered
- **iOS**: Verify iOS client ID in Info.plist
- **Both**: Ensure google-services.json/GoogleService-Info.plist are up to date

### Common Errors:
1. **"Invalid client"**: Client ID mismatch between code and Google Console
2. **"Unauthorized redirect_uri"**: URL not registered in Google Console  
3. **"Access blocked"**: App not verified in Google Console (for external users)

## ✅ Expected Behavior

### Web Flow:
1. User clicks "Sign in with Google"
2. Redirects to Google OAuth consent screen
3. User grants permissions  
4. Google redirects back to Supabase callback URL
5. Supabase processes authentication
6. User lands back in app, authenticated

### Mobile Flow:
1. User clicks "Sign in with Google"
2. Google Sign-In modal appears
3. User selects account and grants permissions
4. Google returns ID token to app
5. App sends ID token to Supabase for verification
6. User is authenticated and logged in

## 🛠️ Files Modified
- `lib/services/google_auth_service.dart` - Simplified and fixed
- `lib/services/supabase_config.dart` - Updated redirect URL handling
- Removed dependency on `simplified_google_auth.dart`

The authentication should now work reliably on both web and mobile platforms using Supabase's built-in OAuth capabilities! 🎉
