import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const card = [
    BoxShadow(
      color: Color.fromRGBO(65, 45, 33, 0.10),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static const soft = [
    BoxShadow(
      color: Color.fromRGBO(32, 20, 51, 0.05),
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ];

  static const floating = [
    BoxShadow(
      color: Color.fromRGBO(32, 20, 51, 0.12),
      blurRadius: 28,
      offset: Offset(0, 14),
    ),
  ];
}
