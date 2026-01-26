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
    final fontFallbacks = [
      devanagariFont, // Hindi, Marathi, English, numbers
      teluguFont, // Telugu
      tamilFont, // Tamil
      kannadaFont, // Kannada
      malayalamFont, // Malayalam
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
  }) {
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
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            if (merchantAddress != null) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                merchantAddress,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
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

  /// Build items sold table
  pw.Widget _buildItemsTable({
    required List<AggregatedItemEntity> items,
    required NumberFormat currencyFormat,
    required List<pw.Font> fontFallbacks,
  }) {
    return pw.Table.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        font: fontFallbacks[0], // Use Devanagari for headers (includes Latin)
        fontFallback: fontFallbacks,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: pw.TextStyle(
        fontSize: 11,
        font:
            fontFallbacks[0], // Base font (Devanagari - includes Latin/English)
        fontFallback: fontFallbacks, // Fallback for other Indian scripts
      ),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Item Name', 'Quantity Sold', 'Revenue'],
      data: items
          .map(
            (item) => [
              item.name,
              item.quantity.toString(),
              currencyFormat.format(item.revenue),
            ],
          )
          .toList(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
      },
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
