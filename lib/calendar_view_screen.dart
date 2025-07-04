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

enum CalendarDisplayMode { month, week }

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
  final List<Schedule> _selectedSchedules = [];
  bool _showTodayButton = false;

  late PageController _monthPageController;
  late PageController _weekPageController;
  static const int initialPageOffset = 5000;

  // ★★★ 新規予定作成フローの刷新 ★★★
  // 仮の予定を管理する
  Schedule? _temporarySchedule; 
  // 作成シートが表示されているかどうかの状態
  bool _isCreatingSchedule = false; 

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
  
  Future<void> _persistChanges() async {
    final allSchedules = _repo.getSchedulesForRange(DateTime(2000), DateTime(2100));
    await _repo.saveSchedules(allSchedules);
    _updateScheduleList();
  }
  
  void _updateScheduleList() {
    if (!mounted) return;
    setState(() {
      final startOfWeek = _focusedDate.subtract(Duration(days: _focusedDate.weekday % 7));
      if (_displayMode == CalendarDisplayMode.month) {
        _schedules = _repo.getSchedulesForMonth(_focusedDate);
      } else {
        _schedules = _repo.getSchedulesForWeek(startOfWeek);
      }
    });
  }


  // === UIイベントハンドラ群 ===

  // ★ 修正: 週表示の空白タップで「仮の予定」を作成し、シートを表示する
  void _onGridTappedInWeekView(DateTime tappedTime) {
    // 既に何かを作成中、または選択モードの場合は何もしない
    if (_temporarySchedule != null || _isCreatingSchedule || _isSelectionMode) return;

    setState(() {
      _temporarySchedule = Schedule.empty().copyWith(
        id: 'temporary_schedule',
        date: tappedTime,
        startHour: tappedTime.hour + tappedTime.minute / 60.0,
        endHour: (tappedTime.hour + 1) + tappedTime.minute / 60.0,
        color: Colors.orange.withOpacity(0.7),
        title: '(タイトル未入力)'
      );
      _isCreatingSchedule = true; // シートを表示状態にする
    });
  }
  
  // ★ 新規: 仮予定がドラッグ/リサイズされたときに呼ばれる
  void _onTemporaryScheduleUpdated(Schedule updatedTemporarySchedule) {
    setState(() {
      _temporarySchedule = updatedTemporarySchedule;
    });
  }

  // ★ 新規: 作成シートが閉じられた or 保存されたときに呼ばれる
  void _onCreationSheetClosed({Schedule? savedSchedule}) async {
    if (savedSchedule != null) {
      if(savedSchedule.id == 'deleted'){
         // 削除の場合は何もしない（IDでの削除は別フロー）
      } else {
         // 保存された場合 (IDを新しいものに差し替える)
         await _addSchedule(savedSchedule.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString()));
      }
    }
    
    // どの道、仮予定は消す
    setState(() {
      _temporarySchedule = null;
      _isCreatingSchedule = false;
    });
  }
  
  void _onScheduleTappedInWeekView(Schedule schedule) async {
      if (schedule.id == 'temporary_schedule') return;

      final result = await showScheduleDetailPopup(context, schedule);
      
      if (result == 'deleted') {
        _removeSchedule(schedule.id);
      } else if (result is Schedule) {
        // 詳細ポップアップから編集画面に飛んで更新した場合の処理
        _updateSchedule(result);
      }
  }

  void _onFABTapped() async {
    // FABからはモーダルでフル表示
    final newSchedule = await showModalBottomSheet<dynamic>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => ScheduleCreationSheet(
        schedule: Schedule.empty().copyWith(date: _focusedDate),
        isQuickAddMode: false,
        onClose: ({Schedule? savedSchedule}) {
          Navigator.of(context).pop(savedSchedule);
        },
      ),
    );
    if (newSchedule is Schedule) {
      _addSchedule(newSchedule);
    }
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
    setState(() {
      _focusedDate = DateTime.now();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
        if(_monthPageController.hasClients) _monthPageController.jumpToPage(initialPageOffset);
        if(_weekPageController.hasClients) _weekPageController.jumpToPage(initialPageOffset);
    });
  }

  void _showYearMonthPicker() async {
    if (_displayMode != CalendarDisplayMode.month) return;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ja'),
    );
    if (picked != null && picked != _focusedDate) {
      final now = DateTime.now();
      final monthDifference = (picked.year - now.year) * 12 + picked.month - now.month;
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if(_monthPageController.hasClients) _monthPageController.jumpToPage(initialPageOffset + monthDifference);
       });
    }
  }


  @override
  Widget build(BuildContext context) {
    final displaySchedules = [..._schedules];
    if (_temporarySchedule != null) {
      displaySchedules.add(_temporarySchedule!);
    }
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: _buildAppBar(),
      // ★ `Stack` を使ってカレンダーと作成シートを重ねる
      body: Stack(
        children: [
          // --- メインのカレンダービュー ---
          Positioned.fill(
            child: IndexedStack(
              index: _displayMode.index,
              children: [
                MonthCalendarView(
                  pageController: _monthPageController,
                  onPageChanged: _onMonthPageChanged,
                  onDateDoubleTapped: _onDateDoubleTappedInMonthView,
                  isSelectionMode: _isSelectionMode,
                  selectedSchedules: _selectedSchedules,
                  onSelectionChanged: (schedule) {},
                  schedules: displaySchedules,
                ),
                WeekCalendarView(
                  key: ValueKey(_focusedDate.millisecondsSinceEpoch),
                  pageController: _weekPageController,
                  onPageChanged: _onWeekPageChanged,
                  focusedDate: _focusedDate,
                  schedules: displaySchedules,
                  onGridTapped: _onGridTappedInWeekView,
                  onScheduleTapped: _onScheduleTappedInWeekView,
                  onScheduleUpdated: _updateSchedule,
                  onTemporaryScheduleUpdated: _onTemporaryScheduleUpdated,
                ),
              ],
            ),
          ),
          // --- ★ 新規予定作成シート ★ ---
          // `AnimatedPositioned` を使って、画面下からのスライドイン/アウトを表現
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            // isCreatingScheduleがtrueなら画面内に、falseなら画面外に配置
            bottom: _isCreatingSchedule ? 0 : -(mediaQuery.size.height * 0.4), 
            left: 0,
            right: 0,
            height: mediaQuery.size.height * 0.4,
            child: ScheduleCreationSheet(
              key: ValueKey(_temporarySchedule?.id ?? 'empty'),
              schedule: _temporarySchedule ?? Schedule.empty().copyWith(date: _focusedDate),
              isQuickAddMode: true,
              onClose: _onCreationSheetClosed,
            ),
          ),
        ],
      ),
      floatingActionButton: _isCreatingSchedule ? null : _buildFloatingActionButtons(),
      bottomSheet: _isSelectionMode ? _buildActionBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String title = _displayMode == CalendarDisplayMode.month
        ? DateFormat('yyyy年 M月', 'ja').format(_focusedDate)
        : DateFormat('yyyy年 M月', 'ja').format(_focusedDate);

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
          onTap: _showYearMonthPicker,
          child: Text(title),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isSelectionMode ? Icons.cancel : Icons.check_box_outline_blank),
          onPressed: () => setState(() {
            _isSelectionMode = !_isSelectionMode;
            if (!_isSelectionMode) _selectedSchedules.clear();
          }),
        ),
        IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        IconButton(icon: const Icon(Icons.person_add), onPressed: () {}),
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
                onPressed: () => showDialog(context: context, builder: (_) => const FilterDialog()),
                child: const Icon(Icons.filter_list),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: 'add_button',
                onPressed: _onFABTapped,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton.icon(icon: const Icon(Icons.delete), label: const Text('削除'), onPressed: _selectedSchedules.isEmpty ? null : () {}),
          TextButton.icon(icon: const Icon(Icons.share), label: const Text('共有'), onPressed: _selectedSchedules.isEmpty ? null : () {}),
          TextButton.icon(icon: const Icon(Icons.group_add), label: const Text('招待'), onPressed: _selectedSchedules.isEmpty ? null : () {}),
        ],
      ),
    );
  }
}