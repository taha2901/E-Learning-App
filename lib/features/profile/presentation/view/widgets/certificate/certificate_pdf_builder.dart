import 'dart:typed_data';
import 'package:e_learning/features/profile/data/models/certificate_data.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CertificatePdfBuilder {
  CertificatePdfBuilder._();

  // PDF palette
  static const _purple      = PdfColor.fromInt(0xFF6C63FF);
  static const _purpleLight = PdfColor.fromInt(0xFFEEF0FF);
  static const _gold        = PdfColor.fromInt(0xFFD4AF37);
  static const _dark        = PdfColor.fromInt(0xFF1A1A2E);
  static const _grey        = PdfColor.fromInt(0xFF6B7280);
  static const _green       = PdfColor.fromInt(0xFF00C896);
  static const _white       = PdfColors.white;
  static const _bg          = PdfColor.fromInt(0xFFFAFAFE);
  static const _divider     = PdfColor.fromInt(0xFFE5E7EB);

  static Future<Uint8List> build(CertificateData data) async {
    final pdf     = pw.Document();
    final dateStr = DateFormat('MMMM d, yyyy').format(data.completionDate);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (ctx) => pw.Stack(
          children: [
            _background(),
            _topBars(),
            _bottomBars(),
            _leftBar(),
            _rightBar(),
            _outerGoldBorder(),
            _innerPurpleBorder(),
            _mainContent(data, dateStr),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ── Border / frame helpers ───────────────────────────────

  static pw.Widget _background() =>
      pw.Positioned.fill(child: pw.Container(color: _bg));

  static pw.Widget _topBars() => pw.Positioned(
    top: 0, left: 0, right: 0,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(height: 8, color: _purple),
        pw.Container(height: 5, color: _gold),
      ],
    ),
  );

  static pw.Widget _bottomBars() => pw.Positioned(
    bottom: 0, left: 0, right: 0,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(height: 5, color: _gold),
        pw.Container(height: 8, color: _purple),
      ],
    ),
  );

  static pw.Widget _leftBar() => pw.Positioned(
    top: 0, bottom: 0, left: 0,
    child: pw.Row(children: [
      pw.Container(width: 8, color: _purple),
      pw.Container(width: 4, color: _gold),
    ]),
  );

  static pw.Widget _rightBar() => pw.Positioned(
    top: 0, bottom: 0, right: 0,
    child: pw.Row(children: [
      pw.Container(width: 4, color: _gold),
      pw.Container(width: 8, color: _purple),
    ]),
  );

  static pw.Widget _outerGoldBorder() => pw.Positioned(
    top: 18, left: 18, right: 18, bottom: 18,
    child: pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _gold, width: 2.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
    ),
  );

  static pw.Widget _innerPurpleBorder() => pw.Positioned(
    top: 26, left: 26, right: 26, bottom: 26,
    child: pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _purple, width: 1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
    ),
  );

  // ── Main content ─────────────────────────────────────────

  static pw.Widget _mainContent(CertificateData data, String dateStr) {
    return pw.Positioned.fill(
      child: pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(60, 32, 60, 32),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            _pdfLogo(),
            pw.SizedBox(height: 6),
            pw.Container(width: 260, height: 1, color: _gold),
            pw.SizedBox(height: 10),
            _pdfTitle(),
            pw.SizedBox(height: 10),
            pw.Text(
              'This is to proudly certify that',
              style: pw.TextStyle(color: _grey, fontSize: 12),
            ),
            pw.SizedBox(height: 10),
            _pdfStudentPill(data.studentName),
            pw.SizedBox(height: 10),
            pw.Text(
              'has successfully completed the course',
              style: pw.TextStyle(color: _grey, fontSize: 12),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              data.courseName,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: _purple,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Container(height: 1, color: _divider),
            pw.SizedBox(height: 14),
            _pdfBottomRow(data, dateStr),
            pw.Expanded(child: pw.SizedBox()),
            pw.Text(
              'Certificate ID: ${data.certificateId}  •  Issued by LearnFlow Academy',
              style: pw.TextStyle(color: _grey, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _pdfLogo() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Container(
          width: 30,
          height: 30,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: _purple,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            'L',
            style: pw.TextStyle(
              color: _white,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          'LearnFlow',
          style: pw.TextStyle(
            color: _purple,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _pdfTitle() {
    return pw.Column(children: [
      pw.Text(
        'CERTIFICATE',
        style: pw.TextStyle(
          color: _dark,
          fontSize: 40,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'O F   C O M P L E T I O N',
        style: pw.TextStyle(
          color: _gold,
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    ]);
  }

  static pw.Widget _pdfStudentPill(String name) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _purpleLight,
        border: pw.Border.all(color: _purple, width: 1.5),
        borderRadius: pw.BorderRadius.circular(40),
      ),
      child: pw.Text(
        name,
        style: pw.TextStyle(
          color: _dark,
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _pdfBottomRow(CertificateData data, String dateStr) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        _pdfSignatureColumn(dateStr, 'Completion Date'),
        _pdfVerifiedBadge(),
        _pdfSignatureColumn(data.instructorName, 'Instructor'),
      ],
    );
  }

  static pw.Widget _pdfSignatureColumn(String value, String label) {
    return pw.Column(children: [
      pw.Container(width: 160, height: 1, color: _dark),
      pw.SizedBox(height: 4),
      pw.Text(
        value,
        style: pw.TextStyle(
          color: _dark,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.Text(
        label,
        style: pw.TextStyle(color: _grey, fontSize: 10),
      ),
    ]);
  }

  static pw.Widget _pdfVerifiedBadge() {
    return pw.Container(
      width: 52,
      height: 52,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        color: const PdfColor.fromInt(0x1A00C896),
        border: pw.Border.all(color: _green, width: 2.5),
      ),
      child: pw.Text(
        '✓',
        style: pw.TextStyle(
          color: _green,
          fontSize: 22,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }
}