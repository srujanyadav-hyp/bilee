# 🎯 Permanent QR Code Receipt System - Version 1.0

> **Status:** Planned for Version 1.0  
> **Current Version:** 0.x (Session-based QR)  
> **Last Updated:** December 13, 2025

---

## 📋 Overview

Currently (v0.x), BILEE generates a **unique QR code for each billing session**. In Version 1.0, we plan to implement a **permanent QR code system** where merchants have ONE QR code that customers can scan to retrieve their receipts.

---

## 🎨 Current System (v0.x)

### Flow:
```
Merchant → Start Billing Session
         ↓
    Generate Unique QR Code
         ↓
    Customer Scans QR
         ↓
    Direct Receipt Display
```

### Issues:
- ❌ New QR code for every session
- ❌ Merchant must generate QR each time
- ❌ Cannot reuse QR codes
- ✅ But: Direct access, no customer input needed

---

## 🚀 Planned System (v1.0)

### Flow:
```
Merchant Registration
    ↓
Generate ONE Permanent QR Code
    ↓
Print & Display at Counter (Forever)
    ↓
Customer Scans QR → Opens App/Web
    ↓
Customer Enters Phone Number
    ↓
System Matches: merchantId + phone
    ↓
Shows Receipt
```

---

## 🔑 Key Components

### 1. **Permanent QR Code**
```
QR Code Contains:
https://bilee.app/receipt/[merchantId]

Example:
https://bilee.app/receipt/abc123xyz456

NOT INCLUDED IN QR:
- Session ID
- Customer details
- Receipt data
- Timestamp
```

### 2. **Customer Lookup Page**
```
URL: /receipt/[merchantId]

UI:
┌─────────────────────────────────────┐
│  📱 Ravi Store's Receipt            │
├─────────────────────────────────────┤
│                                     │
│  Enter Your Details:                │
│                                     │
│  📱 Phone Number                    │
│  [+91 __________]                   │
│                                     │
│  💳 Receipt Number (Optional)       │
│  [#RC_______]                       │
│                                     │
│  [Show My Receipt] 🔍               │
│                                     │
│  Hint: Use the phone number you     │
│  provided during checkout           │
└─────────────────────────────────────┘
```

### 3. **Database Query**
```dart
// Primary lookup: Phone Number
Firestore
  .collection('receipts')
  .where('merchantId', '==', merchantId)
  .where('customerPhone', '==', enteredPhone)
  .where('createdAt', '>=', todayStart)
  .orderBy('createdAt', descending: true)
  .limit(10)
  .get()

// Secondary lookup: Receipt ID
Firestore
  .collection('receipts')
  .where('merchantId', '==', merchantId)
  .where('receiptId', '==', receiptNumber)
  .get()
```

---

## 📊 Unique Identifiers for Lookup

### **Primary Identifier: Phone Number** ⭐⭐⭐⭐⭐
```
Field: customerPhone
Format: +919876543210
Unique: Semi-unique (rare duplicates)
Storage: String

✅ Advantages:
- Easy to remember
- Already collected at checkout
- Natural for Indian market
- Can verify with OTP if needed
- Everyone has a phone

❌ Disadvantages:
- Typo errors possible
- Rare duplicate customers
```

### **Secondary Identifier: Receipt ID** ⭐⭐⭐⭐
```
Field: receiptId
Format: #RC12345 or RC12345
Unique: 100% unique
Storage: String

✅ Advantages:
- Guaranteed unique
- Short format (6-8 chars)
- Good for disputes

❌ Disadvantages:
- Customer must note it down
- Easy to forget
- Not natural
```

### **Tertiary Options (Fallback):**
```
1. Email: customerEmail
   - Not everyone remembers
   - Longer to type
   - Rating: 6/10

2. Customer Name + Phone Last 4:
   - "Ravi + 3210"
   - Fuzzy matching needed
   - Rating: 7/10

3. Session ID:
   - Too technical
   - Not customer-friendly
   - Rating: 2/10
```

---

## 🗂️ Data Model Requirements

### Receipt Entity Updates:
```dart
class ReceiptEntity {
  final String id;
  final String merchantId;
  final String sessionId;
  
  // NEW FIELDS FOR v1.0:
  final String? customerId;          // Firebase UID (if logged in)
  final String? customerPhone;       // Primary lookup key
  final String? customerEmail;       // Secondary lookup
  final String customerName;         // Display only
  final String receiptId;            // Unique receipt number (e.g., #RC12345)
  
  // Existing fields:
  final List<ReceiptItem> items;
  final double billTotal;
  final double paidAmount;
  final double pendingAmount;
  final DateTime createdAt;
  final PaymentEntity? payment;
}
```

