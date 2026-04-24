import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 &&
      MediaQuery.sizeOf(context).width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;

  static double chatListWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024) return 380;
    if (width >= 600) return 320;
    return width;
  }
}
