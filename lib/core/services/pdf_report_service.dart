import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../features/merchant/domain/entities/daily_aggregate_entity.dart';
import 'performance_service.dart';

/// PDF Report Service - Client-side PDF generation
/// COST OPTIMIZATION: Replaces expensive Puppeteer Cloud Function ($50-200/month)
///
/// Benefits:
/// - Zero server cost (runs on client device)
/// - Instant generation (no network latency)
/// - Offline capable
/// - Customizable by merchants
class PDFReportService {
  /// Generate daily sales report as PDF
  Future<Uint8List> generateDailyReport({
    required DailyAggregateEntity aggregate,
    required String merchantName,
    String? merchantAddress,
    String? merchantPhone,
    String? merchantGst,
    String? logoUrl,
  }) async {
    // Track PDF generation performance
    final pdfStartTime = DateTime.now();

    final pdf = pw.Document();
    final dateFormat = DateFormat('MMMM dd, yyyy');

    // Load ALL Indian language fonts for comprehensive script support
    // This enables proper rendering of Telugu, Hindi, Tamil, Kannada, Malayalam,
    // Marathi, Gujarati, Punjabi, Bengali, and English text in PDFs

    // Devanagari script (Hindi, Marathi, Sanskrit)
    final devanagariData = await rootBundle.load(
      'assets/fonts/NotoSansDevanagari/NotoSansDevanagari-Variable.ttf',
    );
    final devanagariFont = pw.Font.ttf(devanagariData);

    // Telugu script
    final teluguData = await rootBundle.load(
      'assets/fonts/NotoSansTelugu/NotoSansTelugu-Variable.ttf',
    );
    final teluguFont = pw.Font.ttf(teluguData);

    // Tamil script
    final tamilData = await rootBundle.load(
      'assets/fonts/NotoSansTamil/NotoSansTamil-Variable.ttf',
    );
    final tamilFont = pw.Font.ttf(tamilData);

    // Kannada script
    final kannadaData = await rootBundle.load(
      'assets/fonts/NotoSansKannada/NotoSansKannada-Variable.ttf',
    );
    final kannadaFont = pw.Font.ttf(kannadaData);

    // Malayalam script
    final malayalamData = await rootBundle.load(
      'assets/fonts/NotoSansMalayalam/NotoSansMalayalam-Variable.ttf',
    );
    final malayalamFont = pw.Font.ttf(malayalamData);

    // Gujarati script
    final gujaratiData = await rootBundle.load(
      'assets/fonts/NotoSansGujarati/NotoSansGujarati-Variable.ttf',
    );
    final gujaratiFont = pw.Font.ttf(gujaratiData);

    // Gurmukhi script (Punjabi)
    final gurmukhiData = await rootBundle.load(
      'assets/fonts/NotoSansGurmukhi/NotoSansGurmukhi-Variable.ttf',
    );
    final gurmukhiFont = pw.Font.ttf(gurmukhiData);

    // Bengali script
    final bengaliData = await rootBundle.load(
      'assets/fonts/NotoSansBengali/NotoSansBengali-Variable.ttf',
    );
    final bengaliFont = pw.Font.ttf(bengaliData);

    // Odia script (Oriya)
    final odiaData = await rootBundle.load(
      'assets/fonts/NotoSansOriya/NotoSansOriya-Variable.ttf',
    );
    final odiaFont = pw.Font.ttf(odiaData);

    // Create theme with Devanagari as base (covers Hindi, Marathi + Latin/English)
    // The PDF library will use the base font, but we'll explicitly specify fonts
    // for table cells to ensure proper rendering
    final theme = pw.ThemeData.withFont(
      base: devanagariFont,
      bold: devanagariFont,
    );

    // Font fallback list - PDF library will try fonts in order until it finds
    // one that supports the characters being rendered
    // ✅ CRITICAL FIX: Reorder to prioritize Telugu/regional fonts BEFORE Devanagari
    // This ensures Telugu characters are rendered with Telugu font, not garbled Devanagari
    final fontFallbacks = [
      teluguFont, // Telugu (prioritize first for Telugu text)
      tamilFont, // Tamil
      kannadaFont, // Kannada
      malayalamFont, // Malayalam
      devanagariFont, // Hindi, Marathi, English, numbers (moved to end as fallback)
      gujaratiFont, // Gujarati
      gurmukhiFont, // Punjabi
      bengaliFont, // Bengali
      odiaFont, // Odia
    ];

    // Currency format with rupee symbol
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    // Load logo if available
    pw.ImageProvider? logo;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        logo = await networkImage(logoUrl);
      } catch (e) {
        // Logo load failed, continue without it
        print('Failed to load logo: $e');
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: theme, // Apply custom theme with font
        build: (context) => [
          // Header with logo and business info
          _buildHeader(
            merchantName: merchantName,
            merchantAddress: merchantAddress,
            merchantPhone: merchantPhone,
            merchantGst: merchantGst,
            logo: logo,
            fontFallbacks: fontFallbacks,
          ),

          pw.SizedBox(height: 20),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 20),

          // Report Title
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'Daily Sales Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Date: ${dateFormat.format(DateTime.parse(aggregate.date))}',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 30),

