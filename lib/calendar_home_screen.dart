// lib/calendar_home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:sukekenn/core/models/event.dart'; // パスを修正
import 'package:sukekenn/add_event_screen.dart'; // 予定追加画面 (event_form.dart に移行を推奨)
import 'package:sukekenn/presentation/pages/calendar/widgets/calendar_event_cell.dart'; // パスを修正
import 'package:sukekenn/presentation/pages/calendar/widgets/event_detail_popup.dart'; // パスを修正
import 'package:sukekenn/presentation/pages/calendar/widgets/event_form.dart'; // パスを修正
import 'package:sukekenn/presentation/providers/app_settings_provider.dart'; // パスを修正
import 'package:sukekenn/my_page_screen.dart'; // MyPageScreen のインポートを追加
import 'package:sukekenn/week_view_screen.dart'; // WeekViewScreen のインポートを追加


// イベントのリストを保持するプロバイダ (Firestoreなどからロード)
final eventsProvider = StateProvider<List<Event>>((ref) {
  // TODO: ここでFirestoreからイベントデータをロードするロジックを実装
  // 現在のユーザーUIDを取得してwhere句に利用するなど
  // 例: FirebaseAuth.instance.currentUser?.uid など
  // 仮のデータ
  return [
    Event(
      id: '1',
      title: 'フレンドとの飲み会',
      ownerId: 'user1',
      startTime: DateTime.now().add(const Duration(hours: 18)),
      endTime: DateTime.now().add(const Duration(hours: 20)),
      type: EventType.friend,
      isFixed: false,
    ),
    Event(
      id: '2',
      title: '誰でもマッチング',
      ownerId: 'user2',
      startTime: DateTime.now().add(const Duration(days: 2, hours: 10)),
      endTime: DateTime.now().add(const Duration(days: 2, hours: 12)),
      type: EventType.anyone,
      isFixed: false,
    ),
    Event(
      id: '3',
      title: '異性とのランチ',
      ownerId: 'user3',
      startTime: DateTime.now().add(const Duration(days: 5, hours: 13)),
      endTime: DateTime.now().add(const Duration(days: 5, hours: 14)),
      type: EventType.oppositeSex,
      isFixed: false,
    ),
    Event(
      id: '4',
      title: '定例ミーティング',
      ownerId: 'user1',
      startTime: DateTime.now().add(const Duration(days: 1, hours: 9)),
      endTime: DateTime.now().add(const Duration(days: 1, hours: 10)),
      type: EventType.fixed,
      isFixed: true,
      backgroundColor: Colors.blueGrey, // 固定予定のカスタム色
      textColor: Colors.white,
    ),
    Event(
      id: '5',
      title: '複数イベントの日',
      ownerId: 'user1',
      startTime: DateTime.now().add(const Duration(days: 0, hours: 10)),
      endTime: DateTime.now().add(const Duration(days: 0, hours: 11)),
      type: EventType.anyone,
      isFixed: false,
    ),
    Event(
      id: '6',
      title: 'もう一個の予定',
      ownerId: 'user1',
      startTime: DateTime.now().add(const Duration(days: 0, hours: 12)),
      endTime: DateTime.now().add(const Duration(days: 0, hours: 13)),
      type: EventType.anyone,
      isFixed: false,
    ),
    Event(
      id: '7',
      title: 'まだ別の日程',
      ownerId: 'user1',
      startTime: DateTime.now().add(const Duration(days: 0, hours: 14)),
      endTime: DateTime.now().add(const Duration(days: 0, hours: 15)),
      type: EventType.anyone,
      isFixed: false,
    ),
    Event(
      id: '8',
      title: '固定予定テスト',
      ownerId: 'user1',
      startTime: DateTime.now().add(const Duration(days: 1, hours: 15)),
      endTime: DateTime.now().add(const Duration(days: 1, hours: 16)),
      type: EventType.fixed,
      isFixed: true,
    ),
  ];
});

// カレンダー表示モードを管理するプロバイダ
final calendarFormatProvider = StateProvider<CalendarFormat>((ref) => CalendarFormat.month);

