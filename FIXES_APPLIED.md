# FIXES APPLIED - READ THIS

## 🐛 Problems Found:

### 1. **All 14 receipts have `customerId=null`**
   - Your user `T8X51IFmoaPeJHqv1GSw4WqKsPK2` (srujanp792@gmail.com) can't see receipts
   - The receipts exist but aren't linked to the customer
   - The billing sessions HAD connectedCustomers, but receipts weren't updated

### 2. **Phone number stored with duplicate country code**
   - Database shows: `"+91+911234567890"` (two +91s!)
   - Users were typing "+911234567890" in the phone field
   - System added +91 again, creating "+91+911234567890"

### 3. **Session cleanup using wrong collection name**
   - Cleanup function looked at `sessions` collection
   - Your app uses `billingSessions` collection
   - Old expired sessions were never deleted

---

## ✅ FIXES APPLIED:

### Fix #1: Migration Script for Existing Receipts
**File**: `functions/migrate_receipt_customerids.js`

**What it does**: Updates all 14 receipts with correct customerId by reading from billing sessions

**How to run**:
```powershell
cd functions

# IMPORTANT: Download Firebase Admin SDK key first
# 1. Go to: https://console.firebase.google.com/project/bilee-b1058/settings/serviceaccounts/adminsdk
# 2. Click "Generate new private key"
# 3. Save as functions/serviceAccountKey.json
# 4. NEVER commit this file to git! (add to .gitignore)

# Run migration
node migrate_receipt_customerids.js
```

**Expected output**:
```
📊 Found 14 receipts with null customerId
✅ Successfully updated: 14 receipts
```

**After migration**: Restart the app - all 14 receipts will appear for srujanp792@gmail.com

---

### Fix #2: Phone Number Validation
**File**: `lib/features/authentication/view/register_screen.dart`

**Changes**:
- Added `onChanged` handler to auto-strip country code if user pastes "+911234567890"
- Added validator check to reject phone numbers starting with "+"
- Now only accepts 10-digit numbers without country code

**How to test**:
1. Register new phone account
2. Try pasting "+911234567890" - it will auto-convert to "1234567890"
3. System adds +91 correctly → stored as "+911234567890" (correct!)

---

### Fix #3: Session Cleanup - Collection Name
**File**: `functions/index.js`

**Changes**:
- Line 249: Changed `collection('sessions')` → `collection('billingSessions')`
- Line 252: Changed `where('created_at'` → `where('createdAt'`
- Line 263: Changed `sessionData.payment_status` → `sessionData.paymentStatus`
- Line 265: Changed `sessionData.expires_at` → `sessionData.expiresAt`

**What it does now**:
- Runs every 1 hour automatically
- Finds sessions older than 24 hours
- Deletes them if they are:
  - Expired (past expiresAt time)
  - Completed with payment
  - Have receipt generated

---

## 📋 ACTION ITEMS:

### Step 1: Deploy Cloud Function fixes
```powershell
cd functions
firebase deploy --only functions
```

### Step 2: Run migration to fix existing receipts
```powershell
cd functions

# Download serviceAccountKey.json first (see instructions above)
node migrate_receipt_customerids.js
```

### Step 3: Test the fixes

**Test Receipt Display**:
1. Login as srujanp792@gmail.com
2. Check receipts screen - should see all 14 receipts
3. Check total spending - should match

**Test Phone Registration**:
1. Try registering new customer with phone
2. Paste "+911234567890" in phone field
3. Should auto-convert to "1234567890"
4. After registration, check Firestore - phone should be "+911234567890" (one +91 only)

**Test Session Cleanup**:
1. Create test billing session
2. Wait 25+ hours (or change cleanup schedule to "every 1 minutes" for testing)
3. Verify old completed sessions are deleted

---

## 🗑️ Cleaning Up Duplicate Phone Numbers

For existing users with duplicate country codes:

1. **Find affected users**: Firebase Console → Firestore → users collection
2. **Look for**: phone fields like "+91+911234567890"
3. **Fix manually**: Edit phone to "+911234567890" (remove duplicate +91)

OR run this query in Firebase Console:
```javascript
// In Firestore Rules Playground or use Firebase Admin SDK
db.collection('users')
  .where('phone', '>=', '+91+91')
  .where('phone', '<', '+91+92')
  .get()
  .then(snapshot => {
    snapshot.forEach(doc => {
      const phone = doc.data().phone;
      if (phone.startsWith('+91+91')) {
        const fixed = phone.replace('+91+91', '+91');
        doc.ref.update({ phone: fixed });
        console.log(`Fixed ${doc.id}: ${phone} → ${fixed}`);
      }
    });
  });
```

---

## 📊 Verification Checklist:

- [ ] Cloud Functions deployed
- [ ] Migration script executed successfully
- [ ] 14 receipts now visible for srujanp792@gmail.com
- [ ] New phone registrations don't duplicate country code
- [ ] Existing duplicate phone numbers cleaned up
- [ ] Session cleanup running (check Cloud Functions logs)

---

## 🚨 IMPORTANT NOTES:

1. **serviceAccountKey.json**: This is a sensitive file with full database access. NEVER commit to git!

2. **Migration is one-time**: The script can be run multiple times safely (it only updates receipts with null customerId)

3. **Future receipts**: After deploying the Cloud Function, all NEW receipts will have correct customerId automatically

4. **Session cleanup**: Helps reduce Firestore storage costs by deleting old sessions

5. **Receipts are permanent**: Receipts are NOT deleted when sessions are cleaned up (they're separate documents)

---

## 📞 If Something Goes Wrong:

- **Receipts still not showing**: Check Firestore → receipts collection → verify customerId field is populated
- **Phone still duplicating**: Clear app cache and reinstall
- **Migration errors**: Make sure serviceAccountKey.json is in functions/ directory

