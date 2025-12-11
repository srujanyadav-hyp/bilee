# 🧾 BILEE - Complete Project Understanding Prompt

## 📋 Project Overview

**BILEE** is a paperless billing system built with Flutter that enables merchants to create digital receipts and customers to receive them instantly via QR code scanning. This eliminates paper waste, reduces merchant costs, and provides digital storage for both parties.

### Core Concept:
1. **Merchant** creates a billing session with items
2. **QR Code** is generated for the session
3. **Customer** scans QR code to view and save receipt
4. **Both** retain digital records (merchant: sales history, customer: purchase history)

### Technology Stack:
- **Flutter 3.10.1** - Cross-platform framework (Android, iOS, Web)
- **Firebase Authentication** - Email, Phone (OTP), Google Sign-In
- **Cloud Firestore** - Real-time NoSQL database
- **go_router 14.7.0** - Declarative routing with deep linking
- **Provider 6.1.1** - State management pattern
- **qr_flutter & mobile_scanner** - QR generation and scanning
- **intl** - Number formatting, currency, date/time

---

## 🏗️ Complete Folder Structure

### Root Level Files:
```
bilee/
├── lib/                          # Main application code
├── android/                      # Android platform code
├── ios/                          # iOS platform code
├── web/                          # Web platform code
├── windows/linux/macos/          # Desktop platform code
├── test/                         # Test files
├── pubspec.yaml                  # Dependencies and project config
├── analysis_options.yaml         # Linter rules
├── README.md                     # Complete project documentation
└── prompt.md                     # This file (project understanding guide)
```

### lib/ Directory Structure (Feature-Based Architecture):

```
lib/
├── main.dart                     # App entry point, Firebase initialization, go_router setup
│
├── core/                         # Shared utilities across features
│   ├── constants/
│   │   ├── app_colors.dart       # ✅ ALL COLORS - NEVER HARDCODE COLORS
│   │   ├── app_dimensions.dart   # ✅ ALL SPACING/SIZES - NEVER HARDCODE DIMENSIONS
│   │   └── app_typography.dart   # ✅ ALL TEXT STYLES - NEVER HARDCODE TEXT STYLES
│   │
│   ├── theme/
│   │   └── app_theme.dart        # Material theme using app_colors.dart
│   │
│   ├── utils/
│   │   ├── validators.dart       # Email, phone, GST validation functions
│   │   ├── formatters.dart       # Currency, date formatting
│   │   └── analytics_helper.dart # Analytics event tracking
│   │
│   └── widgets/
│       ├── custom_button.dart    # Reusable elevated button
│       ├── custom_text_field.dart # Reusable text input field
│       ├── loading_widget.dart   # Circular progress indicator
│       └── error_widget.dart     # Error message display
│
├── features/                     # Feature modules (Clean Architecture)
│   │
│   ├── authentication/           # User login, register, OTP
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── user_model.dart           # User data model (fromFirestore/toFirestore)
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart      # Firebase Auth operations
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart          # Business logic user entity
│   │   │   └── repositories/
│   │   │       └── auth_repository_interface.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart        # Authentication state management
│   │       └── pages/
│   │           ├── login_screen.dart         # Email, Phone, Google login
│   │           ├── register_screen.dart      # New user registration
│   │           ├── otp_screen.dart           # Phone OTP verification
│   │           └── forgot_password_screen.dart
│   │
│   ├── onboarding/               # Role selection (Merchant/Customer)
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── onboarding_provider.dart
│   │       └── pages/
│   │           ├── role_selection_screen.dart     # Choose Merchant or Customer
│   │           └── merchant_onboarding_screen.dart # Business details form
│   │
│   ├── merchant/                 # Merchant-specific features
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── item_model.dart           # Product/Service model
│   │   │   │   ├── session_model.dart        # Billing session model
│   │   │   │   └── daily_aggregate_model.dart # Daily sales summary
│   │   │   └── repositories/
│   │   │       ├── item_repository.dart      # CRUD operations for items
│   │   │       ├── session_repository.dart   # Session management
│   │   │       └── aggregate_repository.dart # Daily summary calculations
│   │   │
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── item_provider.dart        # Item library state
│   │       │   ├── session_provider.dart     # Active session state
│   │       │   └── daily_aggregate_provider.dart # Daily summary state
│   │       │
│   │       └── pages/
│   │           ├── merchant_home_page.dart   # Dashboard with 4 cards (navigation)
│   │           ├── item_library_page.dart    # View/Add/Edit/Delete items
│   │           ├── start_billing_page.dart   # Create session with item selection
│   │           ├── live_session_page.dart    # Active session with QR code
│   │           ├── daily_summary_page.dart   # Sales analytics for today
│   │           └── merchant_profile_page.dart # Business profile edit
│   │
│   └── customer/                 # Customer-specific features (40% complete)
│       └── presentation/
│           └── pages/
│               ├── customer_home_page.dart   # Customer dashboard (basic)
│               ├── qr_scanner_page.dart      # TO BE IMPLEMENTED
│               ├── receipt_view_page.dart    # TO BE IMPLEMENTED
│               └── receipt_history_page.dart # TO BE IMPLEMENTED
│
└── routes/
    └── app_router.dart           # go_router configuration (all routes defined)
```

