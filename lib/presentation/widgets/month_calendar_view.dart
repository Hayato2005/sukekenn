import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';

class MonthCalendarView extends StatelessWidget {
  final PageController pageController;
  final Function(int) onPageChanged;
  final Function(DateTime) onDateDoubleTapped;
  final bool isSelectionMode;
  final List<Schedule> selectedSchedules;
  final Function(Schedule) onSelectionChanged;
  final List<Schedule> schedules;

  MonthCalendarView({
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
      height: 30,
      color: Colors.grey[100],
      child: Row(
        children: List.generate(7, (index) {
          const weekDays = ['日', '月', '火', '水', '木', '金', '土'];
          return Expanded(
            child: Center(
              child: Text(
                weekDays[index],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
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

              final daySchedules = schedules.where((s) => DateUtils.isSameDay(s.date, date)).toList();

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

  Widget _buildDateCell(DateTime date, List<Schedule> daySchedules, bool isCurrentMonth) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isToday ? Colors.red[100] : null,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
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
          ..._buildScheduleItems(daySchedules),
        ],
      ),
    );
  }

  List<Widget> _buildScheduleItems(List<Schedule> schedules) {
    const double scheduleFontSize = 16;

    List<Widget> items = schedules.map((schedule) {
      final bool isSelected = selectedSchedules.any((s) => s.id == schedule.id);
      final bgColor = schedule.color;
      final textColor = bgColor.computeLuminance() < 0.5 ? Colors.white : Colors.black;

      return GestureDetector(
        onTap: isSelectionMode ? () => onSelectionChanged(schedule) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(3),
            border: isSelected ? Border.all(color: Colors.blueAccent, width: 2) : null,
          ),
          child: Text(
            schedule.title,
            style: TextStyle(fontSize: scheduleFontSize, color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }).toList();

    if (items.length > 2) {
      return [
        ...items.take(2),
        Text('+${items.length - 2}件', style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ];
    }
    return items;
  }

  void _showDayTimeline(BuildContext context, DateTime date, List<Schedule> schedules) {
    final dialogWidth = MediaQuery.of(context).size.width * 0.95;
    final dialogHeight = MediaQuery.of(context).size.height * 0.7;
    const double marginTop = 12;

    final hourHeightNotifier = ValueNotifier<double>((dialogHeight - marginTop) / 24);
    final scrollController = ScrollController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${DateFormat('M月d日').format(date)}の予定'),
        content: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: ValueListenableBuilder<double>(
            valueListenable: hourHeightNotifier,
            builder: (context, hourHeight, _) {
              return GestureDetector(
                onScaleStart: (details) => _lastFocalDy = details.localFocalPoint.dy,
                onScaleUpdate: (details) {
                  if (_lastFocalDy == null) return;
                  final focalDy = _lastFocalDy!;
                  final beforeScroll = scrollController.offset;
                  final focalHour = (beforeScroll + focalDy) / hourHeight;

                  final adjustedScale = 1 + (details.scale - 1) * 0.4;
                  double newHeight = (hourHeight * adjustedScale).clamp((dialogHeight - marginTop) / 24, (dialogHeight - marginTop) / 4);
                  hourHeightNotifier.value = newHeight;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final afterScroll = focalHour * newHeight - focalDy;
                    scrollController.jumpTo(afterScroll.clamp(0, scrollController.position.maxScrollExtent));
                  });
                },
                onScaleEnd: (_) => _lastFocalDy = null,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SizedBox(
                    height: 25 * hourHeight,
                    child: Stack(
                      children: [
                        ...List.generate(25, (hour) => Positioned(
                              top: hour * hourHeight,
                              left: 0,
                              right: 0,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '${hour.toString().padLeft(2, '0')}:00',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Container(height: 1, color: Colors.grey.shade500)),
                                ],
                              ),
                            )),
                        ...schedules.map((s) {
                          final topOffset = s.startHour * hourHeight;
                          final durationHeight = ((s.endHour - s.startHour) * hourHeight).clamp(20, double.infinity);
                          return Positioned(
                            top: topOffset,
                            left: 76,
                            right: 18,
                            height: durationHeight.toDouble(),
                            child: Container(
                              decoration: BoxDecoration(
                                color: s.color,
                                borderRadius: BorderRadius.circular(7),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  s.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: s.color.computeLuminance() < 0.5 ? Colors.white : Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('閉じる'))],
      ),
    );
  }

  double? _lastFocalDy;
}

