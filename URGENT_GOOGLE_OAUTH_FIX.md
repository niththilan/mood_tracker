# 🚨 URGENT: Google OAuth Redirect URI Mismatch Fix

## ❌ Current Error
```
Error 400: redirect_uri_mismatch
Request details: origin=http://localhost:50070
```

## 🔧 Immediate Fix Required

### 1. **Update Google Cloud Console** (MUST DO FIRST)

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Navigate to**: APIs & Services → Credentials  
3. **Find your OAuth 2.0 Client**: `631111437135-l2a14dgadurrj360mbom28saane8fngu.apps.googleusercontent.com`
4. **Click Edit** (pencil icon)

### 2. **Add JavaScript Origins** 
In the "Authorized JavaScript origins" section, add:

```
http://localhost:3000
http://localhost:8080
http://localhost:50070
http://127.0.0.1:3000
http://127.0.0.1:8080
http://127.0.0.1:50070
https://xxasezacvotitccxnpaa.supabase.co
```

### 3. **Add Redirect URIs**
In the "Authorized redirect URIs" section, add:

```
http://localhost:3000/auth/callback
http://localhost:8080/auth/callback
http://localhost:50070/auth/callback
http://127.0.0.1:3000/auth/callback
http://127.0.0.1:8080/auth/callback
http://127.0.0.1:50070/auth/callback
https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback
```

### 4. **Save Changes**
Click **"Save"** and wait 2-3 minutes for changes to propagate.

## 🧪 Test After Google Cloud Console Update

After updating Google Cloud Console, test with these commands:

### Option 1: Port 3000 (Recommended)
```bash
flutter run -d chrome --web-port=3000
```

### Option 2: Port 8080  
```bash
flutter run -d chrome --web-port=8080
```

### Option 3: Original Port 50070
```bash
flutter run -d chrome --web-port=50070
```

## 📱 Verify Supabase Configuration

1. Go to your **Supabase Dashboard**
2. Navigate to **Authentication** → **Providers** → **Google**
3. Verify these settings:
   - **Client ID**: `631111437135-l2a14dgadurrj360mbom28saane8fngu.apps.googleusercontent.com`
   - **Authorized redirect URLs** should include your localhost URLs

## ⚡ Quick Fix Script

Run this script for step-by-step guidance:
```bash
./fix_google_oauth.sh
```

## ✅ Success Indicators

After the fix, you should see:
- ✅ Google Sign-In popup appears
- ✅ No redirect_uri_mismatch error
- ✅ Successful authentication flow
- ✅ User logged into your app

## ⚠️ Important Notes

1. **Both JavaScript origins AND redirect URIs** must be added
2. **Exact port matching** is required (50070 in your case)
3. **Wait 2-3 minutes** after saving in Google Cloud Console
4. **Clear browser cache** if issues persist
5. **Use HTTPS in production** - localhost HTTP is only for development

## 🔍 Still Having Issues?

If problems persist after updating Google Cloud Console:

1. **Clear browser cache and cookies**
2. **Try incognito/private browsing mode**
3. **Check browser console for additional errors**
4. **Verify the correct OAuth client ID is being used**
5. **Wait longer for Google's changes to propagate (up to 10 minutes)**

---

**🎯 The core issue is that Google Cloud Console doesn't know about your localhost:50070 origin. Once you add it to the authorized origins and redirect URIs, the Google Sign-In will work perfectly!**
