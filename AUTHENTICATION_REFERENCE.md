# BILEE Authentication - Quick Reference

## 📁 Files Created

### Authentication Screens
```
lib/features/authentication/view/
├── login_screen.dart            (570 lines) - Login with Email/Phone/Google
├── register_screen.dart         (690 lines) - Registration with role fields
├── otp_screen.dart              (420 lines) - OTP verification
└── forgot_password_screen.dart  (340 lines) - Password reset
```

### Dashboard Screens
```
lib/features/merchant/dashboard/view/
└── merchant_dashboard.dart      (110 lines) - Merchant dashboard placeholder

lib/features/customer/dashboard/view/
└── customer_dashboard.dart      (110 lines) - Customer dashboard placeholder
```

### Backend Services
```
lib/core/services/
└── auth_service.dart            (347 lines) - Firebase Authentication service

lib/core/models/
├── user_model.dart              (55 lines)  - Firestore user model
└── auth_models.dart             (45 lines)  - Auth DTOs
```

---

## 🔄 Authentication Flows

### Email/Password Sign In Flow
```
1. User opens app → Splash Screen → Role Selection → Onboarding
2. Click "Sign in" → LoginScreen (Email tab)
3. Enter email + password → Click "Sign In"
4. AuthService.signInWithEmail()
5. On success → Navigate to /merchant/dashboard or /customer/dashboard
```

### Email/Password Registration Flow
```
1. LoginScreen → Click "Don't have an account? Sign up"
2. RegisterScreen (Email tab)
3. Fill form:
   - Merchant: business name, category, email, password, confirm
   - Customer: username, email, password, confirm
4. Click "Sign Up" → AuthService.registerWithEmail()
5. Create Firestore user document in /users/{uid}
6. On success → Navigate to dashboard
```

### Phone Number Registration Flow
```
1. RegisterScreen → Phone tab
2. Fill form:
   - Select country code (+91, +1, +44)
   - Enter phone number (10 digits)
   - Merchant: business name, category
   - Customer: username
3. Click "Send OTP" → AuthService.sendOTP()
4. Navigate to OTPScreen with registration data
5. Enter 6-digit code → AuthService.verifyOTP()
6. Create Firestore user document
7. On success → Navigate to dashboard
```

### Phone Number Sign In Flow
```
1. LoginScreen → Phone tab
2. Select country code + enter phone number
3. Click "Send OTP" → AuthService.sendOTP()
4. Navigate to OTPScreen (isRegistration: false)
5. Enter 6-digit code → AuthService.verifyOTP()
6. On success → Navigate to dashboard
```

### Google Sign-In Flow
```
1. LoginScreen → Click "Continue with Google"
2. Select Google account
3. AuthService.signInWithGoogle()
4. If new user → Create Firestore document with selected role
5. If existing user → Fetch role from Firestore
6. Navigate to /merchant/dashboard or /customer/dashboard
```

### Forgot Password Flow
```
1. LoginScreen → Click "Forgot Password?"
2. ForgotPasswordScreen → Enter email
3. Click "Send Reset Link" → AuthService.sendPasswordResetEmail()
4. Show success confirmation with instructions
5. User checks email → Click reset link
6. Create new password in Firebase hosted page
7. Return to app → Sign in with new password
```

---

## 🗂️ Firestore Structure

### User Document (`/users/{uid}`)
```json
{
  "uid": "firebase_user_id",
  "role": "merchant" | "customer",
  "display_name": "Business Name" | "Username",
  "email": "user@example.com",
  "phone": "+911234567890",
  "category": "Restaurant" | "Retail" | ... (merchant only),
  "kyc_status": "PENDING" | "APPROVED" | "REJECTED" (merchant only),
  "created_at": Timestamp
}
```

---

## 🎨 UI Components

### Login Screen
- **Tabs**: Email, Phone
- **Email Tab**: email field, password field (with visibility toggle), forgot password link
- **Phone Tab**: country code dropdown, phone number field
- **Google Sign-In**: Full-width button with gradient outline
- **Role Badge**: Shows "Merchant" or "Customer" at top
- **Footer**: "Don't have an account? Sign up" link

### Registration Screen
- **Tabs**: Email, Phone
- **Role-Specific Fields**:
  - **Merchant (Email)**: business name, category dropdown, email, password, confirm
  - **Customer (Email)**: username, email, password, confirm
  - **Merchant (Phone)**: business name, category dropdown, country code, phone
  - **Customer (Phone)**: username, country code, phone
- **Category Options**: Restaurant, Retail, Grocery, Pharmacy, Electronics, Clothing, Services, Other
- **Validation**: Email regex, 8+ chars password, password match, 10-digit phone
- **Footer**: "Already have account? Sign in" link

### OTP Screen
- **6-digit input**: Individual fields for each digit
- **Countdown timer**: 60 seconds, auto-starts
- **Resend button**: Disabled until countdown complete, max 3 attempts
- **Change number**: Link to go back
- **Auto-verification**: Android SMS auto-detect support

