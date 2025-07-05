import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';
// 以前のステップで作成したファイルをインポート
import 'package:sukekenn/presentation/widgets/calendar/event_tile.dart';
import 'package:sukekenn/presentation/widgets/calendar/week_grid_painter.dart';

class WeekCalendarView extends StatefulWidget {
  final DateTime startOfWeek;
  final List<Schedule> schedules;
  final Function(DateTime) onGridTapped;
  final Function(Schedule) onScheduleTapped;
  final Function(Schedule) onScheduleUpdated;
  final Function(Schedule) onTemporaryScheduleUpdated;
  final bool isSelectionMode;
  final List<String> selectedScheduleIds;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  const WeekCalendarView({
    super.key,
    required this.startOfWeek,
    required this.schedules,
    required this.onGridTapped,
    required this.onScheduleTapped,
    required this.onScheduleUpdated,
    required this.onTemporaryScheduleUpdated,
    this.isSelectionMode = false,
    this.selectedScheduleIds = const [],
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  State<WeekCalendarView> createState() => _WeekCalendarViewState();
}

class _WeekCalendarViewState extends State<WeekCalendarView> {
  late final ScrollController _scrollController;
  final GlobalKey _gridKey = GlobalKey();

  double _hourHeight = 60.0;
  final double _leftColumnWidth = 40.0;

  Schedule? _draggingSchedule;
  Schedule? _ghostSchedule;

  Timer? _timeIndicatorTimer;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _hourHeight * 8, // 8時を初期表示
    );
    _startTimeIndicatorTimer();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timeIndicatorTimer?.cancel();
    _stopAutoScroll();
    super.dispose();
  }

