// lib/week_view_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeekCalendarView extends StatefulWidget {
  final PageController pageController;
  final Function(int) onPageChanged;
  final DateTime focusedDate;
  final bool isSelectionMode;
  final List<Map<String, dynamic>> selectedSchedules;
  final Function(Map<String, dynamic>) onScheduleSelectionChanged;


  const WeekCalendarView({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    required this.focusedDate,
    required this.isSelectionMode,
    required this.selectedSchedules,
    required this.onScheduleSelectionChanged,
  });

  @override
  State<WeekCalendarView> createState() => _WeekCalendarViewState();
}

class _WeekCalendarViewState extends State<WeekCalendarView> {

  final List<Map<String, dynamic>> schedules = [
      {'date': DateTime.now(), 'title': 'ミーティング', 'color': Colors.blue, 'start_time': '10:00', 'end_time': '11:00'},
      {'date': DateTime.now().add(const Duration(days: 1)), 'title': 'ランチ', 'color': Colors.green, 'start_time': '12:00', 'end_time': '13:00'},
  ];

  @override
  Widget build(BuildContext context) {
    // ScaffoldやAppBarは削除
    return Column(
      children: [
        buildWeekDayBar(widget.focusedDate),
        Expanded(
          child: PageView.builder(
            controller: widget.pageController,
            onPageChanged: widget.onPageChanged,
            itemBuilder: (context, pageIndex) {
               final startOfWeek = widget.focusedDate.subtract(Duration(days: widget.focusedDate.weekday % 7));
               final currentWeekStart = startOfWeek.add(Duration(days: (pageIndex - widget.pageController.initialPage) * 7));
              return buildSingleWeekView(currentWeekStart);
            },
          ),
        ),
      ],
    );
  }

  Widget buildWeekDayBar(DateTime dateInWeek) {
    final startOfWeek = dateInWeek.subtract(Duration(days: dateInWeek.weekday % 7));
    final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
    final formatter = DateFormat('d\nE', 'ja');

    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const SizedBox(width: 40), // タイムライン用の余白
          ...weekDays.map((day) {
            final isToday = DateUtils.isSameDay(day, DateTime.now());
            Color textColor = Colors.black;
            if (day.weekday == DateTime.sunday) textColor = Colors.red;
            if (day.weekday == DateTime.saturday) textColor = Colors.blue;

            return Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isToday ? Colors.yellow[200] : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    formatter.format(day),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor, fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget buildSingleWeekView(DateTime startOfWeek) {
    // タイムラインと予定を重ねて表示するためにStackを使用
    return SingleChildScrollView(
      child: Stack(
        children: [
          // タイムラインの背景グリッド
          buildTimeGrid(),
          // 予定の表示
          buildScheduleLayout(startOfWeek),
        ],
      ),
    );
  }
  
  Widget buildTimeGrid() {
    return Column(
      children: List.generate(24, (index) {
        return Row(
          children: [
            SizedBox(
              width: 40,
              height: 60, // 1時間あたりの高さ
              child: Center(child: Text('${index.toString().padLeft(2, '0')}:00')),
            ),
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget buildScheduleLayout(DateTime startOfWeek) {
    List<Widget> positionedSchedules = [];
    final weekSchedules = schedules.where((s) {
      final sDate = s['date'] as DateTime;
      return sDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) && sDate.isBefore(startOfWeek.add(const Duration(days: 7)));
    }).toList();

    for (var schedule in weekSchedules) {
        final date = schedule['date'] as DateTime;
        final dayIndex = date.weekday % 7;
        final hour = int.parse(schedule['start_time'].split(':')[0]);
        final minute = int.parse(schedule['start_time'].split(':')[1]);
        
        final top = (hour * 60.0) + minute; // 1時間60pxとして計算
        final left = 40.0 + (MediaQuery.of(context).size.width - 40) / 7 * dayIndex;
        final width = (MediaQuery.of(context).size.width - 40) / 7;

        final isSelected = widget.selectedSchedules.contains(schedule);

        positionedSchedules.add(
          Positioned(
            top: top,
            left: left,
            width: width - 2, // 左右の余白
            child: GestureDetector(
              onTap: () {
                if (widget.isSelectionMode) {
                  widget.onScheduleSelectionChanged(schedule);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: (schedule['color'] as Color).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                  border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                ),
                child: Text(
                  schedule['title'],
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          )
        );
    }
    
    return SizedBox(
      height: 24 * 60.0, // 24時間分の高さ
      child: Stack(children: positionedSchedules),
    );
  }
}