import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';

class WeekCalendarView extends StatefulWidget {
  final PageController pageController;
  final Function(int) onPageChanged;
  final DateTime focusedDate;
  final List<Schedule> schedules;

  const WeekCalendarView({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    required this.focusedDate,
    required this.schedules,
  });

  @override
  State<WeekCalendarView> createState() => _WeekCalendarViewState();
}

class _WeekCalendarViewState extends State<WeekCalendarView> {
  final ScrollController _scrollController = ScrollController();
  double _scale = 1.0;
  double _baseScale = 1.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        _baseScale = _scale;
      },
      onScaleUpdate: (details) {
        if ((details.focalPointDelta.dy).abs() > (details.focalPointDelta.dx).abs()) {
          setState(() {
            _scale = (_baseScale * details.scale).clamp(0.5, 4.0);
          });
        }
      },
      child: Column(
        children: [
          _buildWeekDayHeader(widget.focusedDate),
          Expanded(
            child: PageView.builder(
              controller: widget.pageController,
              onPageChanged: widget.onPageChanged,
              itemBuilder: (context, index) {
                final weekOffset = index - 5000;
                final baseDate = widget.focusedDate.add(Duration(days: weekOffset * 7));
                final startOfWeek = baseDate.subtract(Duration(days: baseDate.weekday - 1)); // 月曜日始まり
                return _buildWeekGrid(startOfWeek);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDayHeader(DateTime dateInWeek) {
    final startOfWeek = dateInWeek.subtract(Duration(days: dateInWeek.weekday - 1));
    final formatter = DateFormat('d\nE', 'ja');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 50),
          ...List.generate(7, (i) {
            final day = startOfWeek.add(Duration(days: i));
            final isToday = DateUtils.isSameDay(day, DateTime.now());
            return Expanded(
              child: Column(
                children: [
                  Text(
                    formatter.format(day).split('\n')[1],
                    style: TextStyle(
                      fontSize: 12,
                      color: day.weekday == DateTime.sunday
                          ? Colors.red
                          : (day.weekday == DateTime.saturday ? Colors.blue : Colors.black),
                    ),
                  ),
                  const SizedBox(height: 4),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isToday ? Colors.blue : Colors.transparent,
                    child: Text(
                      formatter.format(day).split('\n')[0],
                      style: TextStyle(
                        fontSize: 14,
                        color: isToday
                            ? Colors.white
                            : (day.weekday == DateTime.sunday
                                ? Colors.red
                                : (day.weekday == DateTime.saturday ? Colors.blue : Colors.black)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeekGrid(DateTime startOfWeek) {
    const hourHeight = 60.0;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Stack(
        children: [
          _buildGridWithTime(hourHeight),
          ..._buildSchedules(hourHeight, startOfWeek),
        ],
      ),
    );
  }

  Widget _buildGridWithTime(double hourHeight) {
    return Column(
      children: List.generate(24, (hour) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 50,
              height: hourHeight * _scale,
              child: hour > 0
                  ? Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          '$hour:00',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: SizedBox(
                height: hourHeight * _scale,
                child: Row(
                  children: List.generate(7, (day) {
                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!),
                            left: day > 0 ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  List<Widget> _buildSchedules(double hourHeight, DateTime startOfWeek) {
    const double scheduleFontSize = 16.0;
    List<Widget> widgets = [];

    for (var schedule in widget.schedules) {
      final sDate = DateUtils.dateOnly(schedule.date);
      final dayIndex = sDate.difference(startOfWeek).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        final double top = schedule.startHour * hourHeight * _scale;
        final double height = (schedule.endHour - schedule.startHour) * hourHeight * _scale;
        widgets.add(Positioned(
          top: top,
          left: 50 + dayIndex * ((MediaQuery.of(context).size.width - 50) / 7),
          width: (MediaQuery.of(context).size.width - 50) / 7,
          height: height,
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: schedule.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Text(
                schedule.title,
                style: TextStyle(
                  fontSize: scheduleFontSize,
                  color: schedule.color.computeLuminance() < 0.5 ? Colors.white : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ));
      }
    }
    return widgets;
  }
}