// 選択モードの状態を管理するプロバイダ
final selectionModeProvider = StateProvider<bool>((ref) => false);
// 選択された予定のIDを管理するプロバイダ
final selectedEventIdsProvider = StateProvider<Set<String>>((ref) => {});

class CalendarHomeScreen extends ConsumerStatefulWidget { // ConsumerStatefulWidgetに変更
  const CalendarHomeScreen({super.key});

  @override
  ConsumerState<CalendarHomeScreen> createState() => _CalendarHomeScreenState(); // ConsumerStateに変更
}

class _CalendarHomeScreenState extends ConsumerState<CalendarHomeScreen> { // ConsumerStateを継承
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 週表示時のズーム倍率 (後で本格的に実装)
  double _hourHeightMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // _fetchEvents() のロジックは eventsProvider に移行することを検討
  }

  // イベントを日付ごとにグループ化するヘルパー関数
  List<Event> _getEventsForDay(DateTime day) {
    final allEvents = ref.watch(eventsProvider); // Riverpodからイベント取得
    return allEvents.where((event) => isSameDay(event.startTime, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    _calendarFormat = ref.watch(calendarFormatProvider); // プロバイダから現在のフォーマットを取得
    final appSettings = ref.watch(appSettingsProvider);
    final selectionMode = ref.watch(selectionModeProvider);
    final selectedEventIds = ref.watch(selectedEventIdsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu), // ≡ボタン
          onPressed: () {
            _showCalendarFormatSwitcher(context);
          },
        ),
        title: Text(
          '${DateFormat('yyyy年M月', 'ja').format(_focusedDay)} '
          '${_calendarFormat == CalendarFormat.week ? '第${_getWeekNumber(_focusedDay)}週' : ''}',
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MyPageScreen())); // MyPageScreenに遷移
          }),
          IconButton(icon: const Icon(Icons.person_add), onPressed: () { /* フレンド追加 */ }),
          if (!selectionMode)
            IconButton(
              icon: const Icon(Icons.check_box_outlined), // ☑️ボタン
              onPressed: () {
                ref.read(selectionModeProvider.notifier).state = true;
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close), // ✖️キャンセルボタン
              onPressed: () {
                ref.read(selectionModeProvider.notifier).state = false;
                ref.read(selectedEventIdsProvider.notifier).state = {};
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 曜日バー (table_calendarが自動で表示するため不要になるが、週表示は別途実装)
              if (_calendarFormat == CalendarFormat.week)
                buildWeekBar(), // 週表示は独自のヘッダーが必要になる場合
              
              // 月表示の場合はTableCalendar
              if (_calendarFormat == CalendarFormat.month)
                TableCalendar<Event>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _showEventsPopup(context, selectedDay, selectionMode, selectedEventIds);
                  },
                  onHeaderTapped: (focusedDay) {
                    _showMonthYearPicker(context, focusedDay);
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: _getEventsForDay,
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      return _buildDayCellContent(context, day, focusedDay, _getEventsForDay(day), selectionMode, selectedEventIds, appSettings.calendarFontSizeMultiplier);
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return _buildDayCellContent(context, day, focusedDay, _getEventsForDay(day), selectionMode, selectedEventIds, appSettings.calendarFontSizeMultiplier, isToday: true);
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return _buildDayCellContent(context, day, focusedDay, _getEventsForDay(day), selectionMode, selectedEventIds, appSettings.calendarFontSizeMultiplier, isSelected: true);
                    },
                    outsideBuilder: (context, day, focusedDay) {
                      return _buildDayCellContent(context, day, focusedDay, _getEventsForDay(day), selectionMode, selectedEventIds, appSettings.calendarFontSizeMultiplier, isOutside: true);
                    },
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarStyle: CalendarStyle(
                    isTodayHighlighted: false,
                    selectedDecoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    todayDecoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    outsideDaysVisible: false,
                  ),
                ),
              // 週表示の場合 (WeekViewScreenに遷移またはここに直接実装)
              if (_calendarFormat == CalendarFormat.week)
                Expanded(
                  child: _buildWeekView(context, appSettings.calendarFontSizeMultiplier),
                ),
            ],
          ),

          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_calendarFormat == CalendarFormat.week) // 週表示でのみ「＋予定追加」
                  FloatingActionButton(
                    heroTag: 'addEventBtn',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EventFormPage()), // EventFormPageに遷移
                      );
                    },
                    child: const Icon(Icons.add),
                  ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'filterBtn',
                  onPressed: () {
                    _showFilterPopup(context);
                  },
                  child: const Icon(Icons.filter_list),
                ),
              ],
            ),
          ),
          if (_calendarFormat == CalendarFormat.month && !_isCurrentMonth(_focusedDay) && _isMonthFarFromToday(_focusedDay))
            Positioned(
              bottom: (_calendarFormat == CalendarFormat.week) ? 120.0 : 80.0, // 週表示なら追加ボタンの上、月表示ならフィルターボタンの上
              right: 16.0,
              child: FloatingActionButton.small(
                heroTag: 'goToTodayBtn',
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = DateTime.now();
                  });
                },
                child: const Icon(Icons.today),
              ),
            ),
          // 選択モード時のアクションバー
          if (selectionMode && selectedEventIds.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Theme.of(context).primaryColor.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () {
                        _confirmDeleteSelectedEvents(context, selectedEventIds);
                      },
                      tooltip: '削除',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${selectedEventIds.length}件の予定を共有します。')),
                        );
                      },
                      tooltip: '共有',
                    ),
                    IconButton(
                      icon: const Icon(Icons.group_add, color: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${selectedEventIds.length}件の予定に招待します。')),
                        );
                      },
                      tooltip: '招待',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 各日セルの内容を構築するウィジェット
  Widget _buildDayCellContent(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
    List<Event> events,
    bool selectionMode,
    Set<String> selectedEventIds,
    double fontSizeMultiplier, {
    bool isToday = false,
    bool isSelected = false,
    bool isOutside = false,
  }) {
    final appSettings = ref.watch(appSettingsProvider);
    final isDarkMode = appSettings.isDarkMode;

    Color backgroundColor = isOutside ? Colors.transparent : (isDarkMode ? Colors.grey[900]! : Colors.white);
    Color borderColor = Colors.grey[300]!;
    if (isDarkMode) {
      borderColor = Colors.grey[700]!;
    }
    if (isToday) {
      borderColor = Colors.blue;
    }
    if (isSelected && !isToday) {
      borderColor = Theme.of(context).primaryColor;
    }

    final maxEventsPerCell = (MediaQuery.of(context).size.width < 350 || fontSizeMultiplier > 1.0) ? 2 : 3;

    return GestureDetector(
      onDoubleTap: () {
        if (_calendarFormat == CalendarFormat.month) {
          ref.read(calendarFormatProvider.notifier).state = CalendarFormat.week;
          setState(() {
            _focusedDay = day;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: isToday || isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 12 * fontSizeMultiplier,
                  color: isOutside ? Colors.grey : (isDarkMode ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length > maxEventsPerCell ? maxEventsPerCell + 1 : events.length,
                itemBuilder: (context, index) {
                  if (index == maxEventsPerCell) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 4.0, right: 4.0, bottom: 2.0),
                      child: Text(
                        '+${events.length - maxEventsPerCell}件',
                        style: TextStyle(fontSize: 9 * fontSizeMultiplier, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final event = events[index];
                  final isEventSelected = selectionMode && selectedEventIds.contains(event.id);
                  return GestureDetector(
                    onTap: () {
                      if (selectionMode) {
                        ref.read(selectedEventIdsProvider.notifier).update((state) {
                          if (isEventSelected) {
                            state.remove(event.id);
                          } else {
                            state.add(event.id);
                          }
                          return state;
                        });
                      } else {
                        showDialog(
                          context: context,
                          builder: (ctx) => EventDetailPopup(event: event),
                        );
                      }
                    },
                    child: CalendarEventCell(
                      event: event,
                      fontSizeMultiplier: fontSizeMultiplier,
                      selectionMode: selectionMode,
                      isSelected: isEventSelected,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 週表示のダミー実装 (WeekViewScreenに遷移または本格的に実装)
  Widget _buildWeekView(BuildContext context, double fontSizeMultiplier) {
    // 現在の_focusedDayに基づいてWeekViewScreenに遷移
    // WeekViewScreen には表示する週の開始日を渡す
    // ここでは直接Widgetを返すのではなく、遷移を促すUIを置くか、
    // WeekViewScreen のロジックをここに統合するか選択
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('週表示のコンテンツ (開発中)', style: TextStyle(fontSize: 16 * fontSizeMultiplier)),
          ElevatedButton(
            onPressed: () {
              // WeekViewScreenに遷移
              Navigator.push(context, MaterialPageRoute(builder: (context) => WeekViewScreen(startDate: _focusedDay)));
            },
            child: Text('WeekViewScreenへ'),
          ),
          // ズームボタン (週表示中のみ)
          // WeekViewScreen 側で管理
        ],
      ),
    );
  }


  // 週番号を取得するヘルパー関数
  int _getWeekNumber(DateTime date) {
    return ((date.day + (DateTime(date.year, date.month, 1).weekday - 1)) / 7).ceil();
  }

  // 日付タップ時のポップアップ (既存の showDayTimeline を置き換え)
  void _showEventsPopup(BuildContext context, DateTime day, bool selectionMode, Set<String> selectedIds) {
    final events = _getEventsForDay(day);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(DateFormat('yyyy年M月d日').format(day) + 'の予定'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final isEventSelected = selectionMode && selectedIds.contains(event.id);
                return ListTile(
                  leading: selectionMode ? Checkbox(
                    value: isEventSelected,
                    onChanged: (bool? value) {
                      ref.read(selectedEventIdsProvider.notifier).update((state) {
                        if (value == true) {
                          state.add(event.id);
                        } else {
                          state.remove(event.id);
                        }
                        return state;
                      });
                    },
                  ) : CircleAvatar(
                    backgroundColor: event.backgroundColor,
                    child: Text(
                      event.title.substring(0, 1),
                      style: TextStyle(color: event.textColor),
                    ),
                  ),
                  title: Text(event.title),
                  subtitle: Text(
                    '${event.type.displayName} - ${DateFormat('HH:mm').format(event.startTime)}',
                    style: TextStyle(
                      color: event.isFixed ? Colors.grey : null,
                    ),
                  ),
                  onTap: () {
                    if (selectionMode) {
                      ref.read(selectedEventIdsProvider.notifier).update((state) {
                        if (isEventSelected) {
                          state.remove(event.id);
                        } else {
                          state.add(event.id);
                        }
                        return state;
                      });
                    } else {
                      Navigator.pop(dialogContext);
                      showDialog(
                        context: context,
                        builder: (ctx) => EventDetailPopup(event: event),
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(calendarFormatProvider.notifier).state = CalendarFormat.week;
                setState(() {
                  _focusedDay = day;
                });
              },
              child: const Text('この週を表示'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(context, MaterialPageRoute(builder: (context) => EventFormPage(initialDate: day)));
              },
              child: const Text('この日に追加'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  // 選択した予定の一括削除確認
  void _confirmDeleteSelectedEvents(BuildContext context, Set<String> selectedIds) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('選択した予定の削除'),
          content: Text('${selectedIds.length}件の予定を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                // TODO: 選択された予定をFirestoreから一括削除するロジック
                ref.read(eventsProvider.notifier).state = ref.read(eventsProvider)
                    .where((e) => !selectedIds.contains(e.id))
                    .toList();
                ref.read(selectionModeProvider.notifier).state = false;
                ref.read(selectedEventIdsProvider.notifier).state = {};
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${selectedIds.length}件の予定を削除しました。')),
                );
              },
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  // フィルターポップアップ
  void _showFilterPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        // TODO: フィルター条件選択UI
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('フィルター設定'), onTap: () {}),
            CheckboxListTile(
              title: const Text('フレンド'),
              value: true,
              onChanged: (bool? value) {},
            ),
            CheckboxListTile(
              title: const Text('誰でも'),
              value: true,
              onChanged: (bool? value) {},
            ),
            CheckboxListTile(
              title: const Text('異性'),
              value: true,
              onChanged: (bool? value) {},
            ),
            CheckboxListTile(
              title: const Text('固定予定'),
              value: true,
              onChanged: (bool? value) {},
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('適用'),
            ),
          ],
        );
      },
    );
  }

  // カレンダー表示形式切り替えメニュー
  void _showCalendarFormatSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('月表示'),
              onTap: () {
                ref.read(calendarFormatProvider.notifier).state = CalendarFormat.month;
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('週表示'),
              onTap: () {
                ref.read(calendarFormatProvider.notifier).state = CalendarFormat.week;
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('自由範囲'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // 年月週ピッカー
  void _showMonthYearPicker(BuildContext context, DateTime initialDate) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('年月選択ピッカー (${DateFormat('yyyy年M月').format(initialDate)})'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('決定'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 現在の月かどうかを判定
  bool _isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // 今日から1ヶ月以上離れているかを判定 (月表示用)
  bool _isMonthFarFromToday(DateTime date) {
    final now = DateTime.now();
    final diffMonths = (date.year - now.year) * 12 + date.month - now.month;
    return diffMonths.abs() >= 1;
  }

  // buildAppBar() はそのまま利用できます
  PreferredSizeWidget buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: Container(
        height: 50,
        color: Colors.grey[200],
        child: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _showMonthYearPicker(context, _focusedDay), // showYearMonthPickerを_showMonthYearPickerに置き換え
                child: Center(
                  child: Text(
                    DateFormat('yyyy年M月', 'ja').format(_focusedDay), // displayedMonthを_focusedDayに置き換え
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.settings), onPressed: () { /* 設定画面へ */ }),
            IconButton(icon: const Icon(Icons.person_add), onPressed: () { /* フレンド追加 */ }),
          ],
        ),
      ),
    );
  }

  Widget buildWeekBar() {
    return Container(
      height: 30,
      color: Colors.grey[100],
      child: Row(
        children: List.generate(7, (index) {
          const weekDays = ['日', '月', '火', '水', '木', '金', '土'];
          return Expanded(
            child: Center(
              child: Text(
                weekDays[index],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ),
    );
  }

  // buildDrawer() はそのまま利用できますが、週表示の遷移先は WeekViewScreen に修正されています
  Widget buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(child: Text('表示切替')),
          ListTile(
            title: const Text('週表示'),
            onTap: () {
              Navigator.pop(context);
              ref.read(calendarFormatProvider.notifier).state = CalendarFormat.week; // Riverpodで週表示に切り替え
              // 週表示に遷移 (既存の WeekViewScreen を利用)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WeekViewScreen(startDate: _focusedDay.subtract(Duration(days: _focusedDay.weekday % 7))),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('月表示'),
            onTap: () {
              Navigator.pop(context);
              ref.read(calendarFormatProvider.notifier).state = CalendarFormat.month; // Riverpodで月表示に切り替え
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('月表示に切替')));
            },
          ),
          ListTile(
            title: const Text('自由範囲選択'),
            subtitle: Text('${DateFormat('yyyy/MM/dd').format(_focusedDay)}〜${DateFormat('yyyy/MM/dd').format(_focusedDay.add(const Duration(days: 6)))}'), // displayedMonthを_focusedDayに置き換え
            onTap: () async {
              final pickedRange = await showDateRangePicker(
                context: context,
                initialDateRange: DateTimeRange(start: _focusedDay, end: _focusedDay.add(const Duration(days: 6))), // displayedMonthを_focusedDayに置き換え
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedRange != null) {
                final rangeDays = pickedRange.end.difference(pickedRange.start).inDays + 1;
                if (rangeDays > 42) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('43日以上は選択できません')),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${rangeDays}日間を表示')));
                  // TODO: 自由範囲表示ロジック
                }
              }
            },
          ),
        ],
      ),
    );
  }
}