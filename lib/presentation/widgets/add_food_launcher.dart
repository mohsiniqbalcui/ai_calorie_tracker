import 'package:flutter/material.dart';
import 'add_food_flow.dart';

class AddFoodFlowLauncher {
  static void open(BuildContext context, String mealType) => AddFoodFlow.show(context, mealType: mealType);
}
