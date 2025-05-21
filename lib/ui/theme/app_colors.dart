import 'package:flutter/material.dart';

/// Единые цвета приложения.
/// Пополняйте при необходимости, но *не* задавайте здесь `TextStyle`.
class AppColors {
  // brand
  static const primary = Color(0xFF4A69FF);
  static const primary20 = Color(0x334A69FF); // 20 % прозрачности

  // нейтральные
  static const dark = Color(0xFF2F2E2D);
  static const grey = Color(0xFF828282);
  static const grey50 = Color(0x7F2F2E2D);     // 50 %
  static const grey30 = Color(0x4C2F2E2D);     // 30 %

  // акценты, использовавшиеся в макете
  static const green      = Color(0xFF015840);
  static const greenLight = Color(0xFFCBE724);
}
