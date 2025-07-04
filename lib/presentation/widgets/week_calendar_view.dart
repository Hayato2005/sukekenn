// lib/presentation/widgets/week_calendar_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';

class WeekCalendarView extends StatefulWidget {
  final PageController pageController;
  final Function(int) onPageChanged;
  final DateTime focusedDate;
  final List<Schedule> schedules;
  // --- 親から受け取るコールバック関数 ---
  final Function(DateTime) onGridTapped;
  final Function(Schedule) onScheduleTapped;
  final Function(Schedule) onScheduleUpdated;
  final Function(Schedule) onTemporaryScheduleUpdated;

  const WeekCalendarView({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    required this.focusedDate,
    required this.schedules,
    required this.onGridTapped,
    required this.onScheduleTapped,
    required this.onScheduleUpdated,
    required this.onTemporaryScheduleUpdated,
  });

  @override
  State<WeekCalendarView> createState() => _WeekCalendarViewState();
}

class _WeekCalendarViewState extends State<WeekCalendarView> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timeIndicatorTimer;

  // --- 状態変数 ---
  double _hourHeight = 60.0;
  double _baseHourHeightOnScaleStart = 60.0;
  Schedule? _draggingSchedule;
  Schedule? _ghostSchedule;
  bool _showZoomResetButton = false;

  final double _leftColumnWidth = 50.0;

  @override
  void initState() {
    super.initState();
    _timeIndicatorTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.mounted) return;
      final now = DateTime.now();
      final initialScrollOffset = now.hour * _hourHeight - (context.size?.height ?? 800) / 4;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(initialScrollOffset.clamp(0.0, _hourHeight * 24));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timeIndicatorTimer?.cancel();
    super.dispose();
  }

  // === ヘルパーメソッド ===
  double _getDayColumnWidth(double viewWidth) => (viewWidth - _leftColumnWidth) / 7;
  double _hourToY(double hour) => hour * _hourHeight;

  DateTime _positionToDateTime(Offset globalPosition, DateTime startOfWeek, double viewWidth) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(globalPosition);
    final dayColumnWidth = _getDayColumnWidth(viewWidth);
    int dayIndex = ((localPosition.dx - _leftColumnWidth) / dayColumnWidth).floor().clamp(0, 6);
    DateTime date = DateUtils.dateOnly(startOfWeek).add(Duration(days: dayIndex));
    double totalMinutes = ((_scrollController.offset + localPosition.dy) / _hourHeight) * 60;
    int snappedMinutes = (totalMinutes / 15).round() * 15;
    return date.add(Duration(minutes: snappedMinutes));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWeekDayHeader(widget.focusedDate),
        Expanded(
          child: Stack(
            children: [
              PageView.builder(
                controller: widget.pageController,
                onPageChanged: widget.onPageChanged,
                itemBuilder: (context, index) {
                  final weekOffset = index - 5000;
                  final now = DateTime.now();
                  final startOfWeekToday = now.subtract(Duration(days: now.weekday % 7));
                  final startOfWeek = DateUtils.addDaysToDate(startOfWeekToday, weekOffset * 7);
                  return _buildSingleWeekView(startOfWeek);
                },
              ),
              if (_showZoomResetButton) _buildZoomResetButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleWeekView(DateTime startOfWeek) {
    final allDaySchedules = widget.schedules.where((s) => s.isAllDay).toList();
    final timedSchedules = widget.schedules.where((s) => !s.isAllDay).toList();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewWidth = constraints.maxWidth;
        return GestureDetector(
          onTapUp: (details) {
            if (_draggingSchedule == null) {
              widget.onGridTapped(_positionToDateTime(details.globalPosition, startOfWeek, viewWidth));
            }
          },
          onScaleStart: (details) {
            _baseHourHeightOnScaleStart = _hourHeight;
          },
          onScaleUpdate: (details) {
            final newHourHeight = (_baseHourHeightOnScaleStart * details.verticalScale).clamp(30.0, 240.0);
            final focalPointY = details.localFocalPoint.dy;
            final scrollOffset = _scrollController.offset;
            final newScrollOffset = (scrollOffset + focalPointY) * (newHourHeight / _hourHeight) - focalPointY;
            setState(() {
              _hourHeight = newHourHeight;
              _showZoomResetButton = true;
            });
            _scrollController.jumpTo(newScrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
          },
          child: Column(
            children: [
              _buildAllDaySection(allDaySchedules, startOfWeek, viewWidth),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SizedBox(
                    height: _hourHeight * 24,
                    width: viewWidth,
                    child: Stack(
                      children: [
                        _buildGridWithTime(viewWidth),
                        ..._buildTimedScheduleBlocks(timedSchedules, startOfWeek, viewWidth),
                        if (_ghostSchedule != null) _buildGhostScheduleBlock(startOfWeek, _ghostSchedule!, viewWidth),
                        _buildTimeIndicator(startOfWeek, viewWidth),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekDayHeader(DateTime dateInWeek) {
    final startOfWeek = dateInWeek.subtract(Duration(days: dateInWeek.weekday % 7));
    final formatter = DateFormat('E', 'ja');
    final dayFormatter = DateFormat('d');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
      child: Row(
        children: [
          SizedBox(width: _leftColumnWidth),
          ...List.generate(7, (i) {
            final day = startOfWeek.add(Duration(days: i));
            final isToday = DateUtils.isSameDay(day, DateTime.now());
            final weekDayColor = day.weekday == DateTime.sunday ? Colors.red : (day.weekday == DateTime.saturday ? Colors.blue : Colors.black87);
            return Expanded(
              child: Column(
                children: [
                  Text(formatter.format(day), style: TextStyle(fontSize: 12, color: weekDayColor)),
                  const SizedBox(height: 4),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isToday ? Colors.blue : Colors.transparent,
                    child: Text(
                      dayFormatter.format(day),
                      style: TextStyle(fontSize: 14, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? Colors.white : weekDayColor),
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

  Widget _buildGridWithTime(double totalWidth) {
    return Stack(
      children: [
        ...List.generate(24, (hour) => Positioned(
          top: _hourToY(hour.toDouble()), left: _leftColumnWidth, width: totalWidth - _leftColumnWidth,
          child: Container(height: _hourHeight, decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)))),
        )),
        ...List.generate(6, (day) => Positioned(
          top: 0, bottom: 0, left: _leftColumnWidth + (day + 1) * _getDayColumnWidth(totalWidth),
          child: Container(width: 0.5, color: Colors.grey.shade300),
        )),
        ...List.generate(24, (hour) => Positioned(
          top: _hourToY(hour.toDouble()) - 7, left: 0, width: _leftColumnWidth - 4,
          child: Text(
            hour == 0 ? '' : '${hour.toString().padLeft(2, '0')}:00',
            textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        )),
      ],
    );
  }

  Widget _buildAllDaySection(List<Schedule> allDaySchedules, DateTime startOfWeek, double viewWidth) {
    if (allDaySchedules.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.only(left: _leftColumnWidth, top: 2, bottom: 2, right: viewWidth - _leftColumnWidth - (7 * _getDayColumnWidth(viewWidth))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(7, (dayIndex){
          final day = startOfWeek.add(Duration(days: dayIndex));
          final schedulesForDay = allDaySchedules.where((s) => DateUtils.isSameDay(s.date, day)).toList();
          return SizedBox(
            width: _getDayColumnWidth(viewWidth),
            child: Column(
              children: schedulesForDay.map((s) => _buildEventTile(s, startOfWeek)).toList(),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildZoomResetButton() {
    return Positioned(
      bottom: 16, right: 16,
      child: FloatingActionButton.small(
        tooltip: 'ズームをリセット',
        onPressed: () => setState(() {
          _hourHeight = 60.0;
          _showZoomResetButton = false;
        }),
        child: const Icon(Icons.zoom_in_map),
      ),
    );
  }

  List<Widget> _buildTimedScheduleBlocks(List<Schedule> schedules, DateTime startOfWeek, double viewWidth) {
    List<Widget> layoutedEvents = [];
    final dayColumnWidth = _getDayColumnWidth(viewWidth);
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final day = startOfWeek.add(Duration(days: dayIndex));
      final eventsInDay = schedules.where((s) => DateUtils.isSameDay(s.date, day)).toList();
      if (eventsInDay.isEmpty) continue;

      final columns = _calculateLayoutColumns(eventsInDay);
      final maxOverlap = columns.length;

      for (int colIndex = 0; colIndex < maxOverlap; colIndex++) {
        for (final schedule in columns[colIndex]) {
          final eventWidth = (dayColumnWidth / maxOverlap);
          final eventLeftOffset = colIndex * eventWidth;
          if (_draggingSchedule?.id == schedule.id) continue;
          layoutedEvents.add(Positioned(
            key: ValueKey(schedule.id),
            top: _hourToY(schedule.startHour),
            left: _leftColumnWidth + dayIndex * dayColumnWidth + eventLeftOffset,
            width: eventWidth,
            height: _hourToY(schedule.endHour - schedule.startHour).clamp(20.0, double.infinity),
            child: _buildEventTile(schedule, startOfWeek),
          ));
        }
      }
    }
    return layoutedEvents;
  }
  
  Widget _buildEventTile(Schedule schedule, DateTime startOfWeek) {
    if (schedule.id == 'temporary_schedule') {
      return _buildTemporaryScheduleBlock(schedule, startOfWeek);
    }
    return GestureDetector(
      onTap: () => widget.onScheduleTapped(schedule),
      onLongPressStart: (details) => setState(() {
        _draggingSchedule = schedule;
        _ghostSchedule = schedule;
      }),
      onLongPressMoveUpdate: (details) {
        if (_draggingSchedule == null) return;
        final newDateTime = _positionToDateTime(details.globalPosition, startOfWeek, MediaQuery.of(context).size.width);
        final duration = _draggingSchedule!.endHour - _draggingSchedule!.startHour;
        final newStartHour = newDateTime.hour + newDateTime.minute / 60.0;
        final clampedStartHour = newStartHour.clamp(0.0, 24.0 - duration);
        setState(() {
          _ghostSchedule = _draggingSchedule!.copyWith(
            date: newDateTime,
            startHour: clampedStartHour,
            endHour: clampedStartHour + duration,
            color: _draggingSchedule!.color.withOpacity(0.7),
          );
        });
      },
      onLongPressEnd: (details) {
        if (_ghostSchedule != null) {
          widget.onScheduleUpdated(_ghostSchedule!.copyWith(color: _draggingSchedule!.color));
        }
        setState(() {
          _draggingSchedule = null;
          _ghostSchedule = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 1.0), padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(color: schedule.color, borderRadius: BorderRadius.circular(4)),
        child: Text(
          schedule.title,
          style: TextStyle(fontSize: 12, color: schedule.color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
        ),
      ),
    );
  }

  Widget _buildTemporaryScheduleBlock(Schedule schedule, DateTime startOfWeek) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: GestureDetector(
            onLongPressStart: (details) => setState(() => _draggingSchedule = schedule),
            onLongPressMoveUpdate: (details) {
              final newDateTime = _positionToDateTime(details.globalPosition, startOfWeek, MediaQuery.of(context).size.width);
              final duration = schedule.endHour - schedule.startHour;
              widget.onTemporaryScheduleUpdated(schedule.copyWith(date: newDateTime, startHour: newDateTime.hour + newDateTime.minute/60.0, endHour: newDateTime.hour + newDateTime.minute/60.0 + duration));
            },
            onLongPressEnd: (details) => setState(() => _draggingSchedule = null),
            child: Container(
              margin: const EdgeInsets.only(right: 1.0),
              decoration: BoxDecoration(border: Border.all(color: Colors.orange.shade700, width: 2), borderRadius: BorderRadius.circular(4)),
              child: Padding(padding: const EdgeInsets.all(4.0), child: Text(schedule.title, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            ),
          ),
        ),
        Positioned(top: -4, left: 0, right: 0,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              final newStart = _positionToDateTime(details.globalPosition, startOfWeek, MediaQuery.of(context).size.width);
              if (newStart.hour + newStart.minute/60.0 >= schedule.endHour) return;
              widget.onTemporaryScheduleUpdated(schedule.copyWith(date: newStart, startHour: newStart.hour + newStart.minute/60.0));
            },
            child: Center(child: Container(width: 24, height: 8, decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(4)))),
          ),
        ),
        Positioned(bottom: -4, left: 0, right: 0,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              final newEnd = _positionToDateTime(details.globalPosition, startOfWeek, MediaQuery.of(context).size.width);
              if (newEnd.hour + newEnd.minute/60.0 <= schedule.startHour) return;
              widget.onTemporaryScheduleUpdated(schedule.copyWith(endHour: newEnd.hour + newEnd.minute/60.0));
            },
            child: Center(child: Container(width: 24, height: 8, decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(4)))),
          ),
        ),
      ],
    );
  }


  List<List<Schedule>> _calculateLayoutColumns(List<Schedule> events) {
    if (events.isEmpty) return [];
    events.sort((a, b) => a.startHour.compareTo(b.startHour));
    List<List<Schedule>> columns = [[]];
    for (final event in events) {
      bool placed = false;
      for (final column in columns) {
        if (column.isEmpty || (column.last.endHour) <= event.startHour) {
          column.add(event);
          placed = true;
          break;
        }
      }
      if (!placed) {
        columns.add([event]);
      }
    }
    return columns;
  }
  
  Widget _buildGhostScheduleBlock(DateTime startOfWeek, Schedule schedule, double viewWidth) {
    final dayIndex = schedule.date.difference(startOfWeek).inDays.clamp(0,6);
    final top = _hourToY(schedule.startHour);
    final height = _hourToY(schedule.endHour - schedule.startHour);
    final timeLabel = DateFormat('H:mm').format(schedule.date);
    return Positioned(
      top: top, left: 0, width: viewWidth,
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: 0, left: _leftColumnWidth, right: 0, child: Container(height: 1, color: Colors.blue.shade300)),
            Positioned(top: -8, left: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4), color: Theme.of(context).scaffoldBackgroundColor, child: Text(timeLabel, style: const TextStyle(fontSize: 12, color: Colors.blue)))),
            Positioned(
              top: 0,
              left: _leftColumnWidth + dayIndex * _getDayColumnWidth(viewWidth),
              width: _getDayColumnWidth(viewWidth),
              height: height,
              child: Container(margin: const EdgeInsets.all(1.0), decoration: BoxDecoration(color: schedule.color, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white.withOpacity(0.8), width: 2))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeIndicator(DateTime startOfWeek, double viewWidth) {
    final now = DateTime.now();
    final dayIndex = DateUtils.dateOnly(now).difference(startOfWeek).inDays;
    if (dayIndex < 0 || dayIndex >= 7) return const SizedBox.shrink();
    final top = _hourToY(now.hour + now.minute / 60.0);
    return Positioned(
      top: top,
      left: _leftColumnWidth,
      width: viewWidth - _leftColumnWidth,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            Expanded(child: Container(height: 2, color: Colors.red)),
          ],
        ),
      ),
    );
  }
}