---

## 🎨 Design System (CRITICAL - NEVER HARDCODE!)

### ✅ How to Access Global Constants:

#### **Colors** - `lib/core/constants/app_colors.dart`
```dart
import 'package:bilee/core/constants/app_colors.dart';

// ✅ CORRECT - Use global colors
Container(
  color: AppColors.primaryBlue,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)

// ❌ WRONG - Never hardcode colors
Container(
  color: Color(0xFF2196F3),  // ❌ DON'T DO THIS!
  child: Text(
    'Hello',
    style: TextStyle(color: Colors.black),  // ❌ DON'T DO THIS!
  ),
)
```

**Available Colors:**
```dart
class AppColors {
  // Primary Colors
  static const primaryBlue = Color(0xFF2196F3);
  static const primaryGreen = Color(0xFF4CAF50);
  static const primaryOrange = Color(0xFFFF9800);
  static const primaryRed = Color(0xFFF44336);
  
  // Text Colors
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFF9E9E9E);
  
  // Background Colors
  static const backgroundLight = Color(0xFFFAFAFA);
  static const backgroundWhite = Color(0xFFFFFFFF);
  static const cardBackground = Color(0xFFFFFFFF);
  
  // Accent Colors
  static const accentYellow = Color(0xFFFFC107);
  static const accentPurple = Color(0xFF9C27B0);
  
  // Status Colors
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFF44336);
  static const warning = Color(0xFFFF9800);
  static const info = Color(0xFF2196F3);
  
  // Border Colors
  static const border = Color(0xFFE0E0E0);
  static const divider = Color(0xFFBDBDBD);
}
```

---

#### **Spacing & Dimensions** - `lib/core/constants/app_dimensions.dart`
```dart
import 'package:bilee/core/constants/app_dimensions.dart';

// ✅ CORRECT - Use global dimensions
Padding(
  padding: EdgeInsets.all(AppDimensions.paddingMedium),
  child: Container(
    height: AppDimensions.buttonHeight,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
    ),
  ),
)

// ❌ WRONG - Never hardcode dimensions
Padding(
  padding: EdgeInsets.all(16.0),  // ❌ DON'T DO THIS!
  child: Container(
    height: 56.0,  // ❌ DON'T DO THIS!
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8.0),  // ❌ DON'T DO THIS!
    ),
  ),
)
```

**Available Dimensions:**
```dart
class AppDimensions {
  // Spacing (use these for padding, margin, gaps)
  static const spacingXS = 4.0;
  static const spacingS = 8.0;
  static const spacingM = 12.0;
  static const spacingMedium = 16.0;
  static const spacingL = 20.0;
  static const spacingXL = 24.0;
  static const spacingXXL = 32.0;
  static const spacingXXXL = 48.0;
  
  // Padding (specific padding values)
  static const paddingSmall = 8.0;
  static const paddingMedium = 16.0;
  static const paddingLarge = 24.0;
  static const paddingXL = 32.0;
  
  // Border Radius
  static const borderRadiusSmall = 4.0;
  static const borderRadiusMedium = 8.0;
  static const borderRadiusLarge = 12.0;
  static const borderRadiusXL = 16.0;
  static const borderRadiusCircular = 100.0;
  
  // Component Sizes
  static const buttonHeight = 56.0;
  static const buttonHeightSmall = 40.0;
  static const iconSize = 24.0;
  static const iconSizeSmall = 20.0;
  static const iconSizeLarge = 32.0;
  
  // AppBar
  static const appBarHeight = 56.0;
  
  // Card
  static const cardElevation = 2.0;
  static const cardPadding = 16.0;
}
```

