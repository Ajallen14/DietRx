import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/dynamic_rule_service.dart';
import 'result_screen.dart';
import '../services/scan_service.dart';
import '../services/database_helper.dart';
import '../widgets/custom_loading.dart';

class IngredientScannerScreen extends StatefulWidget {
  final String scannedBarcode;

  const IngredientScannerScreen({super.key, required this.scannedBarcode});

  @override
  State<IngredientScannerScreen> createState() =>
      _IngredientScannerScreenState();
}

class _IngredientScannerScreenState extends State<IngredientScannerScreen> {
  bool _isProcessing = false;
  bool _isSaving = false;
  Map<String, dynamic>? _extractedData;
  Map<String, dynamic>? _localProductData;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExistingLocalData();
  }

  Future<void> _fetchExistingLocalData() async {
    try {
      final data = await DatabaseHelper().getProduct(widget.scannedBarcode);
      if (data != null && mounted) {
        setState(() {
          _localProductData = data;
          if (data['name'] != null && data['name'].toString().isNotEmpty) {
            _nameController.text = data['name'];
          }
        });
      }
    } catch (e) {
      print("Error fetching local data: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _scanLabel() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      setState(() {
        _isProcessing = true;
        _extractedData = null;
      });

      Map<String, dynamic>? data;
      await Future.wait([
        DynamicRuleService.analyzeProductLabel(
          File(image.path),
        ).then((res) => data = res),
        Future.delayed(const Duration(seconds: 2)),
      ]);

      if (mounted) {
        setState(() {
          _extractedData = data;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error reading label: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveToDatabase() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter the Product Name!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final String productName = _nameController.text.trim();
      final List<dynamic> ingredientsList =
          _extractedData?['ingredients'] ?? [];

      // MERGE LOGIC: Combine API data with existing SQLite data!
      Map<String, dynamic> firestoreData = {
        'name': productName,
        'barcode': widget.scannedBarcode,
        'ingredients': ingredientsList,
        'nutrition': _extractedData?['nutrition'] ?? {},
        'category':
            _extractedData?['category'] ??
            _localProductData?['categories'] ??
            "Unknown",
        'image_url': _localProductData?['image_url'],
        'nutriscore': _localProductData?['nutriscore'],
        'nova_group': _localProductData?['nova_group'],
        'labels': _localProductData?['labels'],
        'is_crowdsourced': true,
        'created_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('Products')
          .doc(widget.scannedBarcode)
          .set(firestoreData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product added"),
            backgroundColor: Colors.green,
          ),
        );

        final scanService = ScanService();
        final newScanResult = await scanService.processBarcode(
          widget.scannedBarcode,
        );

        setState(() => _isSaving = false);

        if (newScanResult != null && mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(result: newScanResult),
            ),
            (route) => route.isFirst,
          );
        } else if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Add Missing Product",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF557B3E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _isProcessing
            ? const CustomLoading(
                message: "Analyzing the label...",
                textColor: Color(0xFF557B3E),
              )
            : _extractedData != null
            ? _buildResultView()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.document_scanner,
                    size: 80,
                    color: Color(0xFF557B3E),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Take a clear photo of the Ingredients list and Nutritional table.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _scanLabel,
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: Text(
                      "Open Camera",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF557B3E),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildResultView() {
    final ingredients = List<String>.from(_extractedData?['ingredients'] ?? []);
    final nutrition = Map<String, dynamic>.from(
      _extractedData?['nutrition'] ?? {},
    );

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Extraction Successful!",
            style: GoogleFonts.poppins(
              color: const Color(0xFF557B3E),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              labelText: "What is the product's name?",
              labelStyle: const TextStyle(color: Colors.black54),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.black12),
                borderRadius: BorderRadius.circular(15),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Color(0xFF8CC63F),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              prefixIcon: const Icon(Icons.fastfood, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ingredients Found:",
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ingredients
                        .map(
                          (ing) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F9DD),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF8CC63F),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              ing,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Nutrition Found:",
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      children: nutrition.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.key.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                e.value.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveToDatabase,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF557B3E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Save to Database",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
