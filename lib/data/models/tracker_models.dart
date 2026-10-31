class WeightEntry {
  final DateTime date;
  final double kg;

  const WeightEntry({required this.date, required this.kg});

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'kg': kg};

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        date: DateTime.parse(json['date'] as String),
        kg: (json['kg'] as num).toDouble(),
      );
}

class ExerciseEntry {
  final String id;
  final String name;
  final int minutes;
  final double calories;
  final DateTime date;

  const ExerciseEntry({
    required this.id,
    required this.name,
    required this.minutes,
    required this.calories,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'minutes': minutes,
        'calories': calories,
        'date': date.toIso8601String(),
      };

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) => ExerciseEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        minutes: (json['minutes'] as num).toInt(),
        calories: (json['calories'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
      );
}

class FastRecord {
  final DateTime start;
  final DateTime end;
  final int goalHours;

  const FastRecord(
      {required this.start, required this.end, required this.goalHours});

  Duration get duration => end.difference(start);
  bool get completed => duration.inMinutes >= goalHours * 60;

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'goal': goalHours,
      };

  factory FastRecord.fromJson(Map<String, dynamic> json) => FastRecord(
        start: DateTime.parse(json['start'] as String),
        end: DateTime.parse(json['end'] as String),
        goalHours: (json['goal'] as num).toInt(),
      );
}

class DayTotals {
  final DateTime date;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int meals;

  const DayTotals({
    required this.date,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.meals = 0,
  });
}

class RecipeIngredient {
  final String name;
  final double grams;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;

  const RecipeIngredient({
    required this.name,
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'grams': grams,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sugar': sugar,
        'sodium': sodium,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> j) => RecipeIngredient(
        name: j['name'] as String,
        grams: (j['grams'] as num).toDouble(),
        kcal: (j['kcal'] as num).toDouble(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
        fiber: (j['fiber'] as num?)?.toDouble() ?? 0,
        sugar: (j['sugar'] as num?)?.toDouble() ?? 0,
        sodium: (j['sodium'] as num?)?.toDouble() ?? 0,
      );
}

class Recipe {
  final String id;
  final String name;
  final int servings;
  final List<RecipeIngredient> ingredients;

  const Recipe(
      {required this.id,
      required this.name,
      required this.servings,
      required this.ingredients});

  double _sum(double Function(RecipeIngredient) f) =>
      ingredients.fold(0.0, (s, i) => s + f(i));

  double get totalGrams => _sum((i) => i.grams);
  double get kcalPerServing => _sum((i) => i.kcal) / servings;
  double get proteinPerServing => _sum((i) => i.protein) / servings;
  double get carbsPerServing => _sum((i) => i.carbs) / servings;
  double get fatPerServing => _sum((i) => i.fat) / servings;
  double get fiberPerServing => _sum((i) => i.fiber) / servings;
  double get sugarPerServing => _sum((i) => i.sugar) / servings;
  double get sodiumPerServing => _sum((i) => i.sodium) / servings;
  double get gramsPerServing => totalGrams / servings;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'servings': servings,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
      };

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        id: j['id'] as String,
        name: j['name'] as String,
        servings: (j['servings'] as num).toInt(),
        ingredients: (j['ingredients'] as List)
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PlannedItem {
  final String id;
  final String mealType;
  final String name;
  final double grams;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  const PlannedItem({
    required this.id,
    required this.mealType,
    required this.name,
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'mealType': mealType,
        'name': name,
        'grams': grams,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  factory PlannedItem.fromJson(Map<String, dynamic> j) => PlannedItem(
        id: j['id'] as String,
        mealType: j['mealType'] as String,
        name: j['name'] as String,
        grams: (j['grams'] as num).toDouble(),
        kcal: (j['kcal'] as num).toDouble(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
      );
}

class MeasurementEntry {
  final DateTime date;
  final double? bodyFat; // %
  final double? waist; // cm
  final double? chest;
  final double? hips;
  final double? arm;
  final double? thigh;

  const MeasurementEntry(
      {required this.date,
      this.bodyFat,
      this.waist,
      this.chest,
      this.hips,
      this.arm,
      this.thigh});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'bodyFat': bodyFat,
        'waist': waist,
        'chest': chest,
        'hips': hips,
        'arm': arm,
        'thigh': thigh,
      };

  factory MeasurementEntry.fromJson(Map<String, dynamic> j) => MeasurementEntry(
        date: DateTime.parse(j['date'] as String),
        bodyFat: (j['bodyFat'] as num?)?.toDouble(),
        waist: (j['waist'] as num?)?.toDouble(),
        chest: (j['chest'] as num?)?.toDouble(),
        hips: (j['hips'] as num?)?.toDouble(),
        arm: (j['arm'] as num?)?.toDouble(),
        thigh: (j['thigh'] as num?)?.toDouble(),
      );
}
