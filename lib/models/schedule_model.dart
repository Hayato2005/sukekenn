// lib/models/schedule_model.dart

import 'package:flutter/material.dart';

class Schedule {
  final String id;
  final String title;
  final DateTime date;
  final double startHour;
  final double endHour;
  final Color color;

  // --- 仕様書に基づき追加したフィールド ---
  final String? description;
  final String? scheduleType; // "空き日程" or "固定予定"
  final String? matchingType; // "誰でも", "異性", "フレンド"
  final String? location; // 場所
  final List<String>? participants; // 参加者のIDリストなど

  Schedule({
    required this.id,
    required this.title,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.color,
    // --- 追加フィールドをコンストラクタに追加 ---
    this.description,
    this.scheduleType,
    this.matchingType,
    this.location,
    this.participants,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'startHour': startHour,
    'endHour': endHour,
    'color': color.value,
    // --- 追加フィールドをJSONに変換 ---
    'description': description,
    'scheduleType': scheduleType,
    'matchingType': matchingType,
    'location': location,
    'participants': participants,
  };

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
    id: json['id'] as String,
    title: json['title'] as String,
    date: DateTime.parse(json['date'] as String),
    startHour: (json['startHour'] as num).toDouble(),
    endHour: (json['endHour'] as num).toDouble(),
    color: Color(json['color'] as int),
    // --- JSONから追加フィールドを読み込み ---
    description: json['description'] as String?,
    scheduleType: json['scheduleType'] as String?,
    matchingType: json['matchingType'] as String?,
    location: json['location'] as String?,
    participants: json['participants'] != null ? List<String>.from(json['participants']) : null,
  );

  /// UI表示用にMapへ変換
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'date': date,
    'startHour': startHour,
    'endHour': endHour,
    'color': color,
    'description': description,
    'scheduleType': scheduleType,
    'matchingType': matchingType,
    'location': location,
    'participants': participants,
  };

  /// 空のスケジュールを返す
  factory Schedule.empty() => Schedule(
    id: '',
    title: '',
    date: DateTime.now(),
    startHour: 0,
    endHour: 0,
    color: Colors.transparent,
    description: '',
    scheduleType: '固定予定',
    matchingType: 'フレンド',
    location: '',
    participants: [],
  );
}