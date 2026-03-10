import 'package:flutter/material.dart';

class Gaps {
  static Widget v(BuildContext context, double ratio) =>
      SizedBox(height: MediaQuery.of(context).size.height * ratio);
  static Widget h(BuildContext context, double ratio) =>
      SizedBox(width: MediaQuery.of(context).size.width * ratio);

  static Widget v1(BuildContext context) => v(context, 0.00125);
  static Widget v2(BuildContext context) => v(context, 0.0025);
  static Widget v3(BuildContext context) => v(context, 0.00375);
  static Widget v4(BuildContext context) => v(context, 0.005);
  static Widget v5(BuildContext context) => v(context, 0.00625);
  static Widget v6(BuildContext context) => v(context, 0.0075);
  static Widget v7(BuildContext context) => v(context, 0.00875);
  static Widget v8(BuildContext context) => v(context, 0.01);
  static Widget v9(BuildContext context) => v(context, 0.01125);
  static Widget v10(BuildContext context) => v(context, 0.0125);
  static Widget v11(BuildContext context) => v(context, 0.01375);
  static Widget v12(BuildContext context) => v(context, 0.015);
  static Widget v14(BuildContext context) => v(context, 0.0175);
  static Widget v16(BuildContext context) => v(context, 0.02);
  static Widget v20(BuildContext context) => v(context, 0.025);
  static Widget v24(BuildContext context) => v(context, 0.03);
  static Widget v28(BuildContext context) => v(context, 0.035);
  static Widget v32(BuildContext context) => v(context, 0.04);
  static Widget v36(BuildContext context) => v(context, 0.045);
  static Widget v40(BuildContext context) => v(context, 0.05);
  static Widget v44(BuildContext context) => v(context, 0.055);
  static Widget v48(BuildContext context) => v(context, 0.06);
  static Widget v52(BuildContext context) => v(context, 0.065);
  static Widget v56(BuildContext context) => v(context, 0.07);
  static Widget v60(BuildContext context) => v(context, 0.075);
  static Widget v64(BuildContext context) => v(context, 0.08);
  static Widget v72(BuildContext context) => v(context, 0.09);
  static Widget v80(BuildContext context) => v(context, 0.1);
  static Widget v96(BuildContext context) => v(context, 0.12);

  static Widget h1(BuildContext context) => h(context, 0.0025);
  static Widget h2(BuildContext context) => h(context, 0.005);
  static Widget h3(BuildContext context) => h(context, 0.0075);
  static Widget h4(BuildContext context) => h(context, 0.01);
  static Widget h5(BuildContext context) => h(context, 0.0125);
  static Widget h6(BuildContext context) => h(context, 0.015);
  static Widget h7(BuildContext context) => h(context, 0.0175);
  static Widget h8(BuildContext context) => h(context, 0.02);
  static Widget h9(BuildContext context) => h(context, 0.0225);
  static Widget h10(BuildContext context) => h(context, 0.025);
  static Widget h11(BuildContext context) => h(context, 0.0275);
  static Widget h12(BuildContext context) => h(context, 0.03);
  static Widget h14(BuildContext context) => h(context, 0.035);
  static Widget h16(BuildContext context) => h(context, 0.04);
  static Widget h20(BuildContext context) => h(context, 0.05);
  static Widget h24(BuildContext context) => h(context, 0.06);
  static Widget h28(BuildContext context) => h(context, 0.07);
  static Widget h32(BuildContext context) => h(context, 0.08);
  static Widget h36(BuildContext context) => h(context, 0.09);
  static Widget h40(BuildContext context) => h(context, 0.1);
  static Widget h44(BuildContext context) => h(context, 0.11);
  static Widget h48(BuildContext context) => h(context, 0.12);
  static Widget h52(BuildContext context) => h(context, 0.13);
  static Widget h56(BuildContext context) => h(context, 0.14);
  static Widget h60(BuildContext context) => h(context, 0.15);
  static Widget h64(BuildContext context) => h(context, 0.16);
  static Widget h72(BuildContext context) => h(context, 0.18);
  static Widget h80(BuildContext context) => h(context, 0.2);
  static Widget h96(BuildContext context) => h(context, 0.24);
}
