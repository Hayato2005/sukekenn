import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
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

class _WeekViewScreenState extends State<WeekViewScreen> with TickerProviderStateMixin {
  // --- State Variables ---
  late PageController _pageController;
  late DateTime _focusedDate;
  List<Map<String, dynamic>> _schedules = [];
  Map<int, List<List<Map<String, dynamic>>>> _layoutedSchedules = {};

  // スクロールとアニメーション用
  late AnimationController _flingController;
  Offset _scrollOffset = Offset.zero;
  double _scale = 1.0;
  double _baseScale = 1.0;
  Timer? _autoScrollTimer;

  // ★★★ 不足していた変数を追加 ★★★
  bool _isSelectionMode = false;
  final List<Map<String, dynamic>> _selectedSchedules = [];

  // ドラッグ＆新規作成用
  Map<String, dynamic>? _draggedSchedule;
  Offset? _dragPosition;
  Map<String, dynamic>? _newEventPlaceholder;
  
  // --- Constants ---
  final double _hourHeight = 60.0;
  final double _timeColumnWidth = 50.0;
  final int _initialWeekIndex = 5000;

  @override
  void initState() {
    super.initState();
    _focusedDate = widget.startDate;
    _pageController = PageController(initialPage: _initialWeekIndex);
    _generateFakeSchedules();

    _flingController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _flingController.addListener(() {
      setState(() {
        final totalHeight = 24 * _hourHeight * _scale;
        final viewHeight = context.size?.height ?? totalHeight;
        final maxScrollY = totalHeight > viewHeight ? totalHeight - viewHeight : 0;
        // アニメーション中にスクロール範囲を制限
        _scrollOffset = Offset(_scrollOffset.dx, _flingController.value.clamp(-maxScrollY, 0.0).toDouble());
      });
    });
  }

  @override
  void dispose() {
    _flingController.dispose();
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // --- Data & Event Handlers ---
  void _generateFakeSchedules() {
    //...(変更なし)
    final random = Random();
    _schedules = List.generate(15, (index) {
      final startHour = random.nextDouble() * 22;
      final duration = random.nextDouble() * 2 + 1;
      final dayOffset = random.nextInt(7);
      return {
        'id': '${_focusedDate.millisecondsSinceEpoch}_${random.nextInt(99999)}',
        'title': '予定 ${index + 1}', 'day': dayOffset, 'startHour': startHour, 'endHour': startHour + duration, 'duration': duration,
        'color': Colors.accents[random.nextInt(Colors.accents.length)],
      };
    });
    _calculateLayout();
  }

  void _calculateLayout() {
    //...(変更なし)
    _layoutedSchedules.clear();
    for (var day = 0; day < 7; day++) {
      var daySchedules = _schedules.where((s) => s['day'] == day).toList();
      daySchedules.sort((a, b) => (a['startHour'] as double).compareTo(b['startHour'] as double));
      var groups = <List<Map<String, dynamic>>>[];
      for (var schedule in daySchedules) {
        bool placed = false;
        for (var group in groups) {
          if (group.every((s) => (schedule['startHour'] >= s['endHour']) || (schedule['endHour'] <= s['startHour']))) {
            group.add(schedule); placed = true; break;
          }
        }
        if (!placed) { groups.add([schedule]); }
      }
      _layoutedSchedules[day] = groups;
    }
  }

  void _showScheduleCreationSheet({bool isPeekView = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: isPeekView ? 0.25 : 0.9,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        builder: (_, controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: ScheduleCreationSheet(controller: controller),
        ),
      ),
    ).whenComplete(() => setState(() => _newEventPlaceholder = null));
  }
  
  // ★★★ 不足していたメソッドを追加 ★★★
  void _showFilterDialog() {
    showDialog(context: context, builder: (context) => const FilterDialog());
  }

