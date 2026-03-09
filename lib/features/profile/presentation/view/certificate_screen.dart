import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/features/profile/data/models/certificate_data.dart';
import 'package:e_learning/features/profile/presentation/view/widgets/certificate/certificate_card.dart';
import 'package:e_learning/features/profile/presentation/view/widgets/certificate/certificate_file_saver.dart';
import 'package:e_learning/features/profile/presentation/view/widgets/certificate/certificate_info_grid.dart';
import 'package:e_learning/features/profile/presentation/view/widgets/certificate/certificate_pdf_builder.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class CertificateScreen extends StatefulWidget {
  final CertificateData data;

  const CertificateScreen({super.key, required this.data});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  bool _isGenerating = false;

  // ── Lifecycle ────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, .08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────

  /// Generates PDF + PNG then opens the system share sheet.
  Future<void> _downloadBoth() async {
    setState(() => _isGenerating = true);
    try {
      final bytes   = await CertificatePdfBuilder.build(widget.data);
      final pdfFile = await CertificateFileSaver.savePdf(bytes, widget.data.certificateId);
      final pngFile = await CertificateFileSaver.savePng(bytes, widget.data.certificateId);

      await Share.shareXFiles(
        [XFile(pdfFile.path), XFile(pngFile.path)],
        subject: 'My LearnFlow Certificate – ${widget.data.courseName}',
        text:    'I just completed "${widget.data.courseName}" on LearnFlow! 🎓',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  /// Opens an in-app full PDF preview with print / share options.
  Future<void> _previewPdf() async {
    final bytes = await CertificatePdfBuilder.build(widget.data);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Certificate Preview'),
            backgroundColor: AppColors.purple,
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

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM d, yyyy').format(widget.data.completionDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Certificate',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.purple,
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
                CertificateCard(data: widget.data, dateStr: dateStr),
                const SizedBox(height: 24),
                CertificateInfoGrid(data: widget.data, dateStr: dateStr),
                const SizedBox(height: 28),
                _DownloadButton(
                  isLoading: _isGenerating,
                  onPressed: _downloadBoth,
                ),
                const SizedBox(height: 12),
                _PreviewButton(onPressed: _previewPdf),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Action buttons ───────────────────────────────────────────────────────────

class _DownloadButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _DownloadButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.download_rounded),
        label: Text(
          isLoading ? 'Generating…' : 'Download PDF + PNG',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PreviewButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.visibility_rounded),
        label: const Text(
          'Preview Certificate',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.purple,
          side: const BorderSide(color: AppColors.purple, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}