---

#### **Typography** - `lib/core/constants/app_typography.dart`
```dart
import 'package:bilee/core/constants/app_typography.dart';

// ✅ CORRECT - Use global text styles
Text(
  'Heading',
  style: AppTypography.headingLarge,
)

Text(
  'Body text',
  style: AppTypography.bodyMedium,
)

// ❌ WRONG - Never hardcode text styles
Text(
  'Heading',
  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),  // ❌ DON'T DO THIS!
)

Text(
  'Body text',
  style: TextStyle(fontSize: 16),  // ❌ DON'T DO THIS!
)
```

**Available Text Styles:**
```dart
class AppTypography {
  // Font Families
  static const String fontFamilyPrimary = 'Poppins';
  static const String fontFamilySecondary = 'Inter';
  
  // Headings (Poppins - Bold)
  static const headingLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const headingMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const headingSmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  // Body Text (Inter - Regular)
  static const bodyLarge = TextStyle(
    fontFamily: fontFamilySecondary,
    fontSize: 18.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const bodyMedium = TextStyle(
    fontFamily: fontFamilySecondary,
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const bodySmall = TextStyle(
    fontFamily: fontFamilySecondary,
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  // Captions & Labels
  static const caption = TextStyle(
    fontFamily: fontFamilySecondary,
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
  );
  
  static const label = TextStyle(
    fontFamily: fontFamilySecondary,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // Button Text
  static const button = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.backgroundWhite,
  );
}
```

---

## 📚 Code Organization & Logic

### 1. **Feature-Based Architecture (Clean Architecture)**

Each feature follows this structure:

```
feature_name/
├── data/                  # External data sources
│   ├── models/           # Data models with Firestore conversion
│   └── repositories/     # Data fetching/storing logic
├── domain/               # Business logic (entities, use cases)
│   ├── entities/
│   └── repositories/
└── presentation/         # UI layer
    ├── providers/        # State management (ChangeNotifier)
    └── pages/           # Screen widgets
```

**Flow:** `UI (Pages) → Provider → Repository → Firestore`

---

### 2. **State Management - Provider Pattern**

**Example:** `item_provider.dart`

```dart
class ItemProvider extends ChangeNotifier {
  final ItemRepository _repository;
  List<ItemModel> _items = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Methods
  Future<void> fetchItems(String merchantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();  // ✅ Update UI

    try {
      _items = await _repository.getItems(merchantId);
      _isLoading = false;
      notifyListeners();  // ✅ Update UI
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();  // ✅ Update UI
    }
  }

  Future<void> addItem(ItemModel item) async {
    await _repository.createItem(item);
    await fetchItems(item.merchantId);  // Refresh list
  }
}
```

**How to Use in UI:**

```dart
// Provide at top level (main.dart or route)
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ItemProvider(ItemRepository())),
  ],
)

// Consume in widget
Consumer<ItemProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) return LoadingWidget();
    if (provider.error != null) return ErrorWidget(provider.error!);
    return ListView.builder(
      itemCount: provider.items.length,
      itemBuilder: (context, index) => ItemCard(provider.items[index]),
    );
  },
)
```

---

### 3. **Navigation - go_router**

**All routes defined in:** `lib/routes/app_router.dart`

```dart
final goRouter = GoRouter(
  initialLocation: '/role-selection',
  routes: [
    // Auth routes
    GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => RegisterScreen()),
    GoRoute(path: '/otp', builder: (context, state) => OtpScreen()),
    
    // Onboarding
    GoRoute(path: '/role-selection', builder: (context, state) => RoleSelectionScreen()),
    GoRoute(path: '/merchant-onboarding', builder: (context, state) => MerchantOnboardingScreen()),
    
    // Merchant routes
    GoRoute(
      path: '/merchant/:merchantId',
      builder: (context, state) {
        final merchantId = state.pathParameters['merchantId']!;
        return MerchantHomePage(merchantId: merchantId);
      },
      routes: [
        GoRoute(path: 'profile', builder: (context, state) => MerchantProfilePage()),
        GoRoute(path: 'items', builder: (context, state) => ItemLibraryPage()),
        GoRoute(path: 'billing', builder: (context, state) => StartBillingPage()),
        GoRoute(path: 'summary', builder: (context, state) => DailySummaryPage()),
        GoRoute(
          path: 'session/:sessionId',
          builder: (context, state) {
            final sessionId = state.pathParameters['sessionId']!;
            return LiveSessionPage(sessionId: sessionId);
          },
        ),
      ],
    ),
    
    // Customer routes
    GoRoute(
      path: '/customer/:customerId',
      builder: (context, state) {
        final customerId = state.pathParameters['customerId']!;
        return CustomerHomePage(customerId: customerId);
      },
    ),
  ],
);
```

