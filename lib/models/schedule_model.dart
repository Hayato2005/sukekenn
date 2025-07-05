// lib/models/schedule_model.dart

import 'package:flutter/material.dart';

// --- Helper Functions for Backward Compatibility ---

// 古いデータ形式（日本語）と新しいデータ形式（英語のenum名）の両方を解釈する
ScheduleType _scheduleTypeFromString(String? name) {
  switch (name) {
    case 'fixed':
    case '固定予定':
      return ScheduleType.fixed;
    case 'available':
    case '空き日程':
      return ScheduleType.available;
    default:
      return ScheduleType.fixed; // 不明な場合は固定予定をデフォルトに
  }
}

MatchingType _matchingTypeFromString(String? name) {
  switch (name) {
    case 'friend':
    case 'フレンド':
      return MatchingType.friend;
    case 'anyone':
    case '誰でも':
      return MatchingType.anyone;
    case 'opposite':
    case '異性':
      return MatchingType.opposite;
    default:
      return MatchingType.friend; // 不明な場合はフレンドをデフォルトに
  }
}


// --- Enums ---

enum ScheduleType {
  fixed,
  available,
}

enum MatchingType {
  friend('フレンド'),
  anyone('誰でも'),
  opposite('異性');

  const MatchingType(this.displayName);
  final String displayName;
}


// --- Main Schedule Class ---

class Schedule {
  final String id;
  final String title;
  final DateTime date;
  final double startHour;
  final double endHour;
  final Color color;
  final bool isAllDay;
  final String? description;
  final ScheduleType scheduleType;
  final MatchingType matchingType;
  final String? location;
  final List<String>? participants;
  final bool isPublic;


  Schedule({
    required this.id,
    required this.title,
    required this.date,
    required this.startHour,
    required this.endHour,
    this.color = Colors.blue,
    this.isAllDay = false,
    this.description,
    this.scheduleType = ScheduleType.fixed,
    this.matchingType = MatchingType.friend,
    this.isPublic = true,
    this.location,
    this.participants,
  });

  Schedule copyWith({
    String? id,
    String? title,
    DateTime? date,
    double? startHour,
    double? endHour,
    Color? color,
    bool? isAllDay,
    String? description,
    ScheduleType? scheduleType,
    MatchingType? matchingType,
    bool? isPublic,
    String? location,
    List<String>? participants,
  }) {
    return Schedule(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      color: color ?? this.color,
      isAllDay: isAllDay ?? this.isAllDay,
      description: description ?? this.description,
      scheduleType: scheduleType ?? this.scheduleType,
      matchingType: matchingType ?? this.matchingType,
      isPublic: isPublic ?? this.isPublic,
      location: location ?? this.location,
      participants: participants ?? this.participants,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'startHour': startHour,
    'endHour': endHour,
    'color': color.value,
    'isAllDay': isAllDay,
    'description': description,
    'scheduleType': scheduleType.name, // 保存時は新しい形式（英語のenum名）で統一
    'matchingType': matchingType.name, // 保存時は新しい形式（英語のenum名）で統一
    'isPublic': isPublic,
    'location': location,
    'participants': participants,
  };

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '(タイトルなし)',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      startHour: (json['startHour'] as num?)?.toDouble() ?? DateTime.now().hour.toDouble(),
      endHour: (json['endHour'] as num?)?.toDouble() ?? (DateTime.now().hour + 1).toDouble(),
      color: Color(json['color'] as int? ?? Colors.blue.value),
      isAllDay: json['isAllDay'] as bool? ?? false,
      description: json['description'] as String?,
      location: json['location'] as String?,
      participants: json['participants'] != null ? List<String>.from(json['participants']) : null,
      isPublic: json['isPublic'] as bool? ?? true,
      
      // ★★★★★ エラー修正箇所 ★★★★★
      // 上で定義したヘルパー関数を使って、安全に文字列からEnumへ変換する
      scheduleType: _scheduleTypeFromString(json['scheduleType'] as String?),
      matchingType: _matchingTypeFromString(json['matchingType'] as String?),
    );
  }


  factory Schedule.empty() => Schedule(
    id: '',
    title: '',
    date: DateTime.now(),
    startHour: DateTime.now().hour.toDouble(),
    endHour: (DateTime.now().hour + 1).toDouble(),
  );
}