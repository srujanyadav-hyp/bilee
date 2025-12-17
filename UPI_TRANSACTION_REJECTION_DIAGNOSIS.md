# UPI Transaction Rejection Diagnosis

## Current Issue
**Error**: "This type of transaction is not allowed"  
**When**: After entering UPI PIN  
**Merchant**: SINDOL SHARADA (9346839708@ptsbi)

## What's Working ✅
1. ✅ QR scanning successful
2. ✅ Smart QR detection working (detecting static QR without amount)
3. ✅ UPI URI building correctly with amount
4. ✅ App chooser dialog displaying (PhonePe, Samsung Wallet, etc.)
5. ✅ UPI app launching and opening payment screen
6. ✅ PIN entry screen appearing

## Where It Fails ❌
❌ **After PIN entry** - Bank/merchant rejection

## Possible Causes

### 1. Merchant VPA Restrictions
- VPA: `9346839708@ptsbi` (State Bank of India)
- Some merchant accounts don't accept app-initiated payments
- Only accept direct QR scans from payment apps

### 2. Minimum Amount Restriction
- Current test: ₹1.00
- Many merchants require minimum ₹10 or ₹50
- Try increasing amount to ₹10 or ₹20

### 3. Transaction Note/Purpose
- Current note: "Payment via Bilee - Restaurant"
- Some banks reject transactions with specific keywords
- Try simpler note: "Payment" or "Bill Payment"

### 4. Merchant Account Status
- Account might be temporarily disabled
- Merchant might need to activate UPI acceptance
- Contact merchant to verify account is active

### 5. Payment App Specific Issues
- Some merchants whitelist specific payment apps
- Try different apps from chooser:
  - PhonePe
  - Samsung Wallet
  - Google Pay
  - Paytm

## Testing Checklist

### Test 1: Verify Merchant QR Outside App
```
1. Open PhonePe app directly
2. Scan the same merchant QR
3. Enter ₹10
4. Try to complete payment
```
**If this fails** → Merchant VPA issue, not your app

### Test 2: Try Higher Amount
```
1. In your app, scan QR
2. Enter ₹10 (not ₹1)
3. Try payment
```
**If this works** → Minimum amount restriction

### Test 3: Try Different UPI Apps
```
1. Scan QR in your app
2. When chooser appears, try:
   - First: PhonePe
   - Second: Samsung Wallet
   - Third: Google Pay (if installed)
```
**If one works** → App-specific merchant restriction

### Test 4: Check URI Format
Current URI being sent:
```
upi://pay?pa=9346839708@ptsbi&pn=SINDOL%20%20SHARADA&am=1.00&cu=INR&tn=Payment%20via%20Bilee%20-%20Restaurant
```

Try simplifying:
```dart
// In upi_payment_service.dart, change:
transactionNote = 'Payment'  // Instead of 'Payment via Bilee - Restaurant'
```

### Test 5: Verify Merchant Directly
Ask merchant:
- Is your UPI payment acceptance active?
- What's the minimum transaction amount?
- Have you received UPI payments recently?
- Can you try scanning your own QR with PhonePe?

## Logs to Monitor

When testing, watch for these in logs:
```
📤 UPI URI (manual): upi://pay?pa=...
✅ UPI app chooser displayed via platform channel
✅ Payment successful!
```

Then after returning from UPI app, check for any error messages.

## Expected Behavior

### If Merchant VPA is Valid:
1. Chooser appears ✅
2. Select app ✅
3. Enter PIN ✅
4. Payment processes ✅
5. Success message ✅

### If Merchant VPA has Issues:
1. Chooser appears ✅
2. Select app ✅
3. Enter PIN ✅
4. **Error: "Transaction not allowed"** ❌

## Recommendation

**Most Likely Cause**: Merchant VPA `9346839708@ptsbi` either:
- Doesn't accept app-initiated payments (only direct QR scans)
- Has minimum amount requirement
- Is temporarily inactive

**Next Steps**:
1. Test with ₹10 instead of ₹1
2. If still fails, test the merchant QR directly in PhonePe app
3. If PhonePe also rejects it, contact the merchant
4. Try a different merchant's QR for testing

## Code Changes Made

### Fixed Platform Channel Communication
**Before**: `launchUpiWithChooser` with parameter `uri`  
**After**: `launchUpiChooser` with parameter `upiUri`

Now Flutter and Android are synchronized.

## About the Chooser Dialog

The dialog showing "PhonePe, Samsung Wallet, etc." is **CORRECT** and **EXPECTED**! 

This is the feature you requested:
- ✅ Shows all UPI apps installed
- ✅ Lets you choose which app to use
- ✅ Samsung Wallet is legitimate UPI app on Samsung devices

If you want only PhonePe to open directly (no chooser), we can disable the chooser feature.
