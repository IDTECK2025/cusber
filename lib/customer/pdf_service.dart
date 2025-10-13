import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gold_pos/models/customer_model.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class CustomerPDFService {
  /// Generate a PDF document for the given customer
  static Future<pw.Document> _generateCustomerPDF(Customer customer) async {
    final regularFont = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(customer),
            pw.SizedBox(height: 24),
            _buildSection('PERSONAL DETAILS', [
              ['Full Name', customer.fullName],
              ['Email Address', customer.email],
              ['Phone Number', customer.phoneNumber],
              ['Customer ID', customer.customerId],
              ['Nominee Name', customer.nomineeName],
              ['Nominee Phone', customer.nomineePhone],
            ]),
            pw.SizedBox(height: 16),
            _buildSection('ADDRESS DETAILS', [
              ['Address', customer.address],
              ['City', customer.city],
              ['State', customer.state],
            ]),
            pw.SizedBox(height: 16),
            _buildSection('SCHEME DETAILS', [
              ['Scheme Amount', '₹${customer.schemeAmount.toStringAsFixed(2)}'],
              ['Join Date', _formatDate(customer.joinDate)],
              ['Scheme Date', _formatDate(customer.schemeDate)],
            ]),
          ];
        },
        footer: (pw.Context context) => _buildFooter(),
      ),
    );

    return pdf;
  }

  /// Show PDF Preview dialog
  static Future<void> preview(Customer customer, BuildContext context) async {
    try {
      final pdf = await _generateCustomerPDF(customer);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 700),
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: PdfPreview(
                            build: (format) => pdf.save(),
                            padding: EdgeInsets.zero,
                            allowPrinting: false,
                            allowSharing: false,
                            canChangeOrientation: false,
                            canChangePageFormat: false,
                            canDebug: false,
                            maxPageWidth: 700,
                            initialPageFormat: PdfPageFormat.a4,
                            pdfFileName:
                                'Customer_${customer.customerId}_${customer.fullName.replaceAll(' ', '_')}.pdf',
                            pdfPreviewPageDecoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () => printPDF(customer, context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text(
                                  'PRINT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await download(customer, context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.download,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Download',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      _showError(context, 'Error generating PDF: $e');
    }
  }

  /// Print PDF
  static Future<void> printPDF(Customer customer, BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdf = await _generateCustomerPDF(customer);

      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        try {
          final printers = await Printing.listPrinters();
          if (printers.isNotEmpty) {
            await Printing.directPrintPdf(
              printer: printers.first,
              onLayout: (_) async => pdf.save(),
              name: 'Customer_Details_${DateTime.now().millisecondsSinceEpoch}',
            );
            _showSuccess(context, 'Sent to printer successfully!');
            return;
          }
        } catch (e) {
          debugPrint('Direct print failed: $e');
        }
      }

      // Fallback → print dialog
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'Customer_Details_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      _showError(context, 'Printing failed: $e');
    } finally {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  /// Save/Download PDF
  static Future<void> download(Customer customer, BuildContext context) async {
    try {
      final pdf = await _generateCustomerPDF(customer);
      final fileName =
          'Customer_${customer.customerId}_${customer.fullName.replaceAll(' ', '_')}.pdf';

      try {
        final outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Customer Details PDF',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(await pdf.save());
          _showSuccess(
            context,
            'PDF saved successfully: ${path.basename(outputFile)}',
          );
          return;
        } else {
          _showWarning(context, 'Save canceled');
          return;
        }
      } catch (pickerError) {
        debugPrint('File picker failed: $pickerError');

        final documentsDir = await getApplicationDocumentsDirectory();
        final filePath = path.join(documentsDir.path, fileName);

        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());

        _showSuccess(context, 'PDF saved to Documents folder: $fileName');
      }
    } catch (e) {
      _showError(context, 'Save failed: $e');
    }
  }

  // --- Private helpers ---

  static pw.Widget _buildHeader(Customer customer) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 2, color: PdfColor.fromInt(0xFFc49253)),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CUSTOMER DETAILS',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFFc49253),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Customer ID:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                customer.customerId,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSection(String title, List<List<String>> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFFc49253),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2.5),
            },
            children:
                data.map((row) {
                  return pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                          border: pw.Border(
                            right: pw.BorderSide(color: PdfColors.grey300),
                          ),
                        ),
                        child: pw.Text(
                          row[0],
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          row[1].isNotEmpty ? row[1] : 'Not provided',
                          style: const pw.TextStyle(fontSize: 11, height: 1.3),
                          maxLines:
                              title == 'ADDRESS DETAILS' && row[0] == 'Address'
                                  ? 6
                                  : 2,
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(width: 1, color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Text(
            'System Generated Document',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    return date != null
        ? DateFormat('dd/MM/yyyy').format(date)
        : 'Not provided';
  }

  static void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  static void _showSuccess(BuildContext context, String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  static void _showWarning(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.orange),
    );
  }
}
