# Firestore Security Rules Documentation

## Overview

This document explains the security rules for the BILEE Firestore database. These rules ensure that merchants and customers can only access data they are authorized to see, preventing unauthorized access and data breaches.

## Database Configuration

- **Database Instance**: `bilee` (custom database, not default)
- **Rules File**: `firebase/firestore.rules`

## Rules Structure

### 1. Merchants Collection

**Path**: `/merchants/{merchantId}`

**Rules**:
- Merchants can read and write only their own document
- Access check: `request.auth.uid == merchantId`

**Subcollection - Items**:

**Path**: `/merchants/{merchantId}/items/{itemId}`

**Rules**:
- Only the merchant owner can manage items
- No public access to item library

**Use Cases**:
- Merchant adds new item to library
- Merchant updates item price/name
- Merchant deletes discontinued item
- Merchant views all items in library

**Example Denied Access**:
```
❌ Merchant A tries to read Merchant B's items
❌ Unauthenticated user tries to list items
❌ Customer tries to access merchant's item library
```

### 2. Sessions Collection

**Path**: `/sessions/{sessionId}`

**Rules**:
- **Create**: Authenticated user can create session if `merchant_id == auth.uid`
- **Read**: Merchant can read their own sessions, customers can read if authenticated
- **Update**: Only merchant can update their own sessions
- **Delete**: Blocked (sessions are archived, not deleted)

**Fields Validated**:
- `merchant_id` must match creator's UID on creation
- Only merchant can mark session as PAID or FINALIZED

**Use Cases**:
- Merchant creates live billing session
- Merchant updates session with payment info
- Customer app reads session details via QR code
- Merchant finalizes session

**Example Denied Access**:
```
❌ Merchant A tries to update Merchant B's session
❌ User tries to delete any session
❌ Unauthenticated user tries to create session
```

### 3. Receipts Collection

**Path**: `/receipts/{receiptId}`

**Rules**:
- **Read**: Merchant can read receipts they created, authenticated customers can read
- **Write**: Only cloud functions can create/update receipts
- **Delete**: Blocked (receipts are immutable)

**Security Model**:
- Receipts are created exclusively by `finalizeSession` cloud function
- Prevents tampering with receipt data
- Merchants access via `merchant_id` filter
- Customers access via receipt reference in app

**Use Cases**:
- Merchant views past receipts
- Customer accesses receipt from email/app
- Cloud function creates receipt after session finalization

**Example Denied Access**:
```
❌ Merchant tries to manually create receipt
❌ User tries to modify existing receipt
❌ Anyone tries to delete receipt
```

### 4. Daily Aggregates Collection

**Path**: `/daily_aggregates/{aggregateId}`

**Document ID Format**: `{merchantId}_{YYYY-MM-DD}`

**Rules**:
- **Read**: Merchant can read their own aggregates (extracted from document ID)
- **Create/Update**: Merchant can create/update if merchant_id matches auth.uid
- **Delete**: Blocked (aggregates are permanent)

**Security Features**:
- Merchant ID extracted from document ID using split('_')[0]
- Double verification: both document ID and merchant_id field must match
- Prevents merchants from accessing other merchants' sales data

**Use Cases**:
- Merchant views today's sales summary
- Merchant accesses historical daily reports
- App updates daily aggregate after session finalization

**Example Denied Access**:
```
❌ Merchant A tries to read Merchant B's daily totals
❌ User tries to create aggregate for another merchant
❌ Anyone tries to delete aggregate
```

### 5. Users Collection

**Path**: `/users/{userId}`

**Rules**:
- Users can read and write only their own user document
- Standard authentication check

**Use Cases**:
- User updates profile information
- App reads user preferences

## Security Best Practices

### Authentication Requirements

All operations require Firebase Authentication:
```dart
// User must be signed in
request.auth != null
```

### Merchant Verification

Merchants are verified by matching auth UID:
```dart
// Ensure authenticated user is the merchant owner
request.auth.uid == merchantId
```

### Data Validation

Rules validate document structure:
```dart
// On session creation, merchant_id must match auth UID
request.resource.data.merchant_id == request.auth.uid
```

### Immutability Protection

Critical documents cannot be deleted:
```dart
// Prevent deletion of receipts and aggregates
allow delete: if false;
```

## Testing Security Rules

### Local Testing with Emulator

```bash
# Start Firestore emulator
firebase emulators:start --only firestore

# Run security rules tests
firebase emulators:exec --only firestore "npm test"
```

### Unit Tests Structure

Create `firebase/firestore.test.js`:

```javascript
const testing = require('@firebase/rules-unit-testing');

describe('Firestore Security Rules', () => {
  let testEnv;
  
  beforeEach(async () => {
    testEnv = await testing.initializeTestEnvironment({
      projectId: 'bilee-test',
      firestore: {
        rules: fs.readFileSync('firestore.rules', 'utf8'),
        host: 'localhost',
        port: 8080,
      },
    });
  });
  
  it('should allow merchant to read own items', async () => {
    const merchantId = 'merchant_123';
    const context = testEnv.authenticatedContext(merchantId);
    const itemRef = context.firestore()
      .collection('merchants').doc(merchantId)
      .collection('items').doc('item_1');
    
    await testing.assertSucceeds(itemRef.get());
  });
  
  it('should deny merchant from reading other merchant items', async () => {
    const context = testEnv.authenticatedContext('merchant_123');
    const itemRef = context.firestore()
      .collection('merchants').doc('merchant_456')
      .collection('items').doc('item_1');
    
    await testing.assertFails(itemRef.get());
  });
});
```

## Deployment

### Deploy Rules to Production

```bash
# Deploy only Firestore rules
firebase deploy --only firestore:rules

# Deploy to specific database instance
firebase deploy --only firestore:rules:bilee
```

### Verify Deployment

1. Go to Firebase Console → Firestore Database → Rules
2. Verify rules are active and simulator passes tests
3. Check rules version matches deployment timestamp

## Common Issues

### Issue 1: "Missing or insufficient permissions"

**Cause**: User doesn't have required authentication or ownership
**Solution**: Verify user is signed in and accessing their own data

### Issue 2: Cloud functions can't write receipts

**Cause**: Service account permissions not configured
**Solution**: Ensure functions use admin SDK with proper initialization

### Issue 3: Aggregates not updating

**Cause**: Document ID format doesn't match merchant_id extraction
**Solution**: Verify document ID format: `{merchantId}_{YYYY-MM-DD}`

## Rule Maintenance

### When to Update Rules

- Adding new collections or subcollections
- Changing document ID formats
- Adding new user roles (admin, staff, etc.)
- Implementing customer-specific features

### Version Control

- Always test rules in emulator before deployment
- Use Firebase Console simulator to test edge cases
- Document rule changes in this file
- Keep rules file in version control

## Security Checklist

✅ All collections require authentication  
✅ Merchants can only access their own data  
✅ Receipts are immutable and function-created only  
✅ Sessions cannot be deleted  
✅ Daily aggregates are permanent  
✅ Customer access is properly scoped  
✅ No wildcard read/write permissions  
✅ Document ID format enforces security (aggregates)  

## Additional Resources

- [Firestore Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Security Rules Testing](https://firebase.google.com/docs/rules/unit-tests)
- [Common Security Rules Patterns](https://firebase.google.com/docs/firestore/security/rules-conditions)
