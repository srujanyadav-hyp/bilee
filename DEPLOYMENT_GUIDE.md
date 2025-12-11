# BILEE Firebase Backend - Complete Deployment Guide

## Overview

This guide covers the complete deployment of BILEE's Firebase backend infrastructure including Firestore security rules, composite indexes, Cloud Functions, and Firebase Storage.

---

## Prerequisites

### 1. Install Firebase CLI
```powershell
npm install -g firebase-tools
```

### 2. Login to Firebase
```powershell
firebase login
```

### 3. Verify Project Connection
```powershell
firebase projects:list
```

Ensure 'bilee' project is listed.

---

## Deployment Steps

### Step 1: Deploy Firestore Security Rules

**Location:** `firestore.rules`

**Deploy Command:**
```powershell
firebase deploy --only firestore:rules
```

**Verify:**
- Go to Firebase Console → Firestore Database → Rules
- Confirm rules show:
  - `items` collection: Merchant-only access
  - `billingSessions` collection: Merchant create/update, authenticated read
  - `dailyAggregates` collection: Merchant-only access

**Test Security:**
```javascript
// In Firebase Console → Firestore → Rules Playground
// Test 1: Merchant creating item (should ALLOW)
match /databases/bilee/documents/items/{itemId}
Authenticated: Yes
User ID: merchant_123
Request data: { merchantId: "merchant_123", name: "Coffee" }

// Test 2: Different merchant reading item (should DENY)
match /databases/bilee/documents/items/{itemId}
Authenticated: Yes
User ID: merchant_456
Document data: { merchantId: "merchant_123" }
```

---

### Step 2: Deploy Composite Indexes

**Location:** `firestore.indexes.json`

**Deploy Command:**
```powershell
firebase deploy --only firestore:indexes
```

**Verify:**
- Go to Firebase Console → Firestore Database → Indexes
- Confirm composite indexes:
  1. `items`: merchantId (ASC) + name (ASC)
  2. `billingSessions`: merchantId (ASC) + status (ASC) + createdAt (DESC)
  3. `billingSessions`: merchantId (ASC) + createdAt (DESC)
  4. `dailyAggregates`: merchantId (ASC) + date (DESC)

**Index Build Time:** 1-5 minutes (wait for "Enabled" status)

---

### Step 3: Deploy Firebase Storage Rules

**Location:** `storage.rules`

**Deploy Command:**
```powershell
firebase deploy --only storage
```

**Verify:**
- Go to Firebase Console → Storage → Rules
- Confirm rules for:
  - `/reports/{merchantId}/{reportId}`: Merchant write, authenticated read with expiry
  - `/receipts/{sessionId}/{receiptId}`: Merchant write, session participants read

**Test Storage Upload:**
```dart
// In Flutter app
final ref = FirebaseStorage.instance.ref('reports/merchant_123/test.pdf');
await ref.putData(pdfBytes);
final url = await ref.getDownloadURL();
print('Uploaded: $url');
```

---

### Step 4: Deploy Cloud Functions

**Location:** `functions/`

#### 4.1 Install Dependencies
```powershell
cd functions
npm install
```

#### 4.2 Configure Environment Variables

**For Email Sending:**
```powershell
firebase functions:config:set email.user="noreply@bilee.app"
firebase functions:config:set email.password="your-app-password"
```

**Note:** Use Gmail App Password (not regular password):
1. Go to Google Account → Security → 2-Step Verification
2. Scroll to "App passwords"
3. Generate password for "Mail"
4. Copy 16-character password

#### 4.3 Deploy Functions
```powershell
firebase deploy --only functions
```

**Expected Output:**
```
✔  functions: Finished running predeploy script.
i  functions: preparing codebase default for deployment
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudbuild.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
✔  functions: required API cloudbuild.googleapis.com is enabled
i  functions: preparing functions directory for uploading...
i  functions: packaged functions (X KB) for uploading
✔  functions: functions folder uploaded successfully
i  functions: deploying functions
i  functions: updating Node.js 18 function finalizeSession(us-central1)...
i  functions: updating Node.js 18 function generateDailyReport(us-central1)...
✔  functions[finalizeSession(us-central1)] Successful update operation.
✔  functions[generateDailyReport(us-central1)] Successful update operation.

✔  Deploy complete!
```

#### 4.4 Verify Deployed Functions

