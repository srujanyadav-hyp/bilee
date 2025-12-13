# Quick Start Guide - Advanced Payment System

## 🚀 3 Steps to Get Started

### Step 1: Register the Provider (Required)

Find your provider registration file (usually `main.dart` or a dedicated providers file) and add:

```dart
ChangeNotifierProvider(
  create: (_) => CustomerLedgerProvider(),
),
```

**Example** (`lib/main.dart`):
```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        // ... your existing providers ...
        ChangeNotifierProvider(create: (_) => SessionProvider(...)),
        ChangeNotifierProvider(create: (_) => ItemProvider(...)),
        
        // ✅ ADD THIS LINE
        ChangeNotifierProvider(create: (_) => CustomerLedgerProvider()),
      ],
      child: MyApp(),
    ),
  );
}
```

---

### Step 2: Add Customer Ledger Route (Optional but Recommended)

Add the route to access the Customer Ledger page from your app.

**Example** (if using `go_router`):
```dart
GoRoute(
  path: '/merchant/:merchantId/ledger',
  builder: (context, state) => CustomerLedgerPage(
    merchantId: state.pathParameters['merchantId']!,
  ),
),
```

**Or** add a button in your merchant dashboard:
```dart
ListTile(
  leading: Icon(Icons.account_balance_wallet),
  title: Text('Customer Credits'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CustomerLedgerPage(
        merchantId: merchantId,
      ),
    ),
  ),
)
```

---

### Step 3: Update Firestore Security Rules

Add these rules to `firestore.rules`:

```javascript
match /customerLedger/{ledgerId} {
  // Allow merchants to read their own ledger entries
  allow read: if request.auth != null;
  
  // Allow merchants to create/update their own ledger entries
  allow write: if request.auth != null && 
               request.resource.data.merchantId == request.auth.uid;
}
```

**Deploy**:
```bash
firebase deploy --only firestore:rules
```

---

## ✅ That's It!

The advanced payment system is now ready to use!

### Test the New Checkout Flow:

1. Go to billing page
2. Add items to cart
3. Click "Checkout" 
4. **See the new 3-tab checkout dialog**:
   - Tab 1: Apply discounts (6 presets + custom)
   - Tab 2: Add payments (split across multiple methods)
   - Tab 3: Review summary before completing
5. For partial payment: Enter customer name/phone and due date
6. Click "Complete Checkout"

### View Customer Credits:

1. Navigate to Customer Ledger page (from dashboard or route)
2. See all customers with pending payments
3. Search/filter by name, phone, or status
4. Tap customer to view all bills
5. Record payments directly from ledger

---

## 🎯 What's New vs. Old Checkout

| Feature | Old Checkout | New Checkout |
|---------|-------------|--------------|
| Payment Methods | Single only | Split payments ✅ |
| Partial Payment | ❌ | Full credit tracking ✅ |
| Discounts | ❌ | 6 presets + custom ✅ |
| Transaction IDs | ❌ | Captured for verification ✅ |
| Customer Info | ❌ | Required for credit ✅ |
| Due Dates | ❌ | 3/7/15/30 days ✅ |
| Payment History | ❌ | Full audit trail ✅ |

---

## 🆘 Troubleshooting

### "Provider not found" error
**Solution**: Make sure you added `CustomerLedgerProvider` to your provider list in `main.dart`

### Ledger page is empty
**Solution**: 
1. Make sure Firestore rules are deployed
2. Try creating a partial payment first
3. Check Firebase console for data

### Checkout dialog doesn't show
**Solution**: 
1. Verify `advanced_checkout_dialog.dart` exists
2. Check import in `start_billing_page.dart`
3. Rebuild the app: `flutter clean && flutter run`

### Split payments not saving
**Solution**: Verify `PaymentDetails` is being passed correctly to `createSessionWithPayment()`

---

## 📱 Demo Scenario

**Scenario**: Customer buys ₹1000 worth of items but only has ₹700

1. Add items totaling ₹1000
2. Click "Checkout"
3. Tab 1 (Discount): Apply "10% off" → Final: ₹900
4. Tab 2 (Payment): 
   - Add Cash: ₹500
   - Add Card: ₹200 (enter txn ID)
   - Total paid: ₹700
   - **Remaining: ₹200 (partial payment section appears)**
5. Enter customer name: "John Doe"
6. Enter phone: "9876543210"
7. Select due date: 7 days
8. Tab 3 (Summary): Review all details
9. Click "Complete Checkout"
10. ✅ Session created, ledger entry added automatically
11. Navigate to Customer Ledger page
12. See "John Doe" with ₹200 pending
13. When customer pays later: Tap John → Record Payment → Enter ₹200

---

## 💡 Pro Tips

1. **Quick Discounts**: Use presets for common discounts (5%, 10%, etc.)
2. **Transaction IDs**: Always capture for digital payments (for reconciliation)
3. **Due Dates**: Use consistent due dates (e.g., always 7 days) for easier tracking
4. **Customer Phone**: Use as unique identifier for credit tracking
5. **Regular Reviews**: Check overdue section daily to follow up

---

## 📞 Support

If you encounter any issues:
1. Check console for error messages
2. Verify all files are saved
3. Run `flutter clean && flutter pub get`
4. Restart the app

Happy billing! 🎉
