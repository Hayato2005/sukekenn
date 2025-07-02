import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:sukekenn/filter_dialog.dart';
import 'package:sukekenn/main_screen.dart';
import 'package:sukekenn/presentation/pages/calendar/widgets/week_drawer.dart';
import 'package:sukekenn/schedule_creation_sheet.dart';

class WeekViewScreen extends StatefulWidget {
  final DateTime startDate;
  const WeekViewScreen({super.key, required this.startDate});

  @override
  State<WeekViewScreen> createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends State<WeekViewScreen> {
  late DateTime _currentDate;
  late List<Map<String, dynamic>> fakeSchedules;
  double _scale = 1.0;
  final TransformationController _transformationController = TransformationController();

  bool _isSelectionMode = false;
  final List<Map<String, dynamic>> _selectedSchedules = [];

  @override
  void initState() {
    super.initState();
    // 渡された日付が日曜でない場合、その週の日曜に補正する
    _currentDate = widget.startDate.subtract(Duration(days: widget.startDate.weekday % 7));
    _generateFakeSchedules();
  }

  void _generateFakeSchedules() {
    final random = Random();
    fakeSchedules = List.generate(10, (index) {
      final startHour = random.nextInt(22);
      final duration = random.nextInt(3) + 1;
      final dayOffset = random.nextInt(7);
      return {
        'id': '${_currentDate.millisecondsSinceEpoch}-$index',
        'title': '予定 ${index + 1}',
        'day': dayOffset,
        'startHour': startHour,
        'endHour': startHour + duration,
        'color': Colors.primaries[random.nextInt(Colors.primaries.length)],
      };
    });
  }

  void _changeWeek(int days) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: days));
      _generateFakeSchedules();
    });
  }
  
  void _showScheduleCreationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: ScheduleCreationSheet(controller: controller),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => const FilterDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildWeekHeader(),
      drawer: const WeekDrawer(),
      body: Column(
        children: [
          // 曜日バーを追加
          buildWeekDayBar(),
          Expanded(
            child: buildWeekView(),
          ),
          if (_isSelectionMode) buildActionBar(),
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(context),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'week_filter_button',
            mini: true,
            onPressed: _showFilterDialog,
            child: const Icon(Icons.filter_list),
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: _isSelectionMode ? 0.0 : 1.0,
            child: IgnorePointer(
              ignoring: _isSelectionMode,
              child: FloatingActionButton(
                heroTag: 'week_add_button',
                onPressed: _showScheduleCreationSheet,
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar buildWeekHeader() {
    // (AppBarのコードは前回のものから変更なし)
    return AppBar(
      title: GestureDetector(
        onTap: showWeekPicker,
        child: Text(
          '${DateFormat('yyyy年 M月').format(_currentDate)} 第${((_currentDate.day - 1) / 7).floor() + 1}週',
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isSelectionMode ? Icons.cancel : Icons.check_box_outline_blank),
          color: Colors.black,
          onPressed: () {
            setState(() {
              _isSelectionMode = !_isSelectionMode;
              if (!_isSelectionMode) {
                _selectedSchedules.clear();
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.black),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.person_add, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }

  // ★★★ 新しく追加した曜日バー ★★★
  Widget buildWeekDayBar() {
    const weekDayChars = ['日', '月', '火', '水', '木', '金', '土'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: List.generate(7, (index) {
          final date = _currentDate.add(Duration(days: index));
          final today = DateTime.now();
          final bool isToday = date.year == today.year && date.month == today.month && date.day == today.day;
          
          Color textColor;
          if(isToday) {
            textColor = Colors.blue;
          } else if (date.weekday == DateTime.saturday) {
            textColor = Colors.blue.shade700;
          } else if (date.weekday == DateTime.sunday) {
            textColor = Colors.red.shade600;
          } else {
            textColor = Colors.black87;
          }

          return Expanded(
            child: Column(
              children: [
                Text(
                  weekDayChars[date.weekday % 7],
                  style: TextStyle(fontSize: 12, color: textColor),
                ),
                const SizedBox(height: 2),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isToday ? Colors.blue : Colors.transparent,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.white : textColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void showWeekPicker() async {
    // (showWeekPickerのコードは前回のものから変更なし)
    if (_isSelectionMode) return;
    int selectedYear = _currentDate.year;
    int selectedMonth = _currentDate.month;
    int selectedWeek = ((_currentDate.day - 1) / 7).floor() + 1;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('年月週を選択'),
        content: SizedBox(
          height: 150,
          child: Row(
            children: [
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  onSelectedItemChanged: (index) => selectedYear = 2000 + index,
                  controller: FixedExtentScrollController(initialItem: selectedYear - 2000),
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) => Center(child: Text('${2000 + index}年')),
                    childCount: 101,
                  ),
                ),
              ),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  onSelectedItemChanged: (index) => selectedMonth = index + 1,
                  controller: FixedExtentScrollController(initialItem: selectedMonth - 1),
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) => Center(child: Text('${index + 1}月')),
                    childCount: 12,
                  ),
                ),
              ),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  onSelectedItemChanged: (index) => selectedWeek = index + 1,
                  controller: FixedExtentScrollController(initialItem: selectedWeek - 1),
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) => Center(child: Text('第${index + 1}週')),
                    childCount: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                DateTime firstDayOfMonth = DateTime(selectedYear, selectedMonth, 1);
                DateTime dateInSelectedWeek = firstDayOfMonth.add(Duration(days: (selectedWeek - 1) * 7));
                _currentDate = dateInSelectedWeek.subtract(Duration(days: dateInSelectedWeek.weekday % 7));
                _generateFakeSchedules();
              });
              Navigator.pop(context);
            },
            child: const Text('完了'),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar buildBottomNavigationBar(BuildContext context) {
    // (buildBottomNavigationBarのコードは前回のものから変更なし)
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'チャット'),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'フレンド'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'マッチング'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'マイページ'),
      ],
      currentIndex: 0,
      onTap: (index) {
        if (index == 0) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => MainScreen(initialIndex: index)),
            (Route<dynamic> route) => false,
          );
        }
      },
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
    );
  }

  // (buildWeekView, buildTimeColumn, buildGrid, buildScheduleLayout, buildActionBar の各メソッドは前回のものから変更ありません)
  Widget buildWeekView() {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          _changeWeek(-7);
        } else if (details.primaryVelocity! < 0) {
          _changeWeek(7);
        }
      },
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 4.0,
        onInteractionEnd: (details) {
          setState(() {
            _scale = _transformationController.value.getMaxScaleOnAxis();
          });
        },
        child: SingleChildScrollView(
          child: SizedBox(
            height: 24 * 60 * _scale,
            child: Row(
              children: [
                buildTimeColumn(),
                Expanded(
                  child: Stack(
                    children: [
                      buildGrid(),
                      ...buildScheduleLayout(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTimeColumn() {
    return Column(
      children: List.generate(24, (index) {
        return SizedBox(
          height: 60 * _scale,
          width: 50,
          child: Center(child: Text('${index.toString().padLeft(2, '0')}:00')),
        );
      }),
    );
  }

  Widget buildGrid() {
    return Column(
      children: List.generate(24, (hour) {
        return SizedBox(
          height: 60 * _scale,
          child: Row(
            children: List.generate(7, (day) {
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: const BorderSide(color: Colors.grey),
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  List<Widget> buildScheduleLayout() {
    return fakeSchedules.map((schedule) {
      final bool isSelected = _selectedSchedules.any((s) => s['id'] == schedule['id']);
      final dayWidth = (MediaQuery.of(context).size.width - 50) / 7;

      return Positioned(
        top: schedule['startHour'] * 60 * _scale,
        left: schedule['day'] * dayWidth,
        height: (schedule['endHour'] - schedule['startHour']) * 60 * _scale,
        width: dayWidth,
        child: GestureDetector(
          onTap: _isSelectionMode
              ? () {
                  setState(() {
                    if (isSelected) {
                      _selectedSchedules.removeWhere((s) => s['id'] == schedule['id']);
                    } else {
                      _selectedSchedules.add(schedule);
                    }
                  });
                }
              : null,
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: schedule['color'],
              borderRadius: BorderRadius.circular(4),
              border: isSelected ? Border.all(color: Colors.blueAccent, width: 2.5) : null,
            ),
            child: Text(
              schedule['title'],
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('削除'),
            onPressed: _selectedSchedules.isEmpty ? null : () {},
          ),
          TextButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('共有'),
            onPressed: _selectedSchedules.isEmpty ? null : () {},
          ),
          TextButton.icon(
            icon: const Icon(Icons.group_add),
            label: const Text('招待'),
            onPressed: _selectedSchedules.isEmpty ? null : () {},
          ),
        ],
      ),
    );
  }
}