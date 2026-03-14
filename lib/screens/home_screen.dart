import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import '../../services/database_helper.dart';
import 'scanner_screen.dart';
import '../widgets/custom_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- UI CONSTANTS ---
  final Color _headerGreen = const Color(0xFF557B3E);
  final Color _flameOrange = const Color(0xFFFFB74D);
  final Color _borderGreen = const Color(0xFF8CC63F);
  final Color _borderRed = const Color(0xFFE57373);

  // --- STATE VARIABLES ---
  bool _isDbReady = false;
  bool _isLoadingHistory = true;
  List<Map<String, dynamic>> _history = [];

  int _safeCount = 0;
  int _unsafeCount = 0;
  int _currentStreak = 0;
  bool _scannedToday = false;

  final List<String> _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
        Future.delayed(const Duration(seconds: 1)),
      ]);

      if (mounted) {
        setState(() {
          _history = data;
          _calculateStatsAndStreak();
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

  void _calculateStatsAndStreak() {
    _safeCount = 0;
    _unsafeCount = 0;
    Set<String> uniqueScanDates = {};

    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    for (var item in _history) {
      // 1. Calculate Pie Chart Stats
      if (item['status'] == 'safe') _safeCount++;
      if (item['status'] == 'unsafe') _unsafeCount++;

      // 2. Extract Dates for Streak
      String scanTime = item['scanned_at']?.toString() ?? "";
      if (scanTime.length >= 10) {
        uniqueScanDates.add(scanTime.substring(0, 10));
      }
    }

    _scannedToday = uniqueScanDates.contains(todayStr);

    // 3. Calculate Streak
    int streak = 0;
    DateTime checkDate = _scannedToday
        ? now
        : now.subtract(const Duration(days: 1));

    while (true) {
      String dateStr =
          "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
      if (uniqueScanDates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    _currentStreak = streak;
  }

  // --- DYNAMIC FLAME SCALING ---
  double _getFlameScale() {
    if (_currentStreak == 0) return 0.7; // Smallest
    if (_currentStreak == 1) return 1.0; // Normal
    if (_currentStreak == 2) return 1.3; // Bigger
    return 1.6; // Max size
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "DietRx",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _headerGreen,
        elevation: 0,
      ),
      body: _isLoadingHistory
          ? CustomLoading(
              message: "Loading Dashboard...",
              textColor: textPrimary,
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStreakSection(isDark, textPrimary, textSecondary),
                  const SizedBox(height: 20),
                  _buildStatsSection(cardColor, textPrimary, textSecondary),
                  const SizedBox(height: 20),
                  _buildRecentScansSection(
                    textPrimary,
                    textSecondary,
                    cardColor,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
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
          closedColor: _isDbReady
              ? const Color(0xFF1B4D3E)
              : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
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

  // STREAK & CALENDAR SECTION
  Widget _buildStreakSection(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120, // Constrained width so the flame doesn't block text
                child: Transform.scale(
                  scale: _getFlameScale(),
                  child: Lottie.asset(
                    'assets/animations/fire.json',
                    fit: BoxFit.contain,
                    delegates: _currentStreak == 0
                        ? LottieDelegates(
                            values: [
                              ValueDelegate.colorFilter(
                                const ['**'],
                                value: const ColorFilter.mode(
                                  Colors.grey,
                                  BlendMode.srcATop,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),

              const SizedBox(width: 15),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$_currentStreak",
                    style: GoogleFonts.poppins(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    "day streak",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: _flameOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!_scannedToday)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        "Scan today to keep it!",
                        style: GoogleFonts.poppins(
                          color: textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Calendar Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              DateTime now = DateTime.now();
              int currentDay = now.weekday;
              DateTime startOfWeek = now.subtract(
                Duration(days: currentDay - 1),
              );
              DateTime dateOfIndex = startOfWeek.add(Duration(days: index));

              String dateStr =
                  "${dateOfIndex.year}-${dateOfIndex.month.toString().padLeft(2, '0')}-${dateOfIndex.day.toString().padLeft(2, '0')}";

              bool isToday =
                  dateOfIndex.day == now.day && dateOfIndex.month == now.month;

              // Check if user scanned on this date
              bool isScanned = _history.any((item) {
                String scanTime = item['scanned_at']?.toString() ?? "";
                return scanTime.startsWith(dateStr);
              });

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Column(
                  children: [
                    Text(
                      _weekDays[index],
                      style: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isScanned
                            ? const Color(0xFFF57C00)
                            : (isToday
                                  ? (isDark ? Colors.white24 : Colors.black12)
                                  : Colors.transparent),
                        border: isToday && !isScanned
                            ? Border.all(
                                color: const Color(0xFFF57C00),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Center(
                        child: isScanned
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : Text(
                                "${dateOfIndex.day}",
                                style: GoogleFonts.poppins(
                                  color: isToday ? textPrimary : textSecondary,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // PIE CHART STATS SECTION
  Widget _buildStatsSection(
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (_history.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Pie Chart
            SizedBox(
              height: 120,
              width: 120,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 30,
                  sections: [
                    PieChartSectionData(
                      value: _safeCount > 0 ? _safeCount.toDouble() : 1,
                      color: _borderGreen,
                      title: '',
                      radius: 20,
                    ),
                    PieChartSectionData(
                      value: _unsafeCount > 0 ? _unsafeCount.toDouble() : 1,
                      color: _borderRed,
                      title: '',
                      radius: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 30),

            // Right: Stat Legend
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Food Items",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, color: _borderGreen, size: 12),
                          const SizedBox(width: 8),
                          Text(
                            "Safe",
                            style: GoogleFonts.poppins(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "$_safeCount",
                        style: GoogleFonts.poppins(
                          color: _borderGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, color: _borderRed, size: 12),
                          const SizedBox(width: 8),
                          Text(
                            "Unsafe",
                            style: GoogleFonts.poppins(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "$_unsafeCount",
                        style: GoogleFonts.poppins(
                          color: _borderRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HORIZONTAL RECENT SCANS SECTION
  Widget _buildRecentScansSection(
    Color textPrimary,
    Color textSecondary,
    Color cardColor,
  ) {
    if (_history.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "Last Scanned Items",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 15),

        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final item = _history[index];
              final isSafe = item['status'] == 'safe';
              final borderColor = isSafe ? _borderGreen : _borderRed;

              return Container(
                width: 120,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child:
                            item['image_url'] != null &&
                                item['image_url'].toString().isNotEmpty
                            ? Image.network(
                                item['image_url'],
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: isSafe
                                    ? _borderGreen.withOpacity(0.1)
                                    : _borderRed.withOpacity(0.1),
                                child: Icon(
                                  isSafe
                                      ? Icons.check_circle_outline
                                      : Icons.warning_amber_rounded,
                                  color: borderColor,
                                  size: 40,
                                ),
                              ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text(
                            item['name'] ?? 'Unknown',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