  void _startTimeIndicatorTimer() {
    _timeIndicatorTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  DateTime? _positionToDateTime(Offset globalPosition) {
    final RenderBox? gridBox =
        _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return null;

    final Offset localPosition = gridBox.globalToLocal(globalPosition);
    final dayColumnWidth = (gridBox.size.width - _leftColumnWidth) / 7;

    final int dayIndex =
        ((localPosition.dx - _leftColumnWidth) / dayColumnWidth).floor();
    if (dayIndex < 0 || dayIndex > 6) return null;

    final date = widget.startOfWeek.add(Duration(days: dayIndex));

    final double hour = (localPosition.dy / _hourHeight).clamp(0.0, 24.0);
    final int hourPart = hour.toInt();
    final int minutePart = ((hour - hourPart) * 60).toInt();

    return DateTime(
        date.year, date.month, date.day, hourPart, minutePart);
  }

  void _onDragEnd() {
    widget.onDragEnd?.call();
    _stopAutoScroll();
    if (_ghostSchedule != null) {
      // 親ウィジェットに更新を通知
      widget.onScheduleUpdated(_ghostSchedule!);
    }
    setState(() {
      _draggingSchedule = null;
      _ghostSchedule = null;
    });
  }

  void _handleAutoScroll(Offset globalPosition) {
    final RenderBox view = context.findRenderObject() as RenderBox;
    final viewHeight = view.size.height;
    final y = globalPosition.dy;
    const scrollThreshold = 70.0;
    const scrollSpeed = 10.0;

    if (y < scrollThreshold) {
      _startAutoScroll(-scrollSpeed);
    } else if (y > viewHeight - scrollThreshold) {
      _startAutoScroll(scrollSpeed);
    } else {
      _stopAutoScroll();
    }
  }

  void _startAutoScroll(double speed) {
    if (_autoScrollTimer != null) return;

    _autoScrollTimer =
        Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _scrollController.jumpTo(_scrollController.offset + speed);
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  List<List<Schedule>> _calculateLayoutColumns(List<Schedule> dailySchedules) {
    if (dailySchedules.isEmpty) return [];

    List<List<Schedule>> columns = [];
    dailySchedules.sort((a, b) => a.startHour.compareTo(b.startHour));

    for (var schedule in dailySchedules) {
      bool placed = false;
      for (var column in columns) {
        if (column.every((s) =>
            schedule.startHour >= s.endHour || schedule.endHour <= s.startHour)) {
          column.add(schedule);
          placed = true;
          break;
        }
      }
      if (!placed) {
        columns.add([schedule]);
      }
    }
    return columns;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWeekDayHeader(widget.startOfWeek),
        Expanded(
          child: GestureDetector(
            onTapUp: (details) {
              final tappedTime = _positionToDateTime(details.globalPosition);
              if (tappedTime != null) {
                widget.onGridTapped(tappedTime);
              }
            },
            onScaleUpdate: (details) {
              setState(() {
                _hourHeight = (_hourHeight * details.scale).clamp(30.0, 120.0);
              });
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                height: _hourHeight * 24,
                child: LayoutBuilder(builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  return Stack(
                    key: _gridKey,
                    children: [
                      _buildGridWithTime(totalWidth),
                      ..._buildTimedScheduleBlocks(totalWidth),
                      if (_ghostSchedule != null)
                        _buildGhostScheduleBlock(
                            _ghostSchedule!, totalWidth),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDayHeader(DateTime startOfWeek) {
    return Container(
      padding: EdgeInsets.only(left: _leftColumnWidth),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: List.generate(7, (index) {
          final date = startOfWeek.add(Duration(days: index));
          final isToday = DateUtils.isSameDay(date, DateTime.now());
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              alignment: Alignment.center,
              child: Text(
                DateFormat.E('ja').format(date),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isToday ? Theme.of(context).primaryColor : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGridWithTime(double totalWidth) {
    return Stack(
      children: [
        CustomPaint(
          size: Size(totalWidth, _hourHeight * 24),
          painter: WeekGridPainter(
            hourHeight: _hourHeight,
            leftColumnWidth: _leftColumnWidth,
            context: context,
          ),
        ),
        _buildTimeIndicator(totalWidth),
      ],
    );
  }

  List<Widget> _buildTimedScheduleBlocks(double totalWidth) {
    final List<Widget> scheduleBlocks = [];
    final dayColumnWidth = (totalWidth - _leftColumnWidth) / 7;

    for (int day = 0; day < 7; day++) {
      final targetDate = widget.startOfWeek.add(Duration(days: day));
      final dailySchedules = widget.schedules.where((s) {
        return DateUtils.isSameDay(s.date, targetDate);
      }).toList();

      final layoutColumns = _calculateLayoutColumns(dailySchedules);

      for (int colIndex = 0; colIndex < layoutColumns.length; colIndex++) {
        final column = layoutColumns[colIndex];
        final eventWidth = dayColumnWidth / layoutColumns.length;
        final eventLeftOffset = colIndex * eventWidth;

        for (var schedule in column) {
          final top = schedule.startHour * _hourHeight;
          final height = (schedule.endHour - schedule.startHour) * _hourHeight;
          final left = _leftColumnWidth + (day * dayColumnWidth) + eventLeftOffset;

          scheduleBlocks.add(
            Positioned(
              top: top,
              left: left,
              width: eventWidth.clamp(0, double.infinity),
              height: height.clamp(0, double.infinity),
              child: EventTile(
                schedule: schedule,
                isSelected: widget.isSelectionMode && widget.selectedScheduleIds.contains(schedule.id),
                isDragging: _draggingSchedule?.id == schedule.id,
                onTap: (tappedSchedule) {
                    widget.onScheduleTapped(tappedSchedule);
                },
                onLongPressStart: (details) {
                  if (widget.isSelectionMode || schedule.id.startsWith('temporary')) return;
                  widget.onDragStart?.call();
                  setState(() {
                    _draggingSchedule = schedule;
                    _ghostSchedule = schedule;
                  });
                },
                onLongPressMoveUpdate: (details) {
                  if (_draggingSchedule == null) return;
                  _handleAutoScroll(details.globalPosition);
                  final newDateTime = _positionToDateTime(details.globalPosition);
                  if (newDateTime == null) return;

                  final duration = _draggingSchedule!.endHour - _draggingSchedule!.startHour;
                  final newStartHour =
                      (newDateTime.hour + newDateTime.minute / 60.0).clamp(0.0, 24.0 - duration);

                  setState(() {
                    _ghostSchedule = _draggingSchedule!.copyWith(
                      date: newDateTime,
                      startHour: newStartHour,
                      endHour: newStartHour + duration,
                    );
                  });
                  widget.onTemporaryScheduleUpdated(_ghostSchedule!);
                },
                onLongPressEnd: (details) => _onDragEnd(),
              ),
            ),
          );
        }
      }
    }
    return scheduleBlocks;
  }

  Widget _buildGhostScheduleBlock(Schedule schedule, double totalWidth) {
    final dayColumnWidth = (totalWidth - _leftColumnWidth) / 7;
    final top = schedule.startHour * _hourHeight;
    final height = (schedule.endHour - schedule.startHour) * _hourHeight;
    final dayIndex = schedule.date.weekday % 7;
    final left = _leftColumnWidth + (dayIndex * dayColumnWidth);

    return Positioned(
      top: top,
      left: left,
      width: dayColumnWidth,
      height: height,
      child: Opacity(
        opacity: 0.5,
        child: Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: schedule.color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey, style: BorderStyle.solid),
          ),
          child: Text(
            schedule.title,
            style: TextStyle(
              fontSize: 12,
              color: schedule.color.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeIndicator(double totalWidth) {
    final now = DateTime.now();
    final endOfWeek = widget.startOfWeek.add(const Duration(days: 7));

    if (now.isBefore(widget.startOfWeek) || now.isAfter(endOfWeek)) {
      return const SizedBox.shrink();
    }

    final dayColumnWidth = (totalWidth - _leftColumnWidth) / 7;
    final top = (now.hour + now.minute / 60.0) * _hourHeight;
    final dayIndex = now.weekday % 7;
    final left = _leftColumnWidth + (dayIndex * dayColumnWidth);

    return Positioned(
      top: top - 1,
      left: left,
      right: totalWidth - (left + dayColumnWidth),
      child: Container(
        height: 2,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}