import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_helper.dart';
import '../utils/health_rules.dart';

// 1. DATA MODEL
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
  
  // Nutrient Data
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

  // 2. THE MAIN PROCESS
  Future<ScanResult?> processBarcode(String barcode) async {
    // A. Fetch Product from Offline SQLite
    final product = await _dbHelper.getProduct(barcode);
    if (product == null) return null;

    // B. Parse Product Data
    String name = product['name'] ?? "Unknown Product";
    String ingredients = (product['ingredients'] ?? "").toLowerCase();
    String? imageUrl = product['image_url'];
    String? nutriscore = product['nutriscore'];
    String? categories = product['categories'];
    String? labels = product['labels'];
    int? novaGroup = product['nova_group'] as int?;

    // Nutrients
    double? sugar = product['sugars_100g'] as double?;
    double? salt = product['salt_100g'] as double?;
    double? fat = product['fat_100g'] as double?;
    double? satFat = product['saturated_fat_100g'] as double?;
    double? calories = product['calories_100g'] as double?;

    // --- C. FETCH REAL USER PROFILE FROM FIREBASE ---
    List<String> userConditions = [];
    List<String> userAllergies = [];

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch the user document
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;

          if (data['selectedDiseases'] != null) {
            userConditions = List<String>.from(data['selectedDiseases']);
          }
          if (data['allergies'] != null) {
            userAllergies = List<String>.from(data['allergies']);
          }
        }
      }
    } catch (e) {
      print("⚠️ Error fetching user profile: $e");
    }

    // D. ANALYZE HEALTH RULES
    List<String> warnings = [];
    List<String> unknown = [];

    // --- CHECK 1: Medical Conditions ---
    for (var condition in userConditions) {
      if (diseaseRules.containsKey(condition)) {
        final rule = diseaseRules[condition]!;
        
        // Keyword Check
        for (var forbidden in rule.forbiddenKeywords) {
          if (ingredients.contains(forbidden.toLowerCase())) {
            warnings.add("⚠️ $condition: Contains '${forbidden}'");
            break; 
          }
        }

        // Nutrient Check
        rule.nutrientLimits.forEach((nutrientKey, limit) {
          double? productValue;
          if (nutrientKey == 'sugar_100g') productValue = sugar;
          if (nutrientKey == 'salt_100g') productValue = salt;
          if (nutrientKey == 'fat_100g') productValue = fat;
          if (nutrientKey == 'sat_fat_100g') productValue = satFat;
          
          if (productValue != null && productValue > limit) {
            warnings.add("🛑 $condition: High $nutrientKey (${productValue}g > ${limit}g limit)");
          }
        });

      } else {
        unknown.add(condition);
      }
    }

    // --- CHECK 2: Allergies ---
    String allergensList = (product['allergens'] ?? "").toLowerCase();
    
    for (var allergy in userAllergies) {
      // 1. Check strict 'allergens' column
      if (allergensList.contains(allergy.toLowerCase())) {
         warnings.add("☠️ ALLERGY ALERT: Contains ${allergy}");
         continue;
      }

      // 2. Fallback: Check ingredients text
      if (diseaseRules.containsKey(allergy)) {
        final rule = diseaseRules[allergy]!;
        for (var forbidden in rule.forbiddenKeywords) {
          if (ingredients.contains(forbidden.toLowerCase())) {
            warnings.add("☠️ ALLERGY ALERT: Contains ${forbidden}");
            break; 
          }
        }
      }
    }

    // --- CHECK 3: Nova Group (Ultra-Processed) ---
    if (novaGroup == 4) {
      warnings.add("🏭 Warning: Ultra-Processed Food (Nova 4)");
    }

    // E. FINAL RESULT
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