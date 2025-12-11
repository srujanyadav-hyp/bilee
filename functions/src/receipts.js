const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const handlebars = require('handlebars');

const db = admin.firestore();

// Configure email transporter (use your email service)
const transporter = nodemailer.createTransport({
  service: 'gmail', // or 'SendGrid', 'AWS SES', etc.
  auth: {
    user: process.env.EMAIL_USER || 'noreply@bilee.app',
    pass: process.env.EMAIL_PASSWORD || 'your-app-password',
  },
});

/**
 * Send receipt to customer via email
 */
async function sendReceipt(sessionId, recipientEmail, sessionData) {
  // Email template
  const template = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: Arial, sans-serif; background: #F8F9FA; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; overflow: hidden; }
        .header { background: linear-gradient(135deg, #00D4AA 0%, #1E5BFF 100%); color: white; padding: 30px; text-align: center; }
        .content { padding: 30px; }
        .receipt-info { background: #F8F9FA; padding: 15px; border-radius: 8px; margin-bottom: 20px; }
        .items { margin: 20px 0; }
        .item { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #DEE2E6; }
        .totals { margin-top: 20px; padding-top: 20px; border-top: 2px solid #DEE2E6; }
        .total-row { display: flex; justify-content: space-between; padding: 5px 0; }
        .total-row.final { font-weight: bold; font-size: 18px; color: #1E5BFF; }
        .footer { text-align: center; padding: 20px; color: #6C757D; font-size: 12px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Payment Receipt</h1>
          <p>BILEE - Paperless Billing</p>
        </div>
        
        <div class="content">
          <div class="receipt-info">
            <p><strong>Session ID:</strong> {{sessionId}}</p>
            <p><strong>Date:</strong> {{date}}</p>
            <p><strong>Payment Method:</strong> {{paymentMethod}}</p>
            {{#if txnId}}
            <p><strong>Transaction ID:</strong> {{txnId}}</p>
            {{/if}}
          </div>
          
          <h2>Items</h2>
          <div class="items">
            {{#each items}}
            <div class="item">
              <span>{{name}} × {{qty}}</span>
              <span>₹{{total}}</span>
            </div>
            {{/each}}
          </div>
          
          <div class="totals">
            <div class="total-row">
              <span>Subtotal:</span>
              <span>₹{{subtotal}}</span>
            </div>
            <div class="total-row">
              <span>Tax:</span>
              <span>₹{{tax}}</span>
            </div>
            <div class="total-row final">
              <span>Total Paid:</span>
              <span>₹{{total}}</span>
            </div>
          </div>
        </div>
        
        <div class="footer">
          <p>Thank you for your business!</p>
          <p>This is an automated receipt from BILEE</p>
        </div>
      </div>
    </body>
    </html>
  `;

  const compiledTemplate = handlebars.compile(template);
  const html = compiledTemplate({
    sessionId: sessionId,
    date: new Date(sessionData.createdAt.toDate()).toLocaleString('en-IN'),
    paymentMethod: sessionData.paymentMethod || 'N/A',
    txnId: sessionData.txnId,
    items: sessionData.items.map(item => ({
      name: item.name,
      qty: item.qty,
      total: item.total.toFixed(2),
    })),
    subtotal: sessionData.subtotal.toFixed(2),
    tax: sessionData.tax.toFixed(2),
    total: sessionData.total.toFixed(2),
  });

  // Send email
  const mailOptions = {
    from: '"BILEE" <noreply@bilee.app>',
    to: recipientEmail,
    subject: `Payment Receipt - ${sessionId}`,
    html: html,
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log('Receipt sent:', info.messageId);
    
    // Log to Firestore for tracking
    await db.collection('emailLogs').add({
      sessionId: sessionId,
      recipient: recipientEmail,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      messageId: info.messageId,
      status: 'sent',
    });
    
    return info;
  } catch (error) {
    console.error('Error sending receipt email:', error);
    
    // Log failed attempt
    await db.collection('emailLogs').add({
      sessionId: sessionId,
      recipient: recipientEmail,
      attemptedAt: admin.firestore.FieldValue.serverTimestamp(),
      error: error.message,
      status: 'failed',
    });
    
    throw error;
  }
}

module.exports = { sendReceipt };
