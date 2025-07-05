// lib/presentation/widgets/calendar/week_grid_painter.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class WeekGridPainter extends CustomPainter {
  final double hourHeight;
  final double leftColumnWidth;
  final BuildContext context;

  WeekGridPainter({required this.hourHeight, required this.leftColumnWidth, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0;
    
    final dayColumnWidth = (size.width - leftColumnWidth) / 7;

    // 水平線 (時間ごと)
    for (int hour = 0; hour < 24; hour++) {
      final y = hour * hourHeight;
      canvas.drawLine(Offset(leftColumnWidth, y), Offset(size.width, y), linePaint);
    }

    // 垂直線 (曜日ごと)
    for (int day = 1; day < 7; day++) {
      final x = leftColumnWidth + day * dayColumnWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    
    // 時間ラベル
    for (int hour = 1; hour < 24; hour++) {
        final y = hour * hourHeight;
        final textPainter = TextPainter(
          text: TextSpan(
            text: DateFormat('H').format(DateTime(2000, 1, 1, hour)),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(leftColumnWidth - textPainter.width - 4, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}