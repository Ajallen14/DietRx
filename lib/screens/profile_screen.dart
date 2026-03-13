import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../services/profile_service.dart';
import '../services/database_helper.dart';
import '../widgets/custom_loading.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- UI CONSTANTS & DYNAMIC THEME COLORS ---
  final Color _headerGreen = const Color(0xFF557B3E);
  final Color _borderGreen = const Color(0xFF8CC63F);

  // Dynamic color getters
  bool get isDark => MyApp.themeNotifier.value == ThemeMode.dark;
  Color get bgColor => isDark ? const Color(0xFF121212) : Colors.white;
  Color get cardColor => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get textPrimary => isDark ? Colors.white : Colors.black87;
  Color get textSecondary => isDark ? Colors.white70 : Colors.black54;
  Color get pillBgColor =>
      isDark ? const Color(0xFF2A3D1E) : const Color(0xFFF4F9DD);
  Color get dividerColor => isDark ? Colors.white12 : Colors.black12;

  // --- STATE VARIABLES ---
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  String _userName = "User";
  String _userEmail = "";
  String? _photoUrl;

  File? _localImageFile;
  bool _isUploadingPhoto = false;

  List<String> _conditions = [];
  List<String> _allergies = [];

  int _totalScanned = 0;
  int _safeItems = 0;
  int _notSafeItems = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      await Future.wait([
        () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            _userName = user.displayName ?? "User";
            _userEmail = user.email ?? "";
            _photoUrl = user.photoURL;

            final doc = await FirebaseFirestore.instance
                .collection('Health_Profiles')
                .doc(user.uid)
                .get();

            if (doc.exists && doc.data() != null) {
              final data = doc.data()!;
              _conditions = List<String>.from(data['conditions'] ?? []);
              _allergies = List<String>.from(data['allergies'] ?? []);
            }
          }

          final dbHelper = DatabaseHelper();
          final history = await dbHelper.getScanHistory();

          int safeCount = 0;
          int unsafeCount = 0;

          for (var item in history) {
            if (item['status'] == 'safe') safeCount++;
            if (item['status'] == 'unsafe') unsafeCount++;
          }

          _totalScanned = history.length;
          _safeItems = safeCount;
          _notSafeItems = unsafeCount;
        }(),
        Future.delayed(const Duration(seconds: 2)),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- EDIT NAME ---
  void _showEditNameDialog() {
    TextEditingController nameController = TextEditingController(
      text: _userName,
    );
    bool isSaving = false;
    final parentContext = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Edit Name",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: _headerGreen,
                  fontSize: 18,
                ),
              ),
              content: TextField(
                controller: nameController,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: "Enter your name",
                  hintStyle: TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: isDark ? Colors.black45 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text("Cancel", style: TextStyle(color: textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newName = nameController.text.trim();
                          if (newName.isEmpty) return;

                          setStateDialog(() => isSaving = true);

                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            await user?.updateDisplayName(newName);

                            if (mounted) {
                              setState(() => _userName = newName);
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text("Name updated successfully!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setStateDialog(() => isSaving = false);
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to update name."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _headerGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Save",
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- EDIT PHOTO ---
  Future<void> _pickProfilePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _localImageFile = File(image.path);
        _isUploadingPhoto = true;
      });

      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile photo updated!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update photo: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- ADD ITEM DIALOG LOGIC ---
  void _showAddItemDialog(bool isAllergy) {
    TextEditingController controller = TextEditingController();
    bool isAdding = false;
    final parentContext = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isAllergy ? "Add New Allergy" : "Add Health Condition",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: _headerGreen,
                  fontSize: 18,
                ),
              ),
              content: TextField(
                controller: controller,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: "e.g. ${isAllergy ? 'Dairy' : 'Diabetes'}",
                  hintStyle: TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: isDark ? Colors.black45 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isAdding
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text("Cancel", style: TextStyle(color: textPrimary)),
                ),
                ElevatedButton(
                  onPressed: isAdding
                      ? null
                      : () async {
                          final text = controller.text.trim();
                          if (text.isEmpty) return;

                          setStateDialog(() => isAdding = true);

                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              if (isAllergy) {
                                await FirebaseFirestore.instance
                                    .collection('Health_Profiles')
                                    .doc(user.uid)
                                    .set({
                                      'allergies': FieldValue.arrayUnion([
                                        text,
                                      ]),
                                    }, SetOptions(merge: true));
                                _allergies.add(text);
                              } else {
                                await FirebaseFirestore.instance
                                    .collection('Health_Profiles')
                                    .doc(user.uid)
                                    .set({
                                      'conditions': FieldValue.arrayUnion([
                                        text,
                                      ]),
                                    }, SetOptions(merge: true));
                                _conditions.add(text);
                              }
                            }

                            try {
                              await _profileService.addCustomCondition(
                                text,
                                isAllergy: isAllergy,
                              );
                            } catch (aiError) {
                              print(
                                "AI Rule generation took too long or failed: $aiError",
                              );
                            }

                            if (mounted) {
                              setState(() {});
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                  content: Text("Added $text to your profile!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setStateDialog(() => isAdding = false);
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Failed to add item to your profile.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _headerGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: isAdding
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Add",
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildStaticAppBar() {
    return AppBar(
      backgroundColor: _headerGreen,
      elevation: 0,
      centerTitle: true,
      title: Text(
        "My Profile",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: _buildStaticAppBar(),
        body: const CustomLoading(
          message: "Fetching your profile...",
          textColor: Color(0xFF557B3E),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildStaticAppBar(),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(color: _headerGreen),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Container(
                        height: 90,
                        width: double.infinity,
                        color: bgColor,
                      ),
                    ),
                    Container(
                      height: 100,
                      width: double.infinity,
                      color: _headerGreen,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 30,
                        left: 24,
                        right: 24,
                        bottom: 20,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: dividerColor, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black45
                                  : const Color(0xFFD1D5DB),
                              blurRadius: isDark ? 8 : 0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 20,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _pickProfilePhoto,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    height: 80,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFB1C9D6),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: cardColor,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _isUploadingPhoto
                                          ? const Padding(
                                              padding: EdgeInsets.all(20.0),
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                              ),
                                            )
                                          : _localImageFile != null
                                          ? Image.file(
                                              _localImageFile!,
                                              fit: BoxFit.cover,
                                            )
                                          : _photoUrl != null &&
                                                _photoUrl!.isNotEmpty
                                          ? Image.network(
                                              _photoUrl!,
                                              fit: BoxFit.cover,
                                            )
                                          : const Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _headerGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: cardColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: _showEditNameDialog,
                                    borderRadius: BorderRadius.circular(5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _userName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              color: textPrimary,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _userEmail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                Container(
                  color: bgColor,
                  width: double.infinity,
                  child: Column(
                    children: [
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          "The food you choose today shapes your health tomorrow. 🍃",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatBox(
                                _totalScanned.toString(),
                                "Items scanned",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatBox(
                                _safeItems.toString(),
                                "Safe Items",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatBox(
                                _notSafeItems.toString(),
                                "Not Safe Items",
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              "🌿",
                              "Diagnosed health conditions",
                              () => _showAddItemDialog(false),
                            ),
                            const SizedBox(height: 15),
                            _conditions.isEmpty
                                ? Text(
                                    "No conditions added yet.",
                                    style: GoogleFonts.poppins(
                                      color: textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: _conditions
                                        .map(
                                          (condition) => _buildChip(condition),
                                        )
                                        .toList(),
                                  ),
                            const SizedBox(height: 20),
                            Divider(color: dividerColor, thickness: 1.5),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              "🌿",
                              "Food allergies",
                              () => _showAddItemDialog(true),
                            ),
                            const SizedBox(height: 15),
                            _allergies.isEmpty
                                ? Text(
                                    "No allergies added yet.",
                                    style: GoogleFonts.poppins(
                                      color: textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: _allergies
                                        .map((allergy) => _buildChip(allergy))
                                        .toList(),
                                  ),
                            const SizedBox(height: 20),
                            Divider(color: dividerColor, thickness: 1.5),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            _buildActionButton(
                              icon: isDark ? Icons.light_mode : Icons.dark_mode,
                              label: isDark
                                  ? "Switch to Light Mode"
                                  : "Switch to Dark Mode",
                              color: _headerGreen,
                              onTap: () {
                                setState(() {
                                  MyApp.themeNotifier.value = isDark
                                      ? ThemeMode.light
                                      : ThemeMode.dark;
                                });
                              },
                            ),
                            const SizedBox(height: 15),

                            _buildActionButton(
                              icon: Icons.logout,
                              label: "Log Out",
                              color: Colors.redAccent,
                              onTap: () async {
                                await FirebaseAuth.instance.signOut();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _borderGreen, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: dividerColor),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              number,
              style: GoogleFonts.poppins(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String emoji, String title, VoidCallback onAdd) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ),
        InkWell(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: textPrimary, width: 1.2),
            ),
            child: Icon(Icons.add, size: 16, color: textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: pillBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderGreen, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
