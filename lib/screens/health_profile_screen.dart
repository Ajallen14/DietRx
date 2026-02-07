import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  // --- DATA SOURCES ---
  final List<String> _allConditions = [
    'Diabetes',
    'Hypertension',
    'Thyroid',
    'PCOS',
    'Celiac',
    'Heart Problems',
    'Cholesterol',
    'Lactose Intolerance',
  ];

  final List<String> _allAllergies = [
    'Peanuts',
    'Tree Nuts',
    'Milk',
    'Eggs',
    'Wheat',
    'Soy',
    'Fish',
    'Shellfish',
  ];

  // --- STATE VARIABLES ---
  final List<String> _selectedConditions = [];
  final List<String> _selectedAllergies = [];
  bool _isLoading = false;

  // Controllers for the two "Add Other" fields
  final TextEditingController _otherConditionController =
      TextEditingController();
  final TextEditingController _otherAllergyController = TextEditingController();

  @override
  void dispose() {
    _otherConditionController.dispose();
    _otherAllergyController.dispose();
    super.dispose();
  }

  // --- LOGIC: Add a new custom chip ---
  void _addCustomItem(
    TextEditingController controller,
    List<String> mainList,
    List<String> selectedList,
  ) {
    final text = controller.text.trim();
    // Don't add empty or duplicate items
    if (text.isNotEmpty && !mainList.contains(text)) {
      setState(() {
        mainList.add(text);
        selectedList.add(text);
        controller.clear();
      });
    }
  }

  // --- DATABASE LOGIC ---
  Future<void> _saveToFirebase() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Map<String, dynamic> data = {
        'user_id': user.uid,
        'conditions': _selectedConditions,
        'allergies': _selectedAllergies,
        'last_updated': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('Health_Profiles')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Saved!"),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to AuthWrapper to route to Home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B4D3E),
      appBar: AppBar(
        title: Text(
          "Health Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: HEALTH CONDITIONS ---
            Text(
              "Health Conditions",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Do you have any diagnosed health condition?",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 20),

            // Chips List
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _allConditions.map((condition) {
                final isSelected = _selectedConditions.contains(condition);
                return _buildChip(condition, isSelected, (selected) {
                  setState(() {
                    if (selected) {
                      _selectedConditions.add(condition);
                    } else {
                      _selectedConditions.remove(condition);
                    }
                  });
                });
              }).toList(),
            ),

            const SizedBox(height: 15),

            // Add other Condition
            _buildAddOtherRow(
              controller: _otherConditionController,
              label: "Add other condition...",
              onAdd: () => _addCustomItem(
                _otherConditionController,
                _allConditions,
                _selectedConditions,
              ),
            ),

            const SizedBox(height: 40),

            // --- SECTION 2: ALLERGIES ---
            Text(
              "Do you have any allergies?",
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 15),

            // Chips List (Allergies)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _allAllergies.map((allergy) {
                final isSelected = _selectedAllergies.contains(allergy);
                return _buildChip(allergy, isSelected, (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAllergies.add(allergy);
                    } else {
                      _selectedAllergies.remove(allergy);
                    }
                  });
                });
              }).toList(),
            ),

            const SizedBox(height: 15),

            // Add other Allergy
            _buildAddOtherRow(
              controller: _otherAllergyController,
              label: "Add other allergy...",
              onAdd: () => _addCustomItem(
                _otherAllergyController,
                _allAllergies,
                _selectedAllergies,
              ),
            ),

            const SizedBox(height: 50),

            // --- SAVE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveToFirebase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B4D3E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF1B4D3E))
                    : Text(
                        "Save & Continue",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      backgroundColor: const Color(0xFF2E7D62),
      selectedColor: Colors.white,
      checkmarkColor: const Color(0xFF1B4D3E),
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? const Color(0xFF1B4D3E) : Colors.white,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.white : Colors.transparent),
      ),
      onSelected: onSelected,
    );
  }

  Widget _buildAddOtherRow({
    required TextEditingController controller,
    required String label,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 10),

        // The "Add" Button
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: Color(0xFF1B4D3E), size: 28),
            tooltip: "Add to list",
          ),
        ),
      ],
    );
  }
}
