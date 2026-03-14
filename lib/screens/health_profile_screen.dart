import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../services/profile_service.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen>
    with SingleTickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();

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

  bool _isAddingCondition = false;
  bool _isAddingAllergy = false;

  final TextEditingController _otherConditionController =
      TextEditingController();
  final TextEditingController _otherAllergyController = TextEditingController();

  // --- ANIMATION VARIABLES ---
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _otherConditionController.dispose();
    _otherAllergyController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedWidget(Widget child, int index) {
    final delay = (index * 0.1).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Future<void> _addCustomItem(
    TextEditingController controller,
    List<String> mainList,
    List<String> selectedList,
    bool isAllergy,
  ) async {
    final text = controller.text.trim();

    if (text.isEmpty || mainList.contains(text)) return;

    setState(() {
      if (isAllergy) {
        _isAddingAllergy = true;
      } else {
        _isAddingCondition = true;
      }
    });

    FocusScope.of(context).unfocus();

    try {
      await _profileService.addCustomCondition(text, isAllergy: isAllergy);

      setState(() {
        mainList.add(text);
        selectedList.add(text);
        controller.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Rules for $text generated!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: Could not generate rules."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isAllergy) {
            _isAddingAllergy = false;
          } else {
            _isAddingCondition = false;
          }
        });
      }
    }
  }

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Health Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF546F35),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedWidget(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Health Conditions",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Do you have any diagnosed health condition?",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              0,
            ),

            _buildAnimatedWidget(
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
              1,
            ),

            const SizedBox(height: 15),

            _buildAnimatedWidget(
              _buildAddOtherRow(
                controller: _otherConditionController,
                label: "Add other condition...",
                isAdding: _isAddingCondition,
                onAdd: () => _addCustomItem(
                  _otherConditionController,
                  _allConditions,
                  _selectedConditions,
                  false,
                ),
              ),
              2,
            ),

            const SizedBox(height: 40),

            _buildAnimatedWidget(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Do you have any allergies?",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
              3,
            ),

            _buildAnimatedWidget(
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
              4,
            ),

            const SizedBox(height: 15),

            _buildAnimatedWidget(
              _buildAddOtherRow(
                controller: _otherAllergyController,
                label: "Add other allergy...",
                isAdding: _isAddingAllergy,
                onAdd: () => _addCustomItem(
                  _otherAllergyController,
                  _allAllergies,
                  _selectedAllergies,
                  true,
                ),
              ),
              5,
            ),

            const SizedBox(height: 50),

            _buildAnimatedWidget(
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveToFirebase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAF5B4),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(
                        color: Color(0xFF96B83D),
                        width: 1.5,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFF546F35),
                        )
                      : Text(
                          "Save & Continue",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              6,
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
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFEAF5B4),
      checkmarkColor: Colors.black,
      labelStyle: GoogleFonts.poppins(
        color: Colors.black,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF96B83D) : Colors.grey.shade400,
        ),
      ),
      onSelected: onSelected,
    );
  }

  Widget _buildAddOtherRow({
    required TextEditingController controller,
    required String label,
    required VoidCallback onAdd,
    required bool isAdding,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(color: Colors.black54),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF96B83D)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
            onSubmitted: (_) {
              if (!isAdding) onAdd();
            },
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black54, width: 1),
          ),
          child: isAdding
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(
                    color: Color(0xFF546F35),
                    strokeWidth: 3,
                  ),
                )
              : IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, color: Colors.black, size: 28),
                  tooltip: "Add to list",
                ),
        ),
      ],
    );
  }
}
