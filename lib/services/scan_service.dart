import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_helper.dart';
import '../utils/health_rules.dart';

class ScanResult {
  final String productName;
  final bool isSafe;
  final List<String> warnings;
  final List<String> unknownConditions;
  final String? imageUrl;
  final String? nutriscore;
  final int? novaGroup;
  final String? categories;
  final String? labels;
  final double? sugar;
  final double? salt;
  final double? fat;
  final double? calories;

  ScanResult({
    required this.productName,
    required this.isSafe,
    required this.warnings,
    required this.unknownConditions,
    this.imageUrl,
    this.nutriscore,
    this.novaGroup,
    this.categories,
    this.labels,
    this.sugar,
    this.salt,
    this.fat,
    this.calories,
  });
}

class ScanService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<ScanResult?> processBarcode(String barcode) async {
    // A. Fetch Product from SQLite
    final product = await _dbHelper.getProduct(barcode);
    if (product == null) return null;

    // B. Parse Data
    String name = product['name'] ?? "Unknown Product";
    String ingredients = (product['ingredients'] ?? "").toLowerCase();
    String? imageUrl = product['image_url'];
    String? nutriscore = product['nutriscore'];
    int? novaGroup = product['nova_group'] as int?;
    String? categories = product['categories'];
    String? labels = product['labels'];

    double? sugar = product['sugars_100g'] as double?;
    double? salt = product['salt_100g'] as double?;
    double? fat = product['fat_100g'] as double?;
    double? satFat = product['saturated_fat_100g'] as double?;
    double? calories = product['calories_100g'] as double?;

    // --- C. FETCH USER PROFILE ---
    List<String> userConditions = [];
    List<String> userAllergies = [];

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var doc = await FirebaseFirestore.instance
            .collection('Health_Profiles')
            .doc(user.uid)
            .get();
        Map<String, dynamic>? data;

        if (doc.exists) {
          data = doc.data();
        } else {
          final query = await FirebaseFirestore.instance
              .collection('Health_Profiles')
              .where('user_id', isEqualTo: user.uid)
              .get();

          if (query.docs.isNotEmpty) {
            data = query.docs.first.data();
          }
        }

        if (data != null) {
          if (data['conditions'] != null) {
            userConditions = List<String>.from(data['conditions']);
          } else if (data['diseases'] != null) {
            userConditions = List<String>.from(data['diseases']);
          }

          if (data['allergies'] != null) {
            userAllergies = List<String>.from(data['allergies']);
          }
        }
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }

    // D. ANALYZE HEALTH RULES
    List<String> warnings = [];
    List<String> unknown = [];

    // 1. Check Diseases
    for (var condition in userConditions) {
      if (diseaseRules.containsKey(condition)) {
        final rule = diseaseRules[condition]!;

        // Rule A: Nutrient Limits
        rule.nutrientLimits.forEach((nutrientKey, limit) {
          double? val;
          if (nutrientKey == 'sugar_100g') val = sugar;
          if (nutrientKey == 'salt_100g') val = salt;
          if (nutrientKey == 'fat_100g') val = fat;
          if (nutrientKey == 'sat_fat_100g') val = satFat;

          if (val != null && val > limit) {
            warnings.add("$condition: High $nutrientKey (${val}g > ${limit}g)");
          }
        });

        // Rule B: Forbidden Keywords
        for (var forbidden in rule.forbiddenKeywords) {
          if (ingredients.contains(forbidden.toLowerCase())) {
            warnings.add("$condition: Contains '$forbidden'");
            break;
          }
        }
      } else {
        unknown.add(condition);
      }
    }

    // 2. Check Allergies
    String allergenCol = (product['allergens'] ?? "").toLowerCase();

    for (var allergy in userAllergies) {
      if (allergenCol.contains(allergy.toLowerCase())) {
        warnings.add("ALLERGY: Contains $allergy");
        continue;
      }
      if (ingredients.contains(allergy.toLowerCase())) {
        warnings.add("ALLERGY: Contains $allergy (Found in ingredients)");
        continue;
      }
      if (diseaseRules.containsKey(allergy)) {
        final rule = diseaseRules[allergy]!;
        for (var forbidden in rule.forbiddenKeywords) {
          if (ingredients.contains(forbidden.toLowerCase())) {
            warnings.add("ALLERGY: Contains $forbidden");
            break;
          }
        }
      }
    }

    // 3. Nova Warning
    if (novaGroup == 4) {
      warnings.add("Ultra-Processed Food (Nova 4)");
    }

    return ScanResult(
      productName: name,
      isSafe: warnings.isEmpty,
      warnings: warnings,
      unknownConditions: unknown,
      imageUrl: imageUrl,
      nutriscore: nutriscore,
      novaGroup: novaGroup,
      categories: categories,
      labels: labels,
      sugar: sugar,
      salt: salt,
      fat: fat,
      calories: calories,
    );
  }
}
