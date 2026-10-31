import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../../data/remote/open_food_facts.dart';

/// Scans a product barcode (EAN/UPC) and looks it up in Open Food Facts.
/// Pops the matching `FoodEntry`. A typed-code fallback covers devices
/// without a camera and barcodes that will not scan.
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final _scanner = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _manual = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _scanner.dispose();
    _manual.dispose();
    super.dispose();
  }

  Future<void> _lookup(String code) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final entry = await context.read<OpenFoodFactsSource>().byBarcode(code);
      if (!mounted) return;
      if (entry == null) {
        setState(() {
          _busy = false;
          _message =
              'No product found for $code. Try searching by name or add it manually.';
        });
        return;
      }
      HapticFeedback.mediumImpact();
      Navigator.pop(context, entry);
    } on FoodSourceException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan barcode'),
        actions: [
          IconButton(
              tooltip: 'Torch',
              icon: const Icon(Icons.flashlight_on_rounded),
              onPressed: _scanner.toggleTorch),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      height: size.height * 0.36,
                      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Radii.lg),
                          color: Colors.black),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(
                            controller: _scanner,
                            onDetect: (capture) {
                              final code = capture.barcodes
                                  .map((b) => b.rawValue)
                                  .whereType<String>()
                                  .firstOrNull;
                              if (code != null) _lookup(code);
                            },
                            errorBuilder: (context, error) =>
                                _CameraError(error: error),
                          ),
                          ValueListenableBuilder<MobileScannerState>(
                            valueListenable: _scanner,
                            builder: (context, state, _) => state.error != null
                                ? const SizedBox.shrink()
                                : Center(
                                    child: Container(
                                      width: size.width * 0.62,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            width: 2.5),
                                        borderRadius:
                                            BorderRadius.circular(Radii.md),
                                      ),
                                    ),
                                  ),
                          ),
                          if (_busy)
                            Container(
                                color: Colors.black54,
                                child: const Center(
                                    child: CircularProgressIndicator())),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                          'Point the camera at the barcode on the package.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(children: [
                          Icon(Icons.info_outline_rounded,
                              color: theme.colorScheme.error),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(_message!,
                                  style: theme.textTheme.bodyMedium)),
                        ]),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manual,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(14)
                      ],
                      textInputAction: TextInputAction.search,
                      onSubmitted: _lookup,
                      decoration: const InputDecoration(
                          hintText: 'Or type the barcode number',
                          prefixIcon: Icon(Icons.dialpad_rounded)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(72, Heights.input)),
                    onPressed: _busy ? null : () => _lookup(_manual.text),
                    child: const Text('Find'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final MobileScannerException error;
  const _CameraError({required this.error});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: const Color(0xFF1B1F1C),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_rounded,
                color: Colors.white70, size: 36),
            const SizedBox(height: 12),
            Text(
              denied
                  ? 'Camera access is off. Enable it in Settings, or type the barcode below.'
                  : 'The camera is not available here. Type the barcode below.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
