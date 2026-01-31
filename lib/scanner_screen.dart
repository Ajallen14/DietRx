import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'services/scan_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );
  final ScanService _scanService = ScanService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan Food"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isProcessing) return;
              if (capture.barcodes.isNotEmpty &&
                  capture.barcodes.first.rawValue != null) {
                _handleScan(capture.barcodes.first.rawValue!);
              }
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.green),
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
        _showErrorDialog("Product not found in database.");
      } else {
        _showResultSheet(result);
      }
    } catch (e) {
      _showErrorDialog("Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showResultSheet(ScanResult result) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: result.isSafe ? Colors.green[50] : Colors.red[50],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. IMAGE & BADGES ROW
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: result.imageUrl != null
                          ? Image.network(
                              result.imageUrl!,
                              errorBuilder: (c, o, s) =>
                                  const Icon(Icons.fastfood, size: 50),
                            )
                          : const Icon(
                              Icons.fastfood,
                              size: 50,
                              color: Colors.grey,
                            ),
                    ),
                    const SizedBox(width: 16),
                    // Badges Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.productName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (result.nutriscore != null)
                                _buildBadge(
                                  "Nutri-Score: ${result.nutriscore!.toUpperCase()}",
                                  Colors.blue,
                                ),
                              if (result.novaGroup != null)
                                _buildBadge(
                                  "Nova: ${result.novaGroup}",
                                  _getNovaColor(result.novaGroup!),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. VERDICT
                Text(
                  result.isSafe ? "SAFE TO CONSUME" : "AVOID THIS",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: result.isSafe ? Colors.green[800] : Colors.red[800],
                  ),
                ),

                // 3. WARNINGS
                if (!result.isSafe) ...[
                  const Divider(),
                  ...result.warnings.map(
                    (w) => ListTile(
                      leading: const Icon(Icons.cancel, color: Colors.red),
                      title: Text(
                        w,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      dense: true,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // 4. NEXT BUTTON
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.black,
                  ),
                  child: const Text(
                    "Scan Next",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getNovaColor(int group) {
    if (group == 1) return Colors.green;
    if (group == 4) return Colors.red;
    return Colors.orange;
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