### Firestore Indexes Required:
```
Collection: receipts

Composite Indexes:
1. merchantId + customerPhone + createdAt (DESC)
2. merchantId + receiptId
3. merchantId + customerEmail + createdAt (DESC)
4. merchantId + createdAt (DESC) // For merchant's view

Single Field Indexes:
- merchantId
- customerPhone
- receiptId
- customerEmail
```

---

## 🔄 User Flow Comparison

### Scenario: Customer wants to view receipt

#### **Current (v0.x):**
```
1. Merchant generates session QR
2. Customer scans QR
3. Receipt displayed immediately
   
Steps: 2
Time: ~5 seconds
```

#### **Planned (v1.0):**
```
1. Customer scans permanent QR at counter
2. App opens → Shows input screen
3. Customer enters phone: 9876543210
4. Customer taps "Show Receipt"
5. System searches & displays receipt
   
Steps: 4
Time: ~15 seconds
```

### **Trade-off Analysis:**
- **Merchant:** Easier (one-time QR setup)
- **Customer:** Extra step (enter phone)
- **Scalability:** Better (multiple customers simultaneously)
- **Privacy:** Better (phone verification)

---

## 🛠️ Technical Implementation Plan

### Phase 1: Backend Setup
```
1. Update ReceiptEntity model
   - Add customerPhone field
   - Add receiptId field (auto-generated)
   
2. Create Firestore indexes
   - merchantId + customerPhone + createdAt
   - merchantId + receiptId
   
3. Update receipt creation logic
   - Capture customer phone at checkout
   - Generate unique receiptId
   - Save with proper indexing
```

### Phase 2: QR Generation
```
1. Merchant Profile Page
   - Add "Generate Permanent QR" button
   - QR contains: https://bilee.app/receipt/[merchantId]
   - Download/Print options
   
2. QR Code Display Options
   - Download PNG/PDF
   - Print directly
   - Share via WhatsApp/Email
```

### Phase 3: Customer Receipt Page
```
1. Create route: /receipt/:merchantId
   
2. Build UI:
   - Merchant name/logo display
   - Phone number input (primary)
   - Receipt ID input (secondary)
   - Smart detection (auto-identify input type)
   
3. Search Logic:
   - Try phone first
   - Fallback to receipt ID
   - Show multiple receipts if found
   - Handle "Not Found" gracefully
```

### Phase 4: Advanced Features
```
1. Receipt History
   - Show last 5 receipts
   - Filter by date
   - Download/Share receipt
   
2. Smart Input
   - Auto-detect phone vs receipt ID
   - Format phone number (+91)
   - Suggestions for partial matches
   
3. Verification
   - Optional OTP for sensitive data
   - Security for high-value receipts
```

---

## 📱 Multiple Customers Support

### Problem:
```
10:00 AM - Customer A billing (phone: 9876543210)
10:02 AM - Customer B billing (phone: 9988776655)
10:03 AM - Both scan same permanent QR
```

### Solution:
```
Customer A scans → Enters 9876543210 → Sees A's receipt
Customer B scans → Enters 9988776655 → Sees B's receipt

✅ No confusion
✅ No session conflicts
✅ Privacy maintained
```

---

## 🔒 Security Considerations

### 1. **Privacy Protection**
```
❌ Problem: Anyone can scan merchant's QR
✅ Solution: Requires customer phone to view receipt

If wrong person scans:
- Cannot see others' receipts without their phone number
- Natural security layer
```

### 2. **Data Protection**
```
Optional Enhancements:
1. OTP Verification
   - For receipts > ₹10,000
   - Send OTP to customer phone
   - Verify before showing receipt

2. Time-based Access
   - Receipts older than 30 days require OTP
   - Recent receipts (today) no OTP needed

3. Attempt Limiting
   - Max 3 wrong phone attempts
   - Rate limiting per device
```

### 3. **GDPR Compliance**
```
- Customer phone stored with consent
- Deletable by customer request
- Anonymous after 90 days (optional)
```

---

## ⚠️ Potential Issues & Solutions

### Issue 1: Customer Forgot Phone Number
```
Problem: "I don't remember which number I gave"

Solutions:
1. Show hint: "Last 4 digits: XXXX3210"
2. Merchant lookup: Search by name
3. Receipt ID fallback
4. Call merchant for help
```

### Issue 2: Typo in Phone Number
```
Problem: Customer types 9876543211 instead of 9876543210

Solutions:
1. Fuzzy matching (similar numbers)
2. "Did you mean: 9876543210?"
3. Try again prompt
4. Receipt ID option
```

