# Google OAuth Configuration Fix

## Problem
You're getting the error: "Custom scheme URIs are not allowed for 'WEB' client type" when trying to sign in with Google on web.

## Root Cause
Your Google OAuth client in Google Cloud Console is either:
1. Misconfigured for web applications
2. Missing the correct authorized redirect URIs
3. Using the wrong client type

## Solution

### Step 1: Fix Google Cloud Console Configuration

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to "APIs & Services" > "Credentials"
3. Find your OAuth 2.0 Client ID for web application
4. Click on it to edit

### Step 2: Update Authorized Redirect URIs

Add these URIs to your **Web Application** OAuth client:

```
https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback
http://localhost:56565/auth/callback
http://localhost:3000/auth/callback
http://127.0.0.1:56565/auth/callback
```

### Step 3: Verify Client Type

Make sure you have:
- **Web Application** client for web/browser use
- **iOS** client for iOS apps  
- **Android** client for Android apps

### Step 4: Update Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to Authentication > Providers
3. Enable Google provider
4. Enter your **Web Application** client ID and secret
5. Save the configuration

### Current Client IDs in Use:
- Web: `631111437135-bvvu4b15elvmctbclkbmag856kke0nmq.apps.googleusercontent.com`
- Android: `631111437135-234lcguj55v09qd7415e7ohr2p55b58j.apps.googleusercontent.com`
- iOS: `631111437135-jg42a9hahfchrrfhva4mbb0bddaq5g5f.apps.googleusercontent.com`

### Testing
After making these changes:
1. Clear your browser cache and cookies
2. Restart the Flutter web app
3. Try Google Sign-In again

## Alternative Quick Fix
If you need an immediate solution, you can temporarily disable the web OAuth and use email/password authentication while fixing the Google configuration.
