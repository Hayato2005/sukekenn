// lib/presentation/widgets/month_calendar_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';
import 'dart:ui' as ui;

class MonthCalendarView extends StatelessWidget {
  final PageController pageController;
  final Function(int) onPageChanged;
  final Function(DateTime) onDateDoubleTapped;
  final bool isSelectionMode;
  final List<Schedule> selectedSchedules;
  final Function(Schedule) onSelectionChanged;
  final Function(Schedule) onScheduleTapped; // スケジュールタップ用のコールバックを追加
  final List<Schedule> schedules;

  const MonthCalendarView({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    required this.onDateDoubleTapped,
    required this.isSelectionMode,
    required this.selectedSchedules,
    required this.onSelectionChanged,
    required this.onScheduleTapped, // コールバックを受け取る
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
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey.shade300))
      ),
      child: Row(
        children: List.generate(7, (index) {
          const weekDays = ['日', '月', '火', '水', '木', '金', '土'];
          return Expanded(
            child: Center(
              child: Text(
                weekDays[index],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: index == 0 ? Colors.red : (index == 6 ? Colors.blue : Colors.black87),
                  ),
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
                date = firstDayOfMonth.add(Duration(days: dayNum - 1));
                isCurrentMonth = false;
              } else if (dayNum > daysInMonth) {
                date = firstDayOfMonth.add(Duration(days: dayNum - 1));
                isCurrentMonth = false;
              } else {
                date = DateTime(month.year, month.month, dayNum);
              }

              final daySchedules = schedules.where((s) => DateUtils.isSameDay(s.date, date)).toList();

              return Expanded(
                child: GestureDetector(
                  onLongPress: isCurrentMonth ? () => _showDayTimeline(context, date, daySchedules) : null,
                  onDoubleTap: isCurrentMonth ? () => onDateDoubleTapped(date) : null,
                  child: _buildDateCell(context, date, daySchedules, isCurrentMonth, col),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDateCell(BuildContext context, DateTime date, List<Schedule> daySchedules, bool isCurrentMonth, int dayOfWeek) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    Color dateColor;
    if (!isCurrentMonth) {
      dateColor = Colors.grey.shade400;
    } else if (isToday) {
      dateColor = Colors.red;
    } else if (dayOfWeek == 0) {
      dateColor = Colors.red.shade700;
    } else if (dayOfWeek == 6) {
      dateColor = Colors.blue.shade700;
    } else {
      dateColor = Colors.black87;
    }

    return Container(
      decoration: BoxDecoration(
        color: isToday && isCurrentMonth ? Colors.red[50] : null,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          left: BorderSide(color: Colors.grey.shade200)
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: dateColor,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildScheduleItems(context, daySchedules, constraints.maxHeight),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
 
  List<Widget> _buildScheduleItems(BuildContext context, List<Schedule> schedules, double availableHeight) {
    schedules.sort((a,b) => a.startHour.compareTo(b.startHour));
    const double itemHeight = 22.0; 
    final int maxVisibleItems = (availableHeight / itemHeight).floor();

    List<Widget> items = schedules.map((schedule) {
      final bool isSelected = selectedSchedules.any((s) => s.id == schedule.id);
      final bgColor = schedule.color;
      final textColor = bgColor.computeLuminance() < 0.5 ? Colors.white : Colors.black87;

      return GestureDetector(
        onTap: () {
          if (isSelectionMode) {
            onSelectionChanged(schedule);
          } else {
            onScheduleTapped(schedule); 
          }
        },
        child: Container(
          height: itemHeight - 4,
          margin: const EdgeInsets.fromLTRB(2, 0, 2, 2),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(3),
            border: isSelected ? Border.all(color: Colors.blueAccent, width: 2) : null,
          ),
          child: Text(
            schedule.title,
            style: TextStyle(fontSize: 12, color: textColor),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      );
    }).toList();

    if (items.length > maxVisibleItems && maxVisibleItems > 0) {
      return [
        ...items.take(maxVisibleItems - 1),
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text('+${items.length - (maxVisibleItems - 1)}件...', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ),
      ];
    }
    return items;
  }
  
  void _showDayTimeline(BuildContext context, DateTime date, List<Schedule> schedules) {
    showDialog(
        context: context,
        builder: (context) {
            return AlertDialog(
                title: Text(DateFormat('M月d日 (E)', 'ja').format(date)),
                contentPadding: EdgeInsets.zero,
                content: SizedBox(
                    width: double.maxFinite,
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _DayTimelineContent(
                        schedules: schedules,
                        onScheduleTapped: (schedule) {
                           Navigator.of(context).pop(); // ダイアログを閉じてから
                           onScheduleTapped(schedule); // ポップアップを表示
                        },
                    ),
                ),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('閉じる'),
                    )
                ],
            );
        },
    );
  }
}


class _DayTimelineContent extends StatefulWidget {
  final List<Schedule> schedules;
  final Function(Schedule) onScheduleTapped;

  const _DayTimelineContent({required this.schedules, required this.onScheduleTapped});

  @override
  _DayTimelineContentState createState() => _DayTimelineContentState();
}

class _DayTimelineContentState extends State<_DayTimelineContent> {
  final ScrollController _scrollController = ScrollController();
  final double _hourHeight = 60.0;
  final double _leftPadding = 50.0;

  @override
  void initState() {
    super.initState();
    // 8時が初期表示位置になるように設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(7 * _hourHeight); // 0時から7時間後
      }
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final laidOutSchedules = _calculateLayoutColumns(widget.schedules);

    return SingleChildScrollView(
      controller: _scrollController,
      child: SizedBox(
        height: 24 * _hourHeight,
        child: Stack(
          children: [
            // 時間グリッド線
            CustomPaint(
              size: Size.infinite,
              painter: _TimelinePainter(hourHeight: _hourHeight, leftPadding: _leftPadding),
            ),
            // スケジュールタイル
            ..._buildScheduleTiles(laidOutSchedules, context),
          ],
        ),
      ),
    );
  }

  List<List<Schedule>> _calculateLayoutColumns(List<Schedule> dailySchedules) {
    if (dailySchedules.isEmpty) return [];

    List<List<Schedule>> columns = [];
    dailySchedules.sort((a, b) => a.startHour.compareTo(b.startHour));

    for (var schedule in dailySchedules) {
      bool placed = false;
      for (var column in columns) {
        if (column.every((s) => schedule.startHour >= s.endHour || schedule.endHour <= s.startHour)) {
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
  
  // ★★★★★ 修正点 ★★★★★
  // 引数の型を List<List<List<Schedule>>> から List<List<Schedule>> に修正
  List<Widget> _buildScheduleTiles(List<List<Schedule>> laidOutSchedules, BuildContext context) {
    final List<Widget> tiles = [];
    // ダイアログの幅を基準にするため、MediaQueryを使用
    final dialogWidth = MediaQuery.of(context).size.width * 0.9; // AlertDialogのデフォルトの水平マージン(40*2)を考慮したおおよその幅
    final rightSectionWidth = dialogWidth - _leftPadding - 24; // AlertDialogのcontentPaddingを考慮

    for (int i = 0; i < laidOutSchedules.length; i++) {
        final column = laidOutSchedules[i]; // column は List<Schedule>
        final columnWidth = rightSectionWidth / laidOutSchedules.length;
        final leftOffset = _leftPadding + (i * columnWidth);

        for(final schedule in column) { // schedule は Schedule
            final top = schedule.startHour * _hourHeight;
            final height = (schedule.endHour - schedule.startHour) * _hourHeight;

            tiles.add(Positioned(
                top: top,
                left: leftOffset,
                width: columnWidth,
                height: height.clamp(0, double.infinity), // heightが負にならないように
                child: GestureDetector(
                    onTap: () => widget.onScheduleTapped(schedule), // 正しい型で渡す
                    child: Container(
                        margin: const EdgeInsets.all(1.0),
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                            color: schedule.color, // 正しくプロパティにアクセス
                            borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                            schedule.title,
                            style: TextStyle(
                                color: schedule.color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                        ),
                    ),
                ),
            ));
        }
    }
    return tiles;
  }
}


class _TimelinePainter extends CustomPainter {
  final double hourHeight;
  final double leftPadding;

  _TimelinePainter({required this.hourHeight, required this.leftPadding});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;

    for (int hour = 0; hour < 24; hour++) {
      final y = hour * hourHeight;
      // 水平線
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width, y), linePaint);
      
      // 時間ラベル
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${hour.toString().padLeft(2, '0')}:00',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      // ラベルが線の中央に来るようにy座標を調整
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}