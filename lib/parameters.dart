import 'package:flutter/material.dart';

const Color iconGreen = Color(0xFF1B5E20);
const Color iconPurple = Color(0xFF512DA8);
const Color iconGold = Color(0xFFFFD700);

LinearGradient iconGradient = LinearGradient(
  // colors: [Colors.green, Colors.purple],
  colors: [iconGreen, iconPurple],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.4, 0.9],
);

LinearGradient iconGradientLight = LinearGradient(
  // colors: [Colors.green, Colors.purple],
  colors: [Color(0xFFA5D6A7), Color(0xFFB39DDB)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.4, 0.9],
);