**In Firebase Console:**
- Go to Functions → Dashboard
- Verify all functions are deployed:
  - `generateDailyReport` (Callable)
  - `sendReceipt` (Callable)
  - `triggerDailyAggregateUpdate` (Callable)
  - `onSessionCompleted` (Firestore trigger)
  - `onSessionPaid` (Firestore trigger)
  - `expireOldSessions` (Scheduled - every 10 min)
  - `cleanupExpiredSessions` (Scheduled - daily 2 AM)

**Test Callable Function:**
```dart
// In Flutter app
final functions = FirebaseFunctions.instance;
final result = await functions.httpsCallable('generateDailyReport').call({
  'merchantId': 'merchant_123',
  'date': '2024-01-15',
  'format': 'pdf',
});
print('Report URL: ${result.data['downloadUrl']}');
```

---

### Step 5: Complete Deployment (All at Once)

**Deploy Everything:**
```powershell
firebase deploy
```

This deploys:
- Firestore rules
- Firestore indexes
- Storage rules
- Cloud Functions

**Estimated Time:** 3-5 minutes

---

## Flutter App Integration

### 1. Update `main.dart`

Ensure Firebase is initialized with the correct database:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  // Use 'bilee' database instance
  FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'bilee',
  );
  
  setupDependencyInjection();
  runApp(const MyApp());
}
```

### 2. Test Cloud Functions Integration

The datasource already calls cloud functions:

```dart
// lib/data/datasources/merchant_firestore_datasource.dart
final result = await _functions.httpsCallable('generateDailyReport').call({
  'merchantId': merchantId,
  'date': date,
  'format': format,
});
```

No changes needed - it's already integrated!

---

## Testing Guide

### Test 1: Security Rules

**Test merchant-only item access:**
```dart
// Should succeed
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: 'merchant@bilee.app',
  password: 'password',
);
await FirebaseFirestore.instance.collection('items').add({
  'merchantId': FirebaseAuth.instance.currentUser!.uid,
  'name': 'Test Item',
});

// Should fail
await FirebaseFirestore.instance.collection('items').add({
  'merchantId': 'different_merchant_id',
  'name': 'Test Item',
});
```

### Test 2: Composite Indexes

**Test query performance:**
```dart
// This query should be fast (using index)
final items = await FirebaseFirestore.instance
  .collection('items')
  .where('merchantId', isEqualTo: merchantId)
  .orderBy('name')
  .get();

print('Query took: ${items.metadata.isFromCache ? "cache" : "server"}');
```

### Test 3: Cloud Functions

**Test daily report generation:**
```dart
final functions = FirebaseFunctions.instance;
try {
  final result = await functions.httpsCallable('generateDailyReport').call({
    'merchantId': merchantId,
    'date': '2024-01-15',
    'format': 'pdf',
  });
  print('✅ Report generated: ${result.data['downloadUrl']}');
} catch (e) {
  print('❌ Error: $e');
}
```

**Test receipt sending:**
```dart
try {
  await functions.httpsCallable('sendReceipt').call({
    'sessionId': 'sess_123',
    'recipientEmail': 'customer@example.com',
  });
  print('✅ Receipt sent');
} catch (e) {
  print('❌ Error: $e');
}
```

### Test 4: Firebase Storage

**Test file upload:**
```dart
final storage = FirebaseStorage.instance;
final reportRef = storage.ref('reports/$merchantId/test-${DateTime.now().millisecondsSinceEpoch}.pdf');

await reportRef.putData(pdfBytes, SettableMetadata(
  contentType: 'application/pdf',
));

final downloadUrl = await reportRef.getDownloadURL();
print('✅ Uploaded: $downloadUrl');
```

---

## Monitoring and Logs

### View Function Logs

**Real-time logs:**
```powershell
firebase functions:log
```

**In Firebase Console:**
- Functions → Logs
- Filter by function name
- Check for errors and performance metrics

### Monitor Firestore Usage

**In Firebase Console:**
- Firestore Database → Usage
- Check:
  - Document reads/writes
  - Storage size
  - Network egress

### Monitor Storage Usage

**In Firebase Console:**
- Storage → Usage
- Check:
  - Files stored
  - Bandwidth used
  - Operations count

---

## Cost Estimates

### Free Tier Limits

**Firestore:**
- 50K reads/day
- 20K writes/day
- 1 GB storage

**Cloud Functions:**
- 2M invocations/month
- 400K GB-seconds compute
- 200K CPU-seconds

**Storage:**
- 5 GB storage
- 1 GB downloads/day

### Typical BILEE Usage (Small Merchant)

**Daily:**
- 100 billing sessions
- 500 Firestore reads (session monitoring, items)
- 200 Firestore writes (sessions, aggregates)
- 10 function invocations (reports, receipts)
- 50 MB storage (reports, receipts)

**Monthly Cost:** FREE (well within limits)

**Medium Merchant (1000 sessions/day):**
- Firestore: ~$5/month
- Functions: ~$2/month
- Storage: ~$1/month
**Total: ~$8/month**

---

## Troubleshooting

### Issue: Security Rules Not Applied

**Solution:**
```powershell
# Redeploy rules
firebase deploy --only firestore:rules