  void _handleFling(DragEndDetails details, Size viewSize) {
    _autoScrollTimer?.cancel();
    final velocity = details.velocity.pixelsPerSecond;

    // 縦方向のフリック
    final simulationY = FrictionSimulation(0.2, _scrollOffset.dy, velocity.dy);
    final totalHeight = 24 * _hourHeight * _scale;
    final viewHeight = viewSize.height;
    final maxScrollY = totalHeight > viewHeight ? totalHeight - viewHeight : 0;
    
    final animationY = Tween<double>(begin: _scrollOffset.dy, end: _scrollOffset.dy)
        .chain(CurveTween(curve: Curves.decelerate))
        .animate(_flingController);
    
    _flingController.animateWith(simulationY);
  }
  
  // ★★★ 自動スクロール処理 ★★★
  void _handleAutoScroll(Offset globalPosition) {
    final screenHeight = MediaQuery.of(context).size.height;
    const scrollZoneHeight = 80.0;
    const scrollSpeed = 15.0;

    if (globalPosition.dy < scrollZoneHeight + 100) {
      _autoScrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (timer) {
        final newOffset = _scrollOffset.dy + scrollSpeed;
        setState(() => _scrollOffset = Offset(_scrollOffset.dx, min(0, newOffset)));
      });
    } else if (globalPosition.dy > screenHeight - scrollZoneHeight) {
      final maxScrollY = (24 * _hourHeight * _scale) - (context.size?.height ?? 800) + 200;
       _autoScrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (timer) {
        final newOffset = _scrollOffset.dy - scrollSpeed;
        setState(() => _scrollOffset = Offset(_scrollOffset.dx, max(-maxScrollY, newOffset)));
      });
    } else {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildWeekHeader(),
      drawer: const WeekDrawer(),
      bottomNavigationBar: buildBottomNavigationBar(context),
      body: Column(
        children: [
          buildWeekDayBar(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  final weekOffset = page - _initialWeekIndex;
                  _focusedDate = widget.startDate.add(Duration(days: weekOffset * 7));
                  _generateFakeSchedules();
                });
              },
              itemBuilder: (context, index) {
                return buildSingleWeekView();
              },
            ),
          ),
          if (_isSelectionMode) buildActionBar(),
        ],
      ),
      floatingActionButton: buildFloatingActionButtons(),
    );
  }

  Widget buildSingleWeekView() {
    // (buildSingleWeekViewの中身は、前回提案した手動スクロールではなく、PageView + SingleChildScrollViewの安定した実装に戻します)
    // (これにより斜めスクロールはできませんが、カクつきなく安定した操作が可能です)
    return GestureDetector(
      onTap: () => setState(() => _newEventPlaceholder = null),
      onScaleStart: (details) => _baseScale = _scale,
      onScaleUpdate: (details) => setState(() => _scale = (_baseScale * details.verticalScale).clamp(0.5, 4.0)),
      onTapUp: (details) {
        if (_isSelectionMode || _newEventPlaceholder != null) return;
        final dayWidth = (MediaQuery.of(context).size.width - _timeColumnWidth) / 7;
        final day = ((details.localPosition.dx - _timeColumnWidth) / dayWidth).floor().clamp(0, 6);
        final hour = (details.localPosition.dy / (_hourHeight * _scale));
        
        setState(() {
          _newEventPlaceholder = {
            'day': day, 'startHour': (hour * 4).round() / 4.0, 'endHour': (hour * 4).round() / 4.0 + 1.0,
          };
        });
        _showScheduleCreationSheet(isPeekView: true);
      },
      child: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dayWidth = (constraints.maxWidth - _timeColumnWidth) / 7;
            return DragTarget<Map<String, dynamic>>(
              onWillAcceptWithDetails: (details) => true,
              onMove: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                setState(() => _dragPosition = renderBox.globalToLocal(details.offset));
              },
              onLeave: (data) => setState(() => _dragPosition = null),
              onAcceptWithDetails: (details) {
                 final renderBox = context.findRenderObject() as RenderBox;
                final localOffset = renderBox.globalToLocal(details.offset);
                
                final day = ((localOffset.dx - _timeColumnWidth) / dayWidth).floor().clamp(0, 6);
                final hour = (localOffset.dy / (_hourHeight * _scale));
                
                setState(() {
                  final schedule = details.data;
                  schedule['day'] = day;
                  schedule['startHour'] = (hour * 4).round() / 4.0;
                  schedule['endHour'] = schedule['startHour'] + schedule['duration'];
                  _draggedSchedule = null;
                  _dragPosition = null;
                  _calculateLayout();
                });
              },
              builder: (context, candidateData, rejectedData) {
                return SizedBox(
                  height: 24 * _hourHeight * _scale,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    buildTimeColumn(),
                    Expanded(child: Stack(clipBehavior: Clip.none, children: [
                      buildGrid(), ...buildScheduleLayout(dayWidth),
                      if (_newEventPlaceholder != null) buildNewEventPlaceholder(dayWidth),
                      if (_dragPosition != null) buildDragFeedback(),
                    ])),
                  ]),
                );
              },
            );
          },
        ),
      ),
    );
  }
  
  List<Widget> buildScheduleLayout(double dayWidth) {
    // (変更なし)
    List<Widget> positionedWidgets = []; _layoutedSchedules.forEach((day, groups) { final groupWidth = dayWidth / groups.length; for (int i = 0; i < groups.length; i++) { final group = groups[i]; final leftOffset = i * groupWidth; for (var schedule in group) { final isBeingDragged = _draggedSchedule != null && _draggedSchedule!['id'] == schedule['id']; final scheduleWidget = Container(width: groupWidth, padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: (schedule['color'] as Color).withOpacity(0.8), borderRadius: BorderRadius.circular(4)), child: Text(schedule['title'], style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)); positionedWidgets.add(Positioned(key: ValueKey(schedule['id']), top: (schedule['startHour'] as double) * _hourHeight * _scale, left: (schedule['day'] as int) * dayWidth + leftOffset, height: (schedule['duration'] as double) * _hourHeight * _scale, width: groupWidth, child: Draggable<Map<String, dynamic>>(data: schedule, onDragStarted: () => setState(() => _draggedSchedule = schedule), onDragEnd: (details) => setState(() { _draggedSchedule = null; _dragPosition = null; }), feedback: Material(color: Colors.transparent, child: SizedBox(height: (schedule['duration'] as double) * _hourHeight * _scale, width: groupWidth, child: scheduleWidget)), childWhenDragging: Opacity(opacity: 0.3, child: scheduleWidget), child: Visibility(visible: !isBeingDragged, child: GestureDetector(onTap: () {}, child: scheduleWidget))))); } } }); return positionedWidgets;
  }
  
  Widget buildNewEventPlaceholder(double dayWidth) {
    // (変更なし)
    final placeholder = _newEventPlaceholder!; final top = (placeholder['startHour'] as double) * _hourHeight * _scale; final height = ((placeholder['endHour'] as double) - (placeholder['startHour'] as double)) * _hourHeight * _scale; Widget handle = Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.blue, width: 2))); return Positioned(top: top, left: (placeholder['day'] as int) * dayWidth, height: height, width: dayWidth, child: Stack(clipBehavior: Clip.none, children: [Container(margin: const EdgeInsets.all(1), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), border: Border.all(color: Colors.blue, width: 1.5), borderRadius: BorderRadius.circular(4))), Positioned(top: -8, left: 0, right: 0, child: Align(alignment: Alignment.center, child: GestureDetector(onVerticalDragUpdate: (details) { setState(() { final newStartHour = placeholder['startHour'] + details.delta.dy / (_hourHeight * _scale); if (newStartHour < placeholder['endHour']) placeholder['startHour'] = (newStartHour * 4).round() / 4.0; }); }, child: handle))), Positioned(bottom: -8, left: 0, right: 0, child: Align(alignment: Alignment.center, child: GestureDetector(onVerticalDragUpdate: (details) { setState(() { final newEndHour = placeholder['endHour'] + details.delta.dy / (_hourHeight * _scale); if (newEndHour > placeholder['startHour']) placeholder['endHour'] = (newEndHour * 4).round() / 4.0; }); }, child: handle)))]));
  }
  
  // ★★★ ドラッグ中の補助線と時間表示（領域修正） ★★★
  Widget buildDragFeedback() {
    if (_draggedSchedule == null || _dragPosition == null) return const SizedBox.shrink();
    
    final hour = (_dragPosition!.dy / (_hourHeight * _scale));
    final snappedHour = (hour * 4).round() / 4.0;
    final timeString = DateFormat('H:mm').format(DateTime(2025,1,1).add(Duration(minutes: (snappedHour * 60).round())));

    return Positioned(
      top: snappedHour * _hourHeight * _scale,
      left: -_timeColumnWidth, // 時間列の左端に合わせる
      width: MediaQuery.of(context).size.width, // 全幅を確保
      child: Row(
        children: [
          // 動的な時間ラベル
          SizedBox(
            width: _timeColumnWidth,
            child: Text(timeString, textAlign: TextAlign.right, style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          // 点線
          Expanded(child: CustomPaint(painter: DottedLinePainter())),
        ],
      ),
    );
  }

  // --- その他のUI構築・ヘルパーメソッド ---
  AppBar buildWeekHeader() { final weekStartDate = _focusedDate.subtract(Duration(days: _focusedDate.weekday % 7)); return AppBar(title: Text('${DateFormat('yyyy年 M月').format(weekStartDate)} 第${((weekStartDate.day - 1) / 7).floor() + 1}週'), actions: [ IconButton(icon: Icon(_isSelectionMode ? Icons.cancel : Icons.check_box_outline_blank), onPressed: () => setState(() { _isSelectionMode = !_isSelectionMode; if (!_isSelectionMode) _selectedSchedules.clear(); })), IconButton(icon: const Icon(Icons.settings), onPressed: () {}), IconButton(icon: const Icon(Icons.person_add), onPressed: () {})]); }
  Widget buildWeekDayBar() { const weekDayChars = ['日', '月', '火', '水', '木', '金', '土']; final weekStartDate = _focusedDate.subtract(Duration(days: _focusedDate.weekday % 7)); return Container(padding: const EdgeInsets.symmetric(vertical: 4.0), decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade300))), child: Row(children: [SizedBox(width: _timeColumnWidth), Expanded(child: Row(children: List.generate(7, (index) { final date = weekStartDate.add(Duration(days: index)); final today = DateTime.now(); final bool isToday = date.year == today.year && date.month == today.month && date.day == today.day; final color = isToday ? Theme.of(context).primaryColor : (date.weekday == DateTime.sunday ? Colors.red : Colors.black87); return Expanded(child: Column(children: [Text(weekDayChars[date.weekday % 7], style: TextStyle(fontSize: 12, color: color)), const SizedBox(height: 2), CircleAvatar(radius: 14, backgroundColor: isToday ? Theme.of(context).primaryColor : Colors.transparent, child: Text('${date.day}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isToday ? Colors.white : color)))])); }))) ])); }
  Widget buildTimeColumn() { return SizedBox(width: _timeColumnWidth, child: Column(children: List.generate(24, (index) => SizedBox(height: _hourHeight * _scale, child: Stack(clipBehavior: Clip.none, children: [if (index > 0) Positioned(top: -8, right: 8, child: Text('${index.toString().padLeft(2, '0')}:00', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)))])))));}
  Widget buildGrid() { return Column(children: List.generate(24, (hour) => Expanded(child: Row(children: List.generate(7, (day) => Expanded(child: Container(decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300), left: BorderSide(color: Colors.grey.shade200))))))))));}
  Widget buildFloatingActionButtons() {return Column(mainAxisSize: MainAxisSize.min, children: [ FloatingActionButton(heroTag: 'week_filter_button', mini: true, onPressed: _showFilterDialog, child: const Icon(Icons.filter_list)), const SizedBox(height: 16), Opacity(opacity: _isSelectionMode ? 0.0 : 1.0, child: IgnorePointer(ignoring: _isSelectionMode, child: FloatingActionButton(heroTag: 'week_add_button', onPressed: () => _showScheduleCreationSheet(isPeekView: false), child: const Icon(Icons.add))))]); }
  BottomNavigationBar buildBottomNavigationBar(BuildContext context) { return BottomNavigationBar(type: BottomNavigationBarType.fixed, items: const [ BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'), BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'チャット'), BottomNavigationBarItem(icon: Icon(Icons.group), label: 'フレンド'), BottomNavigationBarItem(icon: Icon(Icons.search), label: 'マッチング'), BottomNavigationBarItem(icon: Icon(Icons.person), label: 'マイページ')], currentIndex: 0, onTap: (index) { if (index == 0) { Navigator.of(context).pop(); } else { Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => MainScreen(initialIndex: index)), (Route<dynamic> route) => false); } }, selectedItemColor: Theme.of(context).primaryColor, unselectedItemColor: Colors.grey); }
  void showWeekPicker() async { if (_isSelectionMode) return; int selectedYear = _focusedDate.year; int selectedMonth = _focusedDate.month; int selectedWeek = ((_focusedDate.day - 1) / 7).floor() + 1; await showDialog(context: context, builder: (context) => AlertDialog(title: const Text('年月週を選択'), content: SizedBox(height: 150, child: Row(children: [ Expanded(child: ListWheelScrollView.useDelegate(itemExtent: 50, onSelectedItemChanged: (index) => selectedYear = 2000 + index, controller: FixedExtentScrollController(initialItem: selectedYear - 2000), childDelegate: ListWheelChildBuilderDelegate(builder: (context, index) => Center(child: Text('${2000 + index}年')), childCount: 101))), Expanded(child: ListWheelScrollView.useDelegate(itemExtent: 50, onSelectedItemChanged: (index) => selectedMonth = index + 1, controller: FixedExtentScrollController(initialItem: selectedMonth - 1), childDelegate: ListWheelChildBuilderDelegate(builder: (context, index) => Center(child: Text('${index + 1}月')), childCount: 12))), Expanded(child: ListWheelScrollView.useDelegate(itemExtent: 50, onSelectedItemChanged: (index) => selectedWeek = index + 1, controller: FixedExtentScrollController(initialItem: selectedWeek - 1), childDelegate: ListWheelChildBuilderDelegate(builder: (context, index) => Center(child: Text('第${index + 1}週')), childCount: 6)))])), actions: [ TextButton(onPressed: () { final newDate = DateTime(selectedYear, selectedMonth, 1); final page = ((newDate.difference(widget.startDate).inDays / 7).round() + 5000); _pageController.jumpToPage(page); Navigator.pop(context); }, child: const Text('完了'))])); }
  Widget buildActionBar() { return Container(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), color: Colors.grey[200], child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ TextButton.icon(icon: const Icon(Icons.delete), label: const Text('削除'), onPressed: _selectedSchedules.isEmpty ? null : () {}), TextButton.icon(icon: const Icon(Icons.share), label: const Text('共有'), onPressed: _selectedSchedules.isEmpty ? null : () {}), TextButton.icon(icon: const Icon(Icons.group_add), label: const Text('招待'), onPressed: _selectedSchedules.isEmpty ? null : () {})])); }
}

// ★★★ 不足していたクラスを追加 ★★★
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1;
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}