**Navigation Rules:**

```dart
// ✅ PRIMARY NAVIGATION - Updates URL in browser
context.go('/merchant/$merchantId/items');

// ✅ MODAL/OVERLAY - Maintains URL (for dialogs, bottom sheets)
context.push('/item-details');

// ✅ GO BACK
context.pop();

// ❌ NEVER use Navigator.push() - we use go_router only!
```

---

### 4. **Firebase Integration**

#### **Firestore Structure:**

```
firestore/
├── users/
│   └── {userId}/                    # Document ID = Firebase Auth UID
│       ├── email: string
│       ├── name: string
│       ├── phone: string
│       ├── role: 'merchant' | 'customer'
│       ├── createdAt: timestamp
│       └── (merchant fields if role=merchant)
│           ├── businessName: string
│           ├── gstin: string
│           ├── address: string
│
├── items/
│   └── {itemId}/                    # Auto-generated ID
│       ├── merchantId: string       # References users/{userId}
│       ├── name: string
│       ├── price: number
│       ├── gstPercentage: number
│       ├── hsnCode: string
│       ├── category: string
│       ├── stock: number
│       ├── isActive: boolean
│       └── createdAt: timestamp
│
├── sessions/
│   └── {sessionId}/                 # Auto-generated ID
│       ├── merchantId: string
│       ├── items: array of {itemId, name, price, quantity, gst, total}
│       ├── subtotal: number
│       ├── totalGst: number
│       ├── grandTotal: number
│       ├── status: 'active' | 'completed' | 'cancelled'
│       ├── createdAt: timestamp
│       ├── completedAt: timestamp
│       └── scannedBy: string (customerId) when scanned
│
└── daily_aggregates/
    └── {merchantId}/
        └── {date}/                  # Format: YYYY-MM-DD
            ├── totalSales: number
            ├── totalGst: number
            ├── sessionCount: number
            ├── itemsSold: number
            ├── topItems: array
            └── updatedAt: timestamp
```

#### **Firestore Security Rules:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    function isMerchant(merchantId) {
      return isSignedIn() && request.auth.uid == merchantId;
    }
    
    // Users collection - user can only access their own data
    match /users/{userId} {
      allow read, write: if isOwner(userId);
      allow create: if isSignedIn() && request.auth.uid == userId;
    }
    
    // Items collection - merchant can only manage their own items
    match /items/{itemId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && isMerchant(request.resource.data.merchantId);
      allow update, delete: if isMerchant(resource.data.merchantId);
    }
    
    // Sessions collection
    match /sessions/{sessionId} {
      allow read: if isSignedIn();
      allow create, update: if isMerchant(request.resource.data.merchantId);
      allow delete: if isMerchant(resource.data.merchantId);
    }
    
    // Daily aggregates - merchant only
    match /daily_aggregates/{merchantId}/{date} {
      allow read, write: if isMerchant(merchantId);
    }
  }
}
```

#### **Data Models (Example: ItemModel):**

```dart
class ItemModel {
  final String id;
  final String merchantId;
  final String name;
  final double price;
  final double gstPercentage;
  final String hsnCode;
  final String category;
  final int stock;
  final bool isActive;
  final DateTime createdAt;

  ItemModel({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.price,
    required this.gstPercentage,
    required this.hsnCode,
    required this.category,
    required this.stock,
    required this.isActive,
    required this.createdAt,
  });