### Issue 3: Multiple Receipts Found
```
Problem: Same customer, same merchant, multiple visits

Solution:
Show list with timestamps:
┌─────────────────────────────────┐
│ Found 3 receipts:               │
├─────────────────────────────────┤
│ 1. Today 10:30 AM - ₹1,250     │
│ 2. Yesterday 5:00 PM - ₹890    │
│ 3. Dec 10, 3:00 PM - ₹2,100    │
└─────────────────────────────────┘
Customer selects which one
```

### Issue 4: Timing Lag
```
Problem: Customer scans before merchant saves receipt

Solutions:
1. Show "Please wait, billing in progress..."
2. Auto-refresh every 5 seconds
3. Manual refresh button
4. Expected completion time display
```

---

## 🎨 UI/UX Mockups

### Mobile View:
```
┌───────────────────────────────────┐
│ ← Back          Ravi Store    🏪  │
├───────────────────────────────────┤
│                                   │
│        View Your Receipt          │
│                                   │
│  📱 Enter Phone Number            │
│  ┌─────────────────────────────┐ │
│  │ +91 |                       │ │
│  └─────────────────────────────┘ │
│                                   │
│  ──────────── OR ────────────     │
│                                   │
│  🧾 Enter Receipt Number          │
│  ┌─────────────────────────────┐ │
│  │ #RC                         │ │
│  └─────────────────────────────┘ │
│                                   │
│  ┌─────────────────────────────┐ │
│  │   Show My Receipt  🔍       │ │
│  └─────────────────────────────┘ │
│                                   │
│  💡 Tip: Use the phone number    │
│     you provided at checkout     │
│                                   │
└───────────────────────────────────┘
```

### Desktop View:
```
┌─────────────────────────────────────────────────────┐
│  BILEE              Ravi Store          Login       │
├─────────────────────────────────────────────────────┤
│                                                     │
│              View Your Receipt                      │
│              at Ravi Store 🏪                       │
│                                                     │
│    ┌─────────────────────┐  ┌──────────────────┐  │
│    │ 📱 Phone Number     │  │ 🧾 Receipt ID    │  │
│    │ ┌─────────────────┐ │  │ ┌──────────────┐ │  │
│    │ │ +91            │ │  │ │ #RC          │ │  │
│    │ └─────────────────┘ │  │ └──────────────┘ │  │
│    │ [Show Receipt] 🔍   │  │ [Find] 🔍        │  │
│    └─────────────────────┘  └──────────────────┘  │
│                                                     │
│    💡 Enter the phone number you provided          │
│       during checkout, or your receipt number      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 📈 Benefits Analysis

### For Merchants:
```
✅ One-time QR code setup
✅ Print once, use forever
✅ No QR generation per session
✅ Cost effective
✅ Professional appearance
✅ Easy to display at counter
✅ Works for multiple customers simultaneously
```

### For Customers:
```
✅ Always know where to find receipt
✅ Same QR every time (familiar)
✅ Can retrieve old receipts
✅ Multiple receipts viewable
⚠️ Extra step: Enter phone (10 seconds)
```

### For System:
```
✅ Better database queries (indexed)
✅ Scalable architecture
✅ Reduced QR generation load
✅ Better analytics (customer tracking)
⚠️ Requires proper indexing
⚠️ More complex search logic
```

---

## 🔄 Migration Plan (v0.x → v1.0)

### Step 1: Backward Compatibility
```
- Keep session-based QR working (v0.x)
- Add permanent QR as new feature (v1.0)
- Merchants choose which to use
- Both systems coexist
```

### Step 2: Gradual Rollout
```
Week 1-2: Internal testing
Week 3-4: Beta merchants (10-20)
Week 5-6: Public release
Week 7-8: Monitor & improve
```

### Step 3: Feature Toggle
```dart
class MerchantSettings {
  bool enablePermanentQR = false; // Feature flag
  bool enableSessionQR = true;    // Default (v0.x)
  
  // Merchant can enable both
  // Customer gets choice:
  // "Scan session QR" or "Scan permanent QR"
}
```

---

## 💻 Code Structure (Planned)

### New Files to Create:
```
lib/
  features/
    receipt_lookup/
      presentation/
        pages/
          - receipt_lookup_page.dart
          - receipt_display_page.dart
        widgets/
          - phone_input_widget.dart
          - receipt_search_widget.dart
      domain/
        usecases/
          - search_receipt_by_phone.dart
          - search_receipt_by_id.dart
      data/
        repositories/
          - receipt_lookup_repository.dart
    
    merchant/
      presentation/
        pages/
          - permanent_qr_page.dart  // Generate & display
        widgets/
          - qr_download_options.dart
