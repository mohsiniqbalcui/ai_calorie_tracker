/// Built-in food reference. Values are per 100 g and approximate
/// (USDA-style averages); users can always edit an entry after logging.
class FoodEntry {
  final String name;
  final String category;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium; // mg
  final double servingG;
  final String servingLabel;
  final Set<String> tags;

  const FoodEntry({
    required this.name,
    required this.category,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.servingG,
    required this.servingLabel,
    required this.tags,
  });

  /// Nutrition for [grams] of this food.
  FoodPortion portion(double grams) {
    final k = grams / 100;
    return FoodPortion(
      grams: grams,
      kcal: kcal * k,
      protein: protein * k,
      carbs: carbs * k,
      fat: fat * k,
      fiber: fiber * k,
      sugar: sugar * k,
      sodium: sodium * k,
    );
  }

  bool matchesDiet(Set<String> diet) => diet.every(tags.contains);
}

class FoodPortion {
  final double grams;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;

  const FoodPortion({
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
  });
}

class DietOption {
  final String key;
  final String label;
  const DietOption(this.key, this.label);
}

class FoodDatabase {
  static const diets = [
    DietOption('vegetarian', 'Vegetarian'),
    DietOption('vegan', 'Vegan'),
    DietOption('gluten_free', 'Gluten-free'),
    DietOption('dairy_free', 'Dairy-free'),
  ];

  static const categories = [
    'Fruit',
    'Vegetables',
    'Grains',
    'Protein',
    'Dairy',
    'Nuts & Fats',
    'Meals',
    'Snacks & Sweets',
    'Drinks',
  ];

  // Tag letters: V = vegan (implies vegetarian + dairy-free), T = vegetarian,
  // G = gluten-free, D = dairy-free.
  static FoodEntry _f(String name, String cat, double kcal, double p, double c, double f, double fiber,
      double sugar, double sodium, double serving, String label, String tags) {
    final set = <String>{};
    if (tags.contains('V')) set.addAll({'vegan', 'vegetarian', 'dairy_free'});
    if (tags.contains('T')) set.add('vegetarian');
    if (tags.contains('G')) set.add('gluten_free');
    if (tags.contains('D')) set.add('dairy_free');
    return FoodEntry(
      name: name,
      category: cat,
      kcal: kcal,
      protein: p,
      carbs: c,
      fat: f,
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
      servingG: serving,
      servingLabel: label,
      tags: set,
    );
  }

