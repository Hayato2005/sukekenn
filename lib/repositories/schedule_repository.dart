import 'package:flutter/material.dart';
import 'package:sukekenn/models/schedule_model.dart';

class ScheduleRepository {
  static final ScheduleRepository _instance = ScheduleRepository._internal();
  final Map<DateTime, List<Schedule>> _scheduleMap = {};

  factory ScheduleRepository() {
    return _instance;
  }

  ScheduleRepository._internal();

  void addSchedule(Schedule schedule) {
    final dateKey = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
    _scheduleMap.putIfAbsent(dateKey, () => []);
    _scheduleMap[dateKey]!.add(schedule);
  }

  void updateSchedule(Schedule updated) {
    removeSchedule(updated.id);
    addSchedule(updated);
  }

  void removeSchedule(String scheduleId) {
    _scheduleMap.forEach((date, schedules) {
      schedules.removeWhere((s) => s.id == scheduleId);
    });
  }

  List<Schedule> getSchedulesForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return _scheduleMap[dateKey] ?? [];
  }

  /// 例: 月表示用に1ヶ月分をまとめて取得
  List<Schedule> getSchedulesForMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    return _scheduleMap.entries
        .where((entry) => entry.key.isAfter(start.subtract(const Duration(days: 1))) && entry.key.isBefore(end.add(const Duration(days: 1))))
        .expand((entry) => entry.value)
        .toList();
  }

  /// 例: 週表示用に1週間分をまとめて取得
  List<Schedule> getSchedulesForWeek(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return _scheduleMap.entries
        .where((entry) => entry.key.isAfter(startOfWeek.subtract(const Duration(days: 1))) && entry.key.isBefore(endOfWeek.add(const Duration(days: 1))))
        .expand((entry) => entry.value)
        .toList();
  }

  /// 2年分など広範囲の読み込みにも対応できるよう拡張想定
  List<Schedule> getSchedulesForRange(DateTime start, DateTime end) {
    return _scheduleMap.entries
        .where((entry) => entry.key.isAfter(start.subtract(const Duration(days: 1))) && entry.key.isBefore(end.add(const Duration(days: 1))))
        .expand((entry) => entry.value)
        .toList();
  }
}
