const admin = require('firebase-admin');
const puppeteer = require('puppeteer');
const handlebars = require('handlebars');
const { Parser } = require('json2csv');

const db = admin.firestore();
const bucket = admin.storage().bucket();

/**
 * Generate daily report in PDF or CSV format
 */
async function generateDailyReport(merchantId, date, format) {
  // Fetch daily aggregate from Firestore
  const aggregateQuery = await db
    .collection('dailyAggregates')
    .where('merchantId', '==', merchantId)
    .where('date', '==', date)
    .limit(1)
    .get();

  if (aggregateQuery.empty) {
    throw new Error(`No data found for merchant ${merchantId} on ${date}`);
  }

  const aggregateData = aggregateQuery.docs[0].data();

  if (format.toLowerCase() === 'pdf') {
    return await generatePDFReport(merchantId, date, aggregateData);
  } else {
    return await generateCSVReport(merchantId, date, aggregateData);
  }
}

/**
 * Generate PDF report using Puppeteer
 */
async function generatePDFReport(merchantId, date, data) {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  try {
    const page = await browser.newPage();

    // HTML template for PDF
    const template = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; }
          .header { text-align: center; margin-bottom: 30px; }
          .header h1 { color: #1E5BFF; margin: 0; }
          .header p { color: #6C757D; margin: 5px 0; }
          .summary { background: #F8F9FA; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
          .summary-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
          .summary-item { text-align: center; }
          .summary-item .label { color: #6C757D; font-size: 14px; }
          .summary-item .value { font-size: 32px; font-weight: bold; color: #212529; margin-top: 5px; }
          table { width: 100%; border-collapse: collapse; margin-top: 20px; }
          th { background: #1E5BFF; color: white; padding: 12px; text-align: left; }
          td { padding: 10px; border-bottom: 1px solid #DEE2E6; }
          tr:hover { background: #F8F9FA; }
          .footer { text-align: center; margin-top: 40px; color: #6C757D; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>BILEE Daily Sales Report</h1>
          <p>Date: {{date}}</p>
          <p>Generated on: {{generatedDate}}</p>
        </div>
        
        <div class="summary">
          <h2>Summary</h2>
          <div class="summary-grid">
            <div class="summary-item">
              <div class="label">Total Revenue</div>
              <div class="value">₹{{total}}</div>
            </div>
            <div class="summary-item">
              <div class="label">Total Orders</div>
              <div class="value">{{ordersCount}}</div>
            </div>
          </div>
        </div>
        
        <h2>Items Sold</h2>
        <table>
          <thead>
            <tr>
              <th>Item Name</th>
              <th>Quantity Sold</th>
              <th>Revenue</th>
            </tr>
          </thead>
          <tbody>
            {{#each items}}
            <tr>
              <td>{{name}}</td>
              <td>{{qty}}</td>
              <td>₹{{revenue}}</td>
            </tr>
            {{/each}}
          </tbody>
        </table>
        
        <div class="footer">
          <p>BILEE - Paperless Billing System</p>
          <p>This report is generated automatically and contains sensitive business data.</p>
        </div>
      </body>
      </html>
    `;

    const compiledTemplate = handlebars.compile(template);
    const html = compiledTemplate({
      date: date,
      generatedDate: new Date().toLocaleString('en-IN'),
      total: data.total.toFixed(2),
      ordersCount: data.ordersCount,
      items: data.itemsSold.map(item => ({
        name: item.name,
        qty: item.qty,
        revenue: item.revenue.toFixed(2),
      })),
    });

    await page.setContent(html);
    const pdfBuffer = await page.pdf({
      format: 'A4',
      printBackground: true,
      margin: { top: '20px', right: '20px', bottom: '20px', left: '20px' },
    });

    // Upload to Firebase Storage
    const fileName = `bilee-reports/${merchantId}/${date}.pdf`;
    const file = bucket.file(fileName);
    
    await file.save(pdfBuffer, {
      metadata: {
        contentType: 'application/pdf',
        metadata: {
          merchantId: merchantId,
          date: date,
          generatedAt: new Date().toISOString(),
        },
      },
    });

    // Make file publicly accessible for limited time (1 hour)
    const [url] = await file.getSignedUrl({
      action: 'read',
      expires: Date.now() + 60 * 60 * 1000, // 1 hour
    });

    return url;
  } finally {
    await browser.close();
  }
}

/**
 * Generate CSV report
 */
async function generateCSVReport(merchantId, date, data) {
  // Prepare data for CSV
  const csvData = data.itemsSold.map(item => ({
    'Item Name': item.name,
    'Quantity Sold': item.qty,
    'Revenue (₹)': item.revenue.toFixed(2),
  }));

  // Add summary row
  csvData.push({
    'Item Name': '--- SUMMARY ---',
    'Quantity Sold': '',
    'Revenue (₹)': '',
  });
  csvData.push({
    'Item Name': 'Total Orders',
    'Quantity Sold': data.ordersCount,
    'Revenue (₹)': '',
  });
  csvData.push({
    'Item Name': 'Total Revenue',
    'Quantity Sold': '',
    'Revenue (₹)': data.total.toFixed(2),
  });

  const parser = new Parser();
  const csv = parser.parse(csvData);

  // Upload to Firebase Storage
  const fileName = `bilee-reports/${merchantId}/${date}.csv`;
  const file = bucket.file(fileName);
  
  await file.save(csv, {
    metadata: {
      contentType: 'text/csv',
      metadata: {
        merchantId: merchantId,
        date: date,
        generatedAt: new Date().toISOString(),
      },
    },
  });

  // Make file publicly accessible for limited time (1 hour)
  const [url] = await file.getSignedUrl({
    action: 'read',
    expires: Date.now() + 60 * 60 * 1000, // 1 hour
  });

  return url;
}

module.exports = { generateDailyReport };
