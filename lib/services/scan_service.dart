import 'database_helper.dart';
import '../utils/health_rules.dart';

// 1. DATA MODEL (Now includes Nutrients!)
class ScanResult {
  final String productName;
  final bool isSafe;
  final List<String> warnings;
  final List<String> unknownConditions;
  final String? imageUrl;
  final String? nutriscore;

  // Nutrient Data (for display or advanced logic)
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
    // A. Fetch from SQLite
    final product = await _dbHelper.getProduct(barcode);
    if (product == null) return null; // Not found

    // B. Parse Data from DB columns
    String name = product['name'] ?? "Unknown Product";
    String ingredients = (product['ingredients'] ?? "").toLowerCase();
    String? imageUrl = product['image_url'];
    String? nutriscore = product['nutriscore'];

    // C. Parse Nutrients (Handle nulls safely)
    double? sugar = product['sugars_100g'] as double?;
    double? salt = product['salt_100g'] as double?;
    double? fat = product['fat_100g'] as double?;
    double? satFat = product['saturated_fat_100g'] as double?;
    double? calories = product['calories_100g'] as double?;

    // D. Get User Profile (Mocked for now - later link to Firebase)
    // TODO: Fetch this from UserProvider or Firebase
    List<String> userConditions = ['Diabetes', 'Hypertension']; 
    List<String> userAllergies = ['Peanuts'];

    // E. ANALYZE HEALTH RULES
    List<String> warnings = [];
    List<String> unknown = [];

    // --- CHECK 1: Medical Conditions (Numeric + Text) ---
    for (var condition in userConditions) {
      if (diseaseRules.containsKey(condition)) {
        final rule = diseaseRules[condition]!;
        
        // 1. Check Keywords (Ingredients)
        for (var forbidden in rule.forbiddenKeywords) {
          if (ingredients.contains(forbidden.toLowerCase())) {
            warnings.add("⚠️ $condition: Contains '${forbidden}'");
            break; // Found one bad ingredient, move to next condition
          }
        }

        // 2. Check Nutrients (The New Accurate Logic)
        rule.nutrientLimits.forEach((nutrientKey, limit) {
          double? productValue;
          
          // Map string keys to actual variables
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

    // --- CHECK 2: Allergies (Strict Text Match) ---
    for (var allergy in userAllergies) {
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

    // F. FINAL VERDICT
    bool isSafe = warnings.isEmpty;

    return ScanResult(
      productName: name,
      isSafe: isSafe,
      warnings: warnings,
      unknownConditions: unknown,
      imageUrl: imageUrl,
      nutriscore: nutriscore,
      sugar: sugar,
      salt: salt,
      fat: fat,
      calories: calories,
    );
  }
}