# 🔧 Fix: Supabase Sending Magic Links Instead of OTP

## 🚨 **Problem**
Your app is receiving magic links instead of 6-digit OTP codes for password reset.

## 🎯 **Root Cause**
Supabase is configured to send magic links by default. We need to configure it to send OTP codes and use the correct API methods.

## ✅ **Solution: 3-Step Fix**

### **Step 1: Update Supabase Dashboard Settings**

1. **Go to your Supabase Dashboard:**
   - Navigate to `https://app.supabase.com`
   - Select your project

2. **Configure Authentication Settings:**
   ```
   Authentication → Settings → Auth
   ```

3. **Update Email Templates:**
   - Go to `Authentication → Email Templates`
   - Select **"Reset Password"** template
   - **IMPORTANT:** Make sure it's configured to send OTP, not magic links

4. **Enable OTP in Auth Settings:**
   ```
   Authentication → Settings → Auth
   
   Under "Email Settings":
   ✅ Enable email confirmations
   ✅ Enable email change confirmations
   ✅ Enable password recovery
   
   Under "Security Settings":
   ✅ Enable phone confirmations (if using phone)
   ```

### **Step 2: Verify Email Template (Critical)**

In your Supabase dashboard:

```
Authentication → Email Templates → Reset Password
```

**Make sure your template contains OTP token, not magic link:**

```html
<!-- CORRECT: OTP-based template -->
<h2>Reset Your Password</h2>
<p>Enter this code in your app to reset your password:</p>
<h1 style="font-size: 32px; font-weight: bold;">{{ .Token }}</h1>
<p>This code expires in 60 minutes.</p>

<!-- WRONG: Magic link template -->
<!-- <a href="{{ .SiteURL }}/reset-password?access_token={{ .TokenHash }}">Reset Password</a> -->
```

### **Step 3: Code Implementation (Already Fixed)**

Your `auth_service.dart` has been updated with the correct method:

```dart
// ✅ CORRECT: Uses resetPasswordForEmail
Future<void> sendPasswordResetEmail(String email) async {
  try {
    await _supabase.auth.resetPasswordForEmail(email);
  } catch (error) {
    print('Error sending password reset email: $error');
    throw Exception('Failed to send password reset email. Please try again.');
  }
}

// ✅ CORRECT: Uses OtpType.recovery
Future<AuthResponse> verifyPasswordResetOtp({
  required String email,
  required String token,
}) async {
  try {
    final AuthResponse response = await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery, // Critical: Use recovery type
    );
    // ... rest of method
  }
}
```

## 🧪 **Testing the Fix**

1. **Build and run your app:**
   ```bash
   flutter build apk --debug
   flutter install
   ```

2. **Test password reset flow:**
   - Go to login → "Forgot Password?"
   - Enter your email address
   - Check email for **6-digit code** (not a link)
   - Enter code in app → set new password

## 🔍 **Alternative: Force OTP via API**

If the dashboard settings don't work, you can force OTP mode programmatically:

```dart
// Alternative approach if needed
Future<void> sendPasswordResetOTP(String email) async {
  try {
    // Force OTP generation using the recovery endpoint
    await _supabase.auth.api.resetPasswordForEmail(
      email, 
      redirectTo: null, // Explicitly no redirect
      captchaToken: null,
    );
  } catch (error) {
    throw Exception('Failed to send password reset OTP');
  }
}
```

## 📋 **Verification Checklist**

- ✅ Updated `auth_service.dart` with correct methods
- ⚠️ **TO DO:** Configure Supabase dashboard email templates
- ⚠️ **TO DO:** Verify email template uses `{{ .Token }}` not magic links
- ⚠️ **TO DO:** Test password reset flow

## 🚀 **Expected Result**

After implementing this fix:

1. **User enters email** → App calls `resetPasswordForEmail()`
2. **Supabase sends 6-digit OTP** → User receives code (not link)
3. **User enters OTP** → App verifies with `OtpType.recovery`
4. **Password reset successful** → User can login with new password

The key was using `OtpType.recovery` instead of `OtpType.email` and ensuring Supabase is configured to send OTP tokens instead of magic links!
