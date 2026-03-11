import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import '../services/dynamic_rule_service.dart';
import '../services/scan_service.dart';
import 'recipe_result_screen.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final TextEditingController _recipeTextController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  @override
  void dispose() {
    _recipeTextController.dispose();
    super.dispose();
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() => _isProcessing = true);

      Map<String, dynamic>? extractedData;
      await Future.wait([
        DynamicRuleService.analyzeRecipe(imageFile: File(image.path))
            .then((res) => extractedData = res),
        Future.delayed(const Duration(seconds: 2)),
      ]);

      if (extractedData != null && mounted) {
        final evaluation = await ScanService().evaluateRecipe(extractedData!);
        setState(() => _isProcessing = false);
        _showResultScreen(evaluation);
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to analyze recipe.")),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _processText() async {
    if (_recipeTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please paste a recipe first!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      Map<String, dynamic>? extractedData;
      await Future.wait([
        DynamicRuleService.analyzeRecipe(recipeText: _recipeTextController.text)
            .then((res) => extractedData = res),
        Future.delayed(const Duration(seconds: 2)),
      ]);

      if (extractedData != null && mounted) {
        final evaluation = await ScanService().evaluateRecipe(extractedData!);
        setState(() => _isProcessing = false);
        _showResultScreen(evaluation);
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to analyze recipe.")),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showResultScreen(Map<String, dynamic> evaluation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeResultScreen(evaluation: evaluation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Recipe Analyzer",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF557B3E),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/spoon_loading.json',
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                    delegates: LottieDelegates(
                      values: [
                        ValueDelegate.colorFilter(
                          const ['**'],
                          value: const ColorFilter.mode(
                            Color(0xFF8CC63F),
                            BlendMode.srcATop,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Analyzing recipe...",
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Scan a Cookbook or Menu",
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Take a photo of a recipe or upload a screenshot to extract ingredients instantly.",
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.camera_alt,
                          label: "Camera",
                          onTap: () => _processImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.photo_library,
                          label: "Gallery",
                          onTap: () => _processImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  const Divider(color: Colors.black12, thickness: 1),
                  const SizedBox(height: 40),

                  Text(
                    "Paste a Recipe",
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Paste the text or ingredients list here.",
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: TextField(
                      controller: _recipeTextController,
                      maxLines: 8,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText:
                            "e.g., 2 cups flour\n1 tsp baking soda\n1/2 cup sugar...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _processText,
                      icon: const Icon(Icons.analytics, color: Colors.white),
                      label: Text(
                        "Analyze Recipe",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF557B3E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF8CC63F), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF557B3E), size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}