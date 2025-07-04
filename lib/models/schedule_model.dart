// lib/models/schedule_model.dart

import 'package:flutter/material.dart';

class Schedule {
  final String id;
  final String title;
  final DateTime date;
  final double startHour;
  final double endHour;
  final Color color;
  final bool isAllDay;

  final String? description;
  final String? scheduleType;
  final String? matchingType;
  final String? location;
  final List<String>? participants;

  Schedule({
    required this.id,
    required this.title,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.color,
    this.isAllDay = false,
    this.description,
    this.scheduleType,
    this.matchingType,
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
    String? scheduleType,
    String? matchingType,
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
    isAllDay: json['isAllDay'] as bool? ?? false,
    description: json['description'] as String?,
    scheduleType: json['scheduleType'] as String?,
    matchingType: json['matchingType'] as String?,
    location: json['location'] as String?,
    participants: json['participants'] != null ? List<String>.from(json['participants']) : null,
  );

  factory Schedule.empty() => Schedule(
    id: '',
    title: '',
    date: DateTime.now(),
    startHour: 0,
    endHour: 0,
    color: Colors.transparent,
  );
}