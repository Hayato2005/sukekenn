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

class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> with SingleTickerProviderStateMixin {
  final _repo = ScheduleRepository();
  Map<String, Schedule> _allSchedulesMap = {};

  CalendarDisplayMode _displayMode = CalendarDisplayMode.week;
  DateTime _focusedDate = DateTime.now();
  bool _isSelectionMode = false;
  final List<String> _selectedScheduleIds = [];
  bool _showTodayButton = false;

  late PageController _monthPageController;
  late PageController _weekPageController;
  static const int initialPageOffset = 5000;

  // --- スケジュールシート関連の状態 ---
  Schedule? _temporarySchedule; // 仮予定の状態
  PersistentBottomSheetController? _quickSheetController;

  @override
  void initState() {
    super.initState();
    _monthPageController = PageController(initialPage: initialPageOffset);
    _weekPageController = PageController(initialPage: initialPageOffset);
    _loadSchedules();
    _checkIfTodayButtonNeeded();
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    _weekPageController.dispose();
    super.dispose();
  }

  // --- データ操作メソッド ---
  Future<void> _loadSchedules() async {
    await _repo.loadSchedules();
    _updateScheduleMap();
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
    await _repo.saveSchedules(_allSchedulesMap.values.toList());
    _updateScheduleMap();
  }
  void _updateScheduleMap() {
    if (!mounted) return;
    setState(() {
      _allSchedulesMap = _repo.getAllSchedules();
    });
  }


  // --- UIイベントハンドラ ---
  void _onScheduleTapped(Schedule schedule) async {
    if (_temporarySchedule != null) return; 

    if (_isSelectionMode) {
      setState(() {
        if (_selectedScheduleIds.contains(schedule.id)) {
          _selectedScheduleIds.remove(schedule.id);
        } else {
          _selectedScheduleIds.add(schedule.id);
        }
      });
      return;
    }

    final result = await showScheduleDetailPopup(context, schedule);
    if (result == null) return;

    if (result == 'edit') {
      _showFullCreationSheet(schedule);
    } else if (result == 'deleted') {
      await _removeSchedule(schedule.id);
    }
  }

  void _onFABTapped() {
    final now = DateTime.now();
    final schedule = Schedule.empty().copyWith(
      id: 'temporary_schedule_${now.millisecondsSinceEpoch}',
      date: _focusedDate,
      startHour: _snapToMinutes(now.hour.toDouble() + now.minute/60.0, 15),
      endHour: _snapToMinutes(now.hour.toDouble() + now.minute/60.0 + 1, 15),
    );
    _showFullCreationSheet(schedule);
  }

  // --- 当初の仕様に戻したシート表示ロジック ---

