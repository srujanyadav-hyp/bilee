# BILEE - Paperless Billing System 📱💳

> Digital receipts made simple, safe, and instant.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.10.1-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey)

---

## 📖 Table of Contents

- [Project Overview](#-project-overview)
- [Current Implementation Status](#-current-implementation-status)  
- [Folder Structure](#-folder-structure)
- [Features Implemented](#-features-implemented)
- [Technology Stack](#-technology-stack)
- [Architecture & Design Patterns](#-architecture--design-patterns)
- [What's Remaining](#-whats-remaining)
- [Upgrade Paths & Improvements](#-upgrade-paths--improvements)
- [Setup Instructions](#-setup-instructions)
- [Security Implementation](#-security-implementation)
- [Known Issues](#-known-issues)
- [Project Milestones](#-project-milestones)

---

## 🎯 Project Overview

**BILEE** is a modern, paperless billing system designed to eliminate traditional paper receipts. It provides a seamless digital receipt experience for both merchants and customers through QR code-based transactions.

### **Core Concept:**
1. **Merchants** create billing sessions with selected items
2. Generate a **QR code** for the session
3. **Customers** scan the QR code to view and save receipts
4. All data is stored securely in **Firebase Firestore**

### **Benefits:**
- ❌ **No paper receipts** (eco-friendly)
- ❌ **No thermal printer costs** (saves money)
- ❌ **No BPA/BPS chemicals** (health safe)
- ✅ **Instant digital delivery**
- ✅ **Permanent receipt storage**
- ✅ **Easy expense tracking**

---

## 📊 Current Implementation Status

### **Overall Completion: 75%** 🎉

| Module | Status | Completion |
|--------|--------|------------|
| **Authentication System** | ✅ Complete | 100% |
| **Onboarding Flow** | ✅ Complete | 100% |
| **Navigation (go_router)** | ✅ Complete | 100% |
| **Merchant Dashboard** | ✅ Complete | 95% |
| **Item Library Management** | ✅ Complete | 90% |
| **Billing Session Creation** | ✅ Complete | 95% |
| **Live Session (QR Code)** | ✅ Complete | 90% |
| **Daily Summary & Analytics** | ✅ Complete | 85% |
| **Customer Dashboard** | ⚠️ Partial | 40% |
| **Receipt Viewing** | ⚠️ Partial | 50% |
| **Firebase Security Rules** | ✅ Complete | 100% |
| **State Management** | ✅ Complete | 90% |
| **UI/UX Design** | ✅ Complete | 85% |
| **Offline Support** | ❌ Not Started | 0% |
| **Push Notifications** | ❌ Not Started | 0% |

---

## 📁 Folder Structure

```
bilee/
├── android/                          # Android platform code
├── ios/                              # iOS platform code
├── web/                              # Web platform code
├── windows/                          # Windows platform code
├── linux/                            # Linux platform code
├── macos/                            # macOS platform code
│
├── lib/
│   ├── main.dart                     # App entry point
│   ├── firebase_options.dart         # Firebase config
│   │
│   ├── config/                       # App configurations
│   │   └── app_config.dart
│   │
│   ├── core/                         # Core infrastructure
│   │   ├── analytics/
│   │   │   └── analytics_service.dart
│   │   │
│   │   ├── constants/                # Design system
│   │   │   ├── app_colors.dart       # Color palette
│   │   │   ├── app_dimensions.dart   # Spacing/sizing
│   │   │   └── app_typography.dart   # Text styles
│   │   │
│   │   ├── di/                       # Dependency injection
│   │   │   └── service_locator.dart
│   │   │
│   │   ├── errors/
│   │   │   └── failures.dart
│   │   │
│   │   ├── models/                   # Core data models
│   │   │   ├── user_model.dart
│   │   │   └── auth_models.dart
│   │   │
│   │   ├── network/
│   │   │   └── network_info.dart
│   │   │
│   │   ├── router/                   # Navigation
│   │   │   └── app_router.dart       # 168 lines, 12+ routes
│   │   │
│   │   ├── routes/
│   │   │   └── app_routes.dart
│   │   │
│   │   ├── services/                 # Core services
│   │   │   ├── auth_service.dart
│   │   │   ├── firestore_service.dart
│   │   │   └── role_storage_service.dart
│   │   │
│   │   ├── theme/                    # Light/Dark themes
│   │   │   ├── app_theme.dart
│   │   │   ├── theme_provider.dart
│   │   │   └── theme.dart
│   │   │
│   │   └── utils/                    # Utilities
│   │       ├── date_utils.dart
│   │       ├── string_utils.dart
│   │       └── validators.dart
│   │
│   ├── features/                     # Feature modules
│   │   │
│   │   ├── splash/
│   │   │   └── view/
│   │   │       └── splash_screen.dart
│   │   │
│   │   ├── onboarding/
│   │   │   ├── customer/
│   │   │   │   └── view/
│   │   │   │       └── customer_onboarding_screen.dart
│   │   │   ├── merchant/
│   │   │   │   └── view/
│   │   │   │       └── merchant_onboarding_screen.dart
│   │   │   └── role_selection/
│   │   │       └── view/
│   │   │           └── role_selection_screen.dart
│   │   │
│   │   ├── authentication/           # 2500+ lines total
│   │   │   └── view/
│   │   │       ├── login_screen.dart         # 800+ lines
│   │   │       ├── register_screen.dart      # 650+ lines
│   │   │       ├── otp_screen.dart          # 450+ lines
│   │   │       └── forgot_password_screen.dart
│   │   │
│   │   ├── merchant/                 # Merchant features
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── item_model.dart
│   │   │   │   │   ├── session_model.dart
│   │   │   │   │   ├── receipt_model.dart
│   │   │   │   │   └── daily_aggregate_model.dart
│   │   │   │   │
│   │   │   │   └── repositories/
│   │   │   │       └── merchant_repository_impl.dart
│   │   │   │
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── item.dart
│   │   │   │   │   └── session.dart
│   │   │   │   │
│   │   │   │   └── repositories/
│   │   │   │       └── merchant_repository.dart
│   │   │   │
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   ├── merchant_home_page.dart      # 223 lines
│   │   │       │   ├── start_billing_page.dart      # 500+ (redesigned)
│   │   │       │   ├── item_library_page.dart       # 600+ lines
│   │   │       │   ├── daily_summary_page.dart      # 350+ lines
│   │   │       │   ├── merchant_profile_page.dart   # 250+ lines
│   │   │       │   └── live_session_page.dart       # 400+ lines
│   │   │       │
│   │   │       └── providers/
│   │   │           ├── item_provider.dart
│   │   │           ├── session_provider.dart
│   │   │           └── daily_aggregate_provider.dart
│   │   │
│   │   └── customer/
│   │       └── dashboard/
│   │           └── view/
│   │               └── customer_dashboard.dart      # Minimal (needs work)
│   │
│   └── widgets/                      # Reusable widgets
│       └── splash_animation.dart
│
├── test/                             # Testing
│   └── widget_test.dart
│
├── firestore.rules                   # Security rules (225 lines)
├── firebase.json                     # Firebase config
├── pubspec.yaml                      # Dependencies
└── README.md                         # This file
```

**Total Lines of Code:** ~6000+ lines across 50+ Dart files

---

## ✨ Features Implemented

### 🔐 **1. Authentication System** (100%)

**Completed:**
- ✅ **Email/Password Authentication**
  - Registration with email validation
  - Login with credentials
  - Password reset via email
  
- ✅ **Phone Authentication**
  - Firebase Phone Auth
  - 6-digit OTP verification
  - Auto-detection on Android
  - Resend OTP (60s cooldown)
  
- ✅ **Google Sign-In**
  - One-tap authentication
  - Profile sync (name, email, photo)
  
- ✅ **Session Management**
  - Persistent login state
  - Auto-logout on expiry
  - Secure token handling

**Files:** `lib/features/authentication/view/` (4 screens, 2500+ lines)

---

### 🎯 **2. Onboarding Flow** (100%)

**Completed:**
- ✅ Animated splash screen with logo
- ✅ Role selection (Merchant/Customer)
- ✅ Merchant onboarding (3 tutorial slides)
- ✅ Customer onboarding (3 tutorial slides)
- ✅ Skip/Next navigation
- ✅ Role persistence in local storage

**Files:** `lib/features/splash/`, `lib/features/onboarding/`

---

### 🧭 **3. Navigation System** (100%)

**Completed:**
- ✅ **GoRouter v14.7.0** implementation
- ✅ Deep linking & URL-based navigation
- ✅ Path parameters (`:merchantId`, `:sessionId`)
- ✅ Nested routes for merchant features
- ✅ Custom 404 error page
- ✅ Debug logging enabled

**Route Structure:**
```
/ → Splash
/role-selection → Choose role
/onboarding/merchant → Tutorial
/onboarding/customer → Tutorial
/login → Authentication
/register → Create account
/otp → Phone verification
/forgot-password → Reset password
/merchant/:merchantId → Dashboard
  /billing → Start billing
  /items → Item library
  /summary → Daily summary
  /profile → Settings
  /session/:sessionId → Live session
/customer → Customer dashboard
```

**Key Navigation Methods:**
- `context.go()` - Updates URL (primary navigation)
- `context.push()` - Stack navigation (modals)
- `context.pop()` - Go back

**Files:** `lib/core/router/app_router.dart` (168 lines, 12+ routes)

---

### 🏪 **4. Merchant Dashboard** (95%)

**Completed:**
- ✅ Today's sales overview
  - Total revenue display
  - Orders count
  - Items sold count
- ✅ Quick action cards:
  - **Start Billing** (Green gradient card)
  - **Item Library** (Blue gradient card)
  - **Daily Summary** (Orange gradient card)
- ✅ Profile navigation (top-right icon)
- ✅ Real-time data sync from Firestore
- ✅ Loading states & empty states
- ✅ Error handling

**Remaining:**
- ⚠️ Revenue trend charts (weekly/monthly)
- ⚠️ Top-selling items graph
- ⚠️ Recent transactions list

**Files:** `lib/features/merchant/presentation/pages/merchant_home_page.dart` (223 lines)

---

### 📦 **5. Item Library Management** (90%)

**Completed:**
- ✅ **Full CRUD Operations:**
  - Create items (name, price, HSN, tax rate)
  - Read/List all items
  - Update item details
  - Delete items with confirmation
  
- ✅ **UI Features:**
  - Search functionality
  - Filter items by name
  - Card-based responsive layout
  - Add item dialog (form validation)
  - Edit item dialog (pre-filled data)
  - Delete confirmation dialog
  
- ✅ **Validation:**
  - Required fields check
  - Price > 0 validation
  - Tax rate 0-100% validation
  - Name uniqueness check
  
- ✅ **Data Sync:**
  - Real-time Firestore synchronization
  - Loading states (spinner)
  - Error handling with SnackBars
  - Success notifications

**Remaining:**
- ⚠️ **Categories:** Item categorization & filtering
- ⚠️ **Images:** Item photos (Firebase Storage)
- ⚠️ **Bulk Operations:** Import/export CSV/Excel
- ⚠️ **Inventory:** Stock tracking & low stock alerts

**Files:** `lib/features/merchant/presentation/pages/item_library_page.dart` (600+ lines)

---

### 💰 **6. Billing Session Creation** (95%)

**Completed (Latest Redesign):**
- ✅ **Modern UI Redesign:**
  - Split layout: 3:2 ratio (Items:Cart)
  - Grid view for items (2 columns, beautiful cards)
  - Search bar with instant filtering
  - Gradient item cards with icons
  - GST badge display on items
  - Professional cart design
  - Animated empty states
  - Responsive design (no overflow)
  
- ✅ **Item Selection:**
  - Tap entire card to add to cart
  - Visual feedback (green SnackBar)
  - Item count badge
  - Search by item name
  - Filtered results display
  
- ✅ **Cart Management:**
  - Add/Remove items
  - Quantity adjustment (+/-) buttons
  - Real-time calculations
  - Price per item × quantity
  - Subtotal display
  - Tax calculation (per item tax rate)
  - Total amount (large display)
  
- ✅ **Session Creation:**
  - Generate unique session ID
  - Store session in Firestore
  - Navigate to live session page
  - Large green "Create Session" button
  - Disabled state when cart empty

**Calculations:**
- Subtotal = Σ(price × quantity)
- Tax = Σ(price × quantity × taxRate/100)
- Total = Subtotal + Tax

**Remaining:**
- ⚠️ Discount functionality (% or flat)
- ⚠️ Payment method selection
- ⚠️ Saved carts feature
- ⚠️ Barcode scanner for items

**Files:** `lib/features/merchant/presentation/pages/start_billing_page.dart` (Redesigned - 500+ lines)

---

### 📱 **7. Live Session (QR Code Display)** (90%)

**Completed:**
- ✅ **QR Code Generation:**
  - Unique session URL embedded
  - High-resolution QR rendering
  - Dynamic QR based on session ID
  
- ✅ **Session Details:**
  - Items list with quantities
  - Price breakdown per item
  - Tax calculation display
  - Large total amount display
  
- ✅ **Session Timer:**
  - 30-minute countdown
  - Auto-expiry after time limit
  - Visual timer indicator
  
- ✅ **Customer Connection:**
  - Real-time customer count
  - Connected customers list
  - Live updates via Firestore listeners
  
- ✅ **Session Actions:**
  - Complete session button
  - Receipt generation on completion
  - Navigate back to dashboard

**Remaining:**
- ⚠️ Manual session extension option
- ⚠️ Share QR (WhatsApp, Email, Print)
- ⚠️ Real-time chat with customers
- ⚠️ Multiple payment methods

**Files:** `lib/features/merchant/presentation/pages/live_session_page.dart` (400+ lines)

---

### 📊 **8. Daily Summary & Analytics** (85%)

**Completed:**
- ✅ **Date Selection:**
  - Calendar picker (any past date)
  - Default to today's date
  - Smooth date navigation
  
- ✅ **Sales Metrics:**
  - Total revenue for selected day
  - Number of orders completed
  - Items sold breakdown (by name)
  - Average order value
  
- ✅ **Top Items:**
  - Most sold items list
  - Quantity sold per item
  - Revenue generated per item
  
- ✅ **Data Visualization:**
  - Card-based metrics display
  - Color-coded statistics
  - Empty state handling
  - Loading states

**Remaining:**
- ⚠️ **Charts:** Revenue trend chart (fl_chart package)
- ⚠️ **Reports:** Weekly/Monthly comparison
- ⚠️ **Export:** Download as PDF/Excel
- ⚠️ **Email:** Auto-send daily reports
- ⚠️ **Filters:** Date range, category, payment method

**Files:** `lib/features/merchant/presentation/pages/daily_summary_page.dart` (350+ lines)

---

### 👤 **9. Merchant Profile** (90%)

**Completed:**
- ✅ **Profile Display:**
  - User name display
  - Email address
  - Phone number
  - Profile photo (if available)
  
- ✅ **App Settings:**
  - Theme toggle (Light/Dark mode)
  - Theme persistence (SharedPreferences)
  - Instant theme switch
  
- ✅ **Logout:**
  - Firebase sign-out
  - Clear local data
  - Navigate to login screen

**Remaining:**
- ⚠️ **Profile Editing:**
  - Update name
  - Change phone number
  - Upload profile photo
  
- ⚠️ **Business Details:**
  - Business name
  - GST number
  - Business address
  - Business logo upload
  
- ⚠️ **Preferences:**
  - Default tax rate
  - Receipt template selection
  - Currency settings

**Files:** `lib/features/merchant/presentation/pages/merchant_profile_page.dart` (250+ lines)

---

### 👥 **10. Customer Dashboard** (40%)

**Completed:**
- ✅ Basic layout with AppBar
- ✅ Navigation route defined
- ✅ Empty state design

**Remaining (60% work):**
- ❌ **QR Scanner:** Camera integration, scan merchant QR
- ❌ **Receipt History:** List of all scanned receipts
- ❌ **Receipt Details:** View full receipt with items
- ❌ **Search & Filter:** Find receipts by date/merchant
- ❌ **Save/Share:** Download receipt, share via WhatsApp
- ❌ **Statistics:** Total spending, monthly breakdown

**Files:** `lib/features/customer/dashboard/view/customer_dashboard.dart` (Minimal - needs expansion)

---

## 🛠 Technology Stack

### **Frontend:**
- **Flutter:** 3.10.1
- **Dart:** ^3.10.1

### **State Management:**
- **Provider:** 6.1.2 (Main state management)
- **Get It:** 8.0.2 (Dependency injection)

### **Navigation:**
- **go_router:** 14.7.0 (Declarative routing, deep linking)

### **Backend & Cloud:**
- **Firebase Core:** 3.6.0
- **Firebase Auth:** 5.3.1 (Email, Phone, Google)
- **Cloud Firestore:** 5.4.4 (Real-time database)
- **Firebase Analytics:** 11.3.3 (Event tracking)
- **Firebase Storage:** 12.3.4 (File storage - not used yet)

### **UI/UX Libraries:**
- **Google Fonts:** 6.2.1 (Poppins, Inter)
- **Cupertino Icons:** 1.0.8

### **Additional Packages:**
- **google_sign_in:** 6.2.2 (OAuth)
- **shared_preferences:** 2.3.3 (Local storage)
- **qr_flutter:** 4.2.0 (QR generation)
- **intl:** 0.19.0 (Date formatting)
- **flutter_secure_storage:** 9.2.2 (Secure token storage)

---

## 🏗 Architecture & Design Patterns

### **1. Clean Architecture:**

```
┌─────────────────────────────────┐
│   Presentation Layer            │  ← UI, Widgets, Pages
│   (Flutter Widgets)             │
├─────────────────────────────────┤
│   Domain Layer                  │  ← Business Logic, Use Cases
│   (Pure Dart)                   │
├─────────────────────────────────┤
│   Data Layer                    │  ← API, Database, Models
│   (Firebase, Local Storage)     │
└─────────────────────────────────┘
```

---

## 📜 Development Rules & Principles

### **Strict Rules Followed Throughout Development:**

#### **1. Code Organization Rules:**

✅ **Feature-Based Module Structure (Mandatory)**
- Every feature MUST have its own folder in `lib/features/`
- Each feature MUST follow Data → Domain → Presentation layers
- NO mixing of feature code across modules
- Related files MUST stay together

✅ **File Naming Convention (Strict)**
```
✅ Correct:
  - merchant_home_page.dart
  - item_provider.dart
  - session_model.dart
  
❌ Incorrect:
  - MerchantHomePage.dart
  - ItemProvider.dart
  - sessionmodel.dart
```
- All file names MUST be `snake_case`
- File name MUST match the main class name (converted to snake_case)
- MUST use descriptive names (no abbreviations like `mhp.dart`)

✅ **Folder Structure Rules:**
```
feature/
  ├── data/
  │   ├── models/        # Data classes with fromFirestore/toFirestore
  │   └── repositories/  # Implementation of domain repositories
  ├── domain/
  │   ├── entities/      # Pure Dart business objects
  │   └── repositories/  # Abstract repository interfaces
  └── presentation/
      ├── pages/         # Full screen widgets
      ├── widgets/       # Reusable UI components
      └── providers/     # State management (ChangeNotifier)
```

---

#### **2. State Management Rules:**

✅ **Provider Pattern (Enforced)**
- MUST use `Provider` for state management
- NO setState() in StatefulWidgets for business logic
- ALL business logic MUST be in Provider classes
- Providers MUST extend `ChangeNotifier`
- MUST call `notifyListeners()` after state changes

✅ **Provider Structure:**
```dart
class ItemProvider extends ChangeNotifier {
  // 1. Private state variables
  List<ItemModel> _items = [];
  bool _isLoading = false;
  String? _error;
  
  // 2. Public getters (read-only access)
  List<ItemModel> get items => _items;
  bool get isLoading => _isLoading;
  bool get hasItems => _items.isNotEmpty;
  
  // 3. Public methods (actions)
  Future<void> loadItems(String merchantId) async {
    _isLoading = true;
    notifyListeners(); // MUST call this
    
    try {
      _items = await repository.getItems(merchantId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // MUST call this
    }
  }
}
```

✅ **Provider Usage Rules:**
- MUST use `Consumer<Provider>` for rebuilding widgets
- MUST use `context.read<Provider>()` for one-time actions
- MUST use `context.watch<Provider>()` sparingly (causes rebuilds)
- NO Provider logic in build() methods

---

#### **3. Navigation Rules:**

✅ **go_router Only (Mandatory)**
- MUST use go_router for ALL navigation
- NO Navigator.push(), Navigator.pop() (except for dialogs)
- MUST use `context.go()` for URL-updating navigation
- MUST use `context.push()` ONLY for modals/overlays
- MUST use `context.pop()` for going back

✅ **Route Definition Rules:**
```dart
// ✅ Correct: Declarative, centralized
GoRoute(
  path: '/merchant/:merchantId/billing',
  name: 'merchant_billing',
  builder: (context, state) {
    final merchantId = state.pathParameters['merchantId']!;
    return StartBillingPage(merchantId: merchantId);
  },
)

// ❌ Incorrect: Navigator usage (forbidden)
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => StartBillingPage()),
);
```

✅ **Navigation Method Selection:**
- **Primary navigation** → `context.go()` (updates URL)
- **Modal/Dialog** → `context.push()` (keeps URL)
- **Go back** → `context.pop()`
- **With data** → Use `extra` parameter

---

#### **4. Firebase Integration Rules:**

✅ **Firestore Rules (Mandatory)**
- EVERY collection MUST have security rules
- MUST validate `request.auth.uid` for ownership
- MUST validate data types and required fields
- NO open rules (`allow read, write: if true;`) in production
- MUST use helper functions for reusable logic

✅ **Data Model Rules:**
```dart
class ItemModel {
  final String id;
  final String name;
  final double price;
  final double taxRate;
  final String merchantId;
  final DateTime createdAt;
  
  // ✅ MUST have: fromFirestore factory
  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      // ... MUST handle null values
    );
  }
  
  // ✅ MUST have: toFirestore method
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'taxRate': taxRate,
      'merchantId': merchantId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
```

✅ **Firestore Query Rules:**
- MUST use `.snapshots()` for real-time data
- MUST use `.get()` for one-time reads
- MUST handle errors with try-catch
- MUST show loading states
- MUST limit queries (`.limit(50)`)

---

#### **5. UI/UX Design Rules:**

✅ **Design System Compliance (Strict)**
- MUST use colors from `AppColors` class
- MUST use spacing from `AppDimensions` class
- MUST use text styles from `AppTypography` class
- NO hardcoded colors like `Color(0xFF...)` directly in widgets
- NO magic numbers for spacing (use constants)

✅ **Color Usage:**
```dart
// ✅ Correct: Using design system
Container(
  color: AppColors.primaryBlue,
  padding: EdgeInsets.all(AppDimensions.paddingMD),
  child: Text('Hello', style: AppTypography.h1),
)

// ❌ Incorrect: Hardcoded values
Container(
  color: Color(0xFF2196F3),
  padding: EdgeInsets.all(16),
  child: Text('Hello', style: TextStyle(fontSize: 32)),
)
```

✅ **Spacing System:**
```dart
// Mandatory spacing values
XS: 4px   // Tiny gaps, icon padding
SM: 8px   // Small gaps, chip padding
MD: 16px  // Default spacing, card padding
LG: 24px  // Section spacing
XL: 32px  // Large gaps
XXL: 48px // Screen padding
```

✅ **Widget Structure Rules:**
- MUST extract large widgets into separate methods
- MUST create custom widgets if reused 2+ times
- MUST use `const` constructors when possible
- Widget build() methods MUST be < 100 lines
- MUST separate business logic from UI

---

#### **6. Error Handling Rules:**

✅ **Mandatory Try-Catch Blocks:**
```dart
// ✅ Correct: Comprehensive error handling
Future<void> createItem(ItemModel item) async {
  try {
    _isLoading = true;
    notifyListeners();
    
    await firestore.collection('items').add(item.toFirestore());
    
    _error = null;
    _isLoading = false;
    notifyListeners();
    
  } catch (e) {
    _error = 'Failed to create item: ${e.toString()}';
    _isLoading = false;
    notifyListeners();
    
    // MUST log errors
    debugPrint('Error creating item: $e');
  }
}
```

✅ **User Feedback Rules:**
- MUST show SnackBar for success/error messages
- MUST show loading indicators during async operations
- MUST show empty states when no data
- MUST show error states with retry option
- NO silent failures

---

#### **7. Security Rules:**

✅ **Authentication Checks (Mandatory)**
- MUST check `request.auth != null` in Firestore rules
- MUST validate user ownership (`request.auth.uid == merchantId`)
- MUST validate data before writing to Firestore
- NO direct user input to Firestore without validation

✅ **Data Validation Rules:**
```dart
// Client-side validation
if (name.isEmpty) return 'Name is required';
if (price <= 0) return 'Price must be greater than 0';
if (taxRate < 0 || taxRate > 100) return 'Tax rate must be 0-100%';

// Server-side validation (Firestore rules)
function isValidItem() {
  return request.resource.data.price is number
      && request.resource.data.price >= 0
      && request.resource.data.taxRate >= 0
      && request.resource.data.taxRate <= 100;
}
```

✅ **Sensitive Data Rules:**
- MUST use `flutter_secure_storage` for tokens
- NO storing passwords locally
- NO exposing API keys in code
- MUST use environment variables for secrets

---

#### **8. Code Quality Rules:**

✅ **Naming Conventions:**
```dart
// Classes: PascalCase
class MerchantHomePage extends StatefulWidget {}

// Variables: camelCase
final String merchantId;
bool isLoading = false;

// Constants: camelCase with const
const double defaultTaxRate = 18.0;

// Private members: _underscore prefix
String _internalState;

// Methods: camelCase, verb-based
void loadItems() {}
Future<void> createSession() async {}
```

✅ **File Size Rules:**
- MUST keep files under 500 lines
- If > 500 lines, MUST split into multiple files
- Extract reusable widgets to separate files
- Extract complex logic to services/utils

✅ **Comment Rules:**
```dart
// ✅ MUST add comments for:
// 1. Complex business logic
// 2. Non-obvious algorithms
// 3. Public APIs
// 4. Workarounds

/// Calculates the total amount including tax
/// 
/// Formula: Total = Subtotal + (Subtotal × TaxRate / 100)
double calculateTotal(double subtotal, double taxRate) {
  return subtotal + (subtotal * taxRate / 100);
}
```

---

#### **9. Testing Rules (To Be Enforced):**

✅ **Mandatory Tests:**
- MUST write unit tests for business logic
- MUST write widget tests for UI components
- MUST test all Provider methods
- MUST test all validation functions
- Target: > 80% code coverage

✅ **Test Structure:**
```dart
// MUST follow Arrange-Act-Assert pattern
test('should calculate total correctly', () {
  // Arrange
  final provider = SessionProvider();
  final item = ItemModel(price: 100, taxRate: 18);
  
  // Act
  provider.addToCart(item);
  final total = provider.cartTotal;
  
  // Assert
  expect(total, 118.0);
});
```

---

#### **10. Performance Rules:**

✅ **Optimization Requirements:**
- MUST use `const` constructors for static widgets
- MUST use `ListView.builder` for long lists (not ListView())
- MUST implement pagination for > 50 items
- MUST lazy load images
- MUST dispose controllers/listeners in dispose()

✅ **Prohibited Practices:**
```dart
// ❌ Forbidden: Building widgets in loops
for (var item in items) {
  widgets.add(ItemCard(item: item)); // NO!
}

// ✅ Correct: Use builder
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemCard(item: items[index]),
)
```

---

#### **11. Git Commit Rules:**

✅ **Commit Message Format:**
```
type(scope): subject

Types: feat, fix, docs, style, refactor, test, chore
Scope: feature name (auth, billing, items)
Subject: imperative mood, < 50 chars

Examples:
feat(auth): add Google sign-in integration
fix(billing): resolve cart total calculation bug
docs(readme): update installation instructions
refactor(items): extract validation to separate function
test(session): add unit tests for session provider
```

✅ **Commit Frequency:**
- MUST commit after completing each feature
- MUST commit before major refactoring
- MUST commit working code (no broken commits)

---

#### **12. Documentation Rules:**

✅ **README Requirements:**
- MUST update README when adding features
- MUST document folder structure changes
- MUST list all dependencies with versions
- MUST include setup instructions
- MUST document known issues

✅ **Code Documentation:**
```dart
/// MUST document all public classes
/// MUST document all public methods
/// MUST document complex algorithms
/// SHOULD document non-obvious decisions

/// Manages billing session state and cart operations.
/// 
/// Provides methods to:
/// - Add items to cart
/// - Update quantities
/// - Calculate totals (subtotal, tax, total)
/// - Create Firestore sessions
class SessionProvider extends ChangeNotifier {
  // ...
}
```

---

### **Development Principles Applied:**

#### **✅ DRY (Don't Repeat Yourself):**
- Extract reusable widgets into separate files
- Use constants for repeated values
- Create utility functions for common operations

#### **✅ KISS (Keep It Simple, Stupid):**
- Prefer simple solutions over complex ones
- Avoid premature optimization
- Write readable code > clever code

#### **✅ YAGNI (You Aren't Gonna Need It):**
- Don't implement features before they're needed
- Focus on current requirements
- Avoid over-engineering

#### **✅ Single Responsibility Principle:**
- Each class/method does ONE thing
- Providers manage state, not UI
- Repositories handle data, not business logic

#### **✅ Separation of Concerns:**
- UI in Presentation layer
- Business logic in Domain layer
- Data access in Data layer
- NO mixing of responsibilities

---

### **Quality Assurance Checklist:**

Before considering a feature "complete", it MUST:
- [ ] ✅ Follow folder structure rules
- [ ] ✅ Use Provider for state management
- [ ] ✅ Have proper error handling
- [ ] ✅ Show loading states
- [ ] ✅ Show empty states
- [ ] ✅ Use design system (colors, spacing, typography)
- [ ] ✅ Have Firestore security rules
- [ ] ✅ Validate user input
- [ ] ✅ Use go_router for navigation
- [ ] ✅ Have proper comments
- [ ] ✅ Follow naming conventions
- [ ] ✅ Be responsive (mobile, tablet, web)
- [ ] ✅ Work offline (when offline support is added)
- [ ] ✅ Have unit tests (when testing is added)

---

**These rules ensure:**
- 🎯 **Consistency** across the entire codebase
- 🔒 **Security** with proper validation and rules
- 🚀 **Performance** with optimization best practices
- 🧹 **Maintainability** with clean, organized code
- 📚 **Scalability** with proper architecture
- 🐛 **Fewer Bugs** with comprehensive error handling

### **2. Feature-Based Structure:**

Each feature module is self-contained with:
- **Data:** Models, Repositories, Data Sources
- **Domain:** Entities, Use Cases, Repository Interfaces
- **Presentation:** Pages, Widgets, Providers (State)

### **3. Design Patterns Used:**

| Pattern | Purpose | Location |
|---------|---------|----------|
| **Repository** | Data abstraction | `lib/features/*/data/repositories/` |
| **Provider** | State management | `lib/features/*/presentation/providers/` |
| **Singleton** | Service instances | `lib/core/di/service_locator.dart` |
| **Factory** | Model creation | `*.fromFirestore()` methods |
| **Observer** | Firebase listeners | Firestore snapshot streams |
| **MVVM** | Separation of concerns | View ↔ Provider ↔ Repository |

### **4. State Management Flow:**

```
User Action
    ↓
Widget (View)
    ↓
Provider (ViewModel)
    ↓
Repository (Data)
    ↓
Firestore / Auth
    ↓
Provider notifies listeners
    ↓
Widget rebuilds
```

### **5. Navigation Architecture:**

- **Declarative Routing:** go_router defines routes in one place
- **Path Parameters:** `/merchant/:merchantId/session/:sessionId`
- **Named Routes:** Easy code organization
- **Guard Routes:** Authentication checks (planned)

---

## ⚠️ What's Remaining

### **Critical (Must-Have):**

#### **1. Customer Module** (60% work remaining)
- [ ] QR Scanner implementation
  - Camera permission handling
  - Scan merchant QR codes
  - Parse session URL from QR
  - Navigate to receipt view
  
- [ ] Receipt Viewing Interface
  - Display session details
  - Show items with quantities
  - Price breakdown (subtotal, tax, total)
  - Merchant info display
  
- [ ] Receipt History Management
  - List all scanned receipts
  - Search by merchant/date
  - Filter by date range
  - Sort by date/amount
  
- [ ] Save & Share
  - Save receipt to device
  - Generate PDF receipt
  - Share via WhatsApp/Email
  - Export functionality

**Estimated Time:** 2-3 weeks

---

#### **2. Receipt Generation** (50% work remaining)
- [ ] PDF Generation
  - Receipt template design
  - Items table formatting
  - Merchant branding
  - QR code on receipt
  
- [ ] Sharing Integration
  - WhatsApp share
  - Email integration
  - SMS option
  - Social media share

**Estimated Time:** 1-2 weeks

---

#### **3. Advanced Analytics** (40% work remaining)
- [ ] Charts Integration
  - Install fl_chart package
  - Revenue trend line chart
  - Item-wise pie chart
  - Hour-wise bar chart
  
- [ ] Reports
  - Weekly summary
  - Monthly comparison
  - Year-over-year growth
  - Custom date range
  
- [ ] Export Options
  - Export as PDF
  - Export as Excel
  - Email reports
  - Scheduled reports

**Estimated Time:** 2 weeks

---

#### **4. Profile Management** (30% work remaining)
- [ ] Edit Profile
  - Update name
  - Change phone number
  - Upload profile photo
  - Email change (with verification)
  
- [ ] Business Information
  - Business name
  - GST number validation
  - Business address
  - Business logo upload
  - Operating hours
  
- [ ] App Preferences
  - Default tax rate
  - Currency settings
  - Receipt template
  - Notification preferences

**Estimated Time:** 1 week

---

### **Important (Should-Have):**

#### **5. Offline Support** (100% work remaining)
- [ ] Local Database Setup
  - Hive or Drift integration
  - Schema design
  - Migration strategy
  
- [ ] Offline Caching
  - Cache items locally
  - Cache daily summaries
  - Cache user profile
  
- [ ] Sync Mechanism
  - Detect online/offline status
  - Queue offline operations
  - Auto-sync when online
  - Conflict resolution

**Estimated Time:** 3-4 weeks

---

#### **6. Push Notifications** (100% work remaining)
- [ ] FCM Setup
  - Firebase Cloud Messaging config
  - Device token registration
  - Permission handling
  
- [ ] Notification Types
  - Session completion alerts
  - New receipt notifications
  - Daily summary reminders
  - Payment received alerts
  
- [ ] In-App Notifications
  - Notification center
  - Mark as read/unread
  - Action buttons

**Estimated Time:** 2 weeks

---

#### **7. Search & Filter** (60% work remaining)
- [ ] Global Search
  - Search across items
  - Search in receipts
  - Search customers
  
- [ ] Advanced Filters
  - Date range filters
  - Amount range filters
  - Category filters
  - Status filters
  
- [ ] Sort Options
  - Sort by date
  - Sort by amount
  - Sort by popularity

**Estimated Time:** 1 week

---

#### **8. Export & Reports** (80% work remaining)
- [ ] PDF Export
  - Daily summary PDF
  - Monthly report PDF
  - Custom report PDF
  
- [ ] Excel Export
  - Transaction export
  - Item-wise sales
  - Customer data
  
- [ ] Automated Reports
  - Email daily summary
  - Weekly digest
  - Monthly statement

**Estimated Time:** 2 weeks

---

### **Nice-to-Have:**

#### **9. Multi-Language Support** (100% work remaining)
- [ ] i18n Setup (intl package)
- [ ] Language selector in settings
- [ ] English, Hindi, Telugu, Tamil translations
- [ ] RTL support for Arabic

**Estimated Time:** 2-3 weeks

---

#### **10. Accessibility** (70% work remaining)
- [ ] Screen reader support (Semantics)
- [ ] High contrast mode
- [ ] Font scaling support
- [ ] Keyboard navigation
- [ ] Color blind friendly palette

**Estimated Time:** 1-2 weeks

---

#### **11. Performance Optimization** (50% work remaining)
- [ ] Image optimization & lazy loading
- [ ] List virtualization (large datasets)
- [ ] Caching strategy (Firebase)
- [ ] Memory leak detection
- [ ] App size reduction

**Estimated Time:** 1 week

---

#### **12. Testing** (90% work remaining)
- [ ] Unit tests (business logic)
- [ ] Widget tests (UI components)
- [ ] Integration tests (features)
- [ ] End-to-end tests
- [ ] Test coverage >80%

**Estimated Time:** 3-4 weeks

---

## 🚀 Upgrade Paths & Improvements

### **Phase 1: Complete Core Features** (4-5 weeks)

#### **Week 1-2: Customer Module**
- [ ] Day 1-3: QR Scanner implementation
  - Camera package integration
  - Permission handling
  - QR code parsing
  
- [ ] Day 4-7: Receipt Viewing
  - Build receipt UI
  - Fetch session from Firestore
  - Display items & totals
  
- [ ] Day 8-10: Receipt History
  - List view with search
  - Filter by date
  - Pull-to-refresh

#### **Week 3: Receipt Sharing & PDF**
- [ ] Day 1-3: PDF Generation
  - pdf package integration
  - Receipt template design
  - Generate PDF from session
  
- [ ] Day 4-5: Share Functionality
  - Share via WhatsApp
  - Email integration
  - Save to device

#### **Week 4-5: Analytics Enhancement**
- [ ] Day 1-3: Charts Integration
  - Install fl_chart
  - Revenue trend chart
  - Top items pie chart
  
- [ ] Day 4-7: Reports
  - Weekly/Monthly reports
  - Export as PDF/Excel
  - Email automation

---

### **Phase 2: Advanced Features** (5-6 weeks)

#### **Week 6-8: Offline Support**
- [ ] Week 1: Database Setup
  - Hive integration
  - Schema design
  - CRUD operations
  
- [ ] Week 2: Caching Logic
  - Cache items, sessions
  - Cache user data
  - Cache daily summaries
  
- [ ] Week 3: Sync Mechanism
  - Online/offline detection
  - Queue offline changes
  - Auto-sync & conflict resolution

#### **Week 9-10: Notifications**
- [ ] Week 1: FCM Setup
  - Firebase config
  - Device tokens
  - Permission handling
  
- [ ] Week 2: Notification Types
  - Session alerts
  - Daily reminders
  - In-app notifications

#### **Week 11: Profile & Business Setup**
- [ ] Edit profile features
- [ ] Business information form
- [ ] Logo upload (Firebase Storage)
- [ ] App preferences

---

### **Phase 3: Polish & Optimization** (3-4 weeks)

#### **Week 12-13: UI/UX Improvements**
- [ ] Smooth animations
- [ ] Loading skeletons
- [ ] Error state designs
- [ ] Accessibility audit
- [ ] Performance optimization

#### **Week 14-15: Testing & QA**
- [ ] Write unit tests
- [ ] Widget tests
- [ ] Integration tests
- [ ] Bug fixes
- [ ] Documentation updates

---

### **Specific Page Improvements:**

#### **Start Billing Page** (Current: 95%)
**Current State:** ✅ Modern UI redesigned with grid, search, cart

**Add These:**
- [ ] Item categories dropdown
- [ ] Discount functionality (% or ₹)
- [ ] Saved carts (resume later)
- [ ] Quick add favorite items
- [ ] Barcode scanner for items

---

#### **Live Session Page** (Current: 90%)
**Current State:** ✅ QR display, timer, customer count

**Add These:**
- [ ] Extend session time button
- [ ] Show customer names (not just count)
- [ ] Real-time chat with customers
- [ ] Manual payment marking
- [ ] Multiple payment methods (Cash, UPI, Card)

---

#### **Daily Summary** (Current: 85%)
**Current State:** ✅ Basic metrics, date picker, top items

**Add These:**
- [ ] Interactive line chart (revenue trend)
- [ ] Comparison with yesterday/last week
- [ ] Hour-wise sales distribution
- [ ] Export as PDF button
- [ ] Email daily report automatically

---

#### **Item Library** (Current: 90%)
**Current State:** ✅ CRUD, search, validation

**Add These:**
- [ ] Upload item images
- [ ] Category management
- [ ] Bulk import from CSV
- [ ] Inventory tracking (stock count)
- [ ] Low stock alerts
- [ ] Item variants (size, color)

---

#### **Authentication** (Current: 100%)
**Current State:** ✅ Email, Phone, Google working

**Nice-to-Have:**
- [ ] Biometric login (fingerprint/face)
- [ ] "Remember me" option
- [ ] Session timeout settings
- [ ] Multi-device logout
- [ ] Login history page

---

#### **Security Enhancements** (Current: 100% basic)
**Current State:** ✅ Firestore rules implemented

**Add These:**
- [ ] Firebase App Check (bot protection)
- [ ] Rate limiting on API calls
- [ ] Encrypt sensitive data locally
- [ ] Audit logs (who did what, when)
- [ ] GDPR compliance (data export/delete)

---

## 📥 Setup Instructions

### **Prerequisites:**
- Flutter SDK 3.10.1 or higher
- Dart SDK 3.10.1 or higher
- Android Studio or VS Code with Flutter extension
- Firebase account (free tier is sufficient)

---

### **Installation Steps:**

#### **1. Clone Repository:**
```bash
git clone <repository-url>
cd bilee
```

#### **2. Install Dependencies:**
```bash
flutter pub get
```

#### **3. Firebase Setup:**

**Option A: Using FlutterFire CLI (Recommended):**
```bash
# Install FlutterFire CLI globally
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

**Option B: Manual Setup:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project named "bilee"
3. Add Android/iOS/Web apps
4. Download `google-services.json` (Android) → `android/app/`
5. Download `GoogleService-Info.plist` (iOS) → `ios/Runner/`
6. Download `firebase-config.js` (Web) → `web/`

---

#### **4. Firebase Services Configuration:**

**Enable Authentication:**
```
Firebase Console → Authentication → Sign-in method
✅ Email/Password
✅ Phone
✅ Google
```

**Create Firestore Database:**
```
Firebase Console → Firestore Database → Create Database
Mode: Production mode
Location: Choose nearest region
```

**Deploy Security Rules:**
```bash
firebase deploy --only firestore:rules
```

---

#### **5. Run the App:**

```bash
# Android
flutter run -d android

# iOS (Mac only)
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows

# List available devices
flutter devices
```

---

### **Environment Variables (Optional):**

Create `.env` file in project root:
```
FIREBASE_API_KEY=your_api_key
FIREBASE_APP_ID=your_app_id
FIREBASE_PROJECT_ID=your_project_id
```

---

## 🔒 Security Implementation

### **1. Firebase UID in URLs - Is it Safe?**

✅ **YES, it's completely secure!**

**Why:**
- Firebase UIDs are **random 28-character strings** (e.g., `qSTADZ19yIfz4s7z7H7qNIOiuHI3`)
- **Non-sequential** - Can't enumerate users by trying UID+1, UID+2
- **Not personally identifiable** - Doesn't reveal name, email, or phone
- **Industry standard** - Used by Google, Stripe, AWS, GitHub

**Example:**
```
URL: /merchant/qSTADZ19yIfz4s7z7H7qNIOiuHI3/billing
```

Even if someone changes the URL to another UID, they **cannot access data** due to Firestore security rules.

---

### **2. Firestore Security Rules (Implemented):**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper Functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    function isMerchant(merchantId) {
      return isSignedIn() && request.auth.uid == merchantId;
    }
    
    // Users Collection (Own profile only)
    match /users/{userId} {
      allow read, write: if isOwner(userId);
      allow create: if isSignedIn() && request.auth.uid == userId;
    }
    
    // Items Collection (Merchant ownership check)
    match /items/{itemId} {
      allow read: if isMerchant(resource.data.merchantId);
      allow create: if isMerchant(request.resource.data.merchantId);
      allow update, delete: if isMerchant(resource.data.merchantId);
    }
    
    // Sessions Collection (Anyone can read, merchant can write)
    match /sessions/{sessionId} {
      allow read: if isSignedIn();
      allow create, update: if isMerchant(request.resource.data.merchantId);
    }
    
    // Daily Aggregates (Merchant only)
    match /daily_aggregates/{aggregateId} {
      allow read, write: if isMerchant(resource.data.merchantId);
    }
  }
}
```

---

### **3. Data Validation (Client + Server):**

**Client-Side (UI Validation):**
- ✅ Input sanitization
- ✅ Type checking
- ✅ Required field validation
- ✅ Range limits (price > 0, tax 0-100%)
- ✅ String length restrictions

**Server-Side (Firestore Rules):**
```javascript
// Example: Item validation
function isValidItem() {
  let data = request.resource.data;
  return data.name is string 
      && data.name.size() > 0 
      && data.name.size() <= 200
      && data.price is number 
      && data.price >= 0
      && data.taxRate >= 0 
      && data.taxRate <= 100;
}
```

---

### **4. Best Practices Followed:**

| Practice | Status | Implementation |
|----------|--------|----------------|
| **Backend Authorization** | ✅ | Firestore rules validate `request.auth.uid` |
| **Client Validation** | ✅ | Form validators, input sanitization |
| **Secure Storage** | ✅ | flutter_secure_storage for tokens |
| **HTTPS Only** | ✅ | Firebase enforces HTTPS |
| **Session Management** | ✅ | Auto-logout, token refresh |
| **Rate Limiting** | ⚠️ | Not implemented (future) |
| **App Check** | ⚠️ | Not implemented (future) |

---

## 📊 Performance Metrics

### **Current Performance:**

| Metric | Current | Target |
|--------|---------|--------|
| **Cold Start** | ~2-3 seconds | <2 seconds |
| **Hot Reload** | <1 second | <1 second |
| **Firestore Read** | 200-500ms | <100ms (with cache) |
| **Firestore Write** | 300-600ms | <300ms |
| **UI Frame Rate** | 60fps (mostly) | 60fps (always) |
| **App Size (APK)** | ~25MB | <20MB |

### **Optimization Targets:**

- [ ] Implement Firestore persistence (offline cache)
- [ ] Use ListView.builder for large lists
- [ ] Lazy load images
- [ ] Reduce widget rebuilds
- [ ] Code splitting for web

---

## 🎨 Design System

### **Color Palette:**

```dart
// Primary Colors
primaryBlue: #2196F3
primaryGreen: #4CAF50
primaryOrange: #FF9800

// Background
lightBackground: #F5F7FA
darkBackground: #121212
lightSurface: #FFFFFF
darkSurface: #1E1E1E

// Text
lightTextPrimary: #212121
lightTextSecondary: #757575
darkTextPrimary: #FFFFFF
darkTextSecondary: #B0B0B0

// Borders
lightBorder: #E0E0E0
darkBorder: #424242
```

---

### **Typography:**

```dart
// Headings
h1: FontSize 32px, Weight Bold, Poppins
h2: FontSize 24px, Weight Bold, Poppins
h3: FontSize 20px, Weight SemiBold, Poppins

// Body
body1: FontSize 16px, Weight Regular, Inter
body2: FontSize 14px, Weight Regular, Inter

// Caption
caption: FontSize 12px, Weight Regular, Inter
```

---

### **Spacing System:**

```dart
spacingXS:  4px   // Tiny gaps
spacingSM:  8px   // Small gaps
spacingMD:  16px  // Default spacing
spacingLG:  24px  // Section spacing
spacingXL:  32px  // Large gaps
spacingXXL: 48px  // Screen padding
```

---

### **Border Radius:**

```dart
radiusSM:  8px   // Buttons, chips
radiusMD:  12px  // Cards
radiusLG:  16px  // Dialogs
radiusXL:  24px  // Bottom sheets
```

---

## 📊 Analytics Events Tracked

### **Implemented:**
- ✅ `onboarding_role_viewed`
- ✅ `onboarding_role_selected` (merchant/customer)
- ✅ `onboarding_merchant_viewed`
- ✅ `onboarding_merchant_continue`
- ✅ `auth_method_selected` (email/phone/google)
- ✅ `auth_attempt` (success/failure)
- ✅ `session_created`
- ✅ `item_created`

### **To Be Added:**
- [ ] `item_added_to_cart`
- [ ] `cart_checkout`
- [ ] `session_completed`
- [ ] `receipt_viewed`
- [ ] `receipt_shared`
- [ ] `profile_updated`
- [ ] `theme_toggled`

---

## 🐛 Known Issues

### **1. Google Sign-In Web Warning**
**Issue:** Deprecation warning for `signIn()` method on web  
**Message:** "Use renderButton instead"  
**Impact:** Low (functionality works correctly)  
**Fix:** Migrate to new Google Identity Services API  
**Priority:** Low

---

### **2. Input Method Manager Timeouts (Android)**
**Issue:** Keyboard timeout warnings in logs  
**Message:** "Timeout waiting for IME to handle input event"  
**Impact:** None (system-level issue)  
**Fix:** Not needed (Android OS issue)  
**Priority:** None

---

### **3. Start Billing Page Overflow**
**Status:** ✅ **FIXED** in latest redesign  
**Fix:** Proper Flexible/Expanded widgets, responsive layout  
**Priority:** Resolved

---

### **4. Firestore Unavailable on Emulator**
**Issue:** Sometimes Firestore is unavailable on Android emulator  
**Message:** "The service is currently unavailable"  
**Impact:** Medium (test data not loading)  
**Fix:** Restart emulator, check internet connection  
**Priority:** Medium

---

## 🤝 Contributing

### **Development Workflow:**
1. Create a feature branch: `feature/customer-qr-scanner`
2. Implement changes with proper comments
3. Test thoroughly on multiple devices
4. Update this README if folder structure changes
5. Submit pull request with clear description

### **Code Standards:**
- Follow Flutter style guide
- Use meaningful variable names (`merchantId`, not `mId`)
- Add comments for complex logic
- Write tests for new features
- Keep functions small (<50 lines)

### **Commit Message Format:**
```
type(scope): subject

Examples:
feat(customer): add QR scanner functionality
fix(billing): resolve cart calculation bug
docs(readme): update installation steps
style(ui): improve card shadows
refactor(auth): extract OTP logic to service
test(items): add unit tests for item model
```

---

## 📄 License

**Private and Proprietary**

This project is not open-source and is not for public distribution.

---

## 👥 Author

**Srujan Yadav**
- GitHub: [@srujanyadav-hyp](https://github.com/srujanyadav-hyp)
- Email: psrujan792@gmail.com

---

## 🎯 Project Milestones

### **Milestone 1: MVP (Merchant)** ✅ Completed (Nov-Dec 2025)
- ✅ Authentication (Email, Phone, Google)
- ✅ Onboarding flow
- ✅ Merchant dashboard
- ✅ Item library management
- ✅ Session creation & QR generation
- ✅ Daily summary basics

**Result:** 75% app completion, merchant side functional

---

### **Milestone 2: Customer App** ⏳ In Progress (Dec 2025)
- [ ] QR scanner
- [ ] Receipt viewing
- [ ] Receipt history
- [ ] Save/Share receipts

**Target:** 90% app completion

---

### **Milestone 3: Analytics & Export** ⏳ Planned (Jan 2026)
- [ ] Charts & graphs (fl_chart)
- [ ] Weekly/Monthly reports
- [ ] PDF/Excel export
- [ ] Email automation

**Target:** 95% app completion

---

### **Milestone 4: Production Ready** ⏳ Planned (Feb 2026)
- [ ] Offline support
- [ ] Push notifications
- [ ] Complete testing (>80% coverage)
- [ ] Performance optimization
- [ ] App store submission (Play Store, App Store)

**Target:** 100% app completion, production deployment

---

## 🙏 Acknowledgments

- **Flutter Team** - Amazing cross-platform framework
- **Firebase Team** - Reliable backend infrastructure
- **Google Fonts** - Beautiful typography (Poppins, Inter)
- **Material Design** - Comprehensive UI guidelines
- **Provider Package** - Simple yet powerful state management
- **go_router Package** - Modern declarative routing

---

**Last Updated:** December 11, 2025  
**Version:** 1.0.0  
**Status:** 🚀 Active Development (75% Complete)

---

**🎉 BILEE - Making the world paperless, one receipt at a time!**

_For detailed technical documentation, see [ARCHITECTURE.md](ARCHITECTURE.md) (coming soon)_

_For design guidelines, see [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) (exists)_
