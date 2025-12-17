/**
 * ONE-TIME MIGRATION SCRIPT
 * Fixes existing receipts with null customerId by reading from session's connectedCustomers array
 * 
 * HOW TO RUN:
 * 1. cd functions
 * 2. node migrate_receipt_customerids.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // You'll need to download this from Firebase Console

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateReceiptCustomerIds() {
  console.log('🔄 Starting migration of receipt customerIds...\n');

  try {
    // Get all receipts with null customerId
    const receiptsSnapshot = await db.collection('receipts')
      .where('customerId', '==', null)
      .get();

    console.log(`📊 Found ${receiptsSnapshot.size} receipts with null customerId\n`);

    let successCount = 0;
    let failCount = 0;
    let skipCount = 0;

    for (const receiptDoc of receiptsSnapshot.docs) {
      const receiptData = receiptDoc.data();
      const sessionId = receiptData.sessionId;
      const receiptId = receiptDoc.id;

      console.log(`\n📝 Processing receipt ${receiptId}...`);
      console.log(`   Session ID: ${sessionId}`);

      if (!sessionId) {
        console.log(`   ⚠️  No sessionId found, skipping`);
        skipCount++;
        continue;
      }

      // Get the session to find connectedCustomers
      const sessionDoc = await db.collection('billingSessions').doc(sessionId).get();

      if (!sessionDoc.exists) {
        console.log(`   ❌ Session not found, skipping`);
        failCount++;
        continue;
      }

      const sessionData = sessionDoc.data();
      const connectedCustomers = sessionData.connectedCustomers || [];

      if (connectedCustomers.length === 0) {
        console.log(`   ℹ️  No connected customers (walk-in), leaving as null`);
        skipCount++;
        continue;
      }

      const customerId = connectedCustomers[0];
      console.log(`   ✅ Found customerId: ${customerId}`);

      // Update the receipt
      await db.collection('receipts').doc(receiptId).update({
        customerId: customerId,
        migratedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      console.log(`   ✅ Updated receipt with customerId`);
      successCount++;
    }

    console.log('\n\n' + '='.repeat(60));
    console.log('📊 MIGRATION COMPLETE');
    console.log('='.repeat(60));
    console.log(`✅ Successfully updated: ${successCount} receipts`);
    console.log(`⚠️  Skipped (no customer): ${skipCount} receipts`);
    console.log(`❌ Failed: ${failCount} receipts`);
    console.log('='.repeat(60));

  } catch (error) {
    console.error('❌ Migration failed:', error);
  } finally {
    process.exit(0);
  }
}

// Run migration
migrateReceiptCustomerIds();
