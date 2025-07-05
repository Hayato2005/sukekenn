// lib/calendar_view_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';
import 'package:sukekenn/presentation/widgets/month_calendar_view.dart';
import 'package:sukekenn/presentation/widgets/schedule_detail_popup.dart';
import 'package:sukekenn/presentation/widgets/week_calendar_view.dart';
import 'package:sukekenn/repositories/schedule_repository.dart';
import 'package:sukekenn/schedule_creation_sheet.dart';
import 'package:sukekenn/filter_dialog.dart';
import 'dart:math';

enum CalendarDisplayMode { month, week }
enum CreationMode { quick, full }

class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  final _repo = ScheduleRepository();
  List<Schedule> _schedules = [];

  // --- UI状態管理 ---
  CalendarDisplayMode _displayMode = CalendarDisplayMode.week;
  DateTime _focusedDate = DateTime.now();
  bool _isSelectionMode = false;
  final List<String> _selectedScheduleIds = [];
  bool _showTodayButton = false;

  late PageController _monthPageController;
  late PageController _weekPageController;
  static const int initialPageOffset = 5000;

  // --- 新規予定作成フローの状態 ---
  Schedule? _temporarySchedule;
  bool _isCreatingSchedule = false;
  CreationMode _creationMode = CreationMode.quick;
  final DraggableScrollableController _sheetController = DraggableScrollableController();


  @override
  void initState() {
    super.initState();
    _monthPageController = PageController(initialPage: initialPageOffset);
    _weekPageController = PageController(initialPage: initialPageOffset);
    _loadSchedules();
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    _weekPageController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // === データ操作メソッド群 ===
  Future<void> _loadSchedules() async {
    await _repo.loadSchedules();
    _updateScheduleList();
  }

  Future<void> _addSchedule(Schedule schedule) async {
    _repo.addSchedule(schedule);
    await _persistChanges();
  }

  Future<void> _updateSchedule(Schedule schedule) async {
    _repo.updateSchedule(schedule);
    await _persistChanges();
  }

  Future<void> _removeSchedule(String scheduleId) async {
    _repo.removeSchedule(scheduleId);
    await _persistChanges();
  }
   Future<void> _removeMultipleSchedules(List<String> ids) async {
    for (var id in ids) {
      _repo.removeSchedule(id);
    }
    await _persistChanges();
    setState(() {
      _selectedScheduleIds.clear();
      _isSelectionMode = false;
    });
  }


  Future<void> _persistChanges() async {
    final allSchedules = _repo.getSchedulesForRange(DateTime(2000), DateTime(2100));
    await _repo.saveSchedules(allSchedules);
    _updateScheduleList();
  }

  void _updateScheduleList() {
    if (!mounted) return;
    setState(() {
      if (_displayMode == CalendarDisplayMode.month) {
        _schedules = _repo.getSchedulesForMonth(_focusedDate);
      } else {
        final startOfWeek = _focusedDate.subtract(Duration(days: _focusedDate.weekday % 7));
        _schedules = _repo.getSchedulesForWeek(startOfWeek);
      }
    });
  }


  // === UIイベントハンドラ群 ===

  void _onGridTappedInWeekView(DateTime tappedTime) {
    if (_isCreatingSchedule || _isSelectionMode) return;

    setState(() {
      _creationMode = CreationMode.quick;
      _temporarySchedule = Schedule.empty().copyWith(
        id: 'temporary_schedule_${DateTime.now().millisecondsSinceEpoch}',
        title: '',
        date: tappedTime,
        startHour: tappedTime.hour + tappedTime.minute / 60.0,
        endHour: (tappedTime.hour + 1) + tappedTime.minute / 60.0,
        color: Colors.orange.withOpacity(0.8),
      );
      _isCreatingSchedule = true;
    });
  }

  void _onTemporaryScheduleUpdated(Schedule updatedTemporarySchedule) {
    setState(() {
      _temporarySchedule = updatedTemporarySchedule;
    });
  }

  void _onCreationSheetClosed({Schedule? savedSchedule, bool isDeleted = false}) async {
    if (isDeleted) {
       if (_temporarySchedule != null) {
         // 削除フラグがtrueなら、編集中だった予定を削除
         await _removeSchedule(_temporarySchedule!.id);
       }
    }
    else if (savedSchedule != null) {
      // 新規保存 or 更新
      if (savedSchedule.id.startsWith('temporary')) {
         await _addSchedule(savedSchedule.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString()));
      }
      else {
        await _updateSchedule(savedSchedule);
      }
    }

    // 状態をリセットしてシートを閉じる
    setState(() {
      _isCreatingSchedule = false;
      _temporarySchedule = null;
    });
  }

  // month_calendar_view から呼び出される選択変更ハンドラ
  void _onScheduleSelectionChanged(Schedule schedule) {
    setState(() {
        if (_selectedScheduleIds.contains(schedule.id)) {
            _selectedScheduleIds.remove(schedule.id);
        } else {
            _selectedScheduleIds.add(schedule.id);
        }
    });
  }

  // week_calendar_view や month_calendar_view 内の予定タップ時の統一処理
  void _onScheduleTapped(Schedule schedule) async {
    if (schedule.id.startsWith('temporary')) return;

    if (_isSelectionMode) {
      _onScheduleSelectionChanged(schedule);
      return;
    }

    final result = await showScheduleDetailPopup(context, schedule);
    if (result == null) return;

    if (result == 'edit') {
      setState(() {
        _creationMode = CreationMode.full;
        _temporarySchedule = schedule;
        _isCreatingSchedule = true;
      });
    } else if (result == 'deleted') {
      await _removeSchedule(schedule.id);
    }
  }

  void _onFABTapped() {
    setState(() {
      _creationMode = CreationMode.full;
      _temporarySchedule = Schedule.empty().copyWith(id: 'temporary_schedule_${DateTime.now().millisecondsSinceEpoch}');
      _isCreatingSchedule = true;
    });
  }

  void _setDisplayMode(CalendarDisplayMode mode) {
    if (!mounted) return;
    setState(() { _displayMode = mode; });
    _updateScheduleList();
  }

  void _onDateDoubleTappedInMonthView(DateTime date) {
    final now = DateTime.now();
    final startOfWeekToday = now.subtract(Duration(days: now.weekday % 7));
    final startOfWeekTarget = date.subtract(Duration(days: date.weekday % 7));
    final weekDifference = DateUtils.dateOnly(startOfWeekTarget).difference(DateUtils.dateOnly(startOfWeekToday)).inDays ~/ 7;
    final targetWeekPage = initialPageOffset + weekDifference;

    setState(() {
      _displayMode = CalendarDisplayMode.week;
      _focusedDate = date;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(_weekPageController.hasClients) _weekPageController.jumpToPage(targetWeekPage);
    });
  }

  void _onMonthPageChanged(int page) {
    final monthOffset = page - initialPageOffset;
    if (!mounted) return;
    setState(() {
      _focusedDate = DateTime(DateTime.now().year, DateTime.now().month + monthOffset);
      _updateScheduleList();
      _checkIfTodayButtonNeeded();
    });
  }

  void _onWeekPageChanged(int page) {
    final weekOffset = page - initialPageOffset;
    if (!mounted) return;
    setState(() {
      final now = DateTime.now();
      final startOfWeekToday = now.subtract(Duration(days: now.weekday % 7));
      _focusedDate = DateUtils.dateOnly(startOfWeekToday).add(Duration(days: weekOffset * 7));
      _updateScheduleList();
      _checkIfTodayButtonNeeded();
    });
  }

  void _checkIfTodayButtonNeeded() {
     final now = DateTime.now();
     bool needed;
     if (_displayMode == CalendarDisplayMode.month) {
       needed = !(_focusedDate.year == now.year && _focusedDate.month == now.month);
     } else {
       final startOfWeekForFocused = _focusedDate.subtract(Duration(days: _focusedDate.weekday % 7));
       final startOfWeekForNow = now.subtract(Duration(days: now.weekday % 7));
       needed = !DateUtils.isSameDay(startOfWeekForFocused, startOfWeekForNow);
     }

    if (_showTodayButton != needed) {
      if (mounted) setState(() => _showTodayButton = needed);
    }
  }

  void _returnToToday() {
    _focusedDate = DateTime.now();
    _monthPageController.jumpToPage(initialPageOffset);
    _weekPageController.jumpToPage(initialPageOffset);
    _updateScheduleList();
    _checkIfTodayButtonNeeded();
  }

  void _showYearMonthWeekPicker() async {
     final DateTime? picked = await showDatePicker(
      context: context, initialDate: _focusedDate,
      firstDate: DateTime(2000), lastDate: DateTime(2100),
      locale: const Locale('ja'),
    );
     if (picked != null && picked != _focusedDate) {
        if (_displayMode == CalendarDisplayMode.month) {
            final now = DateTime.now();
            final monthDifference = (picked.year - now.year) * 12 + picked.month - now.month;
            _monthPageController.jumpToPage(initialPageOffset + monthDifference);
        } else {
            final now = DateTime.now();
            final startOfWeekToday = now.subtract(Duration(days: now.weekday % 7));
            final startOfWeekTarget = picked.subtract(Duration(days: picked.weekday % 7));
            final weekDifference = DateUtils.dateOnly(startOfWeekTarget).difference(DateUtils.dateOnly(startOfWeekToday)).inDays ~/ 7;
            _weekPageController.jumpToPage(initialPageOffset + weekDifference);
        }
    }
  }


  @override
  Widget build(BuildContext context) {
    final displaySchedules = _temporarySchedule == null
        ? [..._schedules]
        : [..._schedules.where((s) => s.id != _temporarySchedule!.id), _temporarySchedule!];
    
    // MonthCalendarView に渡すために、選択中のIDリストからScheduleオブジェクトのリストを作成
    final selectedSchedulesForMonthView = _schedules
            .where((s) => _selectedScheduleIds.contains(s.id))
            .toList();

    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          IndexedStack(
            index: _displayMode.index,
            children: [
              MonthCalendarView(
                pageController: _monthPageController,
                onPageChanged: _onMonthPageChanged,
                onDateDoubleTapped: _onDateDoubleTappedInMonthView,
                isSelectionMode: _isSelectionMode,
                schedules: _schedules,
                // --- month_calendar_view の仕様に合わせたプロパティを渡す ---
                selectedSchedules: selectedSchedulesForMonthView,
                onSelectionChanged: _onScheduleSelectionChanged,
              ),
              WeekCalendarView(
                key: ValueKey('week_${_focusedDate.toIso8601String()}'),
                pageController: _weekPageController,
                onPageChanged: _onWeekPageChanged,
                focusedDate: _focusedDate,
                schedules: displaySchedules,
                onGridTapped: _onGridTappedInWeekView,
                onScheduleTapped: _onScheduleTapped,
                onScheduleUpdated: _updateSchedule,
                onTemporaryScheduleUpdated: _onTemporaryScheduleUpdated,
                isSelectionMode: _isSelectionMode,
                selectedScheduleIds: _selectedScheduleIds,
              ),
            ],
          ),
          if (_isCreatingSchedule)
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: _creationMode == CreationMode.quick ? 0.25 : 0.9,
              minChildSize: 0.15,
              maxChildSize: 0.9,
              expand: true,
              builder: (BuildContext context, ScrollController scrollController) {
                return ScheduleCreationSheet(
                  key: ValueKey(_temporarySchedule?.id),
                  scrollController: scrollController,
                  schedule: _temporarySchedule ?? Schedule.empty().copyWith(date: _focusedDate),
                  onClose: _onCreationSheetClosed,
                );
              },
            ),
        ],
      ),
      floatingActionButton: _isCreatingSchedule ? null : _buildFloatingActionButtons(),
      bottomSheet: _isSelectionMode ? _buildSelectionActionBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String title;
    if (_displayMode == CalendarDisplayMode.month) {
        title = DateFormat('yyyy年 M月', 'ja').format(_focusedDate);
    } else {
        final startOfWeek = _focusedDate.subtract(Duration(days: _focusedDate.weekday % 7));
        int weekNumber = (startOfWeek.day / 7).ceil();
        title = "${DateFormat('yyyy年 M月', 'ja').format(_focusedDate)} 第$weekNumber週";
    }

    return AppBar(
      leading: IconButton(
        icon: Icon(_displayMode == CalendarDisplayMode.month
            ? Icons.view_week_outlined
            : Icons.calendar_view_month_outlined),
        tooltip: _displayMode == CalendarDisplayMode.month ? '週表示に切り替え' : '月表示に切り替え',
        onPressed: () {
          _setDisplayMode(_displayMode == CalendarDisplayMode.month
              ? CalendarDisplayMode.week
              : CalendarDisplayMode.month);
        },
      ),
      title: Center(
        child: GestureDetector(
          onTap: _showYearMonthWeekPicker,
          child: Text(title, style: const TextStyle(fontSize: 18)),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isSelectionMode ? Icons.cancel_outlined : Icons.check_box_outline_blank),
          tooltip: _isSelectionMode ? '選択をキャンセル' : '予定を選択',
          onPressed: () => setState(() {
            _isSelectionMode = !_isSelectionMode;
            if (!_isSelectionMode) _selectedScheduleIds.clear();
          }),
        ),
        IconButton(icon: const Icon(Icons.settings_outlined), tooltip: '設定', onPressed: () {}),
        IconButton(icon: const Icon(Icons.person_add_outlined), tooltip: 'フレンド追加', onPressed: () {}),
      ],
      elevation: 1,
    );
  }

  Widget? _buildFloatingActionButtons() {
    return Stack(
      children: [
        if (_showTodayButton)
          Positioned(
            bottom: 80,
            right: 4,
            child: FloatingActionButton.small(
              heroTag: 'today_button',
              onPressed: _returnToToday,
              tooltip: '今日に戻る',
              child: const Icon(Icons.today),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'filter_button', mini: true,
                tooltip: '絞り込み',
                onPressed: () => showDialog(context: context, builder: (_) => const FilterDialog()),
                child: const Icon(Icons.filter_list),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: 'add_button',
                tooltip: '新しい予定',
                onPressed: _onFABTapped,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomAppBarTheme.color,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,-2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('削除'),
            onPressed: _selectedScheduleIds.isEmpty
              ? null
              : () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('${_selectedScheduleIds.length}件の予定を削除'),
                      content: const Text('選択した予定を完全に削除しますか？この操作は元に戻せません。'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
                        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('削除', style: TextStyle(color: Colors.red))),
                      ],
                    )
                  );
                  if (confirm ?? false) {
                     await _removeMultipleSchedules(_selectedScheduleIds);
                  }
                },
          ),
          TextButton.icon(icon: const Icon(Icons.share_outlined), label: const Text('共有'), onPressed: _selectedScheduleIds.isEmpty ? null : () {}),
          TextButton.icon(icon: const Icon(Icons.group_add_outlined), label: const Text('招待'), onPressed: _selectedScheduleIds.isEmpty ? null : () {}),
        ],
      ),
    );
  }
}