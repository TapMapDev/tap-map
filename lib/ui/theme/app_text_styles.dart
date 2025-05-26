import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Все типографические константы приложения.
/// Названия очевидные: h18 / body16 / caption14 и т. д.
class AppTextStyles {
  // названия шрифтов
  static const _sf      = 'SF Pro Display';
  static const _inter   = 'Inter';
  static const _poppins = 'Poppins';

  // ────────── Заголовки ──────────
  static const h24 = TextStyle(
    color: AppColors.dark,
    fontSize: 24,
    fontFamily: _poppins,
    fontWeight: FontWeight.w600,
    height: 1.10,
    letterSpacing: -1,
  );

  static const h18 = TextStyle(
    color: AppColors.dark,
    fontSize: 18,
    fontFamily: _sf,
    fontWeight: FontWeight.w600,
    height: 1.22,
    letterSpacing: -0.43,
  );

  // ────────── Основной текст ──────────
  static const body16       = TextStyle(
    color: AppColors.dark,
    fontSize: 16,
    fontFamily: _sf,
    fontWeight: FontWeight.w500,
    height: 1.25,
    letterSpacing: -0.43,
  );

  static const body16Grey   = TextStyle(
    color: AppColors.grey,
    fontSize: 16,
    fontFamily: _sf,
    fontWeight: FontWeight.w500,
    height: 1.25,
    letterSpacing: -0.43,
  );

  static const body16Green  = TextStyle(
    color: AppColors.green,
    fontSize: 16,
    fontFamily: _sf,
    fontWeight: FontWeight.w500,
    height: 1.25,
    letterSpacing: -0.43,
  );

  // ────────── Подписи / caption ──────────
  static const caption14        = TextStyle(
    color: AppColors.grey,
    fontSize: 14,
    fontFamily: _sf,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: -0.43,
  );

  static const caption14Dark    = TextStyle(
    color: AppColors.dark,
    fontSize: 14,
    fontFamily: _sf,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: -0.43,
  );

  static const caption14Primary = TextStyle(
    color: AppColors.primary,
    fontSize: 14,
    fontFamily: _sf,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: -0.43,
  );

  static const caption14Green   = TextStyle(
    color: AppColors.green,
    fontSize: 14,
    fontFamily: _sf,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: -0.43,
  );

  // ────────── Специальные ──────────
  static const ratingBig = TextStyle(
    color: AppColors.dark,
    fontSize: 48,
    fontFamily: _poppins,
    fontWeight: FontWeight.w600,
    height: 1.30,
    letterSpacing: -1,
  );

  static const badge12Green = TextStyle(
    color: AppColors.green,
    fontSize: 12,
    fontFamily: _sf,
    fontWeight: FontWeight.w500,
    height: 1.30,
    letterSpacing: -0.43,
  );

  static const statusBarTime = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontFamily: _inter,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.30,
  );
}
