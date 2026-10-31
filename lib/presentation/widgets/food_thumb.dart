import 'dart:io';

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Small rounded food picture. Shows the remote or local photo when there is
/// one and a tinted category icon otherwise, so layouts never depend on an
/// image loading.
class FoodThumb extends StatelessWidget {
  final String? imageUrl;
  final IconData icon;
  final double size;

  const FoodThumb(
      {super.key,
      this.imageUrl,
      this.icon = Icons.restaurant_rounded,
      this.size = 48});

  static IconData iconForCategory(String category) => switch (category) {
        'Fruit' => Icons.apple_rounded,
        'Vegetables' => Icons.eco_rounded,
        'Grains' => Icons.grain_rounded,
        'Protein' => Icons.set_meal_rounded,
        'Dairy' => Icons.icecream_rounded,
        'Drinks' => Icons.local_cafe_rounded,
        'Snacks' => Icons.cookie_rounded,
        'Nuts & Seeds' => Icons.spa_rounded,
        'Meals' => Icons.ramen_dining_rounded,
        'Packaged' => Icons.inventory_2_rounded,
        _ => Icons.restaurant_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Container(
      width: size,
      height: size,
      color: scheme.primaryContainer,
      child: Icon(icon, size: size * 0.5, color: scheme.primary),
    );
    final url = imageUrl;
    Widget child = fallback;
    if (url != null && url.isNotEmpty) {
      child = url.startsWith('http')
          ? Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
              loadingBuilder: (_, w, progress) =>
                  progress == null ? w : fallback,
            )
          : Image.file(File(url),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback);
    }
    return ClipRRect(
        borderRadius: BorderRadius.circular(Radii.md - 2),
        child: SizedBox(width: size, height: size, child: child));
  }
}
