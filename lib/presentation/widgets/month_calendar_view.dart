import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthCalendarView extends StatelessWidget {
  final PageController pageController;
  final Function(int) onPageChanged;
  final Function(DateTime) onDateDoubleTapped;
  final bool isSelectionMode;
  final List<Map<String, dynamic>> selectedSchedules;
  final Function(Map<String, dynamic>) onSelectionChanged;
  final List<Map<String, dynamic>> schedules;

  const MonthCalendarView({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    required this.onDateDoubleTapped,
    required this.isSelectionMode,
    required this.selectedSchedules,
    required this.onSelectionChanged,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWeekBar(),
        Expanded(
          child: PageView.builder(
            scrollDirection: Axis.vertical,
            controller: pageController,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final monthOffset = index - 5000;
              final month = DateTime(DateTime.now().year, DateTime.now().month + monthOffset);
              return _buildMonthGrid(context, month);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekBar() {
    return Container(
      height: 30, color: Colors.grey[100],
      child: Row(
        children: List.generate(7, (index) {
          const weekDays = ['日', '月', '火', '水', '木', '金', '土'];
          return Expanded(child: Center(child: Text(weekDays[index], style: const TextStyle(fontWeight: FontWeight.bold))));
        }),
      ),
    );
  }

  Widget _buildMonthGrid(BuildContext context, DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final totalCells = ((firstWeekday + daysInMonth) / 7).ceil() * 7;

    return Column(
      children: List.generate(totalCells ~/ 7, (row) {
        return Expanded(
          child: Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - firstWeekday + 1;
              DateTime date;
              bool isCurrentMonth = true;

              if (dayNum < 1) {
                final prevMonth = DateTime(month.year, month.month, 0);
                date = DateTime(prevMonth.year, prevMonth.month, prevMonth.day + dayNum);
                isCurrentMonth = false;
              } else if (dayNum > daysInMonth) {
                date = DateTime(month.year, month.month + 1, dayNum - daysInMonth);
                isCurrentMonth = false;
              } else {
                date = DateTime(month.year, month.month, dayNum);
              }

              final daySchedules = schedules.where((s) {
                final sDate = DateUtils.dateOnly(s['date'] as DateTime);
                return DateUtils.isSameDay(sDate, date);
              }).toList();

              return Expanded(
                child: GestureDetector(
                  onLongPress: isCurrentMonth ? () => _showDayTimeline(context, date, daySchedules) : null,
                  onDoubleTap: isCurrentMonth ? () => onDateDoubleTapped(date) : null,
                  child: _buildDateCell(date, daySchedules, isCurrentMonth),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDateCell(DateTime date, List<Map<String, dynamic>> schedules, bool isCurrentMonth) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    return Container(
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isToday ? Colors.red[100] : null,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${date.day}',
            style: TextStyle(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isCurrentMonth ? (isToday ? Colors.red : Colors.black) : Colors.grey,
            ),
          ),
          ..._buildScheduleItems(schedules),
        ],
      ),
    );
  }

  List<Widget> _buildScheduleItems(List<Map<String, dynamic>> schedules) {
    const double scheduleFontSize = 16; // ★予定タイトルの共通文字サイズ

    List<Widget> items = schedules.map((schedule) {
      final bool isSelected = selectedSchedules.any((s) => s['id'] == schedule['id']);
      final bgColor = schedule['color'] as Color;
      final textColor = bgColor.computeLuminance() < 0.5 ? Colors.white : Colors.black;

      return GestureDetector(
        onTap: isSelectionMode ? () => onSelectionChanged(schedule) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(2),
            border: isSelected ? Border.all(color: Colors.blueAccent, width: 2) : null,
          ),
          child: Text(schedule['title'], style: TextStyle(fontSize: scheduleFontSize, color: textColor), overflow: TextOverflow.ellipsis),
        ),
      );
    }).toList();

    if (items.length > 2) {
      return [...items.take(2), Text('+${items.length - 2}件', style: const TextStyle(fontSize: 9, color: Colors.grey))];
    }
    return items;
  }

  void _showDayTimeline(BuildContext context, DateTime date, List<Map<String, dynamic>> schedules) {
    final double initialHourHeight = 28.75;
    ValueNotifier<double> scaleNotifier = ValueNotifier(1.0);

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: Text('${DateFormat('M月d日').format(date)}の予定'),
            contentPadding: const EdgeInsets.all(0),
            content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.6,
                child: ValueListenableBuilder<double>(
                    valueListenable: scaleNotifier,
                    builder: (context, scale, _) {
                        return GestureDetector(
                            onScaleUpdate: (details) {
                                double newScale = (scale * details.scale).clamp(0.5, 4.0);
                                scaleNotifier.value = newScale;
                            },
                            child: SingleChildScrollView(
                                child: SizedBox(
                                    height: 25 * initialHourHeight * scale,
                                    child: Stack(
                                        children: [
                                            ...List.generate(
                                                25,
                                                (hour) => Positioned(
                                                    top: hour * initialHourHeight * scale,
                                                    left: 0,
                                                    right: 0,
                                                    child: Row(
                                                        children: [
                                                            SizedBox(width: 50, child: Text('${hour.toString().padLeft(2, '0')}:00', style: TextStyle(fontSize: 12 / scale, color: Colors.grey))),
                                                            Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
                                                        ],
                                                    ),
                                                )),
                                            ...schedules.map((s) => Positioned(
                                                top: s['startHour'] * initialHourHeight * scale,
                                                left: 50,
                                                right: 0,
                                                height: (s['endHour'] - s['startHour']) * initialHourHeight * scale,
                                                child: Container(
                                                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                    decoration: BoxDecoration(color: s['color'], borderRadius: BorderRadius.circular(4)),
                                                    padding: const EdgeInsets.all(4),
                                                    child: Text('${s['title']} (ユーザー)',
                                                        style: TextStyle(
                                                            color: (s['color'] as Color).computeLuminance() < 0.5 ? Colors.white : Colors.black,
                                                            fontSize: 10 / scale),
                                                        overflow: TextOverflow.ellipsis),
                                                ),
                                            )),
                                        ],
                                    ),
                                ),
                            ),
                        );
                    },
                ),
            ),
            actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                ),
            ],
        ),
    );
  }
}
