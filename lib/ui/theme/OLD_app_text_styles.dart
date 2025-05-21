import 'package:flutter/material.dart';

class StyleManager {
  static final StyleManager _instance = StyleManager._internal();

  StyleManager._internal();

  factory StyleManager() {
    return _instance;
  }

  static const Color bgColor = Color(0xFFFFFFFF);
  static const Color mainColor = Color.fromARGB(255, 44, 156, 212);
  static const Color blocColor = Color(0xFFF6F5F8);
  static const Color blackColor = Color(0xFF1D1D1D);
  static const Color grayColor = Color(0xFFC5C5CE);
}

class TextStylesManager {
  static final TextStylesManager _instance = TextStylesManager._internal();
  TextStylesManager._internal();
  factory TextStylesManager() {
    return _instance;
  }
  //основные цвета
  static TextStyle headerMain = const TextStyle(
      fontFamily: 'regular',
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: StyleManager.blackColor);
  static TextStyle standartMain = const TextStyle(
      height: 1.25,
      fontFamily: 'regular',
      fontWeight: FontWeight.w500,
      fontSize: 16,
      color: StyleManager.blackColor);
  static TextStyle descriptionMain = const TextStyle(
      fontFamily: 'regular',
      fontWeight: FontWeight.w300,
      fontSize: 14,
      color: StyleManager.blackColor);
  static TextStyle smallnMain = const TextStyle(
      fontFamily: 'regular',
      fontWeight: FontWeight.w300,
      fontSize: 12,
      color: StyleManager.blackColor);
  static TextStyle drawerText = const TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: StyleManager.blackColor,
    height: 20 / 16,
  );
}
