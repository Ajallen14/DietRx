import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/scan_service.dart';
import '../models/scan_result.dart';

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

                // 2. VERDICT TITLE
                Text(
                  result.isSafe ? "SAFE TO EAT" : "AVOID THIS",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: result.isSafe ? Colors.green[800] : Colors.red[800],
                  ),
                ),

                // 3. WARNINGS & ALTERNATIVES SECTION
                if (!result.isSafe) ...[
                  const Divider(),
                  // List Warnings
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

                  const SizedBox(height: 20),

                  // 🚀 ALTERNATIVES LOGIC
                  if (result.alternatives.isNotEmpty) ...[
                    // A. Show List of Alternatives
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "✅ Try These Instead (Tap for Info):",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: result.alternatives.length,
                        itemBuilder: (context, index) {
                          final alt = result.alternatives[index];
                          return GestureDetector(
                            onTap: () => _showReasonDialog(alt),
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: alt['image_url'] != null
                                        ? Image.network(
                                            alt['image_url'],
                                            fit: BoxFit.contain,
                                          )
                                        : const Icon(
                                            Icons.eco,
                                            color: Colors.green,
                                            size: 40,
                                          ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    alt['name'] ?? "Unknown",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.blueGrey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    // B. Show "No Alternatives" Message
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.search_off, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            "No safer alternatives currently available.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            "(We strictly hid items with unknown nutrient levels for your safety)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 20),
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

  // REASON POPUP DIALOG
  void _showReasonDialog(Map<String, dynamic> altProduct) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("Why is ${altProduct['name']} better?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "It belongs to the same specific category.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            // Show the generated reason
            Text(
              altProduct['match_reason'] ?? "It fits all your health limits.",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Got it"),
          ),
        ],
      ),
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
