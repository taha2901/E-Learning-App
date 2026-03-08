import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL  (adapt to your existing CourseModel / UserModel)
// ─────────────────────────────────────────────────────────────────────────────
class CertificateData {
  final String studentName;
  final String courseName;
  final String instructorName;
  final DateTime completionDate;   
  final String certificateId;

  const CertificateData({
    required this.studentName,
    required this.courseName,
    required this.instructorName,
    required this.completionDate,
    required this.certificateId,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CertificateScreen extends StatefulWidget {
  final CertificateData data;

  const CertificateScreen({super.key, required this.data});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isGenerating = false;

  // ── App colours (match your AppColors) ──────────────────
  static const _purple      = Color(0xFF6C63FF);
  static const _purpleLight = Color(0xFFEEF0FF);
  static const _gold        = Color(0xFFD4AF37);
  static const _dark        = Color(0xFF1A1A2E);
  static const _grey        = Color(0xFF6B7280);
  static const _green       = Color(0xFF00C896);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Build PDF bytes ──────────────────────────────────────
  Future<Uint8List> _buildPdfBytes() async {
    final pdf = pw.Document();
    final d   = widget.data;
    final dateStr = DateFormat('MMMM d, yyyy').format(d.completionDate);

    // PDF palette
    const purple      = PdfColor.fromInt(0xFF6C63FF);
    const purpleLight = PdfColor.fromInt(0xFFEEF0FF);
    const gold        = PdfColor.fromInt(0xFFD4AF37);
    const dark        = PdfColor.fromInt(0xFF1A1A2E);
    const grey        = PdfColor.fromInt(0xFF6B7280);
    const green       = PdfColor.fromInt(0xFF00C896);
    const white       = PdfColors.white;
    const bg          = PdfColor.fromInt(0xFFFAFAFE);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (ctx) => pw.Stack(
          children: [
            // Background
            pw.Positioned.fill(child: pw.Container(color: bg)),

            // Top purple + gold bars
            pw.Positioned(
              top: 0, left: 0, right: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(height: 8, color: purple),
                  pw.Container(height: 5, color: gold),
                ],
              ),
            ),

            // Bottom bars
            pw.Positioned(
              bottom: 0, left: 0, right: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(height: 5, color: gold),
                  pw.Container(height: 8, color: purple),
                ],
              ),
            ),

            // Left bar
            pw.Positioned(
              top: 0, bottom: 0, left: 0,
              child: pw.Row(children: [
                pw.Container(width: 8, color: purple),
                pw.Container(width: 4, color: gold),
              ]),
            ),

            // Right bar
            pw.Positioned(
              top: 0, bottom: 0, right: 0,
              child: pw.Row(children: [
                pw.Container(width: 4, color: gold),
                pw.Container(width: 8, color: purple),
              ]),
            ),

            // Outer gold border
            pw.Positioned(
              top: 18, left: 18, right: 18, bottom: 18,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: gold, width: 2.5),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
              ),
            ),

