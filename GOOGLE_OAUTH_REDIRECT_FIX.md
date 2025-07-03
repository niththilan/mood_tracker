# Google OAuth Redirect URI Fix

## Problem
Error 400: redirect_uri_mismatch when trying to sign in with Google from localhost.

## Root Cause
The localhost origin `http://localhost:50070` is not registered in the Google Cloud Console OAuth 2.0 configuration.

## Solution Steps

### 1. Update Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: `mood-tracker-project` (or your actual project name)
3. Navigate to **APIs & Services** → **Credentials**
4. Find your OAuth 2.0 Client ID for Web: `631111437135-l2a14dgadurrj360mbom28saane8fngu.apps.googleusercontent.com`
5. Click **Edit** (pencil icon)

### 2. Add Authorized JavaScript Origins

Add these origins to the **Authorized JavaScript origins** section:

```
http://localhost:50070
http://localhost:3000
http://localhost:8080
http://127.0.0.1:50070
http://127.0.0.1:3000
http://127.0.0.1:8080
https://your-production-domain.com
```

### 3. Add Authorized Redirect URIs

Add these URIs to the **Authorized redirect URIs** section:

```
http://localhost:50070/auth/callback
http://localhost:3000/auth/callback
http://localhost:8080/auth/callback
http://127.0.0.1:50070/auth/callback
http://127.0.0.1:3000/auth/callback
http://127.0.0.1:8080/auth/callback
https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback
https://your-production-domain.com/auth/callback
```

### 4. Save Changes

Click **Save** in the Google Cloud Console.

### 5. Test with Specific Port

Run your Flutter web app on a specific port that you've registered:

```bash
flutter run -d chrome --web-port=50070
```

Or use port 3000:

```bash
flutter run -d chrome --web-port=3000
```

### 6. Update Supabase Configuration

1. Go to your Supabase dashboard
2. Navigate to **Authentication** → **Providers** → **Google**
3. Ensure your **Client ID** matches: `631111437135-l2a14dgadurrj360mbom28saane8fngu.apps.googleusercontent.com`
4. Add all the redirect URIs in the **Authorized redirect URLs** section

## Common Development Ports to Add

For comprehensive development support, add these JavaScript origins:

- `http://localhost:3000`
- `http://localhost:8080` 
- `http://localhost:8081`
- `http://localhost:50070`
- `http://127.0.0.1:3000`
- `http://127.0.0.1:8080`
- `http://127.0.0.1:8081`
- `http://127.0.0.1:50070`

## Production Setup

For production, add:
- Your actual domain: `https://yourdomain.com`
- Supabase callback: `https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback`

## Quick Test Command

After updating Google Cloud Console, test with:

```bash
# Clear Flutter cache
flutter clean

# Run on specific port
flutter run -d chrome --web-port=3000

# Or try the original port
flutter run -d chrome --web-port=50070
```

## Notes

- Changes in Google Cloud Console may take a few minutes to propagate
- Make sure you're editing the correct OAuth client ID
- Both JavaScript origins AND redirect URIs need to be configured
- The port number in the error (50070) must exactly match what you add to Google Cloud Console
