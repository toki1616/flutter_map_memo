import 'package:flutter/material.dart';

class CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 外側（縁取り）となる太い黒線の設定
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // 内側となる細い白線の設定
    final innerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);

    // 背景となる黒い十字を描画
    // 横線
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), borderPaint);
    // 縦線
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), borderPaint);

    // 上から重なる白い十字を描画
    // 横線
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), innerPaint);
    // 縦線
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}