# Check rules in console
firebase firestore:rules:get
```

### Issue: Indexes Not Building

**Solution:**
- Wait 5-10 minutes for index build
- Check Firebase Console → Firestore → Indexes
- If stuck, delete and redeploy:
  ```powershell
  firebase deploy --only firestore:indexes
  ```

### Issue: Cloud Functions Not Callable

**Symptoms:**
```
FunctionsError: NOT_FOUND (functions.httpsCallable)
```

**Solution:**
1. Verify function is deployed:
   ```powershell
   firebase functions:list
   ```

2. Check function region matches Flutter code:
   ```dart
   // If function is in us-central1
   FirebaseFunctions.instanceFor(region: 'us-central1')
   ```

3. Redeploy functions:
   ```powershell
   cd functions
   npm install
   firebase deploy --only functions
   ```

### Issue: Email Not Sending

**Symptoms:**
Receipt function completes but no email received.

**Solution:**
1. Check email configuration:
   ```powershell
   firebase functions:config:get
   ```

2. Verify Gmail App Password is correct

3. Check function logs:
   ```powershell
   firebase functions:log --only sendReceipt
   ```

4. Consider using SendGrid or AWS SES for production:
   ```javascript
   // In functions/src/receipts.js
   const transporter = nodemailer.createTransport({
     service: 'SendGrid',
     auth: {
       user: 'apikey',
       pass: process.env.SENDGRID_API_KEY,
     },
   });
   ```

### Issue: PDF Generation Fails

**Symptoms:**
```
Error: Failed to launch the browser process
```

**Solution:**
Puppeteer requires additional setup for Cloud Functions:

1. Update `functions/package.json`:
   ```json
   "dependencies": {
     "puppeteer": "^21.0.0"
   },
   "engines": {
     "node": "18"
   }
   ```

2. Increase function memory:
   ```javascript
   // In functions/index.js
   exports.generateDailyReport = functions
     .runWith({ memory: '1GB', timeoutSeconds: 120 })
     .https.onCall(async (data, context) => {
       // ... existing code
     });
   ```

---

## Production Checklist

Before going live, verify:

- [ ] **Security Rules Deployed**
  - Test with real user authentication
  - Verify unauthorized access is blocked

- [ ] **Indexes Created**
  - All indexes show "Enabled" status
  - Test queries are fast (<1 second)

- [ ] **Cloud Functions Working**
  - Test all callable functions
  - Verify scheduled functions run
  - Check trigger functions activate

- [ ] **Storage Configured**
  - Test file uploads
  - Verify download URLs work
  - Check file size limits enforced

- [ ] **Email Configured** (if using sendReceipt)
  - Test email delivery
  - Verify email template renders correctly
  - Check spam folder

- [ ] **Monitoring Setup**
  - Enable Firebase Crashlytics
  - Set up performance monitoring
  - Configure budget alerts

- [ ] **Backup Strategy**
  - Enable Firestore daily backups
  - Document restore procedure
  - Test backup restoration

---

## Next Steps

1. **Deploy to Production:**
   ```powershell
   firebase deploy
   ```

2. **Test End-to-End:**
   - Create merchant account
   - Add items to library
   - Start billing session
   - Complete payment
   - Verify daily aggregate updated
   - Generate and download report

3. **Monitor for 24 Hours:**
   - Check function logs for errors
   - Verify scheduled functions run
   - Monitor Firestore usage
   - Check performance metrics

4. **Optimize:**
   - Enable Firestore caching in Flutter
   - Add error handling and retries
   - Implement offline support
   - Add analytics tracking

---

## Support

**Firebase Documentation:**
- https://firebase.google.com/docs/firestore/security/get-started
- https://firebase.google.com/docs/functions
- https://firebase.google.com/docs/storage

**BILEE Support:**
- GitHub Issues: [Your repo URL]
- Email: support@bilee.app

---

**Last Updated:** January 2024
**Version:** 1.0.0