### Forgot Password Screen
- **Email input**: Single field with validation
- **Send button**: Triggers password reset email
- **Success view**: Confirmation message, instructions, try again option
- **Back to login**: Link to return to login screen

---

## 🔑 Key Methods in AuthService

```dart
// Sign in with email/password
Future<AuthResult> signInWithEmail(String email, String password)

// Register with email/password
Future<AuthResult> registerWithEmail(RegistrationData data)

// Send OTP to phone
Future<void> sendOTP({
  required String phoneNumber,
  required String countryCode,
  required Function(String) onCodeSent,
  required Function(String) onError,
  required Function() onAutoVerify,
})

// Verify OTP code
Future<AuthResult> verifyOTP({
  required String verificationId,
  required String smsCode,
  RegistrationData? registrationData,
})

// Sign in with Google
Future<AuthResult> signInWithGoogle(String selectedRole)

// Send password reset email
Future<AuthResult> sendPasswordResetEmail(String email)

// Sign out
Future<void> signOut()

// Get user data from Firestore
Future<UserModel?> getUserData(String uid)
```

---

## 🎯 Navigation Routes

```dart
'/auth/login'           → LoginScreen (Email/Phone/Google sign in)
'/auth/register'        → RegisterScreen (Email/Phone registration)
'/auth/otp'             → OTPScreen (Phone verification)
'/auth/forgot-password' → ForgotPasswordScreen (Password reset)
'/merchant/dashboard'   → MerchantDashboardScreen
'/customer/dashboard'   → CustomerDashboardScreen
'/role_selection'       → RoleSelectionScreen
```

---

## ✅ Form Validations

### Email
```dart
RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
```

### Password
- Minimum 8 characters
- Must match confirm password

### Phone Number
- Exactly 10 digits (numeric only)
- Starts with 6-9 (Indian mobile)

### Business Name / Username
- Not empty
- Minimum 2 characters

---

## 🚨 Error Messages

### Firebase Error Codes → User-Friendly Messages
```
wrong-password             → "Incorrect password. Try again."
user-not-found            → "No account found. Create one."
email-already-in-use      → "Email already in use. Sign in instead."
weak-password             → "Password must be 8+ characters."
invalid-email             → "Please enter a valid email."
network-request-failed    → "Network error — check connection and try again."
too-many-requests         → "Too many attempts. Try again later."
invalid-verification-code → "Invalid code. Please try again."
invalid-phone-number      → "Invalid phone number format."
```

---

## 📝 TODO Before Production

### Firebase Setup
- [ ] Create Firebase project
- [ ] Enable Email/Password authentication
- [ ] Enable Phone authentication (add test numbers)
- [ ] Enable Google Sign-In (setup OAuth consent)
- [ ] Create Firestore database
- [ ] Add Android app (download google-services.json)
- [ ] Add iOS app (download GoogleService-Info.plist)
- [ ] Add SHA-1 fingerprint for Google Sign-In

### Security
- [ ] Update Firestore security rules (remove test mode)
- [ ] Enable App Check for production
- [ ] Add rate limiting for OTP requests
- [ ] Implement proper logging (no credentials)

### Testing
- [ ] Test email/password registration
- [ ] Test phone OTP flow with test numbers
- [ ] Test Google Sign-In on real device
- [ ] Test forgot password flow
- [ ] Test role-specific navigation
- [ ] Test error handling for all scenarios

### Features
- [ ] Implement actual dashboard features
- [ ] Add KYC flow for merchants
- [ ] Add profile editing
- [ ] Add email verification
- [ ] Add phone number verification for email sign-ups
- [ ] Add analytics tracking

---

## 🎨 Design Tokens Used

### Colors
```dart
AppColors.primaryBlue         // #00D4AA (teal-green)
AppColors.primaryBlueLight    // #1E5BFF (blue)
AppColors.primaryGradient     // teal to blue gradient
AppColors.success             // #28A745 (green)
AppColors.error               // #DC3545 (red)
AppColors.lightBackground     // #F8F9FA
AppColors.lightSurface        // #FFFFFF
AppColors.lightTextPrimary    // #212529
AppColors.lightTextSecondary  // #6C757D
AppColors.lightBorder         // #DEE2E6
```

### Typography
```dart
AppTypography.h1         // Poppins 32px bold
AppTypography.h2         // Poppins 24px bold
AppTypography.h3         // Poppins 20px semibold
AppTypography.body1      // Inter 16px regular
AppTypography.body2      // Inter 14px regular
AppTypography.button     // Inter 16px semibold
AppTypography.caption    // Inter 12px regular
```

### Spacing & Dimensions
```dart
AppDimensions.spacingXS   // 4px
AppDimensions.spacingSM   // 8px
AppDimensions.spacingMD   // 16px
AppDimensions.spacingLG   // 24px
AppDimensions.spacingXL   // 32px
AppDimensions.paddingMD   // 16px
AppDimensions.paddingLG   // 24px
AppDimensions.radiusSM    // 4px
AppDimensions.radiusMD    // 8px
AppDimensions.radiusLG    // 12px
```

---

**Last Updated**: December 2024
