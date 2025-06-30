// lib/presentation/pages/calendar/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/event.dart';
import '../../providers/app_settings_provider.dart';
import '../mypage/my_page.dart'; // マイページへの遷移用 (フォント設定のため)
import 'widgets/calendar_event_cell.dart'; // 新規作成
import 'widgets/event_detail_popup.dart'; // 新規作成
import 'widgets/event_form.dart'; // 新規作成

// イベントのリストを保持するプロバイダ (Firestoreなどからロード)
final eventsProvider = StateProvider<List<Event>>((ref) {
  // TODO: ここでFirestoreからイベントデータをロードするロジックを実装
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

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 週表示時のズーム倍率
  double _hourHeightMultiplier = 1.0; // デフォルト倍率

  // イベントを日付ごとにグループ化するヘルパー関数
  List<Event> _getEventsForDay(DateTime day) {
    final allEvents = ref.watch(eventsProvider);
    return allEvents.where((event) => isSameDay(event.startTime, day)).toList();
  }

  // 背景色に応じた文字色を返すヘルパー
  Color _getAdaptiveTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
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
            // 月/週/自由日付切替を表示
            _showCalendarFormatSwitcher(context);
          },
        ),
        title: Text(
          '${DateFormat('yyyy年M月').format(_focusedDay)} '
          '${_calendarFormat == CalendarFormat.week ? '第${_getWeekNumber(_focusedDay)}週' : ''}',
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {
            // 設定画面へ（マイページにフォント設定があるので、例としてマイページに遷移）
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MyPage()));
          }),
          IconButton(icon: const Icon(Icons.person_add), onPressed: () { /* フレンド追加 */ }),
          if (!selectionMode) // 通常モードの場合のみ表示
            IconButton(
              icon: const Icon(Icons.check_box_outlined), // ☑️ボタン
              onPressed: () {
                ref.read(selectionModeProvider.notifier).state = true; // 選択モードON
              },
            )
          else // 選択モードの場合
            IconButton(
              icon: const Icon(Icons.close), // ✖️キャンセルボタン
              onPressed: () {
                ref.read(selectionModeProvider.notifier).state = false; // 選択モードOFF
                ref.read(selectedEventIdsProvider.notifier).state = {}; // 選択を解除
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 月表示の場合のみTableCalendar
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
                      _focusedDay = focusedDay; // update `_focusedDay` as well
                    });
                    // シングルタップ：その日の予定を含むポップアップを表示
                    _showEventsPopup(context, selectedDay, selectionMode, selectedEventIds);
                  },
                  onHeaderTapped: (focusedDay) {
                    // 年月週ピッカー
                    _showMonthYearPicker(context, focusedDay);
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: _getEventsForDay,
                  calendarBuilders: CalendarBuilders(
                    // 各日のセルをカスタマイズ
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
                    // 曜日バーはTableCalendarが固定してくれる
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    // ヘッダー背景色はマッチング種別で変化する仕様を予定 -> アプリ全体のテーマで制御
                  ),
                  calendarStyle: CalendarStyle(
                    isTodayHighlighted: false, // カスタムビルダーでハイライト
                    selectedDecoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    todayDecoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2), // 今日は青枠
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    outsideDaysVisible: false,
                  ),
                ),
              // 週表示の場合 (後で実装)
              if (_calendarFormat == CalendarFormat.week)
                Expanded(
                  child: _buildWeekView(context, appSettings.calendarFontSizeMultiplier),
                ),
            ],
          ),

          // 右下の追加ボタンとフィルターボタン
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: Column(
              children: [
                // 週表示でのみ「＋予定追加」ボタンを表示
                if (_calendarFormat == CalendarFormat.week)
                  FloatingActionButton(
                    heroTag: 'addEvent',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EventFormPage())); // 予定追加画面へ
                    },
                    child: const Icon(Icons.add),
                  ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'filterEvents',
                  onPressed: () {
                    _showFilterPopup(context); // フィルターポップアップを表示
                  },
                  child: const Icon(Icons.filter_list),
                ),
              ],
            ),
          ),
          // 今日へ戻るボタン (月表示で今日から1ヶ月以上離れている場合のみ)
          if (_calendarFormat == CalendarFormat.month && !_isCurrentMonth(_focusedDay) && _isMonthFarFromToday(_focusedDay))
            Positioned(
              bottom: (_calendarFormat == CalendarFormat.week) ? 100.0 : 80.0, // 週表示なら追加ボタンの上、月表示ならフィルターボタンの上
              right: 16.0,
              child: FloatingActionButton.small(
                heroTag: 'goToToday',
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
                color: Theme.of(context).primaryColor.withOpacity(0.8), // テーマカラーを適用
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
                        // TODO: 共有アクション
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${selectedEventIds.length}件の予定を共有します。')),
                        );
                      },
                      tooltip: '共有',
                    ),
                    IconButton(
                      icon: const Icon(Icons.group_add, color: Colors.white),
                      onPressed: () {
                        // TODO: 招待アクション
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

    Color backgroundColor = isOutside ? Colors.transparent : (isDarkMode ? Colors.grey[900] : Colors.white);
    Color borderColor = Colors.grey[300]!;
    if (isDarkMode) {
      borderColor = Colors.grey[700]!;
    }
    if (isToday) {
      borderColor = Colors.blue; // 今日の日付セルは青枠
    }
    if (isSelected && !isToday) { // 今日でなければ選択された日付はプライマリカラー枠
      borderColor = Theme.of(context).primaryColor;
    }

    // セルの背景色をマッチング種別で変化させるロジックは、個々の予定ではなくカレンダー全体のテーマ設定で考慮
    // ここでは個々の予定の背景色をセル内に表示する形
    
    // 最大表示件数を動的に調整
    // 画面サイズとフォントサイズ倍率に応じて調整するが、ここではシンプルに固定値
    final maxEventsPerCell = (MediaQuery.of(context).size.width < 350 || fontSizeMultiplier > 1.0) ? 2 : 3;

    return GestureDetector(
      onDoubleTap: () {
        // 月表示でダブルタップ：その週を週表示に切り替え
        if (_calendarFormat == CalendarFormat.month) {
          ref.read(calendarFormatProvider.notifier).state = CalendarFormat.week;
          setState(() {
            _focusedDay = day; // 選択した日を含む週にフォーカス
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
                physics: const NeverScrollableScrollPhysics(), // スクロールさせない
                itemCount: events.length > maxEventsPerCell ? maxEventsPerCell + 1 : events.length,
                itemBuilder: (context, index) {
                  if (index == maxEventsPerCell) {
                    // +N件表示
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
                        // 選択モードの場合、チェックボックスのON/OFFを切り替える
                        ref.read(selectedEventIdsProvider.notifier).update((state) {
                          if (isEventSelected) {
                            state.remove(event.id);
                          } else {
                            state.add(event.id);
                          }
                          return state;
                        });
                      } else {
                        // 通常モードの場合、予定詳細ポップアップを表示
                        _showEventDetailPopup(context, event);
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

  // 週表示のダミー実装 (後で本格的に実装)
  Widget _buildWeekView(BuildContext context, double fontSizeMultiplier) {
    return Column(
      children: [
        // 曜日バーはTableCalendarと共通化できるが、ここでは簡易的に
        Container(
          height: 30,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final day = DateTime.now().add(Duration(days: index - DateTime.now().weekday + 1));
              return Expanded(
                child: Center(
                  child: Text(
                    DateFormat('E', 'ja').format(day), // 例: 月, 火
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * fontSizeMultiplier),
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              // 左右スワイプで週移動
              setState(() {
                if (details.primaryVelocity! < 0) {
                  _focusedDay = _focusedDay.add(const Duration(days: 7));
                } else if (details.primaryVelocity! > 0) {
                  _focusedDay = _focusedDay.subtract(const Duration(days: 7));
                }
              });
            },
            // ここに週のタイムライン表示とドラッグによる予定追加ロジックを実装
            // SingleChildScrollView + Stack + CustomPaintなどで描画する
            child: ListView.builder(
              itemCount: 1, // ダミー
              itemBuilder: (context, index) {
                return Container(
                  height: 1200 * _hourHeightMultiplier, // 24時間表示の高さ（ズームで変化）
                  color: Colors.grey[100],
                  child: Center(child: Text('週表示のコンテンツ (開発中)\n長押しで予定追加やズームできます。', style: TextStyle(fontSize: 16 * fontSizeMultiplier))),
                );
              },
            ),
          ),
        ),
        // ズームボタン (週表示中のみ)
        if (_calendarFormat == CalendarFormat.week)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 8.0),
              child: FloatingActionButton.small(
                heroTag: 'zoomReset',
                onPressed: () {
                  setState(() {
                    _hourHeightMultiplier = 1.0; // ズームリセット
                  });
                },
                child: const Icon(Icons.zoom_out_map),
              ),
            ),
          ),
      ],
    );
  }

  // 週番号を取得するヘルパー関数
  int _getWeekNumber(DateTime date) {
    // 厳密な週番号計算は複雑なので、簡易版
    return ((date.day + (DateTime(date.year, date.month, 1).weekday - 1)) / 7).ceil();
  }

  // 日付タップ時のポップアップ
  void _showEventsPopup(BuildContext context, DateTime day, bool selectionMode, Set<String> selectedIds) {
    final events = _getEventsForDay(day);
    showDialog(
      context: context,
      builder: (dialogContext) { // BuildContext名を変更してスコープ問題を回避
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
                      // ダイアログを再描画するためにsetStateが必要な場合があるが、
                      // Providerの更新で自動的にWidgetが再描画されるはず
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
                      color: event.isFixed ? Colors.grey : null, // 固定予定は薄く
                    ),
                  ),
                  onTap: () {
                    if (selectionMode) {
                      // チェックボックスのON/OFF
                      ref.read(selectedEventIdsProvider.notifier).update((state) {
                        if (isEventSelected) {
                          state.remove(event.id);
                        } else {
                          state.add(event.id);
                        }
                        return state;
                      });
                    } else {
                      Navigator.pop(dialogContext); // ポップアップを閉じる
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
                // 選択された日を週表示で開く
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
                ref.read(selectionModeProvider.notifier).state = false; // 選択モードOFF
                ref.read(selectedEventIdsProvider.notifier).state = {}; // 選択を解除
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
            // 例: マッチング種別フィルター
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
            // TODO: ジャンル、期間などのフィルター
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
                // TODO: 自由範囲選択UI
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
        // TODO: スライド式ピッカーやキーボード入力式のUIを実装
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
                    // 選択された年月を _focusedDay に反映
                    // setState(() {
                    //   _focusedDay = selectedDate;
                    // });
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
}