  // ✅ REQUIRED: Convert Firestore document to model
  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: doc.id,
      merchantId: data['merchantId'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      gstPercentage: (data['gstPercentage'] ?? 0).toDouble(),
      hsnCode: data['hsnCode'] ?? '',
      category: data['category'] ?? '',
      stock: data['stock'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // ✅ REQUIRED: Convert model to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'merchantId': merchantId,
      'name': name,
      'price': price,
      'gstPercentage': gstPercentage,
      'hsnCode': hsnCode,
      'category': category,
      'stock': stock,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
```

---

### 5. **Error Handling & User Feedback**

**✅ MANDATORY Pattern:**

```dart
Future<void> someAsyncOperation() async {
  _isLoading = true;
  _error = null;
  notifyListeners();  // Show loading state

  try {
    // Do operation
    final result = await _repository.doSomething();
    _data = result;
    _isLoading = false;
    notifyListeners();  // Show success state
    
    // Show success message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Operation successful!'),
        backgroundColor: AppColors.success,
      ),
    );
    
  } catch (e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();  // Show error state
    
    // Show error message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
```

**UI States to Handle:**

1. **Loading:** Show `CircularProgressIndicator`
2. **Empty:** Show "No data available" message
3. **Error:** Show error message with retry button
4. **Success:** Show data

---

## ✅ What Has Been Implemented (75% Complete)

### 🟢 100% Complete:
1. **Authentication System**
   - Email/Password login & registration
   - Phone OTP verification
   - Google Sign-In
   - Password reset
   - Session persistence

2. **Onboarding Flow**
   - Role selection (Merchant/Customer)
   - Merchant business details form
   - Data validation & storage

3. **Navigation System**
   - go_router setup with all routes
   - Deep linking support
   - URL updates correctly
   - Back button handling

### 🟡 90-95% Complete:
4. **Merchant Dashboard**
   - 4-card navigation layout
   - Profile, Items, Billing, Summary access
   - Analytics display (today's sales)
   - Beautiful UI with gradients

5. **Item Library Management**
   - Add/Edit/Delete items
   - Item categories
   - GST & HSN code support
   - Stock tracking
   - Search & filter

6. **Billing Session Creation**
   - Modern grid layout (2 columns)
   - Search functionality
   - Beautiful item cards with gradients
   - Professional cart design
   - Quantity controls
   - Tax calculation
   - Session creation

7. **Live Session & QR**
   - QR code generation
   - Session details display
   - Real-time updates
   - Complete/Cancel session
   - Timer display

8. **Daily Summary**
   - Today's sales metrics
   - Total revenue, GST, sessions
   - Items sold count
   - Basic analytics

9. **Merchant Profile**
   - Business information display
   - Edit business details
   - GST & address management

### 🔴 40% Complete:
10. **Customer Module**
    - Basic customer home page
    - **NEEDS:** QR scanner, receipt viewing, history

---

## 🚧 What Needs to Be Done

### **Priority 1: Critical (2-3 weeks)**

#### 1. **Customer QR Scanner** (3-4 days)
```dart
// File: lib/features/customer/presentation/pages/qr_scanner_page.dart

// Tasks:
- Integrate mobile_scanner package
- Build camera preview UI
- Detect QR code and extract sessionId
- Navigate to receipt view
- Handle permissions (camera access)
- Error handling (invalid QR, no camera)
```

#### 2. **Receipt Viewing** (2-3 days)
```dart
// File: lib/features/customer/presentation/pages/receipt_view_page.dart

// Tasks:
- Fetch session data from Firestore using sessionId
- Display merchant info, items, prices
- Calculate subtotal, GST, total
- Beautiful receipt UI (like a bill)
- Save to customer's history
- Share functionality (PDF/Image)
```

#### 3. **Receipt History** (3-4 days)
```dart
// File: lib/features/customer/presentation/pages/receipt_history_page.dart

// Tasks:
- Create 'customer_receipts' collection in Firestore
- Store scanned receipts with timestamp
- List view of all receipts (date sorted)
- Search & filter (by merchant, date, amount)
- Tap to view full receipt
- Delete functionality
```

#### 4. **Firestore Security Rules Update**
```javascript
// Add to firestore.rules

match /customer_receipts/{customerId}/{receiptId} {
  allow read, write: if isOwner(customerId);
}
```

---

### **Priority 2: Important (2 weeks)**

#### 5. **Analytics Dashboard** (1 week)
```dart
// File: lib/features/merchant/presentation/pages/analytics_page.dart

// Tasks:
- Install fl_chart package
- Revenue trend graph (last 7/30 days)
- Top 5 selling items (bar chart)
- GST breakdown (pie chart)
- Month-over-month comparison
- Export as PDF/Excel
```

#### 6. **Notifications** (3-4 days)
```dart
// Tasks:
- Firebase Cloud Messaging setup
- Send notification when customer scans QR
- Daily summary notification
- Low stock alerts
```

#### 7. **Offline Support** (1 week)
```dart
// Tasks:
- Setup Hive/Drift for local database
- Cache items, sessions offline
- Queue operations when offline
- Sync when back online
- Conflict resolution
```

---

### **Priority 3: Nice-to-Have (1-2 weeks)**

8. **Payment Integration** (Razorpay/Stripe)
9. **Multiple Staff Accounts** (per merchant)
10. **Inventory Management** (stock alerts, reorder)
11. **Customer Loyalty** (points, discounts)
12. **Reports Export** (PDF, Excel, CSV)

---

## 🔒 Development Rules (STRICTLY FOLLOW)

### **1. Code Organization**
✅ Always use feature-based structure  
✅ File naming: snake_case (e.g., `merchant_home_page.dart`)  
✅ Class naming: PascalCase (e.g., `MerchantHomePage`)  
✅ Variable naming: camelCase (e.g., `merchantId`)

### **2. Design System Compliance**
✅ **NEVER** hardcode colors - use `AppColors.*`  
✅ **NEVER** hardcode dimensions - use `AppDimensions.*`  
✅ **NEVER** hardcode text styles - use `AppTypography.*`  
✅ **ALWAYS** check these files first before adding any UI

### **3. State Management**
✅ Use Provider pattern only  
✅ Extend ChangeNotifier for providers  
✅ Call `notifyListeners()` after state changes  
✅ No setState() in pages - use Consumer/Provider.of

### **4. Navigation**
✅ Use go_router only (`context.go()`, `context.push()`)  
✅ **NEVER** use `Navigator.push()`  
✅ `context.go()` for primary navigation (updates URL)  
✅ `context.push()` for modals/dialogs only

### **5. Firebase Rules**
✅ All Firestore operations MUST have security rules  
✅ Validate user ownership on server (Firestore rules)  
✅ Never trust client-side validation alone  
✅ Use helper functions in rules (isOwner, isMerchant)

### **6. Error Handling**
✅ All async operations MUST have try-catch  
✅ Show loading states (`_isLoading = true`)  
✅ Show error states (`_error = message`)  
✅ Show success feedback (SnackBar)  
✅ Handle empty states ("No data" message)

### **7. Data Models**
✅ All Firestore models MUST have `fromFirestore()` factory  
✅ All Firestore models MUST have `toFirestore()` method  
✅ Use Timestamp for dates (convert to DateTime in model)  
✅ Validate data in model constructors

### **8. Code Quality**
✅ Keep files under 500 lines (split if larger)  
✅ Add comments for complex logic  
✅ Use meaningful variable names  
✅ Extract repeated widgets to separate files  
✅ Use const constructors where possible

### **9. Testing** (To be enforced)
✅ Write unit tests for providers  
✅ Write widget tests for UI  
✅ Test error scenarios  
✅ Aim for >80% code coverage

### **10. Git Commits**
✅ Format: `type(scope): subject`  
✅ Examples:  
   - `feat(auth): add google sign-in`  
   - `fix(billing): correct tax calculation`  
   - `refactor(items): extract item card widget`  
   - `docs(readme): update setup instructions`

---

## 🎯 How to Approach New Features

### Step-by-Step Process:

1. **Understand Requirements**
   - What does the feature do?
   - Who is it for? (Merchant/Customer)
   - What data is needed?

2. **Design Data Model**
   - What fields are required?
   - What Firestore collection?
   - Create model with fromFirestore/toFirestore

3. **Setup Firestore Rules**
   - Who can read this data?
   - Who can write this data?
   - Add validation rules

4. **Create Repository**
   - CRUD operations (Create, Read, Update, Delete)
   - Error handling
   - Return proper types

5. **Create Provider**
   - Extend ChangeNotifier
   - Add state variables (_data, _isLoading, _error)
   - Add methods that call repository
   - Call notifyListeners() after state changes

6. **Build UI (Page)**
   - Import design system constants
   - Use Consumer<YourProvider>
   - Handle loading/error/empty states
   - Use global colors/dimensions/typography
   - Add navigation using go_router

7. **Add Route**
   - Update app_router.dart
   - Define path with parameters
   - Test navigation

8. **Test**
   - Test happy path (success case)
   - Test error cases
   - Test edge cases (empty data, invalid input)
   - Test offline behavior

9. **Update Documentation**
   - Update README.md
   - Update this prompt.md if needed
   - Add comments in complex code

---

## 📊 Implementation Status Table

| Module | Completion | Time to Complete | Priority |
|--------|-----------|------------------|----------|
| Authentication | 100% | ✅ Done | - |
| Onboarding | 100% | ✅ Done | - |
| Navigation | 100% | ✅ Done | - |
| Merchant Dashboard | 95% | 1 day (polish) | Medium |
| Item Library | 90% | 2 days (categories, filters) | Medium |
| Billing Session | 95% | 1 day (UI polish) | Low |
| Live Session/QR | 90% | 2 days (timer, notifications) | Medium |
| Daily Summary | 85% | 3 days (charts, export) | Medium |
| Merchant Profile | 90% | 2 days (edit, validation) | Low |
| **Customer QR Scanner** | 0% | **3-4 days** | **HIGH** |
| **Receipt Viewing** | 0% | **2-3 days** | **HIGH** |
| **Receipt History** | 0% | **3-4 days** | **HIGH** |
| Analytics Dashboard | 0% | 1 week | Medium |
| Offline Support | 0% | 1 week | Medium |
| Notifications | 0% | 3-4 days | Medium |
| Payment Gateway | 0% | 1 week | Low |

---

## 🚀 Quick Start Commands

```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build for release (Android)
flutter build apk --release

# Build for release (iOS)
flutter build ios --release

# Run tests
flutter test

# Check code quality
flutter analyze
```

---

## 📖 Key Files to Reference

### **For Design (Colors, Spacing, Text):**
- `lib/core/constants/app_colors.dart`
- `lib/core/constants/app_dimensions.dart`
- `lib/core/constants/app_typography.dart`

### **For Navigation:**
- `lib/routes/app_router.dart`

### **For State Management Examples:**
- `lib/features/merchant/presentation/providers/item_provider.dart`
- `lib/features/merchant/presentation/providers/session_provider.dart`

### **For UI Examples:**
- `lib/features/merchant/presentation/pages/start_billing_page.dart` (Modern UI)
- `lib/features/merchant/presentation/pages/merchant_home_page.dart` (Dashboard)

### **For Data Models:**
- `lib/features/merchant/data/models/item_model.dart`
- `lib/features/merchant/data/models/session_model.dart`

### **For Repository Pattern:**
- `lib/features/merchant/data/repositories/item_repository.dart`

---

## 🎓 Learning Resources

### **Flutter Concepts:**
- State Management: Provider pattern with ChangeNotifier
- Navigation: go_router declarative routing
- Firebase: Authentication, Firestore, Security Rules
- UI: Material Design 3, Custom widgets

### **Best Practices:**
- Clean Architecture (separation of concerns)
- DRY (Don't Repeat Yourself)
- KISS (Keep It Simple, Stupid)
- Single Responsibility Principle

---

## ⚠️ Common Mistakes to Avoid

❌ **Hardcoding colors/dimensions/text styles** → Use global constants  
❌ **Using Navigator.push()** → Use context.go() from go_router  
❌ **No error handling** → Always use try-catch  
❌ **No loading states** → Show progress indicators  
❌ **setState in pages** → Use Provider + notifyListeners  
❌ **Missing Firestore rules** → Always validate on server  
❌ **Large files (>500 lines)** → Split into smaller files  
❌ **No comments on complex logic** → Document your code  
❌ **Trusting client validation** → Validate on server too  
❌ **Forgetting to update README** → Keep docs current  

---

## 📝 Summary

**BILEE is a paperless billing app built with Flutter + Firebase.** It's 75% complete with merchant features fully functional. The customer module needs implementation (QR scanner, receipt viewing, history).

**Key principles:**
1. ✅ Use global design system (AppColors, AppDimensions, AppTypography)
2. ✅ Follow feature-based architecture (data/domain/presentation)
3. ✅ Use Provider for state management
4. ✅ Use go_router for navigation
5. ✅ Always handle errors and show user feedback
6. ✅ Secure with Firestore rules
7. ✅ Keep code clean and documented

**Next steps:**
- Implement customer QR scanner (Priority 1)
- Build receipt viewing interface
- Create receipt history page
- Add analytics dashboard
- Implement offline support
- Add notifications

---

**This document is your complete guide to understanding and continuing BILEE development. Read it carefully before writing any code!** 🚀