```

### Routes to Add:
```dart
// Customer-facing
GoRoute(
  path: '/receipt/:merchantId',
  name: 'receipt-lookup',
  builder: (context, state) {
    final merchantId = state.pathParameters['merchantId']!;
    return ReceiptLookupPage(merchantId: merchantId);
  },
),

// Merchant-facing
GoRoute(
  path: '/merchant/:merchantId/permanent-qr',
  name: 'permanent-qr',
  builder: (context, state) {
    final merchantId = state.pathParameters['merchantId']!;
    return PermanentQRPage(merchantId: merchantId);
  },
),
```

---

## 🧪 Testing Checklist

### Functionality Tests:
- [ ] QR code generation with merchantId
- [ ] Phone number search (exact match)
- [ ] Receipt ID search (exact match)
- [ ] Multiple receipts handling
- [ ] No receipt found scenario
- [ ] Typo handling (fuzzy search)
- [ ] Multiple customers simultaneously
- [ ] Old receipts (30+ days)
- [ ] High-value receipts (security)

### Performance Tests:
- [ ] Search speed < 2 seconds
- [ ] Works with 1000+ receipts per merchant
- [ ] Handles 100 concurrent customers
- [ ] Database query optimization
- [ ] Index effectiveness

### UI/UX Tests:
- [ ] Mobile responsive
- [ ] Tablet layout
- [ ] Desktop layout
- [ ] Input validation
- [ ] Error messages clarity
- [ ] Loading states
- [ ] Offline handling

---

## 📊 Success Metrics

### KPIs to Track:
```
1. Merchant Adoption Rate
   - Target: 40% use permanent QR within 3 months
   
2. Customer Success Rate
   - Target: 90% find receipt on first try
   
3. Average Search Time
   - Target: < 15 seconds from scan to receipt
   
4. Error Rate
   - Target: < 5% "receipt not found"
   
5. Support Tickets
   - Target: < 2% of users need help
```

---

## 🚀 Release Timeline

### Version 1.0 Release Plan:
```
├─ Month 1: Backend Development
│  ├─ Week 1-2: Database schema updates
│  └─ Week 3-4: API endpoints & indexing
│
├─ Month 2: Frontend Development
│  ├─ Week 1-2: Receipt lookup page
│  └─ Week 3-4: QR generation page
│
├─ Month 3: Testing & Beta
│  ├─ Week 1-2: Internal testing
│  └─ Week 3-4: Beta merchants
│
└─ Month 4: Public Release
   ├─ Week 1: Gradual rollout
   └─ Week 2-4: Monitor & iterate
```

---

## 📞 Support & Documentation

### For Merchants:
- [ ] How to generate permanent QR
- [ ] Where to display QR
- [ ] How to help customers
- [ ] Troubleshooting guide

### For Customers:
- [ ] How to scan QR
- [ ] What to do if receipt not found
- [ ] How to get old receipts
- [ ] Privacy & security info

---

## 🤔 Open Questions

1. **Should we require customer registration?**
   - Pro: Better tracking, personalization
   - Con: Extra friction, privacy concerns
   
2. **OTP verification: Always or optional?**
   - Always: More secure, slower
   - Optional: Faster, less secure
   
3. **How long to keep receipts searchable?**
   - 30 days? 90 days? Forever?
   
4. **Should merchants pay for permanent QR?**
   - Free tier: 100 receipts/month
   - Paid: Unlimited + analytics

---

## 📝 Notes & Considerations

- This is a **planned feature** for v1.0
- Current v0.x session-based QR will continue to work
- Implementation requires ~3-4 months
- Will coexist with session QR (merchant choice)
- Focus on Indian market (phone-first approach)
- Privacy and security are priorities
- Scalability designed for 10,000+ merchants

---

## 📄 Related Documents

- [AUTHENTICATION_SETUP.md](./AUTHENTICATION_SETUP.md) - Current auth system
- [PAYMENT_SYSTEM_INTEGRATION_COMPLETE.md](./PAYMENT_SYSTEM_INTEGRATION_COMPLETE.md) - Payment details
- [BARCODE_SCANNER_GUIDE.md](./BARCODE_SCANNER_GUIDE.md) - Scanner integration

---

**Version:** 1.0 (Planned)  
**Status:** Design Document  
**Author:** BILEE Team  
**Date:** December 13, 2025
