// lib/calendar_home_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';

// データを親から受け取るようにするため、StatefulWidgetのままとする
class MonthCalendarView extends StatefulWidget {
  final PageController pageController;
  final Function(int) onPageChanged;
  final bool isSelectionMode;
  final List<Map<String, dynamic>> selectedSchedules;
  final Function(Map<String, dynamic>) onScheduleSelectionChanged;

  const MonthCalendarView({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    required this.isSelectionMode,
    required this.selectedSchedules,
    required this.onScheduleSelectionChanged,
  });

  @override
  State<MonthCalendarView> createState() => _MonthCalendarViewState();
}

class _MonthCalendarViewState extends State<MonthCalendarView> {
  // ダミーのスケジュールデータ。実際には外部から取得したデータを使用します。
  final List<Map<String, dynamic>> schedules = [
    {'date': DateTime.now(), 'title': 'ミーティング', 'color': Colors.blue},
    {'date': DateTime.now().add(const Duration(days: 1)), 'title': 'ランチ', 'color': Colors.green},
    {'date': DateTime.now().add(const Duration(days: 1)), 'title': 'デザインレビュー', 'color': Colors.orange},
  ];

  @override
  Widget build(BuildContext context) {
    // ScaffoldとAppBarは削除し、カレンダーの本体部分のみを返す
    return Column(
      children: [
        buildWeekBar(),
        Expanded(
          child: PageView.builder(
            controller: widget.pageController,
            onPageChanged: widget.onPageChanged,
            itemBuilder: (context, index) {
              final year = 1970 + index ~/ 12;
              final month = 1 + index % 12;
              final monthDate = DateTime(year, month);
              return buildMonthView(monthDate);
            },
          ),
        ),
      ],
    );
  }

  Widget buildWeekBar() {
    final weekDays = ['日', '月', '火', '水', '木', '金', '土'];
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: weekDays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  color: day == '日' ? Colors.red : (day == '土' ? Colors.blue : Colors.black),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildMonthView(DateTime month) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final weekdayOfFirstDay = firstDayOfMonth.weekday % 7;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.7,
      ),
      itemCount: daysInMonth + weekdayOfFirstDay,
      itemBuilder: (context, index) {
        if (index < weekdayOfFirstDay) {
          return Container(); // 月の開始日より前の空のセル
        }
        final day = index - weekdayOfFirstDay + 1;
        final date = DateTime(month.year, month.month, day);
        final isToday = DateUtils.isSameDay(date, DateTime.now());
        final isSunday = date.weekday == DateTime.sunday;
        final isSaturday = date.weekday == DateTime.saturday;

        final daySchedules = schedules.where((s) => DateUtils.isSameDay(s['date'], date)).toList();

        return GestureDetector(
          onTap: () {
            // 日付タップ時の処理
          },
          onLongPress: () {
            // タイムライン表示などの処理
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
                right: BorderSide(color: Colors.grey[300]!),
              ),
              color: isToday ? Colors.yellow[100] : null,
            ),
            child: Column(
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSunday ? Colors.red : (isSaturday ? Colors.blue : Colors.black),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: daySchedules.length,
                    itemBuilder: (context, sIndex) {
                      final schedule = daySchedules[sIndex];
                      final isSelected = widget.selectedSchedules.contains(schedule);
                      return GestureDetector(
                        onTap: () {
                          if (widget.isSelectionMode) {
                            widget.onScheduleSelectionChanged(schedule);
                          } else {
                            // 予定詳細表示など
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: schedule['color'].withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                          ),
                          child: Text(
                            schedule['title'],
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}