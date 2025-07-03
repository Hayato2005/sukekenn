import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

  List<Schedule> getSchedulesForMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    return _scheduleMap.entries
        .where((entry) => entry.key.isAfter(start.subtract(const Duration(days: 1))) && entry.key.isBefore(end.add(const Duration(days: 1))))
        .expand((entry) => entry.value)
        .toList();
  }

  List<Schedule> getSchedulesForWeek(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return _scheduleMap.entries
        .where((entry) => entry.key.isAfter(startOfWeek.subtract(const Duration(days: 1))) && entry.key.isBefore(endOfWeek.add(const Duration(days: 1))))
        .expand((entry) => entry.value)
        .toList();
  }

  List<Schedule> getSchedulesForRange(DateTime start, DateTime end) {
    return _scheduleMap.entries
        .where((entry) => entry.key.isAfter(start.subtract(const Duration(days: 1))) && entry.key.isBefore(end.add(const Duration(days: 1))))
        .expand((entry) => entry.value)
        .toList();
  }

  Future<void> saveSchedules(List<Schedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final schedulesJson = jsonEncode(schedules.map((s) => s.toJson()).toList());
    await prefs.setString('schedules', schedulesJson);
  }

  Future<List<Schedule>> loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final schedulesJson = prefs.getString('schedules');
    final List<Schedule> loadedSchedules = [];
    if (schedulesJson != null) {
      final decoded = jsonDecode(schedulesJson) as List<dynamic>;
      for (final scheduleMap in decoded) {
        final schedule = Schedule.fromJson(scheduleMap as Map<String, dynamic>);
        addSchedule(schedule);
        loadedSchedules.add(schedule);
      }
    }
    return loadedSchedules;
  }
}
