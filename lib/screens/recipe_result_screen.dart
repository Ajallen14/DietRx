import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../services/dynamic_rule_service.dart';
import '../widgets/animated_leaf.dart';
import '../widgets/animated_warning.dart';
import '../widgets/result_components.dart';

class RecipeResultScreen extends StatefulWidget {
  final Map<String, dynamic> evaluation;

  const RecipeResultScreen({super.key, required this.evaluation});

  @override
  State<RecipeResultScreen> createState() => _RecipeResultScreenState();
}

class _RecipeResultScreenState extends State<RecipeResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _loopController;

  late Animation<double> _imageScaleAnim;
  late Animation<double> _pillOpacityAnim;
  late Animation<Offset> _cardSlideAnim;
  late Animation<double> _cardOpacityAnim;

  String? _substitutions;
  bool _isLoadingSubs = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Animations
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _imageScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _pillOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _cardSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _cardOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _entranceController.forward();

    // 2. Infinite Loop Animations
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (!widget.evaluation['isSafe']) {
      _fetchSubstitutions();
    }
  }

  Future<void> _fetchSubstitutions() async {
    setState(() => _isLoadingSubs = true);

    String? subs;
    await Future.wait([
      DynamicRuleService.getRecipeSubstitutions(
        recipeData: widget.evaluation['recipeData'],
        warnings: List<String>.from(widget.evaluation['warnings']),
      ).then((res) => subs = res),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (mounted) {
      setState(() {
        _substitutions = subs;
        _isLoadingSubs = false;
      });
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  List<String> _parseSubstitutions(String rawText) {
    return rawText
        .split('\n')
        .map((e) => e.replaceAll('*', '').replaceAll('-', '').trim())
        .where((e) => e.length > 10)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSafe = widget.evaluation['isSafe'];
    final List<String> warnings = List<String>.from(
      widget.evaluation['warnings'],
    );
    final Map<String, dynamic> recipeData = widget.evaluation['recipeData'];
    final String recipeName = recipeData['recipeName'] ?? "Analyzed Recipe";

    List<String> subList = [];
    if (_substitutions != null) {
      subList = _parseSubstitutions(_substitutions!);
    }

    final Color primaryColor = isSafe
        ? const Color(0xFF4C7B33)
        : const Color(0xFFC11A1A);
    final Color pillColor = isSafe
        ? const Color(0xFF8CC63F)
        : const Color(0xFFE5A4A4);
    final Color pillTextColor = isSafe ? Colors.white : const Color(0xFF7F1D1D);
    final String pillText = isSafe ? "Safe To Cook" : "Not safe to eat";

    List<String> descriptionPoints = isSafe
        ? [
            "This recipe safely matches your dietary profile.",
            "It does not contain any ingredients restricted by your health conditions.",
            "No allergens matching your profile were detected.",
          ]
        : warnings;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          // --- BACKGROUND ACCENT ICONS ---
          if (isSafe) ...[
            AnimatedLeaf(
              finalTop: 100,
              left: 30,
              size: 40,
              delay: 0.0,
              landsOnLeft: true,
            ),
            AnimatedLeaf(
              finalTop: 160,
              right: 30,
              size: 50,
              delay: 0.4,
              landsOnLeft: false,
            ),
          ],
          if (!isSafe) ...[
            AnimatedWarningIcon(
              top: 100,
              left: 30,
              size: 35,
              delay: 0.1,
              isLeft: true,
              color: pillColor,
            ),
            AnimatedWarningIcon(
              top: 160,
              right: 30,
              size: 35,
              delay: 0.3,
              isLeft: false,
              color: pillColor,
            ),
          ],

          // --- FOREGROUND CONTENT ---
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header (Back Button & Title)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            recipeName,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.75,
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(top: 20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.elliptical(
                              MediaQuery.of(context).size.width,
                              140,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 40,
                            left: 24,
                            right: 24,
                            bottom: 60,
                          ),
                          child: Column(
                            children: [
                              // --- IMAGE AREA ---
                              ScaleTransition(
                                scale: _imageScaleAnim,
                                child: AnimatedBuilder(
                                  animation: _loopController,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(
                                        0,
                                        -8 * _loopController.value,
                                      ),
                                      child: child,
                                    );
                                  },
                                  child: isSafe
                                      ? Image.asset(
                                          'assets/images/recipe_safe_icon.png',
                                          width: 150,
                                          height: 150,
                                          fit: BoxFit.contain,
                                        )
                                      : Image.asset(
                                          'assets/images/recipe_unsafe_icon.png',
                                          width: 150,
                                          height: 150,
                                          fit: BoxFit.contain,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 25),

                              // --- STATUS PILL ---
                              FadeTransition(
                                opacity: _pillOpacityAnim,
                                child: AnimatedBuilder(
                                  animation: _loopController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale:
                                          1.0 + (0.04 * _loopController.value),
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: pillColor,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      pillText,
                                      style: GoogleFonts.poppins(
                                        color: pillTextColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 35),

                              // --- CARDS ---
                              SlideTransition(
                                position: _cardSlideAnim,
                                child: FadeTransition(
                                  opacity: _cardOpacityAnim,
                                  child: Column(
                                    children: [
                                      DescriptionCard(
                                        pillColor: pillColor,
                                        pillTextColor: pillTextColor,
                                        descriptionPoints: descriptionPoints,
                                      ),

                                      if (!isSafe) ...[
                                        const SizedBox(height: 30),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.close,
                                                color: primaryColor,
                                                size: 26,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Substitutions",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Container(
                                                  height: 2,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 15),

                                        // Substitutions List
                                        _isLoadingSubs
                                            ? Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 30.0,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: pillColor.withOpacity(
                                                    0.2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  border: Border.all(
                                                    color: primaryColor,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Lottie.asset(
                                                      'assets/animations/spoon_loading.json',
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.contain,
                                                      delegates: LottieDelegates(
                                                        values: [
                                                          ValueDelegate.colorFilter(
                                                            const ['**'],
                                                            value:
                                                                ColorFilter.mode(
                                                                  primaryColor,
                                                                  BlendMode
                                                                      .srcATop,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      "Finding alternatives...",
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color: primaryColor,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : subList.isNotEmpty
                                            ? Column(
                                                children: subList
                                                    .map(
                                                      (sub) => Container(
                                                        margin:
                                                            const EdgeInsets.only(
                                                              bottom: 12.0,
                                                            ),
                                                        padding:
                                                            const EdgeInsets.all(
                                                              16.0,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: pillColor
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                15,
                                                              ),
                                                          border: Border.all(
                                                            color: primaryColor,
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .arrow_forward,
                                                              color:
                                                                  primaryColor,
                                                              size: 22,
                                                            ),
                                                            const SizedBox(
                                                              width: 12,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                sub,
                                                                style: GoogleFonts.poppins(
                                                                  color: Colors
                                                                      .black87,
                                                                  fontSize: 15,
                                                                  height: 1.4,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              )
                                            : Text(
                                                "No specific substitutions found.",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.black54,
                                                ),
                                              ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
