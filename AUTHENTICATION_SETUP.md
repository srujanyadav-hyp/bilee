# BILEE Authentication System - Setup Guide

## ✅ Completed Implementation

### Authentication Screens Created
1. **Login Screen** (`login_screen.dart`)
   - Email/Phone tab toggle
   - Google Sign-In button with gradient outline
   - Role badge display
   - Form validation
   - Loading states

2. **Registration Screen** (`register_screen.dart`)
   - Email/Phone tabs
   - Role-specific fields:
     * Merchant: business name, category dropdown (8 options), email, password
     * Customer: username, email, password
   - Phone registration with country code selector
   - Password visibility toggles
   - Form validation (email regex, 8+ chars password, password match, 10-digit phone)

3. **OTP Verification Screen** (`otp_screen.dart`)
   - 6-digit code input fields
   - 60-second countdown timer
   - Resend OTP button (max 3 attempts)
   - Auto-verification support (Android)
   - Change number action
   - Error handling

4. **Forgot Password Screen** (`forgot_password_screen.dart`)
   - Email input with validation
   - Send reset link button
   - Success confirmation view with instructions
   - Back to login action

5. **Dashboard Screens** (Placeholders)
   - Merchant Dashboard (`merchant_dashboard.dart`)
   - Customer Dashboard (`customer_dashboard.dart`)
   - Sign out functionality

### Backend Services Created
1. **AuthService** (`auth_service.dart`)
   - `signInWithEmail()` - email/password sign in
   - `registerWithEmail()` - email/password registration
   - `sendOTP()` - phone OTP send with callbacks
   - `verifyOTP()` - phone OTP verification
   - `signInWithGoogle()` - Google OAuth flow
   - `sendPasswordResetEmail()` - password reset
   - `signOut()` - sign out from all providers
   - `getUserData()` - fetch user from Firestore
   - Comprehensive error handling with user-friendly messages

2. **Data Models**
   - `UserModel` (`user_model.dart`) - Firestore user document
   - `AuthResult` & `RegistrationData` (`auth_models.dart`) - DTOs

### Routes Updated
- `/auth/login` → NewLoginScreen
- `/auth/register` → RegisterScreen
- `/auth/otp` → OTPScreen
- `/auth/forgot-password` → ForgotPasswordScreen
- `/merchant/dashboard` → MerchantDashboardScreen
- `/customer/dashboard` → CustomerDashboardScreen

### Firebase Initialization
- Added `Firebase.initializeApp()` in `main.dart`
- Error handling for initialization failures

---

## 🔴 REQUIRED: Firebase Setup Steps

### Step 1: Install Flutter Dependencies
```powershell
cd C:\Users\SRUJAN\Desktop\realworld\bilee
flutter pub get
```

### Step 2: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Name: "BILEE" (or your preferred name)
4. Enable Google Analytics (optional)
5. Create project

### Step 3: Configure Firebase Authentication
1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable the following providers:
   - ✅ **Email/Password** - Enable
   - ✅ **Phone** - Enable (requires test phone numbers for development)
   - ✅ **Google** - Enable (requires OAuth consent screen setup)

### Step 4: Create Firestore Database
1. In Firebase Console, go to **Firestore Database**
2. Click **Create database**
3. Start in **Test mode** (for development)
   - Allows read/write access for 30 days
   - ⚠️ Remember to add security rules before production
4. Choose location: `asia-south1` (Mumbai) or nearest to your users

### Step 5: Add Android App to Firebase
1. In Firebase Console, go to **Project Settings** (gear icon)
2. Click **Add app** → **Android**
3. **Android package name**: Get it from `android/app/build.gradle.kts`
   - Look for `applicationId` (usually `com.example.bilee` or similar)
4. **App nickname**: "BILEE Android" (optional)
5. Click **Register app**
6. **Download `google-services.json`**
7. Place file in: `android/app/google-services.json`

### Step 6: Add iOS App to Firebase (if building for iOS)
1. In Firebase Console, go to **Project Settings**
2. Click **Add app** → **iOS**
3. **iOS bundle ID**: Get it from `ios/Runner.xcodeproj/project.pbxproj`
   - Look for `PRODUCT_BUNDLE_IDENTIFIER`
4. Click **Register app**
5. **Download `GoogleService-Info.plist`**
6. Place file in: `ios/Runner/GoogleService-Info.plist`

