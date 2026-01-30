import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'services/scan_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  // Performance settings
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
    formats: const [BarcodeFormat.ean13, BarcodeFormat.upcA],
  );

  final ScanService _scanService = ScanService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan Food Item"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. CAMERA LAYER
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isProcessing) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // 2. LOADING OVERLAY (Wait for Camera)
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, child) {
              if (!state.isInitialized || !state.isRunning) {
                return Container(
                  color: Colors.black,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          "Starting Camera...",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // 3. SCAN GUIDE BOX
          Center(
            child: Container(
              width: 300,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // 4. ANALYZING SPINNER
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      "Analyzing Ingredients...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleScan(String barcode) async {
    setState(() => _isProcessing = true);

    try {
      final result = await _scanService.processBarcode(barcode);

      if (!mounted) return;

      if (result == null) {
        _showErrorDialog(
          "Product not found in offline database.\nCode: $barcode",
        );
      } else {
        _showResultSheet(result);
      }
    } catch (e) {
      _showErrorDialog("Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- 🎨 NEW RESULT SHEET WITH IMAGE ---
  void _showResultSheet(ScanResult result) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: result.isSafe ? Colors.green[50] : Colors.red[50],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          // Limit height so it doesn't cover whole screen
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. PRODUCT IMAGE (Or Icon if offline/missing)
                if (result.imageUrl != null && result.imageUrl!.isNotEmpty)
                  Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(blurRadius: 10, color: Colors.black12),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        result.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, _, __) => _buildStatusIcon(
                          result.isSafe,
                        ), // Fallback if offline
                      ),
                    ),
                  )
                else
                  _buildStatusIcon(result.isSafe),

                const SizedBox(height: 16),

                // 2. Product Name
                Text(
                  result.productName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // 3. NutriScore Badge (New!)
                if (result.nutriscore != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Text(
                      "Nutri-Score: ${result.nutriscore!.toUpperCase()}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // 4. Verdict
                Text(
                  result.isSafe ? "SAFE TO EAT" : "AVOID THIS",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: result.isSafe ? Colors.green[800] : Colors.red[800],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Warnings List
                if (!result.isSafe) ...[
                  const Divider(),
                  ...result.warnings.map(
                    (w) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.cancel, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              w,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // 6. Unknowns
                if (result.unknownConditions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Could not verify: ${result.unknownConditions.join(', ')} (Data missing)",
                            style: TextStyle(
                              color: Colors.brown[800],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // 7. Buttons
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (mounted) setState(() => _isProcessing = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: result.isSafe ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Scan Next Item"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(bool isSafe) {
    return Icon(
      isSafe ? Icons.check_circle : Icons.warning_amber_rounded,
      color: isSafe ? Colors.green : Colors.red,
      size: 100,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Scan Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
