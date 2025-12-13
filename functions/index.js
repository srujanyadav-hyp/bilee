const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// ==================== FINALIZE SESSION ====================
/**
 * Finalizes a session and creates receipt blob in Cloud Storage
 * POST /finalize_session
 * Body: { session_id: string }
 */
exports.finalizeSession = functions.https.onRequest(async (req, res) => {
  // TODO: Implement authentication verification
  // const idToken = req.headers.authorization?.split('Bearer ')[1];
  // const decodedToken = await admin.auth().verifyIdToken(idToken);
  
  try {
    const { session_id } = req.body;
    
    if (!session_id) {
      return res.status(400).json({ error: 'session_id is required' });
    }

    // Fetch session data
    const sessionDoc = await admin.firestore()
      .collection('sessions')
      .doc(session_id)
      .get();
    
    if (!sessionDoc.exists) {
      return res.status(404).json({ error: 'Session not found' });
    }

    const sessionData = sessionDoc.data();
    const receiptId = `rcpt_${Date.now()}`;
    const merchantId = sessionData.merchant_id;
    
    // Create receipt metadata
    const receiptData = {
      receipt_id: receiptId,
      merchant_id: merchantId,
      session_id: session_id,
      timestamp: admin.firestore.Timestamp.now(),
      items: sessionData.items,
      subtotal: sessionData.subtotal,
      tax: sessionData.tax,
      total: sessionData.total,
      payment: {
        method: sessionData.payment_method,
        status: sessionData.payment_status,
        txn_id: sessionData.txn_id,
      },
      signature_meta: {
        algorithm: 'Ed25519',
        public_key_id: `pub_${merchantId}_v1`,
      },
      signature: null,
    };

    // Save receipt metadata to Firestore
    await admin.firestore()
      .collection('receipts')
      .doc(receiptId)
      .set(receiptData);

    // Create full receipt blob (compressed JSON)
    const fullReceiptBlob = JSON.stringify({
      ...receiptData,
      merchant_details: {
        // TODO: Fetch merchant details
        name: 'Merchant Name',
        address: 'Merchant Address',
      },
      customer_details: sessionData.customer_details || null,
    });

    // Compress and upload to Cloud Storage
    const compressed = zlib.gzipSync(fullReceiptBlob);
    const timestamp = new Date(sessionData.created_at.toDate());
    const year = timestamp.getFullYear();
    const month = String(timestamp.getMonth() + 1).padStart(2, '0');
    const day = String(timestamp.getDate()).padStart(2, '0');
    
    const storagePath = `receipts/${merchantId}/${year}/${month}/${day}/${receiptId}.json.gz`;
    const bucket = admin.storage().bucket();
    const file = bucket.file(storagePath);
    
    await file.save(compressed, {
      metadata: {
        contentType: 'application/gzip',
        metadata: {
          receipt_id: receiptId,
          session_id: session_id,
        },
      },
    });

    // Update session status
    await admin.firestore()
      .collection('sessions')
      .doc(session_id)
      .update({
        status: 'FINALIZED',
        receipt_id: receiptId,
      });

    res.json({
      success: true,
      receipt_id: receiptId,
      storage_path: storagePath,
    });
  } catch (error) {
    console.error('Error finalizing session:', error);
    res.status(500).json({ error: error.message });
  }
});

// ==================== GENERATE DAILY REPORT ====================
/**
 * Generates daily summary report (PDF/CSV)
 * POST /generateDailyReport or called via httpsCallable
 * Body: { merchantId: string, date: string, format: 'pdf'|'csv' }
 */
const { generateDailyReport: generateReport } = require('./src/reports');