  // クイック登録：非モーダルなボトムシートを表示
  void _handleTemporaryScheduleCreated(Schedule schedule) {
    _hideQuickSheet();
    
    setState(() {
      _temporarySchedule = schedule;
    });

    _quickSheetController = showBottomSheet(
      context: context,
      enableDrag: true,
      builder: (context) {
        return GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy < -5) {
              _switchToFullScreen();
            }
          },
          child: ScheduleSheetHeader(
            key: ValueKey(_temporarySchedule!.id),
            schedule: _temporarySchedule!,
            onTitleChanged: (newTitle) {
              if (!mounted) return;
              setState(() {
                _temporarySchedule = _temporarySchedule!.copyWith(title: newTitle);
              });
            },
            onClose: _hideQuickSheet,
            onSave: () async {
              if (_temporarySchedule != null && _temporarySchedule!.title.isNotEmpty) {
                await _addSchedule(_temporarySchedule!.copyWith(
                    id: DateTime.now().millisecondsSinceEpoch.toString()
                ));
                _hideQuickSheet();
              }
            },
            onTapHeader: _switchToFullScreen,
          ),
        );
      },
    );

    _quickSheetController?.closed.whenComplete(() {
      if (mounted && _quickSheetController != null) {
        _hideQuickSheet(fromController: false);
      }
    });
  }

  void _switchToFullScreen() {
      final scheduleToEdit = _temporarySchedule;
      _hideQuickSheet();
      _showFullCreationSheet(scheduleToEdit);
  }

  // フル登録・編集：モーダルボトムシートを表示
  void _showFullCreationSheet(Schedule? schedule) async {
    if (schedule == null) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          builder: (_, scrollController) => ScheduleCreationSheet(
            scrollController: scrollController,
            schedule: schedule,
          ),
      )
    );

    if (result == null) return;
    
    // ★★★★★ 修正点 ★★★★★
    // フル表示からドラッグダウンで戻ってきた場合の処理
    final isSwitchingToQuickMode = result['isSwitchingToQuickMode'] as bool?;
    if (isSwitchingToQuickMode == true) {
      final returnedSchedule = result['savedSchedule'] as Schedule?;
      if (returnedSchedule != null) {
         // 正しい週にジャンプしてから仮予定を作成
        _jumpToWeekOfDate(returnedSchedule.date ?? DateTime.now());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleTemporaryScheduleCreated(returnedSchedule);
        });
      }
      return;
    }
    
    _handleSheetResult(result);
  }
  
  void _hideQuickSheet({bool fromController = true}) {
      if (fromController && _quickSheetController != null) {
        _quickSheetController!.close();
      }
      _quickSheetController = null;
      if (mounted) {
        setState(() {
          _temporarySchedule = null;
        });
      }
  }
  
  void _handleSheetResult(Map<String, dynamic> result) async {
    final savedSchedule = result['savedSchedule'] as Schedule?;
    final isDeleted = result['isDeleted'] as bool?;

    if (isDeleted == true && savedSchedule != null) {
       await _removeSchedule(savedSchedule.id);
    } else if (savedSchedule != null) {
      final isNew = savedSchedule.id.startsWith('temporary');
      if (isNew) {
        await _addSchedule(savedSchedule.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString()));
      } else {
        await _updateSchedule(savedSchedule);
      }
    }
  }
  
  double _snapToMinutes(double hour, int minutes) {
    final totalMinutes = hour * 60;
    final snappedTotalMinutes = (totalMinutes / minutes).round() * minutes;
    return snappedTotalMinutes / 60.0;
  }

  // --- ナビゲーションと表示モード関連 ---
  void _setDisplayMode(CalendarDisplayMode mode) {
    if (!mounted) return;
    setState(() { 
      _displayMode = mode; 
      _checkIfTodayButtonNeeded(); 
    });
  }
  void _onDateDoubleTappedInMonthView(DateTime date) {
    _jumpToWeekOfDate(date);
    setState(() {
      _displayMode = CalendarDisplayMode.week;
    });
  }
  
  void _jumpToWeekOfDate(DateTime date) {
    final now = DateTime.now();
    final startOfWeekToday = now.subtract(Duration(days: now.weekday % 7));
    final startOfWeekTarget = date.subtract(Duration(days: date.weekday % 7));
    final weekDifference = DateUtils.dateOnly(startOfWeekTarget).difference(DateUtils.dateOnly(startOfWeekToday)).inDays ~/ 7;
    final targetWeekPage = initialPageOffset + weekDifference;
    
    if (_weekPageController.hasClients) {
       _weekPageController.jumpToPage(targetWeekPage);
    }
    
    setState(() {
      _focusedDate = date;
      _checkIfTodayButtonNeeded();
    });
  }

  void _onMonthPageChanged(int page) {
    final monthOffset = page - initialPageOffset;
    if (!mounted) return;
    setState(() {
      _focusedDate = DateTime(DateTime.now().year, DateTime.now().month + monthOffset);
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
      _checkIfTodayButtonNeeded();
    });
  }
  void _onWeekHeaderTapped(DateTime date) {
    final monthOffset = (date.year - DateTime.now().year) * 12 + date.month - DateTime.now().month;
    final targetMonthPage = initialPageOffset + monthOffset;
    
    setState(() {
      _displayMode = CalendarDisplayMode.month;
      _focusedDate = date;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(_monthPageController.hasClients) _monthPageController.jumpToPage(targetMonthPage);
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
    if (_displayMode == CalendarDisplayMode.month) {
      _monthPageController.jumpToPage(initialPageOffset);
    } else {
      _weekPageController.jumpToPage(initialPageOffset);
    }
  }
  void _showYearMonthWeekPicker() async {
     final DateTime? picked = await showDatePicker(
      context: context, initialDate: _focusedDate,
      firstDate: DateTime(2000), lastDate: DateTime(2100),
      locale: const Locale('ja'),
    );
     if (picked != null && !DateUtils.isSameDay(picked, _focusedDate)) {
        if (_displayMode == CalendarDisplayMode.month) {
            final now = DateTime.now();
            final monthDifference = (picked.year - now.year) * 12 + picked.month - now.month;
            _monthPageController.jumpToPage(initialPageOffset + monthDifference);
        } else {
            _jumpToWeekOfDate(picked);
        }
    }
  }

  // --- ビルドメソッド ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _displayMode.index,
        children: [
          _buildMonthView(),
          _buildWeekView(),
        ],
      ),
      floatingActionButton: _quickSheetController != null ? null : _buildFloatingActionButtons(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String title;
    if (_displayMode == CalendarDisplayMode.month) {
        title = DateFormat('yyyy年 M月', 'ja').format(_focusedDate);
    } else {
        final dayOfYear = int.parse(DateFormat("D").format(_focusedDate));
        final weekOfYear = ((dayOfYear - 1) / 7).ceil();
        title = "${DateFormat('yyyy年 M月', 'ja').format(_focusedDate)} 第${weekOfYear}週";
    }

    return AppBar(
      leading: IconButton(
        icon: Icon(_displayMode == CalendarDisplayMode.month
            ? Icons.view_week_outlined
            : Icons.calendar_view_month_outlined),
        tooltip: _displayMode == CalendarDisplayMode.month ? '週表示に切り替え' : '月表示に切り替え',
        onPressed: () => _setDisplayMode(_displayMode == CalendarDisplayMode.month ? CalendarDisplayMode.week : CalendarDisplayMode.month),
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

  Widget _buildMonthView() {
      final monthDate = DateTime(_focusedDate.year, _focusedDate.month);
      final schedulesForMonth = _allSchedulesMap.values.where((s) {
        return s.date?.year == monthDate.year && s.date?.month == monthDate.month;
      }).toList();
      final selectedSchedulesForMonthView = schedulesForMonth
              .where((s) => _selectedScheduleIds.contains(s.id))
              .toList();

      return MonthCalendarView(
        pageController: _monthPageController,
        onPageChanged: _onMonthPageChanged,
        onDateDoubleTapped: _onDateDoubleTappedInMonthView,
        isSelectionMode: _isSelectionMode,
        schedules: schedulesForMonth,
        selectedSchedules: selectedSchedulesForMonthView,
        onSelectionChanged: (schedule) => _onScheduleTapped(schedule),
        onScheduleTapped: (schedule) => _onScheduleTapped(schedule),
      );
  }

  Widget _buildWeekView() {
    return PageView.builder(
      // ★★★★★ 修正点 ★★★★★
      physics: _temporarySchedule != null ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
      controller: _weekPageController,
      onPageChanged: _onWeekPageChanged,
      itemBuilder: (context, index) {
        final weekOffset = index - initialPageOffset;
        final now = DateTime.now();
        final startOfWeekToday = now.subtract(Duration(days: now.weekday % 7));
        final startOfWeek = DateUtils.dateOnly(startOfWeekToday).add(Duration(days: weekOffset * 7));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));

        final schedulesForWeek = _allSchedulesMap.values.where((s) {
            return s.date != null && !s.date!.isBefore(startOfWeek) && s.date!.isBefore(endOfWeek);
        }).toList();

        return WeekCalendarView(
          key: ValueKey(startOfWeek.toIso8601String()), 
          startOfWeek: startOfWeek,
          schedules: schedulesForWeek,
          onScheduleTapped: _onScheduleTapped,
          onScheduleUpdated: (updatedSchedule) async {
             await _updateSchedule(updatedSchedule);
             _hideQuickSheet();
          },
          onWeekHeaderTapped: _onWeekHeaderTapped,
          onPageRequested: (direction) {
            if (direction < 0) {
              _weekPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
            } else {
              _weekPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
            }
          },
          temporarySchedule: _temporarySchedule,
          onTemporaryScheduleCreated: _handleTemporaryScheduleCreated,
          onTemporaryScheduleUpdated: (schedule) => setState(() => _temporarySchedule = schedule),
          onTemporaryScheduleCleared: _hideQuickSheet,
        );
      },
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
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
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
}