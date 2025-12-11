# Bilee Cloud Functions

This directory contains Cloud Functions for the Bilee merchant module backend operations.

## Overview

These functions handle server-side operations that cannot be performed directly from the Flutter app, including:
- Session finalization and receipt generation
- Daily report generation
- UPI payment webhook processing

## Prerequisites

- Node.js 18+ and npm
- Firebase CLI: `npm install -g firebase-tools`
- Firebase project with Firestore and Cloud Storage enabled
- Service account credentials (for deployment)

## Setup

1. Install dependencies:
   ```bash
   cd functions
   npm install
   ```

2. Configure Firebase:
   ```bash
   firebase login
   firebase use --add  # Select your Firebase project
   ```

3. Set environment variables:
   ```bash
   firebase functions:config:set storage.bucket="your-bucket-name"
   ```

## Functions

### 1. finalizeSession
**Endpoint:** `POST /finalize_session`

Finalizes a live session and creates a receipt blob in Cloud Storage.

**Request Body:**
```json
{
  "session_id": "sess_abc123"
}
```

**Response:**
```json
{
  "success": true,
  "receipt_id": "rcpt_12345",
  "storage_path": "receipts/m_123/2025/11/23/rcpt_12345.json.gz"
}
```

**Operations:**
1. Fetch session data from Firestore
2. Create receipt metadata document in `receipts` collection
3. Generate full receipt JSON blob
4. Compress and upload to Cloud Storage at `receipts/{merchantId}/{YYYY}/{MM}/{DD}/{receiptId}.json.gz`
5. Update session status to FINALIZED
6. Return receipt ID and storage path

### 2. generateDailyReport
**Endpoint:** `POST /generate_daily_report`

Generates a daily summary report (PDF or CSV) from daily aggregate data.

**Request Body:**
```json
{
  "merchant_id": "m_123",
  "date": "2025-11-23",
  "format": "PDF"
}
```

**Response:**
```json
{
  "success": true,
  "report_url": "https://storage.googleapis.com/bilee-reports/m_123/2025/11/23/daily_summary.pdf",
  "expires_at": "2025-11-24T10:00:00Z"
}
```

**Operations:**
1. Fetch daily aggregate from Firestore
2. Generate PDF or CSV using appropriate library (e.g., pdfkit, csv-stringify)
3. Upload to Cloud Storage at `reports/{merchantId}/{YYYY}/{MM}/{DD}/daily_summary.{format}`
4. Generate signed URL with 7-day expiry
5. Return signed URL

### 3. verifyUpiWebhook
**Endpoint:** `POST /verify_upi_webhook`

Processes UPI payment notifications from PSP (Payment Service Provider).

**Request Body:** (Format depends on PSP)
```json
{
  "transaction_id": "UPI123XYZ",
  "session_id": "sess_abc123",
  "amount": 238.00,
  "status": "SUCCESS",
  "signature": "..."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payment verified"
}
```

**Operations:**
1. Verify webhook signature using PSP public key
2. Validate transaction amount matches session total
3. Update session document with payment details
4. Trigger session finalization (call finalizeSession internally)
5. Return success response

### 4. simulatePayment (Testing Only)
**Endpoint:** `POST /simulate_payment`

Simulates a successful payment for testing purposes. **DO NOT deploy to production.**

**Request Body:**
```json
{
  "session_id": "sess_abc123",
  "payment_method": "UPI",
  "txn_id": "TEST_12345"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payment simulated"
}
```

## Deployment

### Development
```bash
firebase emulators:start
```

### Production
```bash
firebase deploy --only functions
```

## Security

### Authentication
All endpoints should verify Firebase Auth tokens:
```javascript
const admin = require('firebase-admin');

exports.finalizeSession = functions.https.onRequest(async (req, res) => {
  // Verify ID token
  const idToken = req.headers.authorization?.split('Bearer ')[1];
  const decodedToken = await admin.auth().verifyIdToken(idToken);
  const merchantId = decodedToken.uid;
  
  // ... rest of function
});
```

### Firestore Rules Integration
Functions run with admin privileges but should validate merchant ownership:
```javascript
// Verify session belongs to merchant
const sessionDoc = await admin.firestore()
  .collection('sessions')
  .doc(sessionId)
  .get();

if (sessionDoc.data().merchant_id !== merchantId) {
  throw new Error('Unauthorized');
}
```

## Storage Paths

### Receipt Blobs
```
receipts/
  {merchantId}/
    {YYYY}/
      {MM}/
        {DD}/
          {receiptId}.json.gz
```

### Daily Reports
```
reports/
  {merchantId}/
    {YYYY}/
      {MM}/
        {DD}/
          daily_summary.pdf
          daily_summary.csv
```

### Lifecycle Rules
Set up Cloud Storage lifecycle rules:
- Transition to Nearline after 30 days
- Transition to Coldline after 90 days
- Archive after 365 days

## Dependencies (package.json stub)

```json
{
  "name": "bilee-functions",
  "version": "1.0.0",
  "engines": {
    "node": "18"
  },
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0",
    "pdfkit": "^0.14.0",
    "csv-stringify": "^6.4.0",
    "zlib": "^1.0.5"
  }
}
```

## Environment Variables

```bash
# Storage bucket name
firebase functions:config:set storage.bucket="bilee-receipts"

# UPI PSP webhook secret (if using PSP)
firebase functions:config:set upi.webhook_secret="your-secret-key"

# UPI PSP public key for signature verification
firebase functions:config:set upi.public_key="-----BEGIN PUBLIC KEY-----..."
```

## Testing

### Local Testing with Emulator
```bash
# Start emulators
firebase emulators:start

# Test endpoint
curl -X POST http://localhost:5001/your-project/us-central1/finalizeSession \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{"session_id":"sess_test123"}'
```

### Unit Tests
```bash
npm test
```

## Monitoring

- View logs: `firebase functions:log`
- Set up alerts for function failures in Firebase Console
- Monitor Cloud Storage usage and costs
- Track function execution times

## Cost Optimization

1. Use background triggers instead of HTTP where possible
2. Implement request batching for bulk operations
3. Cache frequently accessed data
4. Set appropriate function timeouts
5. Use Cloud Scheduler for periodic tasks instead of always-on functions

## PSP Integration Notes

### UPI Payment Flow
1. Merchant shows QR code with session details
2. Customer scans and pays via UPI app
3. PSP receives payment and sends webhook to `/verify_upi_webhook`
4. Function verifies signature and updates session
5. Session is auto-finalized and receipt created

### Supported PSPs
- Razorpay (webhook signature: HMAC SHA256)
- PayU (webhook signature: SHA512)
- PhonePe (webhook signature: custom)
- Custom PSP (configure webhook format in env vars)

## Implementation Checklist

- [ ] Implement finalizeSession function
- [ ] Implement generateDailyReport function
- [ ] Implement verifyUpiWebhook function (when PSP chosen)
- [ ] Add unit tests for each function
- [ ] Configure environment variables
- [ ] Set up Cloud Storage lifecycle rules
- [ ] Deploy to development environment
- [ ] Test with emulator
- [ ] Deploy to production
- [ ] Set up monitoring and alerts

## Support

For issues or questions about Cloud Functions:
1. Check Firebase Console logs
2. Review Firestore security rules
3. Verify environment configuration
4. Check Cloud Storage permissions
5. Contact Firebase support if needed
