import 'package:flutter/material.dart';

class AppColor {

  static const Color green = Color(0xff008264);
  // static const Color lightGrey = Color(0xffeff2f7);
  static const Color lightGrey = Color(0xfff3f3f3);
  static const Color red = Color(0xFFEA5B5B);
  static const Color kLightNavColor = Color(0xff7383a5);
  static const Color kBlue = Color(0xff212734);
  static const Color white = Colors.white;
  static const Color grey = Colors.grey;
  static const Color black = Colors.black87;
  static const Color welcomeBgColor = Color(0xFFF5FDFF);
  
  static const Color snackGreen = Color(0xFF4CB15C);
  static const Color snackBgGreen = Color(0xFFE2F2E5);
  static const Color snackRed = Color(0xFFFF686B);
  static const Color snackBgRed = Color(0xFFFFE7E7);

} 

class AppTheme{

  static final ThemeData themeData = ThemeData(
    useMaterial3: true,
    primaryColor: AppColor.black,
    splashColor: Colors.white60,
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColor.black),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: AppColor.black, elevation: 5, foregroundColor: AppColor.white),
    ),
  );

  static const OutlineInputBorder outlineInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12.0)),
    borderSide: BorderSide(color: AppColor.kLightNavColor),
  );

  static const OutlineInputBorder focusedOutlineInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12.0)),
    borderSide: BorderSide(color: AppColor.grey),
  );

  static const OutlineInputBorder errorOutlineInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12.0)),
    borderSide: BorderSide(color: AppColor.red),
  );

}