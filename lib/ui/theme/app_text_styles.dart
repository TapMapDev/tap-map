import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const _sf      = 'SF Pro Display';
  static const _poppins = 'Poppins';
  static const _inter   = 'Inter';

  // ---------- заголовки ----------
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

  // ---------- основной текст ----------
  static const body16      = _body16(AppColors.dark);
  static const body16Grey  = _body16(AppColors.grey);
  static const body16Green = _body16(AppColors.green);

  // ---------- подписи / caption ----------
  static const caption14      = _caption14(AppColors.grey);
  static const caption14Dark  = _caption14(AppColors.dark);
  static const caption14Prim  = _caption14(AppColors.primary);
  static const caption14Green = _caption14(AppColors.green);

  // ---------- специальные ----------
  static const ratingBig = TextStyle(
    color: AppColors.dark,
    fontSize: 48,
    fontFamily: _poppins,
    fontWeight: FontWeight.w600,
    height: 1.30,
    letterSpacing: -1,
  );

  static const badgeNumber = TextStyle(
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

  // ---------- приватные шаблоны ----------
  static TextStyle _body16(Color c) => TextStyle(
    color: c,
    fontSize: 16,
    fontFamily: _sf,
    fontWeight: FontWeight.w500,
    height: 1.25,
    letterSpacing: -0.43,
  );

  static TextStyle _caption14(Color c) => TextStyle(
    color: c,
    fontSize: 14,
    fontFamily: _sf,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: -0.43,
  );
}
