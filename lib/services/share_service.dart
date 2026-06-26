import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Wraps file I/O + share_plus so screens don't deal with raw
/// `dart:io` paths. Both the PDF invoice and the screenshot-based
/// image invoice go through this same save/share pipeline.
class ShareService {
  /// Writes [bytes] to a temporary file named [fileName] and returns
  /// the saved [File].
  static Future<File> saveBytesToTempFile(
    Uint8List bytes,
    String fileName,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Shares a single file (PDF or image) using the platform share sheet.
  static Future<void> shareFile(File file, {String? text}) async {
    await Share.shareXFiles(
      [XFile(file.path)], 
      text: text
      );
  }

  /// Convenience: builds the PDF bytes into a temp file, named after
  /// the bill ID, and opens the share sheet immediately.
  static Future<void> sharePdfBytes({
    required Uint8List bytes,
    required int billId,
  }) async {
    final file = await saveBytesToTempFile(bytes, 'invoice_$billId.pdf');
    await shareFile(file, text: 'Invoice #$billId');
  }

  /// Convenience: builds a PNG image file from screenshot bytes and
  /// opens the share sheet immediately.
  static Future<void> shareImageBytes({
    required Uint8List bytes,
    required int billId,
  }) async {
    final file = await saveBytesToTempFile(bytes, 'invoice_$billId.png');
    await shareFile(file, text: 'Invoice #$billId');
  }
}