exports.generateDailyReport = functions.https.onCall(async (data, context) => {
  try {
    const { merchantId, date, format = 'pdf' } = data;
    
    if (!merchantId || !date) {
      throw new functions.https.HttpsError('invalid-argument', 'merchantId and date are required');
    }

    // Use the proper report generation function from reports.js
    const downloadUrl = await generateReport(merchantId, date, format);

    return {
      success: true,
      downloadUrl: downloadUrl,
      expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
    };
  } catch (error) {
    console.error('Error generating report:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// ==================== VERIFY UPI WEBHOOK ====================
/**
 * Verifies UPI payment webhook from PSP
 * POST /verify_upi_webhook
 * Body: PSP-specific format
 */
exports.verifyUpiWebhook = functions.https.onRequest(async (req, res) => {
  try {
    // TODO: Implement PSP-specific signature verification
    const { transaction_id, session_id, amount, status, signature } = req.body;
    
    if (!session_id || !transaction_id) {
      return res.status(400).json({ error: 'Invalid webhook data' });
    }

    // TODO: Verify signature using PSP public key
    // const isValid = verifySignature(req.body, signature);
    // if (!isValid) {
    //   return res.status(401).json({ error: 'Invalid signature' });
    // }

    if (status !== 'SUCCESS') {
      return res.json({ success: false, message: 'Payment not successful' });
    }

    // Fetch session and verify amount
    const sessionDoc = await admin.firestore()
      .collection('sessions')
      .doc(session_id)
      .get();
    
    if (!sessionDoc.exists) {
      return res.status(404).json({ error: 'Session not found' });
    }

    const sessionData = sessionDoc.data();
    
    // Verify amount matches
    if (Math.abs(sessionData.total - amount) > 0.01) {
      return res.status(400).json({ error: 'Amount mismatch' });
    }

    // Update session with payment info
    await admin.firestore()
      .collection('sessions')
      .doc(session_id)
      .update({
        payment_method: 'UPI',
        payment_status: 'PAID',
        txn_id: transaction_id,
      });

    res.json({ success: true, message: 'Payment verified' });
  } catch (error) {
    console.error('Error verifying payment:', error);
    res.status(500).json({ error: error.message });
  }
});

// ==================== SIMULATE PAYMENT (TESTING ONLY) ====================
/**
 * Simulates payment for testing - DO NOT DEPLOY TO PRODUCTION
 * POST /simulate_payment
 * Body: { session_id: string, payment_method: string, txn_id: string }
 */
exports.simulatePayment = functions.https.onRequest(async (req, res) => {
  try {
    const { session_id, payment_method, txn_id } = req.body;
    
    await admin.firestore()
      .collection('sessions')
      .doc(session_id)
      .update({
        payment_method: payment_method,
        payment_status: 'PAID',
        txn_id: txn_id,
      });

    res.json({ success: true, message: 'Payment simulated' });
  } catch (error) {
    console.error('Error simulating payment:', error);
    res.status(500).json({ error: error.message });
  }
});

// ==================== AUTO CLEANUP EXPIRED SESSIONS ====================
/**
 * Scheduled function to clean up expired sessions
 * Runs every hour to delete sessions older than 24 hours
 */
exports.cleanupExpiredSessions = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const twentyFourHoursAgo = new Date(now.toMillis() - (24 * 60 * 60 * 1000));
    
    console.log('Starting cleanup of expired sessions...');
    
    try {
      // Find sessions older than 24 hours
      const expiredSessionsSnapshot = await admin.firestore()
        .collection('sessions')
        .where('created_at', '<', admin.firestore.Timestamp.fromDate(twentyFourHoursAgo))
        .get();
      
      console.log(`Found ${expiredSessionsSnapshot.size} expired sessions`);
      
      // Delete sessions in batches
      const batch = admin.firestore().batch();
      let deleteCount = 0;
      
      expiredSessionsSnapshot.forEach((doc) => {
        const sessionData = doc.data();
        
        // Only delete if:
        // 1. Session is expired OR
        // 2. Session is completed OR
        // 3. Session has a receipt (payment recorded)
        const hasReceipt = sessionData.payment_status === 'PAID';
        const isCompleted = sessionData.status === 'COMPLETED';
        const isExpired = sessionData.status === 'EXPIRED' || 
                         (sessionData.expires_at && sessionData.expires_at.toMillis() < now.toMillis());
        
        if (hasReceipt || isCompleted || isExpired) {
          batch.delete(doc.ref);
          deleteCount++;
          console.log(`Marking session ${doc.id} for deletion`);
        }
      });
      
      if (deleteCount > 0) {
        await batch.commit();
        console.log(`Successfully deleted ${deleteCount} expired sessions`);
      } else {
        console.log('No sessions to delete');
      }
      
      return null;
    } catch (error) {
      console.error('Error cleaning up expired sessions:', error);
      throw error;
    }
  });

// ==================== MANUAL SESSION CLEANUP ====================
/**
 * HTTP function to manually trigger session cleanup
 * Useful for testing or immediate cleanup
 * POST /cleanup_sessions
 */
exports.cleanupSessions = functions.https.onRequest(async (req, res) => {
  try {
    const now = admin.firestore.Timestamp.now();
    const hoursAgo = req.body.hours || 24;
    const cutoffTime = new Date(now.toMillis() - (hoursAgo * 60 * 60 * 1000));
    
    const expiredSessionsSnapshot = await admin.firestore()
      .collection('sessions')
      .where('created_at', '<', admin.firestore.Timestamp.fromDate(cutoffTime))
      .get();
    
    const batch = admin.firestore().batch();
    let deleteCount = 0;
    
    expiredSessionsSnapshot.forEach((doc) => {
      const sessionData = doc.data();
      const hasReceipt = sessionData.payment_status === 'PAID';
      const isCompleted = sessionData.status === 'COMPLETED';
      const isExpired = sessionData.status === 'EXPIRED' || 
                       (sessionData.expires_at && sessionData.expires_at.toMillis() < now.toMillis());
      
      if (hasReceipt || isCompleted || isExpired) {
        batch.delete(doc.ref);
        deleteCount++;
      }
    });
    
    if (deleteCount > 0) {
      await batch.commit();
    }
    
    res.json({
      success: true,
      message: `Deleted ${deleteCount} expired sessions`,
      cutoffTime: cutoffTime.toISOString(),
    });
  } catch (error) {
    console.error('Error in manual cleanup:', error);
    res.status(500).json({ error: error.message });
  }
});
