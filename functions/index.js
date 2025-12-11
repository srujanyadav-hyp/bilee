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
 * POST /generate_daily_report
 * Body: { merchant_id: string, date: string, format: 'PDF'|'CSV' }
 */
exports.generateDailyReport = functions.https.onRequest(async (req, res) => {
  try {
    const { merchant_id, date, format = 'PDF' } = req.body;
    
    if (!merchant_id || !date) {
      return res.status(400).json({ error: 'merchant_id and date are required' });
    }

    // Fetch daily aggregate
    const aggregateId = `${merchant_id}_${date}`;
    const aggregateDoc = await admin.firestore()
      .collection('daily_aggregates')
      .doc(aggregateId)
      .get();
    
    if (!aggregateDoc.exists) {
      return res.status(404).json({ error: 'No data for this date' });
    }

    const aggregateData = aggregateDoc.data();
    
    // TODO: Generate actual PDF/CSV using pdfkit or csv-stringify
    // For now, create a simple text representation
    const reportContent = `
Daily Summary Report
Date: ${date}
Merchant ID: ${merchant_id}

Total Revenue: ₹${aggregateData.total.toFixed(2)}
Orders: ${aggregateData.orders_count}
Items Sold: ${aggregateData.items_sold.reduce((sum, item) => sum + item.qty, 0)}

Items Breakdown:
${aggregateData.items_sold.map(item => `- ${item.name}: ${item.qty}`).join('\n')}
    `.trim();

    // Upload to Cloud Storage
    const [year, month, day] = date.split('-');
    const storagePath = `reports/${merchant_id}/${year}/${month}/${day}/daily_summary.${format.toLowerCase()}`;
    const bucket = admin.storage().bucket();
    const file = bucket.file(storagePath);
    
    await file.save(reportContent, {
      metadata: {
        contentType: format === 'PDF' ? 'application/pdf' : 'text/csv',
      },
    });

    // Generate signed URL (7-day expiry)
    const [signedUrl] = await file.getSignedUrl({
      action: 'read',
      expires: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days
    });

    res.json({
      success: true,
      report_url: signedUrl,
      expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
    });
  } catch (error) {
    console.error('Error generating report:', error);
    res.status(500).json({ error: error.message });
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
