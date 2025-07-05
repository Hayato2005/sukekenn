// lib/presentation/widgets/week_calendar_view.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';

class WeekCalendarView extends StatefulWidget {
  final PageController pageController;
  final Function(int) onPageChanged;
  final DateTime focusedDate;
  final List<Schedule> schedules;
  final Function(DateTime) onGridTapped;
  final Function(Schedule) onScheduleTapped;
  final Function(Schedule) onScheduleUpdated;
  final Function(Schedule) onTemporaryScheduleUpdated;
  final bool isSelectionMode;
  final List<String> selectedScheduleIds;

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
    required this.isSelectionMode,
    required this.selectedScheduleIds,
  });

  @override
  State<WeekCalendarView> createState() => _WeekCalendarViewState();
}

class _WeekCalendarViewState extends State<WeekCalendarView> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timeIndicatorTimer;
  Timer? _autoScrollTimer;

  double _hourHeight = 60.0;
  double _baseHourHeightOnScaleStart = 60.0;
  bool _showZoomResetButton = false;

  // ドラッグ中の状態管理
  Schedule? _draggingSchedule;
  Schedule? _ghostSchedule;

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
      final initialScrollOffset = now.hour * _hourHeight - (context.size!.height) / 4;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(initialScrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timeIndicatorTimer?.cancel();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  // === ヘルパーメソッド ===
  double _getDayColumnWidth(double viewWidth) => (viewWidth - _leftColumnWidth) / 7;
  double _hourToY(double hour) => hour * _hourHeight;

  DateTime _positionToDateTime(Offset globalPosition, DateTime startOfWeek, double viewWidth, {bool snapToDay = false}) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return DateTime.now();
    
    final localPosition = renderBox.globalToLocal(globalPosition);
    final dayColumnWidth = _getDayColumnWidth(viewWidth);

    int dayIndex = ((localPosition.dx - _leftColumnWidth) / dayColumnWidth).floor().clamp(0, 6);
    if (snapToDay) {
        final dayOffset = (localPosition.dx - _leftColumnWidth) % dayColumnWidth;
        if (dayOffset < 15 && dayIndex > 0) dayIndex--;
        if (dayOffset > dayColumnWidth - 15 && dayIndex < 6) dayIndex++;
    }

    DateTime date = DateUtils.dateOnly(startOfWeek).add(Duration(days: dayIndex));
    double totalMinutes = ((_scrollController.offset + localPosition.dy) / _hourHeight) * 60;
    int snappedMinutes = (totalMinutes / 15).round() * 15;
    
    return date.add(Duration(minutes: snappedMinutes));
  }

  // === ドラッグ中のオートスクロール処理 ===
  void _handleAutoScroll(Offset globalPosition) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localY = box.globalToLocal(globalPosition).dy;
    final viewHeight = box.size.height;
    const scrollAreaHeight = 50.0;
    const scrollSpeed = 10.0;

    if (localY < scrollAreaHeight) {
      _startAutoScroll(-scrollSpeed);
    } else if (localY > viewHeight - scrollAreaHeight) {
      _startAutoScroll(scrollSpeed);
    } else {
      _stopAutoScroll();
    }
  }

  void _startAutoScroll(double speed) {
    _autoScrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          (_scrollController.offset + speed).clamp(0.0, _scrollController.position.maxScrollExtent)
        );
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfThisWeek = now.subtract(Duration(days: now.weekday % 7));

    return Column(
      children: [
        _buildWeekDayHeader(widget.focusedDate),
        Expanded(
          child: GestureDetector(
            onTapUp: (details) {
              final page = widget.pageController.page?.round() ?? 5000;
              final startOfWeek = DateUtils.addDaysToDate(startOfThisWeek, (page - 5000) * 7);
              widget.onGridTapped(_positionToDateTime(details.globalPosition, startOfWeek, context.size!.width));
            },
            onScaleStart: (details) {
              if (details.pointerCount < 2) return;
              _baseHourHeightOnScaleStart = _hourHeight;
              setState(() => _showZoomResetButton = true);
            },
            onScaleUpdate: (details) {
              if (details.pointerCount < 2) return;
              final newHourHeight = (_baseHourHeightOnScaleStart * details.verticalScale).clamp(30.0, 240.0);
              final scrollOffset = _scrollController.offset;
              final focalPointY = details.localFocalPoint.dy;
              final newScrollOffset = (scrollOffset + focalPointY) * (newHourHeight / _hourHeight) - focalPointY;

              setState(() => _hourHeight = newHourHeight);
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(newScrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
              }
            },
            child: Stack(
              children: [
                PageView.builder(
                  controller: widget.pageController,
                  onPageChanged: widget.onPageChanged,
                  itemBuilder: (context, index) {
                    final weekOffset = index - 5000;
                    final startOfWeek = DateUtils.addDaysToDate(startOfThisWeek, weekOffset * 7);
                    return _buildSingleWeekView(startOfWeek);
                  },
                ),
                if (_ghostSchedule != null)
                  _buildGhostScheduleBlock(
                    DateUtils.addDaysToDate(startOfThisWeek, (widget.pageController.page!.round() - 5000) * 7),
                    _ghostSchedule!,
                    MediaQuery.of(context).size.width
                  ),
                if (_showZoomResetButton) _buildZoomResetButton(),
              ],
            ),
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
        return Column(
          children: [
            _buildAllDaySection(allDaySchedules, startOfWeek, constraints.maxWidth),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: SizedBox(
                  height: _hourHeight * 24,
                  width: constraints.maxWidth,
                  child: Stack(
                    children: [
                      _buildGridWithTime(constraints.maxWidth),
                      ..._buildTimedScheduleBlocks(timedSchedules, startOfWeek, constraints.maxWidth),
                      _buildTimeIndicator(startOfWeek, constraints.maxWidth),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeekDayHeader(DateTime dateInWeek) {
    final startOfWeek = dateInWeek.subtract(Duration(days: dateInWeek.weekday % 7));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(color: Theme.of(context).canvasColor, border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
      child: Row(
        children: [
          SizedBox(width: _leftColumnWidth),
          ...List.generate(7, (i) {
            final day = startOfWeek.add(Duration(days: i));
            final isToday = DateUtils.isSameDay(day, DateTime.now());
            final weekDayColor = day.weekday == DateTime.sunday ? Colors.red : (day.weekday == DateTime.saturday ? Colors.blue : Theme.of(context).textTheme.bodyLarge?.color);
            return Expanded(
              child: Column(
                children: [
                  Text(DateFormat('E', 'ja').format(day), style: TextStyle(fontSize: 12, color: weekDayColor)),
                  const SizedBox(height: 4),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isToday ? Colors.blue : Colors.transparent,
                    child: Text(
                      DateFormat('d').format(day),
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
          top: _hourToY(hour.toDouble()), left: _leftColumnWidth, right: 0,
          child: Container(height: _hourHeight, decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)))),
        )),
        ...List.generate(6, (day) => Positioned(
          top: 0, bottom: 0, left: _leftColumnWidth + (day + 1) * _getDayColumnWidth(totalWidth),
          child: Container(width: 1, color: Colors.grey.shade200),
        )),
        ...List.generate(24, (hour) => Positioned(
          top: _hourToY(hour.toDouble()) - 8, left: 0, width: _leftColumnWidth - 4,
          child: Text(
            hour == 0 ? '' : DateFormat('H').format(DateTime(2000,1,1,hour)),
            textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        )),
      ],
    );
  }

  Widget _buildAllDaySection(List<Schedule> allDaySchedules, DateTime startOfWeek, double viewWidth) {
    if (allDaySchedules.isEmpty) return const SizedBox.shrink();
    return Container();
  }

  List<Widget> _buildTimedScheduleBlocks(List<Schedule> schedules, DateTime startOfWeek, double viewWidth) {
    List<Widget> layoutedEvents = [];
    final dayColumnWidth = _getDayColumnWidth(viewWidth);

    // ★★★★★ エラー修正箇所 ★★★★★
    // 描画前にIDの重複を強制的に排除し、Duplicate keysエラーを防ぐ
    final Set<String> seenIds = {};
    final uniqueSchedules = schedules.where((schedule) => seenIds.add(schedule.id)).toList();

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final day = startOfWeek.add(Duration(days: dayIndex));
      // 重複排除済みのリストを使用する
      final eventsInDay = uniqueSchedules.where((s) => DateUtils.isSameDay(s.date, day)).toList();
      if (eventsInDay.isEmpty) continue;

      final columns = _calculateLayoutColumns(eventsInDay);
      final maxOverlap = columns.length;

      for (int colIndex = 0; colIndex < maxOverlap; colIndex++) {
        for (final schedule in columns[colIndex]) {
          final eventWidth = dayColumnWidth / maxOverlap;
          final eventLeftOffset = colIndex * eventWidth;
          if (_draggingSchedule?.id == schedule.id) continue;

          layoutedEvents.add(Positioned(
            key: ValueKey(schedule.id), // ここで使われるキーが重複しないことを保証
            top: _hourToY(schedule.startHour),
            left: _leftColumnWidth + dayIndex * dayColumnWidth + eventLeftOffset,
            width: eventWidth - 1,
            height: max(20.0, _hourToY(schedule.endHour) - _hourToY(schedule.startHour)),
            child: _buildEventTile(schedule, startOfWeek),
          ));
        }
      }
    }
    return layoutedEvents;
  }

  Widget _buildEventTile(Schedule schedule, DateTime startOfWeek) {
    final bool isTemporary = schedule.id.startsWith('temporary');
    final bool isSelected = widget.isSelectionMode && widget.selectedScheduleIds.contains(schedule.id);

    return GestureDetector(
      onTap: () => widget.onScheduleTapped(schedule),
      onLongPressStart: (details) {
        if (widget.isSelectionMode || isTemporary) return;
        setState(() {
          _draggingSchedule = schedule;
          _ghostSchedule = schedule.copyWith(color: schedule.color.withOpacity(0.5));
        });
      },
      onLongPressMoveUpdate: (details) {
        if (_draggingSchedule == null || isTemporary) return;
        _handleAutoScroll(details.globalPosition);
        final newDateTime = _positionToDateTime(details.globalPosition, startOfWeek, context.size!.width, snapToDay: true);
        final duration = _draggingSchedule!.endHour - _draggingSchedule!.startHour;
        final newStartHour = (newDateTime.hour + newDateTime.minute / 60.0).clamp(0.0, 24.0 - duration);

        setState(() {
          _ghostSchedule = _draggingSchedule!.copyWith(
            date: newDateTime,
            startHour: newStartHour,
            endHour: newStartHour + duration,
            color: _draggingSchedule!.color.withOpacity(0.7),
          );
        });
      },
      onLongPressEnd: (details) {
        if (_draggingSchedule != null && _ghostSchedule != null) {
           widget.onScheduleUpdated(_ghostSchedule!.copyWith(color: _draggingSchedule!.color));
        }
        _stopAutoScroll();
        setState(() {
          _draggingSchedule = null;
          _ghostSchedule = null;
        });
      },
      child: isTemporary
        ? _buildTemporaryScheduleBlock(schedule, startOfWeek)
        : Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: schedule.color.withOpacity(isSelected ? 0.6 : 1.0),
              borderRadius: BorderRadius.circular(4),
              border: isSelected ? Border.all(color: Colors.blue.shade700, width: 2) : null,
            ),
            child: Text(
              schedule.title,
              style: TextStyle(fontSize: 12, color: schedule.color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
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
              _handleAutoScroll(details.globalPosition);
              final newDateTime = _positionToDateTime(details.globalPosition, startOfWeek, context.size!.width);
              final duration = schedule.endHour - schedule.startHour;
              widget.onTemporaryScheduleUpdated(schedule.copyWith(
                  date: newDateTime,
                  startHour: newDateTime.hour + newDateTime.minute / 60.0,
                  endHour: newDateTime.hour + newDateTime.minute / 60.0 + duration));
            },
            onLongPressEnd: (details) {
              _stopAutoScroll();
              setState(() => _draggingSchedule = null);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.orange.shade700, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  schedule.title.isEmpty ? '(タイトル未入力)' : schedule.title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -6, left: 0, right: 0, height: 12,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              _handleAutoScroll(details.globalPosition);
              final newStart = _positionToDateTime(details.globalPosition, startOfWeek, context.size!.width);
              final newStartHour = newStart.hour + newStart.minute / 60.0;
              if (newStartHour >= schedule.endHour - (15/60.0)) return;
              widget.onTemporaryScheduleUpdated(schedule.copyWith(date: newStart, startHour: newStartHour));
            },
            onVerticalDragEnd: (details) => _stopAutoScroll(),
            child: Center(child: Container(width: 24, height: 8, decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(4)))),
          ),
        ),
        Positioned(
          bottom: -6, left: 0, right: 0, height: 12,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              _handleAutoScroll(details.globalPosition);
              final newEnd = _positionToDateTime(details.globalPosition, startOfWeek, context.size!.width);
              final newEndHour = newEnd.hour + newEnd.minute/60.0;
              if (newEndHour <= schedule.startHour + (15/60.0)) return;
              widget.onTemporaryScheduleUpdated(schedule.copyWith(endHour: newEndHour));
            },
            onVerticalDragEnd: (details) => _stopAutoScroll(),
            child: Center(child: Container(width: 24, height: 8, decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(4)))),
          ),
        ),
      ],
    );
  }


  Widget _buildGhostScheduleBlock(DateTime startOfWeek, Schedule schedule, double viewWidth) {
    final dayIndex = schedule.date.difference(startOfWeek).inDays.clamp(0, 6);
    if (dayIndex < 0 || dayIndex > 6) return const SizedBox.shrink();

    final top = _hourToY(schedule.startHour);
    final height = _hourToY(schedule.endHour) - _hourToY(schedule.startHour);
    final timeLabel = DateFormat('H:mm').format(schedule.date);

    return Positioned(
      top: top,
      left: 0,
      width: viewWidth,
      height: height,
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -8, left: 0, width: _leftColumnWidth - 4,
              child: Container(
                  color: Theme.of(context).canvasColor,
                  child: Text(timeLabel, textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold))),
            ),
            Positioned(
              top: 0, left: _leftColumnWidth, right: 0,
              child: CustomPaint(painter: DottedLinePainter()),
            ),
            Positioned(
              top: 0,
              left: _leftColumnWidth + dayIndex * _getDayColumnWidth(viewWidth),
              width: _getDayColumnWidth(viewWidth) - 1,
              height: height,
              child: Opacity(
                  opacity: 0.8,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(color: schedule.color, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      schedule.title,
                      style: TextStyle(fontSize: 12, color: schedule.color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
                      overflow: TextOverflow.ellipsis,
                    )
                  )),
            ),
            if (_draggingSchedule != null)
              Positioned(
                top: _hourToY(_draggingSchedule!.startHour) - top,
                left: _leftColumnWidth + _draggingSchedule!.date.difference(startOfWeek).inDays * _getDayColumnWidth(viewWidth),
                width: _getDayColumnWidth(viewWidth) -1,
                height: _hourToY(_draggingSchedule!.endHour) - _hourToY(_draggingSchedule!.startHour),
                child: Container(decoration: BoxDecoration(color: _draggingSchedule!.color.withOpacity(0.2), borderRadius: BorderRadius.circular(4))),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildTimeIndicator(DateTime startOfWeek, double viewWidth) {
    final now = DateTime.now();
    final dayIndex = DateUtils.dateOnly(now).difference(DateUtils.dateOnly(startOfWeek)).inDays;
    if (dayIndex < 0 || dayIndex >= 7) return const SizedBox.shrink();

    final top = _hourToY(now.hour + now.minute / 60.0);
    final left = _leftColumnWidth + dayIndex * _getDayColumnWidth(viewWidth);

    return Positioned(
      top: top, left: left, width: _getDayColumnWidth(viewWidth),
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
  Widget _buildZoomResetButton() {
    return Positioned(
      bottom: 16, right: 16,
      child: FloatingActionButton.small(
        heroTag: 'zoom_reset_button',
        tooltip: 'ズームをリセット',
        onPressed: () => setState(() {
          _hourHeight = 60.0;
          _showZoomResetButton = false;
        }),
        child: const Icon(Icons.zoom_in_map),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade300
      ..strokeWidth = 1.5;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}