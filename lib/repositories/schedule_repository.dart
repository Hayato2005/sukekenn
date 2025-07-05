// lib/repositories/schedule_repository.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukekenn/models/schedule_model.dart';

class ScheduleRepository {
  Map<String, Schedule> _scheduleMap = {};

  // ★★★★★ エラー修正箇所 ★★★★★
  // calendar_view_screen.dart から呼び出せるように、このメソッドを追加
  Map<String, Schedule> getAllSchedules() {
    return _scheduleMap;
  }

  List<Schedule> getSchedulesForMonth(DateTime month) {
    return _scheduleMap.values.where((schedule) {
      return schedule.date.year == month.year && schedule.date.month == month.month;
    }).toList();
  }

  List<Schedule> getSchedulesForWeek(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return _scheduleMap.values.where((schedule) {
      return schedule.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
             schedule.date.isBefore(endOfWeek);
    }).toList();
  }

  List<Schedule> getSchedulesForRange(DateTime start, DateTime end) {
    return _scheduleMap.values.where((schedule) {
      return schedule.date.isAfter(start.subtract(const Duration(days: 1))) &&
             schedule.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  void addSchedule(Schedule schedule) {
    _scheduleMap[schedule.id] = schedule;
  }

  void updateSchedule(Schedule schedule) {
    if (_scheduleMap.containsKey(schedule.id)) {
      _scheduleMap[schedule.id] = schedule;
    }
  }

  void removeSchedule(String scheduleId) {
    _scheduleMap.remove(scheduleId);
  }

  Future<void> loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final String? schedulesJson = prefs.getString('schedules');
    if (schedulesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(schedulesJson);
        _scheduleMap = {
          for (var item in decoded)
            // Schedule.fromJson で null チェックが強化されたので、読み込みも安定する
            (item['id'] as String): Schedule.fromJson(item as Map<String, dynamic>)
        };
      } catch (e) {
        // JSONの解析に失敗した場合は、データをクリアするなどのフォールバック処理
        print('Failed to load schedules: $e');
        _scheduleMap = {};
      }
    }
  }

  Future<void> saveSchedules(List<Schedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    // List<Schedule> を List<Map> に変換してからJSONエンコードする
    final List<Map<String, dynamic>> schedulesToSave = schedules.map((e) => e.toJson()).toList();
    final String schedulesJson = jsonEncode(schedulesToSave);
    await prefs.setString('schedules', schedulesJson);
  }
}
