import 'dart:typed_data';
import 'package:pdf/pdf.dart'; 
import 'package:printing/printing.dart';
import '../models/bill_model.dart';
import '../models/bill_item_model.dart';
import 'invoice_service.dart'; // ✅ FIXED: Ensure it references the helper service file

class InvoicePrintService {
  /// Directly sends the generated invoice PDF bytes to the native print framework/spooler
  static Future<bool> printInvoice({
    required Bill bill,
    required List<BillItem> items,
  }) async {
    try {
      // ✅ Now it will cleanly resolve without "Undefined" crash
      final Uint8List pdfBytes = await InvoiceService.generateInvoicePdf(
        bill: bill,
        items: items,
        qrData: 'BILL-${bill.id ?? 0}',
      );

      // Triggers the native OS print dialogue box directly with explicit format mapping
      final bool printResult = await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Invoice_${bill.id ?? 'New'}',
        format: PdfPageFormat.roll80, 
      );
      
      return printResult;
    } catch (e) {
      print("Printing integration error: ${e.toString()}");
      return false;
    }
  }
}