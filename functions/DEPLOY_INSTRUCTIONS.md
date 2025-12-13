# Firebase Cloud Functions - Deployment Instructions

## Why Reports Were Failing

The PDF and CSV report generation was failing due to:

1. **Missing Dependencies** - `puppeteer`, `handlebars`, and `json2csv` packages were not installed
2. **Collection Name Mismatch** - Function queried using WHERE clauses instead of direct document ID access
3. **Data Field Mismatch** - Expected `itemsSold` but actual data has `items` field
4. **Wrong Function Type** - Used `onRequest` instead of `onCall` for proper client integration

## Fixes Applied

✅ Added missing dependencies to `package.json`:
- `puppeteer ^21.0.0` - For PDF generation
- `handlebars ^4.7.8` - For HTML templating
- `json2csv ^6.0.0` - For CSV export

✅ Fixed Firestore queries to use composite document IDs (`merchantId_date`)

✅ Fixed data field names to match actual aggregate structure

✅ Changed function type from `onRequest` to `onCall` for proper Firebase callable integration

✅ Added null safety and proper error handling

## Deployment Steps

### 1. Install Dependencies

```bash
cd functions
npm install
```

This will install:
- puppeteer (Chrome/Chromium for PDF generation)
- handlebars (HTML templating)
- json2csv (CSV generation)

### 2. Deploy Cloud Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy just the report generation function
firebase deploy --only functions:generateDailyReport
```

### 3. Verify Deployment

After deployment, check the Firebase Console:
1. Go to Firebase Console → Functions
2. Verify `generateDailyReport` function is listed
3. Check the function URL and configuration

### 4. Test Report Generation

From the Flutter app:
1. Navigate to Dashboard → Daily Summary
2. Click "Export PDF" or "Export CSV"
3. The function will generate and return a signed URL
4. The report will automatically open or show download link

## Function Details

### generateDailyReport

**Type:** `onCall` (Firebase Callable Function)

**Input:**
```json
{
  "merchantId": "string",
  "date": "YYYY-MM-DD",
  "format": "pdf" | "csv"
}
```

**Output:**
```json
{
  "success": true,
  "downloadUrl": "https://storage.googleapis.com/...",
  "expires_at": "ISO timestamp"
}
```

**Process:**
1. Fetches daily aggregate from Firestore (`dailyAggregates/{merchantId}_{date}`)
2. Generates PDF using Puppeteer + Handlebars OR CSV using json2csv
3. Uploads to Firebase Storage (`bilee-reports/{merchantId}/{date}.{format}`)
4. Returns signed URL (valid for 1 hour)

## Troubleshooting

### If deployment fails with "puppeteer install error":

Puppeteer downloads Chromium during installation. If this fails:

```bash
# Skip Chromium download, use system Chrome
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
npm install
```

Then update Cloud Function configuration to use system Chrome.

### If function times out:

Increase timeout in `firebase.json`:

```json
{
  "functions": {
    "runtime": "nodejs20",
    "timeout": "300s"
  }
}
```

### If PDF generation fails:

Check Cloud Function logs:

```bash
firebase functions:log --only generateDailyReport
```

Common issues:
- Missing Chrome/Chromium binary
- Insufficient memory (increase to 1GB or 2GB)
- Storage permissions not configured

### If reports show "No data":

Verify daily aggregates are being created:
1. Check Firestore → `dailyAggregates` collection
2. Verify document ID format: `{merchantId}_{YYYY-MM-DD}`
3. Check data structure matches expected format

## Cost Considerations

- **Function Invocations:** Each report generation = 1 invocation
- **Compute Time:** PDF generation takes ~5-10 seconds
- **Storage:** Reports stored in Firebase Storage (1-hour expiry)
- **Network:** Signed URL downloads don't count toward function egress

Estimated cost: ~₹0.50-1.00 per 100 reports (varies by region)

## Security Notes

- Reports contain sensitive business data
- Signed URLs expire after 1 hour
- Only authenticated merchants can generate their own reports
- Add authentication check in production:

```javascript
if (!context.auth) {
  throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
}
```

## Next Steps

After deployment:
1. Test report generation from Flutter app
2. Monitor function performance in Firebase Console
3. Set up Storage lifecycle rules to auto-delete old reports
4. Consider implementing report caching for frequently requested dates
