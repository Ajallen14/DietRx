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
      // 🚀 LayoutBuilder ensures the Green Box is perfectly centered
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double scanWindowWidth = 300;
          final double scanWindowHeight = 150;
          final Offset center = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2,
          );
          final Rect scanWindow = Rect.fromCenter(
            center: center,
            width: scanWindowWidth,
            height: scanWindowHeight,
          );

          return Stack(
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
              // 🖌️ Visual Overlay (Green Box)
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: ScannerOverlay(scanWindow),
              ),
              // 📝 Hint Text below the box
              Positioned(
                top: center.dy + (scanWindowHeight / 2) + 20,
                left: 0,
                right: 0,
                child: const Text(
                  "Place barcode inside the green box",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                ),
            ],
          );
        },
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
    // 🎨 DETERMINE COLORS & TEXT BEFORE BUILDING UI
    Color bgColor;
    Color textColor;
    String titleText;
    Widget statusWidget;

    // 🚀 LOGIC FOR 3 STATES
    if (result.isMissingData) {
      // 🟠 STATE 1: MISSING RELEVANT DATA (Orange)
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
      titleText = "UNKNOWN STATUS";
      statusWidget = Column(
        children: [
          Icon(Icons.help_outline, size: 60, color: Colors.orange),
          SizedBox(height: 10),
          Text(
            "Nutrition facts missing.\nProduct data not fully present in database.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.orange.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "(We couldn't verify specific nutrients needed for your health profile)",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else if (result.isSafe) {
      // 🟢 STATE 2: SAFE (Green)
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade800;
      titleText = "SAFE TO EAT";
      statusWidget = Container(); // Clean look for safe items
    } else {
      // 🔴 STATE 3: UNSAFE (Red)
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade800;
      titleText = "AVOID THIS";
      statusWidget = Container(); // Warnings list will handle the details
    }

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: bgColor,
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
                // 1. PRODUCT HEADER (Image + Title)
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

                // 2. MAIN STATUS TITLE
                Text(
                  titleText,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),

                // 3. STATUS WIDGET (Icon + Text for Unknown state)
                statusWidget,

                // 4. WARNINGS LIST (Only show if NOT missing data AND NOT safe)
                if (!result.isSafe && !result.isMissingData) ...[
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

                // 5. ALTERNATIVES SECTION
                // Show alternatives if it's Unsafe OR Unknown
                if (!result.isSafe || result.isMissingData) ...[
                  const SizedBox(height: 20),

                  // Check if we actually found any alternatives
                  if (result.alternatives.isNotEmpty) ...[
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
                    // No Alternatives Found Message
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
                            "(We strictly hid items with unknown data for your safety)",
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

  // 🚀 REASON DIALOG for Alternatives
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
              "✅ It belongs to the same specific category.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
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

// 🚀 OVERLAY PAINTER (Draws the Green Box with clear hole)
class ScannerOverlay extends CustomPainter {
  final Rect scanWindow;
  ScannerOverlay(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)),
      );

    // Create the hole
    final path = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    // Draw Dark Background
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, overlayPaint);

    // Draw Green Border
    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