  static final List<FoodEntry> all = [
    // Fruit
    _f('Apple', 'Fruit', 52, .3, 14, .2, 2.4, 10, 1, 182, '1 medium', 'VG'),
    _f('Banana', 'Fruit', 89, 1.1, 23, .3, 2.6, 12, 1, 118, '1 medium', 'VG'),
    _f('Orange', 'Fruit', 47, .9, 12, .1, 2.4, 9, 0, 131, '1 medium', 'VG'),
    _f('Strawberries', 'Fruit', 32, .7, 7.7, .3, 2, 4.9, 1, 150, '1 cup', 'VG'),
    _f('Blueberries', 'Fruit', 57, .7, 14, .3, 2.4, 10, 1, 148, '1 cup', 'VG'),
    _f('Grapes', 'Fruit', 69, .7, 18, .2, .9, 15, 2, 92, '1 cup', 'VG'),
    _f('Mango', 'Fruit', 60, .8, 15, .4, 1.6, 14, 1, 165, '1 cup', 'VG'),
    _f('Pineapple', 'Fruit', 50, .5, 13, .1, 1.4, 10, 1, 165, '1 cup', 'VG'),
    _f('Watermelon', 'Fruit', 30, .6, 7.6, .2, .4, 6.2, 1, 280, '1 wedge', 'VG'),
    _f('Avocado', 'Fruit', 160, 2, 9, 15, 6.7, .7, 7, 100, '1/2 avocado', 'VG'),
    _f('Dates', 'Fruit', 282, 2.5, 75, .4, 8, 63, 2, 24, '1 date', 'VG'),
    // Vegetables
    _f('Broccoli', 'Vegetables', 34, 2.8, 7, .4, 2.6, 1.7, 33, 90, '1 cup', 'VG'),
    _f('Carrot', 'Vegetables', 41, .9, 10, .2, 2.8, 4.7, 69, 60, '1 medium', 'VG'),
    _f('Spinach', 'Vegetables', 23, 2.9, 3.6, .4, 2.2, .4, 79, 30, '1 cup', 'VG'),
    _f('Tomato', 'Vegetables', 18, .9, 3.9, .2, 1.2, 2.6, 5, 120, '1 medium', 'VG'),
    _f('Cucumber', 'Vegetables', 15, .7, 3.6, .1, .5, 1.7, 2, 100, '1/2 cucumber', 'VG'),
    _f('Potato, boiled', 'Vegetables', 87, 1.9, 20, .1, 1.8, .9, 5, 150, '1 medium', 'VG'),
    _f('Sweet potato, baked', 'Vegetables', 90, 2, 21, .2, 3.3, 6.5, 36, 130, '1 medium', 'VG'),
    _f('Onion', 'Vegetables', 40, 1.1, 9.3, .1, 1.7, 4.2, 4, 110, '1 medium', 'VG'),
    _f('Bell pepper', 'Vegetables', 31, 1, 6, .3, 2.1, 4.2, 4, 120, '1 medium', 'VG'),
    _f('Mushrooms', 'Vegetables', 22, 3.1, 3.3, .3, 1, 2, 5, 70, '1 cup', 'VG'),
    _f('Cauliflower', 'Vegetables', 25, 1.9, 5, .3, 2, 1.9, 30, 100, '1 cup', 'VG'),
    _f('Green beans', 'Vegetables', 31, 1.8, 7, .2, 2.7, 3.3, 6, 100, '1 cup', 'VG'),
    _f('Corn', 'Vegetables', 96, 3.4, 21, 1.5, 2.4, 4.5, 15, 90, '1/2 cup', 'VG'),
    // Grains
    _f('White rice, cooked', 'Grains', 130, 2.7, 28, .3, .4, 0, 1, 158, '1 cup', 'VG'),
    _f('Brown rice, cooked', 'Grains', 123, 2.7, 26, 1, 1.6, 0, 4, 195, '1 cup', 'VG'),
    _f('Quinoa, cooked', 'Grains', 120, 4.4, 21, 1.9, 2.8, .9, 7, 185, '1 cup', 'VG'),
    _f('Pasta, cooked', 'Grains', 158, 5.8, 31, .9, 1.8, .6, 1, 140, '1 cup', 'V'),
    _f('Oats (rolled, dry)', 'Grains', 389, 17, 66, 7, 10.6, 1, 2, 40, '1/2 cup dry', 'V'),
    _f('White bread', 'Grains', 265, 9, 49, 3.2, 2.7, 5, 491, 30, '1 slice', 'V'),
    _f('Whole wheat bread', 'Grains', 247, 13, 41, 3.4, 7, 6, 450, 32, '1 slice', 'V'),
    _f('Chapati', 'Grains', 297, 9.5, 46, 8, 4, 1, 360, 40, '1 roti', 'V'),
    _f('Naan', 'Grains', 290, 9, 50, 6, 2, 4, 420, 90, '1 piece', 'T'),
    _f('Tortilla', 'Grains', 312, 8, 52, 8, 3, 2, 600, 45, '1 tortilla', 'V'),
    _f('Cornflakes', 'Grains', 357, 7, 84, .4, 3, 10, 730, 30, '1 bowl', 'V'),
    _f('Granola', 'Grains', 471, 10, 64, 20, 7, 24, 26, 45, '1/2 cup', 'T'),
    // Protein
    _f('Egg, boiled', 'Protein', 155, 13, 1.1, 11, 0, 1.1, 124, 50, '1 large', 'TGD'),
    _f('Omelette', 'Protein', 154, 11, .6, 12, 0, .4, 155, 100, '2 eggs', 'TGD'),
    _f('Chicken breast, cooked', 'Protein', 165, 31, 0, 3.6, 0, 0, 74, 120, '1 breast', 'GD'),
    _f('Chicken thigh, cooked', 'Protein', 209, 26, 0, 11, 0, 0, 95, 100, '1 thigh', 'GD'),
    _f('Beef steak, cooked', 'Protein', 271, 25, 0, 19, 0, 0, 60, 120, '1 steak', 'GD'),
    _f('Ground beef, cooked', 'Protein', 250, 26, 0, 15, 0, 0, 72, 100, '1 patty', 'GD'),
    _f('Lamb, cooked', 'Protein', 294, 25, 0, 21, 0, 0, 72, 100, '1 serving', 'GD'),
    _f('Turkey breast', 'Protein', 135, 30, 0, .7, 0, 0, 55, 100, '1 serving', 'GD'),
    _f('Salmon, cooked', 'Protein', 206, 22, 0, 12, 0, 0, 59, 150, '1 fillet', 'GD'),
    _f('Tuna, canned', 'Protein', 116, 26, 0, 1, 0, 0, 247, 100, '1 can', 'GD'),
    _f('Shrimp, cooked', 'Protein', 99, 24, .2, .3, 0, 0, 111, 85, '3 oz', 'GD'),
    _f('Tofu', 'Protein', 76, 8, 1.9, 4.8, .3, .6, 7, 100, '1/2 cup', 'VG'),
    _f('Tempeh', 'Protein', 192, 20, 7.6, 11, 0, 0, 9, 100, '1 serving', 'VG'),
    _f('Lentils, cooked', 'Protein', 116, 9, 20, .4, 7.9, 1.8, 2, 200, '1 cup', 'VG'),
    _f('Chickpeas, cooked', 'Protein', 164, 8.9, 27, 2.6, 7.6, 4.8, 7, 160, '1 cup', 'VG'),
    _f('Black beans, cooked', 'Protein', 132, 8.9, 24, .5, 8.7, .3, 1, 170, '1 cup', 'VG'),
    _f('Kidney beans, cooked', 'Protein', 127, 8.7, 23, .5, 6.4, .3, 1, 170, '1 cup', 'VG'),
    _f('Bacon, cooked', 'Protein', 541, 37, 1.4, 42, 0, 0, 1717, 16, '1 slice', 'GD'),
    _f('Sausage', 'Protein', 301, 12, 2, 27, 0, 1, 800, 60, '1 link', 'D'),
    _f('Whey protein', 'Protein', 400, 80, 8, 6, 0, 4, 300, 30, '1 scoop', 'TG'),
    // Dairy
    _f('Milk, whole', 'Dairy', 61, 3.2, 4.8, 3.3, 0, 5, 43, 244, '1 cup', 'TG'),
    _f('Milk, skim', 'Dairy', 34, 3.4, 5, .1, 0, 5, 42, 244, '1 cup', 'TG'),
    _f('Almond milk', 'Dairy', 17, .6, .6, 1.1, .2, .2, 67, 240, '1 cup', 'VG'),
    _f('Yogurt, plain', 'Dairy', 61, 3.5, 4.7, 3.3, 0, 4.7, 46, 170, '1 cup', 'TG'),
    _f('Greek yogurt', 'Dairy', 59, 10, 3.6, .4, 0, 3.2, 36, 170, '3/4 cup', 'TG'),
    _f('Cheddar cheese', 'Dairy', 403, 25, 1.3, 33, 0, .5, 621, 28, '1 slice', 'TG'),
    _f('Mozzarella', 'Dairy', 280, 28, 3, 17, 0, 1, 627, 28, '1 oz', 'TG'),
    _f('Paneer', 'Dairy', 265, 18, 1.2, 21, 0, 1, 18, 100, '1/2 cup cubes', 'TG'),
    _f('Cottage cheese', 'Dairy', 98, 11, 3.4, 4.3, 0, 2.7, 364, 110, '1/2 cup', 'TG'),
    _f('Butter', 'Dairy', 717, .9, .1, 81, 0, .1, 11, 14, '1 tbsp', 'TG'),
    _f('Ghee', 'Dairy', 900, 0, 0, 100, 0, 0, 0, 14, '1 tbsp', 'TG'),
    // Nuts & fats
    _f('Almonds', 'Nuts & Fats', 579, 21, 22, 50, 12.5, 4.4, 1, 28, '1 handful', 'VG'),
    _f('Walnuts', 'Nuts & Fats', 654, 15, 14, 65, 6.7, 2.6, 2, 28, '1 handful', 'VG'),
    _f('Cashews', 'Nuts & Fats', 553, 18, 30, 44, 3.3, 6, 12, 28, '1 handful', 'VG'),
    _f('Peanut butter', 'Nuts & Fats', 588, 25, 20, 50, 6, 9, 426, 32, '2 tbsp', 'VG'),
    _f('Chia seeds', 'Nuts & Fats', 486, 17, 42, 31, 34, 0, 16, 12, '1 tbsp', 'VG'),
    _f('Olive oil', 'Nuts & Fats', 884, 0, 0, 100, 0, 0, 2, 14, '1 tbsp', 'VG'),
    _f('Hummus', 'Nuts & Fats', 166, 8, 14, 10, 6, .3, 379, 60, '1/4 cup', 'VG'),
    // Prepared meals
    _f('Pizza slice', 'Meals', 266, 11, 33, 10, 2.3, 3.6, 598, 107, '1 slice', 'T'),
    _f('Cheeseburger', 'Meals', 295, 17, 24, 14, 1.3, 5, 396, 160, '1 burger', ''),
    _f('French fries', 'Meals', 312, 3.4, 41, 15, 3.8, .3, 210, 117, 'medium', 'VG'),
    _f('Fried rice', 'Meals', 163, 4, 25, 5.5, 1, 1, 400, 200, '1 bowl', 'D'),
    _f('Chicken biryani', 'Meals', 175, 8, 22, 6.5, 1, 1, 400, 250, '1 plate', 'GD'),
    _f('Dal (lentil curry)', 'Meals', 105, 6, 15, 2.5, 4, 2, 300, 200, '1 bowl', 'VG'),
    _f('Chicken curry', 'Meals', 150, 12, 5, 9, 1.2, 2, 350, 200, '1 bowl', 'GD'),
    _f('Sushi roll', 'Meals', 140, 5, 28, 1, .8, 4, 400, 100, '4 pieces', 'D'),
    _f('Caesar salad', 'Meals', 190, 7, 8, 15, 1.5, 2, 500, 150, '1 bowl', ''),
    _f('Ham sandwich', 'Meals', 250, 12, 28, 9, 2, 4, 700, 150, '1 sandwich', 'D'),
    _f('Pancakes', 'Meals', 227, 6, 28, 10, .9, 9, 439, 77, '2 pancakes', 'T'),
    _f('Shawarma wrap', 'Meals', 240, 15, 25, 9, 2, 3, 600, 200, '1 wrap', 'D'),
    _f('Falafel', 'Meals', 333, 13, 32, 18, 5, 1, 294, 17, '1 piece', 'V'),
    _f('Samosa', 'Meals', 262, 4.7, 28, 15, 2.8, 1.4, 423, 50, '1 piece', 'V'),
    _f('Dosa', 'Meals', 168, 3.9, 29, 3.7, .9, .5, 260, 100, '1 dosa', 'VG'),
    _f('Idli', 'Meals', 130, 3.5, 27, .5, 1, .5, 170, 40, '1 idli', 'VG'),
    // Snacks & sweets
    _f('Dark chocolate', 'Snacks & Sweets', 598, 7.8, 46, 43, 11, 24, 20, 28, '1 oz', 'V'),
    _f('Milk chocolate', 'Snacks & Sweets', 535, 7.7, 59, 30, 3.4, 52, 79, 28, '1 oz', 'TG'),
    _f('Ice cream', 'Snacks & Sweets', 207, 3.5, 24, 11, .7, 21, 80, 66, '1/2 cup', 'TG'),
    _f('Cookie', 'Snacks & Sweets', 488, 5, 64, 24, 2, 34, 350, 30, '1 cookie', 'T'),
    _f('Potato chips', 'Snacks & Sweets', 536, 7, 53, 35, 4.8, .3, 525, 28, '1 small bag', 'VG'),
    _f('Popcorn', 'Snacks & Sweets', 387, 13, 78, 4.5, 15, .9, 8, 28, '3 cups', 'VG'),
    _f('Donut', 'Snacks & Sweets', 452, 5, 51, 25, 1.7, 23, 326, 60, '1 donut', 'T'),
    _f('Croissant', 'Snacks & Sweets', 406, 8, 46, 21, 2.4, 11, 400, 57, '1 croissant', 'T'),
    _f('Cake slice', 'Snacks & Sweets', 350, 4, 50, 15, 1, 35, 300, 80, '1 slice', 'T'),
    _f('Honey', 'Snacks & Sweets', 304, .3, 82, 0, .2, 82, 4, 21, '1 tbsp', 'TGD'),
    _f('Sugar', 'Snacks & Sweets', 387, 0, 100, 0, 0, 100, 1, 4, '1 tsp', 'VG'),
    _f('Jam', 'Snacks & Sweets', 250, .4, 65, .1, .5, 48, 32, 20, '1 tbsp', 'VG'),
    // Drinks
    _f('Orange juice', 'Drinks', 45, .7, 10, .2, .2, 8.4, 1, 248, '1 cup', 'VG'),
    _f('Cola', 'Drinks', 42, 0, 10.6, 0, 0, 10.6, 4, 355, '1 can', 'VG'),
    _f('Coffee, black', 'Drinks', 1, .1, 0, 0, 0, 0, 2, 240, '1 cup', 'VG'),
    _f('Latte', 'Drinks', 54, 2.9, 4.5, 2.8, 0, 4.2, 40, 350, '1 medium', 'TG'),
    _f('Beer', 'Drinks', 43, .5, 3.6, 0, 0, 0, 4, 355, '1 bottle', 'VD'),
    _f('Green tea', 'Drinks', 1, 0, 0, 0, 0, 0, 1, 240, '1 cup', 'VG'),
  ];

  static FoodEntry? byName(String name) {
    for (final f in all) {
      if (f.name == name) return f;
    }
    return null;
  }

  /// Name search: every word typed must appear in the food name or category.
  static List<FoodEntry> search(String query, {String? category, Set<String> diet = const {}}) {
    final words = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final results = all.where((f) {
      if (category != null && f.category != category) return false;
      if (!f.matchesDiet(diet)) return false;
      final hay = '${f.name} ${f.category}'.toLowerCase();
      return words.every(hay.contains);
    }).toList();
    // Names that start with the query first.
    final q = query.toLowerCase().trim();
    if (q.isNotEmpty) {
      results.sort((a, b) {
        final sa = a.name.toLowerCase().startsWith(q) ? 0 : 1;
        final sb = b.name.toLowerCase().startsWith(q) ? 0 : 1;
        return sa != sb ? sa.compareTo(sb) : a.name.compareTo(b.name);
      });
    }
    return results;
  }
}