            // Inner purple border
            pw.Positioned(
              top: 26, left: 26, right: 26, bottom: 26,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: purple, width: 1),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
              ),
            ),

            // ── Main content ─────────────────────────────
            pw.Positioned.fill(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(60, 32, 60, 32),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [

                    // Logo
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 30, height: 30,
                          decoration: pw.BoxDecoration(
                            color: purple,
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.Text('L',
                            style: pw.TextStyle(
                              color: white, fontSize: 16,
                              fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text('LearnFlow',
                          style: pw.TextStyle(
                            color: purple, fontSize: 18,
                            fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(width: 260, height: 1, color: gold),
                    pw.SizedBox(height: 10),

                    // Title
                    pw.Text('CERTIFICATE',
                      style: pw.TextStyle(
                        color: dark, fontSize: 40,
                        fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('O F   C O M P L E T I O N',
                      style: pw.TextStyle(
                        color: gold, fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2)),
                    pw.SizedBox(height: 10),

                    // "Certify that"
                    pw.Text('This is to proudly certify that',
                      style: pw.TextStyle(color: grey, fontSize: 12)),
                    pw.SizedBox(height: 10),

                    // Student name pill
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 36, vertical: 10),
                      decoration: pw.BoxDecoration(
                        color: purpleLight,
                        border: pw.Border.all(color: purple, width: 1.5),
                        borderRadius: pw.BorderRadius.circular(40),
                      ),
                      child: pw.Text(d.studentName,
                        style: pw.TextStyle(
                          color: dark, fontSize: 24,
                          fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(height: 10),

                    pw.Text('has successfully completed the course',
                      style: pw.TextStyle(color: grey, fontSize: 12)),
                    pw.SizedBox(height: 8),

                    // Course name
                    pw.Text(d.courseName,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        color: purple, fontSize: 18,
                        fontWeight: pw.FontWeight.bold)),

                    pw.SizedBox(height: 14),
                    pw.Container(
                        height: 1,
                        color: const PdfColor.fromInt(0xFFE5E7EB)),
                    pw.SizedBox(height: 14),

                    // ── Bottom 3 columns ──────────────────
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [

                        // Date
                        pw.Column(children: [
                          pw.Container(width: 160, height: 1, color: dark),
                          pw.SizedBox(height: 4),
                          pw.Text(dateStr,
                            style: pw.TextStyle(
                              color: dark, fontSize: 12,
                              fontWeight: pw.FontWeight.bold)),
                          pw.Text('Completion Date',
                            style: pw.TextStyle(color: grey, fontSize: 10)),
                        ]),

                        // Verified badge
                        pw.Container(
                          width: 52, height: 52,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            color: const PdfColor.fromInt(0x1A00C896),
                            border: pw.Border.all(color: green, width: 2.5),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.Text('✓',
                            style: pw.TextStyle(
                              color: green, fontSize: 22,
                              fontWeight: pw.FontWeight.bold)),
                        ),

                        // Instructor
                        pw.Column(children: [
                          pw.Container(width: 160, height: 1, color: dark),
                          pw.SizedBox(height: 4),
                          pw.Text(d.instructorName,
                            style: pw.TextStyle(
                              color: dark, fontSize: 12,
                              fontWeight: pw.FontWeight.bold)),
                          pw.Text('Instructor',
                            style: pw.TextStyle(color: grey, fontSize: 10)),
                        ]),
                      ],
                    ),

                    pw.Expanded(child: pw.SizedBox()),

                    // Footer
                    pw.Text(
                      'Certificate ID: ${d.certificateId}  •  Issued by LearnFlow Academy',
                      style: pw.TextStyle(color: grey, fontSize: 8)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ── Save PDF file ────────────────────────────────────────
  Future<File> _savePdf(Uint8List bytes) async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/certificate_${widget.data.certificateId}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  // ── Convert PDF → PNG (first page, 200 dpi) ─────────────
  Future<File> _savePng(Uint8List pdfBytes) async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/certificate_${widget.data.certificateId}.png');
    await for (final page in Printing.raster(pdfBytes, dpi: 200)) {
      await file.writeAsBytes(await page.toPng());
      break; // first page only
    }
    return file;
  }

  // ── Download PDF + PNG then share both ──────────────────
  Future<void> _downloadBoth() async {
    setState(() => _isGenerating = true);
    try {
      final bytes   = await _buildPdfBytes();
      final pdfFile = await _savePdf(bytes);
      final pngFile = await _savePng(bytes);

      await Share.shareXFiles(
        [XFile(pdfFile.path), XFile(pngFile.path)],
        subject: 'My LearnFlow Certificate – ${widget.data.courseName}',
        text:    'I just completed "${widget.data.courseName}" on LearnFlow! 🎓',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // ── In-app PDF preview ───────────────────────────────────
  Future<void> _preview() async {
    final bytes = await _buildPdfBytes();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Certificate Preview'),
            backgroundColor: _purple,
            foregroundColor: Colors.white,
          ),
          body: PdfPreview(
            build: (_) async => bytes,
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final d       = widget.data;
    final dateStr = DateFormat('MMMM d, yyyy').format(d.completionDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      appBar: AppBar(
        title: const Text('My Certificate',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _CertificateCardWidget(data: d, dateStr: dateStr),
                const SizedBox(height: 24),
                _InfoGrid(data: d, dateStr: dateStr),
                const SizedBox(height: 28),
                _buildDownloadButton(),
                const SizedBox(height: 12),
                _buildPreviewButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton() => SizedBox(
    width: double.infinity, height: 52,
    child: ElevatedButton.icon(
      onPressed: _isGenerating ? null : _downloadBoth,
      icon: _isGenerating
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.download_rounded),
      label: Text(
        _isGenerating ? 'Generating…' : 'Download PDF + PNG',
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        elevation: 2,
      ),
    ),
  );

  Widget _buildPreviewButton() => SizedBox(
    width: double.infinity, height: 52,
    child: OutlinedButton.icon(
      onPressed: _preview,
      icon: const Icon(Icons.visibility_rounded),
      label: const Text('Preview Certificate',
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _purple,
        side: const BorderSide(color: _purple, width: 1.5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CERTIFICATE CARD  (visual preview inside the app)
// ─────────────────────────────────────────────────────────────────────────────
class _CertificateCardWidget extends StatelessWidget {
  final CertificateData data;
  final String dateStr;
  const _CertificateCardWidget(
      {required this.data, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4A42CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60, height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37),
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),

          // Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: Colors.white.withOpacity(.5), width: 1)),
                alignment: Alignment.center,
                child: const Text('L',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
              ),
              const SizedBox(width: 8),
              const Text('LearnFlow',
                style: TextStyle(
                  color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),

          const Text('CERTIFICATE',
            style: TextStyle(
              color: Colors.white, fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2)),
          const Text('OF COMPLETION',
            style: TextStyle(
              color: Color(0xFFD4AF37), fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 4)),
          const SizedBox(height: 16),

          const Text('This is to proudly certify that',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),

          // Student pill
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              border: Border.all(
                  color: Colors.white.withOpacity(.4), width: 1.5),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Text(data.studentName,
              style: const TextStyle(
                color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),

          const Text('has successfully completed',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),

          Text(data.courseName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white, fontSize: 15,
              fontWeight: FontWeight.w700)),

          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(.25)),
          const SizedBox(height: 12),

          // Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CardBottomItem(label: 'Completion', value: dateStr),

              Column(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00C896).withOpacity(.15),
                    border: const Border.fromBorderSide(
                      BorderSide(
                          color: Color(0xFF00C896), width: 2)),
                  ),
                  child: const Icon(Icons.verified_rounded,
                      color: Color(0xFF00C896), size: 22),
                ),
                const SizedBox(height: 4),
                const Text('VERIFIED',
                  style: TextStyle(
                    color: Color(0xFF00C896), fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
              ]),

              _CardBottomItem(
                  label: 'Instructor',
                  value: data.instructorName),
            ],
          ),

          const SizedBox(height: 14),
          Text('ID: ${data.certificateId}',
            style: TextStyle(
              color: Colors.white.withOpacity(.45),
              fontSize: 9)),
        ],
      ),
    );
  }
}

class _CardBottomItem extends StatelessWidget {
  final String label;
  final String value;
  const _CardBottomItem(
      {required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white, fontSize: 12,
          fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label,
        style: TextStyle(
          color: Colors.white.withOpacity(.6),
          fontSize: 10)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO GRID  (4 tiles: student / course / instructor / date)
// ─────────────────────────────────────────────────────────────────────────────
class _InfoGrid extends StatelessWidget {
  final CertificateData data;
  final String dateStr;
  const _InfoGrid({required this.data, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(child: _InfoTile(
          icon: Icons.person_rounded,
          iconColor: const Color(0xFF6C63FF),
          label: 'Student',
          value: data.studentName,
        )),
        const SizedBox(width: 12),
        Expanded(child: _InfoTile(
          icon: Icons.school_rounded,
          iconColor: const Color(0xFF00C896),
          label: 'Course',
          value: data.courseName,
        )),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _InfoTile(
          icon: Icons.person_pin_rounded,
          iconColor: const Color(0xFFD4AF37),
          label: 'Instructor',
          value: data.instructorName,
        )),
        const SizedBox(width: 12),
        Expanded(child: _InfoTile(
          icon: Icons.calendar_today_rounded,
          iconColor: const Color(0xFFFF6B6B),
          label: 'Completed',
          value: dateStr,
        )),
      ]),
    ]);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                style: const TextStyle(
                  color: Color(0xFF6B7280), fontSize: 10,
                  fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1A1A2E), fontSize: 12,
                  fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ]),
    );
  }
}