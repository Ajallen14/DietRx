class ScanResult {
  final String productName;
  final bool isSafe;
  final bool isMissingData;
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

  final List<Map<String, dynamic>> alternatives;

  ScanResult({
    required this.productName,
    required this.isSafe,
    required this.isMissingData,
    required this.warnings,
    required this.unknownConditions,
    required this.alternatives,
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