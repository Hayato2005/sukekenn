// lib/application/providers/calendar_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

// カレンダーの表示形式（月/週）を管理するプロバイダ
final calendarFormatProvider =
    StateProvider<CalendarFormat>((ref) => CalendarFormat.month);

// カレンダーでフォーカスされている日を管理するプロバイダ
final focusedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());

// カレンダーで選択されている日を管理するプロバイダ
final selectedDayProvider = StateProvider<DateTime?>((ref) => DateTime.now());