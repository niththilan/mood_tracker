# 🚨 URGENT: Google OAuth Port 50958 Fix

## ❌ New Error Details
```
Error 400: redirect_uri_mismatch
Request details: origin=http://localhost:50958
```

## 🔧 IMMEDIATE FIX: Use Fixed Port Instead

The issue is that Flutter is using **random ports** each time. We need to use a **fixed port**.

### 🎯 **STEP 1: Stop Current Flutter Process**
Press `Ctrl+C` in your terminal to stop the current Flutter process.

### 🎯 **STEP 2: Run on Fixed Port 3000**
```bash
flutter run -d chrome --web-port=3000
```

### 🎯 **STEP 3: Update Google Cloud Console** 

1. **Go to**: https://console.cloud.google.com/
2. **Navigate to**: APIs & Services → Credentials
3. **Find**: `631111437135-l2a14dgadurrj360mbom28saane8fngu.apps.googleusercontent.com`
4. **Click**: Edit (pencil icon)

### 📍 **STEP 4: Add These JavaScript Origins**
In "Authorized JavaScript origins" section:

```
http://localhost:3000
http://localhost:8080
http://localhost:50958
http://127.0.0.1:3000
http://127.0.0.1:8080
http://127.0.0.1:50958
```

### 🔄 **STEP 5: Add These Redirect URIs**
In "Authorized redirect URIs" section:

```
http://localhost:3000/auth/callback
http://localhost:8080/auth/callback
http://localhost:50958/auth/callback
http://127.0.0.1:3000/auth/callback
http://127.0.0.1:8080/auth/callback
http://127.0.0.1:50958/auth/callback
https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback
```

### 💾 **STEP 6: Save & Test**
1. Click **"Save"** in Google Cloud Console
2. Wait 2-3 minutes for changes to propagate
3. Test with: `flutter run -d chrome --web-port=3000`

## 🚀 **Recommended Ports for Development**

Always use **fixed ports** to avoid this issue:

```bash
# Option 1: Port 3000 (Recommended)
flutter run -d chrome --web-port=3000

# Option 2: Port 8080
flutter run -d chrome --web-port=8080

# Option 3: Port 8000
flutter run -d chrome --web-port=8000
```

## ⚡ **Quick Fix Script**

```bash
#!/bin/bash
echo "🔧 Stopping any running Flutter processes..."
pkill -f "flutter run"

echo "🚀 Starting Flutter on port 3000..."
flutter run -d chrome --web-port=3000
```

## 🎯 **Root Cause**
Flutter uses **random available ports** when `--web-port` is not specified. Each time you restart, it picks a new port, causing the redirect_uri_mismatch error.

## ✅ **Success Checklist**
- ✅ Added all necessary origins to Google Cloud Console
- ✅ Added all necessary redirect URIs to Google Cloud Console  
- ✅ Running Flutter on a **fixed port** (3000)
- ✅ Waited 2-3 minutes after updating Google Cloud Console
- ✅ Google Sign-In works without errors

## 🆘 **Still Having Issues?**

1. **Clear browser cache** and cookies
2. **Try incognito/private mode**
3. **Wait up to 10 minutes** for Google's changes to propagate
4. **Check Google Cloud Console** that you edited the correct OAuth client
5. **Verify Supabase configuration** matches the client ID

---

**🎯 Key Solution: Always use `--web-port=3000` to ensure consistent port!**
