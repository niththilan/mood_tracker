# Google Sign-In Setup Guide

## Overview
This guide covers the complete setup of Google Sign-In with Supabase authentication for your Flutter app.

## Configuration Summary
Your app is now configured with the following Google OAuth credentials:

- **Android Client ID**: `631111437135-tcgtegjv0lhkeu2b9etg5gebil1869km.apps.googleusercontent.com`
- **iOS Client ID**: `631111437135-7qpnbn8g86r44rj8s2nhai7jth30gm10.apps.googleusercontent.com`
- **Web Client ID**: `631111437135-rmre7e09akna4ln09ha33vnvnmee9gu9.apps.googleusercontent.com`
- **Web Client Secret**: `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`
- **Supabase Callback URL**: `https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback`

## Supabase Dashboard Configuration

### 1. Authentication Settings
In your Supabase dashboard (https://xxasezacvotitccxnpaa.supabase.co):

1. Go to **Authentication** → **Providers**
2. Find **Google** and click **Enable**
3. Configure the following settings:
   - **Client ID**: `631111437135-rmre7e09akna4ln09ha33vnvnmee9gu9.apps.googleusercontent.com`
   - **Client Secret**: `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`
   - **Redirect URL**: `https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback`

### 2. Site URL Configuration
1. Go to **Authentication** → **URL Configuration**
2. Add the following to **Redirect URLs**:
   - `https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback`
   - For development: `http://localhost:3000/auth/callback` (if testing web)
   - For mobile: `com.example.mood_tracker://auth/callback`

## Google Cloud Console Configuration

### 1. OAuth Consent Screen
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** → **OAuth consent screen**
3. Configure:
   - App name: "Mood Tracker"
   - User support email: Your email
   - Authorized domains: `supabase.co`
   - Developer contact: Your email

### 2. OAuth 2.0 Client IDs
Ensure your OAuth 2.0 client IDs are configured with the following redirect URIs:

**Web Application**:
- `https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback`

**Android Application**:
- Package name: `com.example.mood_tracker`
- SHA-1 certificate fingerprint: (Add your debug/release SHA-1)

**iOS Application**:
- Bundle ID: `com.example.moodTracker` (check your iOS project settings)

## Testing the Setup

### 1. Install Dependencies
Run the following command to ensure all dependencies are installed:
```bash
flutter pub get
```

### 2. Platform-specific Setup

**Android**:
- Ensure `google-services.json` is in `android/app/`
- Your SHA-1 certificate fingerprint is added to Google Console
- To get SHA-1 for debug:
  ```bash
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
  ```

**iOS**:
- Ensure URL scheme is configured in `Info.plist`
- Bundle identifier matches Google Console configuration

### 3. Test Authentication Flow

The authentication flow will:
1. Open Google Sign-In
2. User selects Google account
3. Google redirects to Supabase
4. Supabase creates/updates user session
5. App receives authenticated user

## Troubleshooting

### Common Issues

1. **"Error 400: invalid_request"**
   - Check client IDs match exactly
   - Verify redirect URLs in Google Console

2. **"Error 400: redirect_uri_mismatch"**
   - Add all redirect URIs to Google Console
   - Check Supabase callback URL configuration

3. **Android: "Developer Error"**
   - Verify `google-services.json` is correct
   - Check SHA-1 certificate fingerprint
   - Ensure package name matches

4. **iOS: Sign-in doesn't work**
   - Verify URL scheme in `Info.plist`
   - Check bundle identifier
   - Ensure iOS client ID is correct

### Debug Steps

1. Check Supabase logs in dashboard
2. Check Flutter console output
3. Verify Google Console configuration
4. Test on different devices/simulators

## Additional Notes

- The app uses different flows for mobile (Google Sign-In package) and web (Supabase OAuth)
- All sensitive credentials are properly configured
- Error handling includes user-friendly messages
- The setup supports both development and production environments

## Security Considerations

- Client secrets should never be exposed in client-side code
- Use environment variables for production deployments
- Regularly rotate OAuth credentials
- Monitor authentication logs in Supabase dashboard
