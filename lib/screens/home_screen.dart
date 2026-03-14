import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/database_helper.dart';
import 'scanner_screen.dart';
import 'login_screen.dart';
import '../widgets/custom_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDbReady = false;
  bool _isLoadingHistory = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _initDatabaseAndHistory();
  }

  Future<void> _initDatabaseAndHistory() async {
    try {
      await DatabaseHelper().database;
      await _loadHistory();
    } catch (e) {
      print("Database Init Failed: $e");
    }
  }

  Future<void> _loadHistory() async {
    try {
      List<Map<String, dynamic>> data = [];
      await Future.wait([
        DatabaseHelper().getScanHistory().then((res) => data = res),
        Future.delayed(const Duration(seconds: 2)),
      ]);

      if (mounted) {
        setState(() {
          _history = data;
          _isLoadingHistory = false;
          _isDbReady = true;
        });
      }
    } catch (e) {
      print("Failed to load history: $e");
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
          _isDbReady = true;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'safe':
        return Colors.green;
      case 'unsafe':
        return Colors.redAccent;
      case 'unknown':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'safe':
        return Icons.check_circle;
      case 'unsafe':
        return Icons.cancel;
      case 'unknown':
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "DietRx",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1B4D3E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),

      body: _isLoadingHistory
          ? CustomLoading(
              message: "Loading Scans...",
              textColor: textPrimary,
            )
          : _history.isEmpty
          ? Center(
              child: Text(
                "No scanned items yet.",
                style: GoogleFonts.poppins(color: textSecondary, fontSize: 16),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "Recent Scans",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      final statusColor = _getStatusColor(item['status']);
                      final statusIcon = _getStatusIcon(item['status']);

                      String scanTime = item['scanned_at']?.toString() ?? "";
                      try {
                        if (scanTime.isNotEmpty) {
                          DateTime parsedDate = DateTime.parse(scanTime);
                          String day = parsedDate.day.toString().padLeft(2, '0');
                          String month = parsedDate.month.toString().padLeft(2, '0');
                          String year = parsedDate.year.toString();
                          scanTime = "$day - $month - $year";
                        }
                      } catch (e) {}

                      return Card(
                        color: cardColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: borderColor, width: 1),
                        ),
                        elevation: isDark ? 0 : 2,
                        shadowColor: Colors.black12,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[850] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: item['image_url'] != null &&
                                    item['image_url'].toString().isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      item['image_url'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                          title: Text(
                            item['name'] ?? 'Unknown Product',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              scanTime,
                              style: GoogleFonts.poppins(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          trailing: Icon(statusIcon, color: statusColor, size: 28),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: OpenContainer(
          transitionType: ContainerTransitionType.fade,
          transitionDuration: const Duration(milliseconds: 500),
          openBuilder: (context, _) => const ScannerScreen(),
          onClosed: (_) => _loadHistory(),
          closedElevation: 6.0,
          closedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          closedColor: _isDbReady ? const Color(0xFF1B4D3E) : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
          tappable: _isDbReady,
          closedBuilder: (context, openContainer) {
            return Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isDbReady
                      ? const Icon(Icons.qr_code_scanner, color: Colors.white)
                      : const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white54,
                          ),
                        ),
                  const SizedBox(width: 12),
                  Text(
                    _isDbReady ? "Scan Now" : "Readying...",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}