### Step 7: Configure Google Sign-In (Android)
1. Get SHA-1 certificate fingerprint:
```powershell
cd android
.\gradlew signingReport
```
2. Copy the SHA-1 fingerprint from debug keystore
3. In Firebase Console → **Project Settings** → **Android app**
4. Add SHA-1 fingerprint
5. Download updated `google-services.json` if needed

### Step 8: Configure Google Sign-In (iOS)
1. Open `ios/Runner/Info.plist`
2. Add the following before `</dict>`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```
3. Replace `YOUR_REVERSED_CLIENT_ID` with value from `GoogleService-Info.plist`
   - Look for `REVERSED_CLIENT_ID` key

---

## 🧪 Testing Guide

### Test Email/Password Authentication
1. Run the app: `flutter run`
2. Navigate to Login screen
3. Click "Don't have an account? Sign up"
4. Select role (Merchant/Customer) in previous screens
5. Fill registration form:
   - Email: `test@example.com`
   - Password: `password123` (8+ chars)
   - Confirm password: `password123`
6. Click "Sign Up"
7. Should navigate to dashboard after successful registration

### Test Phone Authentication
1. In Firebase Console → Authentication → Sign-in method → Phone
2. Add test phone number: `+91 1234567890` with code `123456`
3. In app, go to Registration → Phone tab
4. Enter test phone number
5. Click "Send OTP"
6. Enter test code `123456`
7. Should verify and navigate to dashboard

### Test Google Sign-In
1. Ensure Google Sign-In is enabled in Firebase Console
2. In app, click "Continue with Google" button
3. Select Google account
4. Should sign in and navigate to dashboard

### Test Forgot Password
1. Go to Login screen
2. Click "Forgot Password?"
3. Enter registered email
4. Check email for password reset link
5. Click link and reset password

---

## 🔒 Security Considerations

### Firestore Security Rules (Update before production)
Replace test mode rules with:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User documents
    match /users/{userId} {
      // Users can read their own data
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Only authenticated users can create their own document
      allow create: if request.auth != null && request.auth.uid == userId;
      
      // Users can update their own data (except role)
      allow update: if request.auth != null 
        && request.auth.uid == userId
        && request.resource.data.role == resource.data.role;
      
      // No deletes
      allow delete: if false;
    }
  }
}
```

### Environment Variables (For Production)
- Never commit Firebase config files to public repositories
- Use environment variables for API keys
- Enable App Check for production

---

## 📱 Running the App

### Run on Android
```powershell
flutter run -d android
```

### Run on iOS
```powershell
flutter run -d ios
```

### Build Release APK (Android)
```powershell
flutter build apk --release
```

### Build Release App Bundle (Android)
```powershell
flutter build appbundle --release
```

---

## 🐛 Troubleshooting

### Error: "Firebase not initialized"
- **Solution**: Ensure `Firebase.initializeApp()` is called in `main.dart` before `runApp()`
- Check that `google-services.json` exists in `android/app/`

### Error: "PlatformException: sign_in_failed"
- **Solution**: Add SHA-1 fingerprint to Firebase Console
- Rebuild app after adding SHA-1

### Error: "No Firebase App '[DEFAULT]' has been created"
- **Solution**: Run `flutter clean` then `flutter pub get`
- Delete `build/` folder and rebuild

### Phone Auth not working
- **Solution**: Enable Phone authentication in Firebase Console
- For testing, add test phone numbers in Firebase Console
- Ensure you have internet connection

### Google Sign-In not working
- **Solution**: 
  - Check SHA-1 is added to Firebase Console
  - Download latest `google-services.json`
  - Enable Google Sign-In in Firebase Console
  - Run `flutter clean` and rebuild

---

## 📋 Next Steps

1. **Run `flutter pub get`** to install dependencies
2. **Setup Firebase project** following Step 2-8 above
3. **Test authentication flows** on emulator/device
4. **Implement dashboard features** (replace placeholder screens)
5. **Add Firestore security rules** before production
6. **Add analytics tracking** for user behavior
7. **Implement KYC flow** for merchants
8. **Add unit tests** for authentication logic
9. **Add integration tests** for complete auth flow

---

## 📝 Notes

- All screens use AppColors, AppTypography, and AppDimensions for consistency
- AuthService includes comprehensive error handling with user-friendly messages
- OTP screen supports auto-verification on Android
- Registration screen handles role-specific fields dynamically
- Forgot password screen includes success confirmation with instructions
- Dashboard screens are placeholders - implement actual features as needed

---

**Created**: December 2024
**Last Updated**: December 2024
