# Supabase Google OAuth Configuration for Web

## Important: Supabase Dashboard Configuration

To make Google Sign-In work on your deployed Netlify site, you need to configure your Supabase project:

### 1. **Google OAuth Provider Setup**

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project: `xxasezacvotitccxnpaa`
3. Navigate to **Authentication** > **Providers**
4. Find **Google** provider and click **Edit**

### 2. **Required Google OAuth Settings**

Configure these settings in Supabase:

```
✅ Enable Google Provider: ON

🔑 Client ID (Google): 631111437135-rmre7e09akna4ln09ha33vnvnmee9gu9.apps.googleusercontent.com

🗝️ Client Secret (Google): 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

🔄 Redirect URL: https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback
```

### 3. **Site URL Configuration**

In **Authentication** > **URL Configuration**:

```
🌐 Site URL: https://your-netlify-app.netlify.app

📝 Redirect URLs: 
- https://your-netlify-app.netlify.app/**
- https://your-netlify-app.netlify.app/auth/callback
- http://localhost:3000/** (for local testing)
```

### 4. **Google Cloud Console Configuration**

Make sure your Google Cloud Console is configured for web:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** > **Credentials**
3. Edit your OAuth 2.0 Client ID
4. Add these to **Authorized JavaScript origins**:
   ```
   https://your-netlify-app.netlify.app
   http://localhost:8080 (for local testing)
   ```
5. Add these to **Authorized redirect URIs**:
   ```
   https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback
   ```

### 5. **Testing Steps**

1. **Local Test:**
   ```bash
   flutter build web --release
   cd build/web
   python3 -m http.server 8080
   # Test at http://localhost:8080
   ```

2. **Production Test:**
   - Deploy to Netlify
   - Test Google Sign-In on your live site

### 6. **Common Issues**

**Issue:** "Origin not allowed"
**Fix:** Add your Netlify domain to Google Cloud Console authorized origins

**Issue:** "Redirect URI mismatch" 
**Fix:** Ensure Supabase callback URL is in Google Cloud Console redirect URIs

**Issue:** "Access blocked"
**Fix:** Check if your Google project is in testing mode and add test users

### 7. **Environment Variables for Netlify**

Set these in your Netlify site settings:

```
SUPABASE_URL=https://xxasezacvotitccxnpaa.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4YXNlemFjdm90aXRjY3hucGFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1ODE3MTIsImV4cCI6MjA2NDE1NzcxMn0.aUygIOPiI1HqFwKifXGYIolzeIQGbpjzGCC861LHRS4
```

## Updated Code Summary

The following files have been updated to fix Google Sign-In on web:

1. ✅ `lib/services/google_auth_service.dart` - Web-compatible implementation
2. ✅ `web/index.html` - Added Google Sign-In SDK
3. ✅ `netlify.toml` - Updated CSP headers for Google
4. ✅ `lib/main.dart` - Initialize Google Sign-In for web

Your Google Sign-In should now work on both mobile and web platforms!
