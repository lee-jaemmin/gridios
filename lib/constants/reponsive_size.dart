import 'package:flutter/material.dart';

class ResponsiveSizes {
  static double width(BuildContext context, double ratio) =>
      MediaQuery.of(context).size.width * ratio;

  static double height(BuildContext context, double ratio) =>
      MediaQuery.of(context).size.height * ratio;

  // p for padding
  static double p(BuildContext context, double size) =>
      width(context, size / 400);

  // f for font size
  static double f(BuildContext context, double size) =>
      width(context, size / 400);
}