          // Summary Cards
          _buildSummaryCards(
            totalRevenue: aggregate.totalRevenue,
            totalOrders: aggregate.totalOrders,
            currencyFormat: currencyFormat,
          ),

          pw.SizedBox(height: 30),

          // Items Sold Table
          pw.Text(
            'Items Sold',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildItemsTable(
            items: aggregate.items,
            currencyFormat: currencyFormat,
            fontFallbacks: fontFallbacks,
          ),

          pw.SizedBox(height: 40),

          // Footer
          _buildFooter(),
        ],
      ),
    );

    // Track PDF generation performance
    final pdfEndTime = DateTime.now();
    PerformanceService.trackPDFGeneration(
      duration: pdfEndTime.difference(pdfStartTime),
      reportType: 'daily_sales',
      pageCount: pdf.document.pdfPageList.pages.length,
    );

    return pdf.save();
  }

  /// Build header with business info
  pw.Widget _buildHeader({
    required String merchantName,
    String? merchantAddress,
    String? merchantPhone,
    String? merchantGst,
    pw.ImageProvider? logo,
    required List<pw.Font> fontFallbacks,
  }) {
    // Detect fonts for merchant info (may contain Indian language text)
    final nameFont = _detectFont(merchantName, fontFallbacks);
    final addressFont = merchantAddress != null
        ? _detectFont(merchantAddress, fontFallbacks)
        : fontFallbacks[4];

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Business Info
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              merchantName,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                font: nameFont,
                fontFallback: fontFallbacks,
              ),
            ),
            if (merchantAddress != null) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                merchantAddress,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                  font: addressFont,
                  fontFallback: fontFallbacks,
                ),
              ),
            ],
            if (merchantPhone != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                'Phone: $merchantPhone',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
            if (merchantGst != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                'GSTIN: $merchantGst',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ],
        ),

        // Logo
        if (logo != null)
          pw.Container(width: 80, height: 80, child: pw.Image(logo))
        else
          pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Center(
              child: pw.Text(
                merchantName.substring(0, 1).toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build summary cards with key metrics
  pw.Widget _buildSummaryCards({
    required double totalRevenue,
    required int totalOrders,
    required NumberFormat currencyFormat,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryCard(
            title: 'Total Revenue',
            value: currencyFormat.format(totalRevenue),
            icon: '₹',
            color: PdfColors.green700,
          ),
          pw.Container(width: 1, height: 60, color: PdfColors.grey400),
          _buildSummaryCard(
            title: 'Total Orders',
            value: totalOrders.toString(),
            icon: '#',
            color: PdfColors.blue700,
          ),
        ],
      ),
    );
  }

  /// Build individual summary card
  pw.Widget _buildSummaryCard({
    required String title,
    required String value,
    required String icon,
    required PdfColor color,
  }) {
    return pw.Column(
      children: [
        pw.Container(
          width: 50,
          height: 50,
          decoration: pw.BoxDecoration(
            color: color.shade(0.1),
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text(
              icon,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  /// Detect script from text and return appropriate font
  /// Supports all major Indian languages by Unicode range detection
  /// Scans entire text to find the dominant script (not just first character)
  pw.Font _detectFont(String text, List<pw.Font> fontFallbacks) {
    if (text.isEmpty) return fontFallbacks[4]; // Default to Devanagari

    // Count characters in each script to find dominant language
    int teluguCount = 0;
    int tamilCount = 0;
    int kannadaCount = 0;
    int malayalamCount = 0;
    int devanagariCount = 0;
    int gujaratiCount = 0;
    int gurmukhiCount = 0;
    int bengaliCount = 0;
    int odiaCount = 0;

    // Scan all characters to find which script dominates
    for (int i = 0; i < text.length; i++) {
      final codePoint = text.codeUnitAt(i);

      // Telugu: U+0C00–U+0C7F
      if (codePoint >= 0x0C00 && codePoint <= 0x0C7F) {
        teluguCount++;
      }
      // Tamil: U+0B80–U+0BFF
      else if (codePoint >= 0x0B80 && codePoint <= 0x0BFF) {
        tamilCount++;
      }
      // Kannada: U+0C80–U+0CFF
      else if (codePoint >= 0x0C80 && codePoint <= 0x0CFF) {
        kannadaCount++;
      }
      // Malayalam: U+0D00–U+0D7F
      else if (codePoint >= 0x0D00 && codePoint <= 0x0D7F) {
        malayalamCount++;
      }
      // Devanagari (Hindi, Marathi, Sanskrit): U+0900–U+097F
      else if (codePoint >= 0x0900 && codePoint <= 0x097F) {
        devanagariCount++;
      }
      // Gujarati: U+0A80–U+0AFF
      else if (codePoint >= 0x0A80 && codePoint <= 0x0AFF) {
        gujaratiCount++;
      }
      // Gurmukhi (Punjabi): U+0A00–U+0A7F
      else if (codePoint >= 0x0A00 && codePoint <= 0x0A7F) {
        gurmukhiCount++;
      }
      // Bengali: U+0980–U+09FF
      else if (codePoint >= 0x0980 && codePoint <= 0x09FF) {
        bengaliCount++;
      }
      // Odia (Oriya): U+0B00–U+0B7F
      else if (codePoint >= 0x0B00 && codePoint <= 0x0B7F) {
        odiaCount++;
      }
    }

    // Return font for the script with most characters
    int maxCount = 0;
    pw.Font selectedFont = fontFallbacks[4]; // Default Devanagari

    if (teluguCount > maxCount) {
      maxCount = teluguCount;
      selectedFont = fontFallbacks[0]; // Telugu
    }
    if (tamilCount > maxCount) {
      maxCount = tamilCount;
      selectedFont = fontFallbacks[1]; // Tamil
    }
    if (kannadaCount > maxCount) {
      maxCount = kannadaCount;
      selectedFont = fontFallbacks[2]; // Kannada
    }
    if (malayalamCount > maxCount) {
      maxCount = malayalamCount;
      selectedFont = fontFallbacks[3]; // Malayalam
    }
    if (devanagariCount > maxCount) {
      maxCount = devanagariCount;
      selectedFont = fontFallbacks[4]; // Devanagari
    }
    if (gujaratiCount > maxCount) {
      maxCount = gujaratiCount;
      selectedFont = fontFallbacks[5]; // Gujarati
    }
    if (gurmukhiCount > maxCount) {
      maxCount = gurmukhiCount;
      selectedFont = fontFallbacks[6]; // Gurmukhi
    }
    if (bengaliCount > maxCount) {
      maxCount = bengaliCount;
      selectedFont = fontFallbacks[7]; // Bengali
    }
    if (odiaCount > maxCount) {
      maxCount = odiaCount;
      selectedFont = fontFallbacks[8]; // Odia
    }

    // If no Indian script found (pure English/numbers), use Devanagari
    // Devanagari font includes Latin characters and numbers
    return selectedFont;
  }

  /// Build items sold table with smart font detection
  pw.Widget _buildItemsTable({
    required List<AggregatedItemEntity> items,
    required NumberFormat currencyFormat,
    required List<pw.Font> fontFallbacks,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue800),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Item Name',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  font: fontFallbacks[4], // Devanagari for headers (English)
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Quantity Sold',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  font: fontFallbacks[4],
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Revenue',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  font: fontFallbacks[4],
                ),
              ),
            ),
          ],
        ),
        // Data rows with smart font detection
        ...items.map((item) {
          // ✅ SMART FONT DETECTION: Automatically pick correct font for item name
          final itemFont = _detectFont(item.name, fontFallbacks);

          // Create custom fallback list with detected font FIRST
          // This ensures the correct script font is prioritized
          final customFallbacks = [
            itemFont,
            ...fontFallbacks.where((f) => f != itemFont),
          ];

          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  item.name,
                  style: pw.TextStyle(
                    fontSize: 11,
                    font: itemFont, // Primary font for detected script
                    fontFallback:
                        customFallbacks, // Detected font first, then others
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  item.quantity.toString(),
                  style: pw.TextStyle(
                    fontSize: 11,
                    font:
                        fontFallbacks[4], // Numbers use Devanagari (has Latin)
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  currencyFormat.format(item.revenue),
                  style: pw.TextStyle(
                    fontSize: 11,
                    font: fontFallbacks[4], // Currency uses Devanagari (has ₹)
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Build footer
  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'BILEE - Paperless Billing System',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'This report is generated automatically and contains sensitive business data.',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated at ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Share PDF via platform share dialog
  Future<void> sharePDF({
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }

  /// Print PDF directly
  Future<void> printPDF({required Uint8List pdfBytes, String? jobName}) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: jobName ?? 'Daily Report',
    );
  }

  /// Save PDF to device storage
  Future<String?> savePDF({
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    try {
      // On mobile, this will save to downloads
      // On web, this will trigger browser download
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      return filename;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }
}
