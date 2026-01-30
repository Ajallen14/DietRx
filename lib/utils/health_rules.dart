class HealthRule {
  final List<String> forbiddenKeywords; // Check text (Ingredients)
  final Map<String, double> nutrientLimits; // Check numbers (Values per 100g)

  HealthRule({required this.forbiddenKeywords, required this.nutrientLimits});
}

final Map<String, HealthRule> diseaseRules = {
  // MEDICAL CONDITIONS
  'Diabetes': HealthRule(
    forbiddenKeywords: ['sugar', 'sucrose', 'corn syrup', 'fructose', 'glucose', 'cane juice', 'maltodextrin', 'dextrose', 'molasses'],
    nutrientLimits: {
      'sugar_100g': 5.0, 
      'carbs_100g': 60.0, 
    },
  ),

  'Hypertension': HealthRule(
    forbiddenKeywords: ['salt', 'sodium', 'monosodium glutamate', 'msg', 'baking soda', 'brine', 'soy sauce'],
    nutrientLimits: {
      'salt_100g': 1.5, 
      'sodium_100g': 0.6, 
    },
  ),

  'Heart Problems': HealthRule(
    forbiddenKeywords: ['palm oil', 'hydrogenated', 'shortening', 'lard', 'tallow', 'margarine'],
    nutrientLimits: {
      'sat_fat_100g': 4.0,
      'cholesterol_100g': 0.05, 
      'sodium_100g': 0.4, 
    },
  ),

  'Cholesterol': HealthRule(
    forbiddenKeywords: ['palm oil', 'butter', 'ghee', 'cream', 'lard', 'fatty meat', 'coconut oil'],
    nutrientLimits: {
      'sat_fat_100g': 5.0, 
      'cholesterol_100g': 0.05,
      'trans_fat_100g': 0.0, 
    },
  ),

  'PCOS': HealthRule(
    forbiddenKeywords: ['sugar', 'white flour', 'maida', 'refined flour', 'corn syrup'],
    nutrientLimits: {
      'sugar_100g': 6.0, 
      'carbs_100g': 50.0, 
    },
  ),

  'Thyroid': HealthRule(
    forbiddenKeywords: ['soy', 'soybean', 'tofu', 'tempeh', 'edamame', 'cabbage', 'broccoli', 'cauliflower', 'kale'],
    nutrientLimits: {}, 
  ),

  'Celiac': HealthRule(
    forbiddenKeywords: ['wheat', 'barley', 'rye', 'malt', 'brewer\'s yeast', 'seitan', 'bulgur', 'couscous', 'farina', 'semolina'],
    nutrientLimits: {}, 
  ),

  'Lactose Intolerance': HealthRule(
    forbiddenKeywords: ['milk', 'lactose', 'cream', 'butter', 'cheese', 'yogurt', 'curd', 'whey', 'casein', 'milk solids'],
    nutrientLimits: {},
  ),

  // ALLERGIES
  'Peanuts': HealthRule(
    forbiddenKeywords: ['peanut', 'groundnut', 'arachis oil', 'monkey nuts'],
    nutrientLimits: {},
  ),

  'Tree Nuts': HealthRule(
    forbiddenKeywords: ['almond', 'cashew', 'walnut', 'pecan', 'pistachio', 'macadamia', 'hazelnut', 'brazil nut', 'pinenut', 'chestnut'],
    nutrientLimits: {},
  ),

  'Milk': HealthRule(
    forbiddenKeywords: ['milk', 'lactose', 'cream', 'butter', 'cheese', 'yogurt', 'whey', 'casein', 'nougat', 'ghee'],
    nutrientLimits: {},
  ),

  'Eggs': HealthRule(
    forbiddenKeywords: ['egg', 'albumin', 'globulin', 'lysozyme', 'ovalbumin', 'lecithin', 'mayonnaise', 'meringue'],
    nutrientLimits: {},
  ),

  'Wheat': HealthRule(
    forbiddenKeywords: ['wheat', 'bread crumbs', 'flour', 'semolina', 'spelt', 'bran', 'germ', 'couscous'],
    nutrientLimits: {},
  ),

  'Soy': HealthRule(
    forbiddenKeywords: ['soy', 'soybean', 'tofu', 'tempeh', 'edamame', 'miso', 'tamari', 'shoyu', 'teriyaki', 'vegetable protein'],
    nutrientLimits: {},
  ),

  'Fish': HealthRule(
    forbiddenKeywords: ['fish', 'anchovy', 'bass', 'catfish', 'cod', 'flounder', 'grouper', 'haddock', 'hake', 'halibut', 'herring', 'mahi', 'perch', 'pike', 'pollock', 'salmon', 'snapper', 'sole', 'swordfish', 'tilapia', 'trout', 'tuna'],
    nutrientLimits: {},
  ),

  'Shellfish': HealthRule(
    forbiddenKeywords: ['shrimp', 'crab', 'lobster', 'prawn', 'crayfish', 'krill', 'clam', 'mussel', 'oyster', 'scallop', 'squid', 'octopus', 'snail'],
    nutrientLimits: {},
  ),
};