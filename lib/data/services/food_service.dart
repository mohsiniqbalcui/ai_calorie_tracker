import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

import '../models/food_item.dart';

class FoodService {
  // Load the API key from the environment
  String get _apiKey => dotenv.env['GOOGLE_AI_API_KEY'] ?? '';

  bool _initialized = false;

  static const _missingKey =
      'AI logging is not configured. Add GOOGLE_AI_API_KEY to the .env file, or log with search, barcode or manual entry.';

  /// Starts Gemini on first use so the app still launches without an API key.
  bool _ensureInitialized() {
    final key = _apiKey;
    if (key.isEmpty || key == 'your_api_key_here') return false;
    if (!_initialized) {
      Gemini.init(apiKey: key);
      _initialized = true;
    }
    return true;
  }

  Future<Either<String, FoodItem>> detectFoodAndCalories(File imageFile) async {
    if (!_ensureInitialized()) return const Left(_missingKey);
    try {
      if (!imageFile.existsSync()) {
        return Left('File not found: ${imageFile.path}');
      }

      final response = await Gemini.instance.textAndImage(
        text: 'Analyze this image and identify the food. '
            'Estimate its calories, protein, carbs, and fat. '
            'Return ONLY a valid JSON object in this exact format: {"name": "food name", "calories": 100, "protein": 10, "carbs": 20, "fat": 5} '
            'Do not include any other text, explanations, or formatting. Just the JSON object.',
        images: [imageFile.readAsBytesSync()],
      );

      final output = response?.output;
      if (output == null || output.isEmpty) {
        return Left('No response output from Gemini API');
      }

      // Try to find JSON in the output, handling various formats
      String jsonString = '';

      // First, try to find complete JSON object
      final completeMatch = RegExp(r'\{.*\}').firstMatch(output);
      if (completeMatch != null) {
        jsonString = completeMatch.group(0)!;
      } else {
        // If no complete JSON found, try to extract and fix malformed JSON
        final jsonStart = output.indexOf('"name"');
        if (jsonStart != -1) {
          // Find the end of the JSON object
          final jsonEnd = output.indexOf('}', jsonStart);
          if (jsonEnd != -1) {
            // Extract the JSON part and add missing opening brace
            jsonString = '{' + output.substring(jsonStart, jsonEnd + 1);
          }
        }
      }

      if (jsonString.isEmpty) {
        return Left('No valid JSON found in output: $output');
      }

      final foodData = jsonDecode(jsonString);

      // Validate that all required fields are present
      if (!foodData.containsKey('name') ||
          !foodData.containsKey('calories') ||
          !foodData.containsKey('protein') ||
          !foodData.containsKey('carbs') ||
          !foodData.containsKey('fat')) {
        return Left('Invalid JSON structure: missing required fields');
      }

      final foodItem = FoodItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: foodData['name'].toString(),
        calories: (foodData['calories'] as num).toDouble(),
        protein: (foodData['protein'] as num).toDouble(),
        carbs: (foodData['carbs'] as num).toDouble(),
        fat: (foodData['fat'] as num).toDouble(),
        quantity: 100.0,
        timestamp: DateTime.now(),
      );
      debugPrint('Successfully created food item: ${foodItem.name}');
      return Right(foodItem);
    } catch (e) {
      debugPrint('Error in detectFoodAndCalories: $e');
      return Left('Failed to detect food: ${e.toString()}');
    }
  }

  Future<Either<String, FoodItem>> detectFoodFromText(
      String foodDescription) async {
    debugPrint('=== FOOD SERVICE DETECTFOODFROMTEXT CALLED ===');
    debugPrint('Food description: "$foodDescription"');
    if (!_ensureInitialized()) return const Left(_missingKey);
    try {
      if (foodDescription.trim().isEmpty) {
        debugPrint('Food description is empty, returning error');
        return Left('Food description cannot be empty');
      }

      debugPrint('Calling Gemini API...');
      final response = await Gemini.instance.text(
        'Analyze this food description and estimate its nutritional values. '
        'Food: "$foodDescription" '
        'Estimate calories, protein, carbs, and fat for a typical serving. '
        'Return ONLY a valid JSON object in this exact format: {"name": "food name", "calories": 100, "protein": 10, "carbs": 20, "fat": 5} '
        'Do not include any other text, explanations, or formatting. Just the JSON object.',
      );
      debugPrint('Gemini API response received');

      final output = response?.output;
      if (output == null || output.isEmpty) {
        return Left('No response output from Gemini API');
      }

      // Try to find JSON in the output, handling various formats
      String jsonString = '';

      // First, try to find complete JSON object
      final completeMatch = RegExp(r'\{.*\}').firstMatch(output);
      if (completeMatch != null) {
        jsonString = completeMatch.group(0)!;
      } else {
        // If no complete JSON found, try to extract and fix malformed JSON
        final jsonStart = output.indexOf('"name"');
        if (jsonStart != -1) {
          // Find the end of the JSON object
          final jsonEnd = output.indexOf('}', jsonStart);
          if (jsonEnd != -1) {
            // Extract the JSON part and add missing opening brace
            jsonString = '{' + output.substring(jsonStart, jsonEnd + 1);
          }
        }
      }

      if (jsonString.isEmpty) {
        return Left('No valid JSON found in output: $output');
      }

      final foodData = jsonDecode(jsonString);

      // Validate that all required fields are present
      if (!foodData.containsKey('name') ||
          !foodData.containsKey('calories') ||
          !foodData.containsKey('protein') ||
          !foodData.containsKey('carbs') ||
          !foodData.containsKey('fat')) {
        return Left('Invalid JSON structure: missing required fields');
      }

      final foodItem = FoodItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: foodData['name'].toString(),
        calories: (foodData['calories'] as num).toDouble(),
        protein: (foodData['protein'] as num).toDouble(),
        carbs: (foodData['carbs'] as num).toDouble(),
        fat: (foodData['fat'] as num).toDouble(),
        quantity: 100.0,
        timestamp: DateTime.now(),
      );
      debugPrint('Successfully created food item: ${foodItem.name}');
      return Right(foodItem);
    } catch (e) {
      debugPrint('Error in detectFoodFromText: $e');
      return Left('Failed to detect food from text: ${e.toString()}');
    }
  }
}
