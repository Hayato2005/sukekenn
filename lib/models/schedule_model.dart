import 'package:flutter/material.dart';

class Schedule {
  final String id;
  final String title;
  final DateTime date;
  final double startHour;
  final double endHour;
  final Color color;

  Schedule({
    required this.id,
    required this.title,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'startHour': startHour,
        'endHour': endHour,
        'color': color.value,
      };

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
        id: json['id'] as String,
        title: json['title'] as String,
        date: DateTime.parse(json['date'] as String),
        startHour: (json['startHour'] as num).toDouble(),
        endHour: (json['endHour'] as num).toDouble(),
        color: Color(json['color'] as int),
      );

  /// UI表示用にMapへ変換
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'date': date,
        'startHour': startHour,
        'endHour': endHour,
        'color': color,
      };

  /// 空のスケジュールを返す
  factory Schedule.empty() => Schedule(
        id: '',
        title: '',
        date: DateTime.now(),
        startHour: 0,
        endHour: 0,
        color: Colors.transparent,
      );
}
