// services/certificate_file_saver.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class CertificateFileSaver {
  CertificateFileSaver._();

  static Future<File> savePdf(Uint8List bytes, String certificateId) async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/certificate_$certificateId.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Converts the first page of a PDF to PNG at 200 dpi.
  static Future<File> savePng(Uint8List pdfBytes, String certificateId) async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/certificate_$certificateId.png');
    await for (final page in Printing.raster(pdfBytes, dpi: 200)) {
      await file.writeAsBytes(await page.toPng());
      break; // first page only
    }
    return file;
  }
}