import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'experiment_details_screen.dart';
import '../widgets/experiment_details_modal.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue ?? '';
    if (value.isEmpty) return;

    // Expect format: healthlab://experiment/{id}
    final uri = Uri.tryParse(value);
    final maybeId = uri != null && uri.scheme == 'healthlab' && uri.host == 'experiment'
        ? (uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '')
        : (value.startsWith('healthlab://experiment/')
            ? value.split('healthlab://experiment/').last
            : '');

    if (maybeId.isEmpty) return;
    _handled = true;

    // Build minimal data; ExperimentDetailsScreen will fetch more via Firestore
    final experimentData = <String, dynamic>{
      'id': maybeId,
      'title': 'Experiment',
      'description': '',
      'emojis': const ['🧪'],
      'published': true,
    };

    if (!mounted) return;
    // Close the scanner first, then show modal on previous context
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 50)).then((_) {
      if (!mounted) return;
      showExperimentDetailsModal(context, experimentData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00432D),
      body: SafeArea(
        child: Stack(
          children: [
            MobileScanner(
              controller: MobileScannerController(facing: CameraFacing.back),
              onDetect: _onDetect,
            ),
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Align the QR within the frame to scan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}


