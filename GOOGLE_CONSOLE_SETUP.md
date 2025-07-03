# Google Cloud Console Setup - URGENT FIX

## Current Issue
Your Flutter app is getting `redirect_uri_mismatch` errors because the Google Cloud Console OAuth client isn't configured with the correct localhost ports.

## IMMEDIATE ACTION REQUIRED

### Step 1: Update Google Cloud Console
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to APIs & Services → Credentials
3. Find your OAuth 2.0 client ID for web application
4. Click "Edit" (pencil icon)

### Step 2: Add Authorized JavaScript Origins
Add these URLs to "Authorized JavaScript origins":
```
http://localhost:3000
http://localhost:8080
http://localhost:50958
http://localhost:5000
http://localhost:8000
http://127.0.0.1:3000
http://127.0.0.1:8080
```

### Step 3: Add Authorized Redirect URIs
Add these URLs to "Authorized redirect URIs":
```
http://localhost:3000/auth/callback
http://localhost:8080/auth/callback
http://localhost:50958/auth/callback
http://localhost:5000/auth/callback
http://localhost:8000/auth/callback
http://127.0.0.1:3000/auth/callback
http://127.0.0.1:8080/auth/callback
```

### Step 4: Save Changes
- Click "Save" in Google Cloud Console
- Wait 5-10 minutes for changes to propagate

### Step 5: Test Again
Your app is now running on http://localhost:3000 (fixed port)
- Open the app in your browser
- Try Google Sign-In
- It should work without redirect_uri_mismatch errors

## Important Notes
- Always run Flutter web with a fixed port: `flutter run -d chrome --web-port=3000`
- If you use a different port, make sure it's added to Google Cloud Console
- Clear browser cache/cookies if you still have issues
- Try incognito mode for testing

## Your Current Configuration
- Web Client ID: 123456789-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com
- App is running on: http://localhost:3000
- Redirect URI needed: http://localhost:3000/auth/callback

## If Still Not Working
1. Check browser console for errors
2. Verify you're using the correct client ID
3. Make sure Supabase dashboard has the correct redirect URL
4. Wait a few more minutes for Google changes to propagate
