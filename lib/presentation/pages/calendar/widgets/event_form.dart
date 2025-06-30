// lib/presentation/pages/calendar/widgets/event_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/core/models/event.dart'; // パスを修正
import 'package:sukekenn/presentation/pages/calendar/widgets/color_picker_bottom_sheet.dart'; // パスを修正

class EventFormPage extends ConsumerStatefulWidget {
  final Event? event; // 編集時は既存のイベントを渡す
  final DateTime? initialDate; // 新規作成時の初期日付

  const EventFormPage({super.key, this.event, this.initialDate});

  @override
  ConsumerState<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends ConsumerState<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late DateTime _startTime;
  late DateTime _endTime;
  late EventType _eventType;
  late bool _isFixed;
  late bool _isPublic;
  int? _minParticipants;
  int? _maxParticipants;
  DateTime? _recruitmentDeadline;
  String? _locationPrefecture;
  String? _locationCity;
  String? _locationRange;
  List<String> _genres = [];
  // TODO: EventMatchingConditionsのプロパティをStateとして持つ
  Color _backgroundColor = Colors.blue; // デフォルト色を適当に設定
  Color _textColor = Colors.white; // 自動設定されるので、初期値は適当でOK

  bool _isAdvancedSettingsExpanded = false; // 詳細設定の折りたたみ状態

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      // 編集モード
      _titleController = TextEditingController(text: widget.event!.title);
      _startTime = widget.event!.startTime;
      _endTime = widget.event!.endTime;
      _eventType = widget.event!.type;
      _isFixed = widget.event!.isFixed;
      _isPublic = widget.event!.isPublic;
      _minParticipants = widget.event!.minParticipants;
      _maxParticipants = widget.event!.maxParticipants;
      _recruitmentDeadline = widget.event!.recruitmentDeadline;
      _locationPrefecture = widget.event!.locationPrefecture;
      _locationCity = widget.event!.locationCity;
      _locationRange = widget.event!.locationRange;
      _genres = widget.event!.genres ?? [];
      _backgroundColor = widget.event!.backgroundColor;
      _textColor = widget.event!.textColor;
      // TODO: 詳細条件の初期化
    } else {
      // 新規作成モード
      _titleController = TextEditingController();
      final now = widget.initialDate ?? DateTime.now();
      _startTime = DateTime(now.year, now.month, now.day, now.hour, 0);
      _endTime = _startTime.add(const Duration(hours: 1)); // デフォルト1時間
      _eventType = EventType.anyone; // デフォルトは「誰でも」マッチング
      _isFixed = false;
      _isPublic = true;
      _backgroundColor = _eventType.defaultBackgroundColor;
      _textColor = _eventType.defaultTextColor;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // 背景色を選択し、自動で文字色を決定する
  void _selectBackgroundColor() async {
    final Color? pickedColor = await showModalBottomSheet<Color>(
      context: context,
      builder: (context) => ColorPickerBottomSheet(
        initialColor: _backgroundColor,
        // TODO: ユーザーのカスタムパレットや履歴を渡す
        // customColors: userPresets.map((p) => p.color).toList(),
      ),
    );

    if (pickedColor != null) {
      setState(() {
        _backgroundColor = pickedColor;
        _textColor = Event.getAdaptiveTextColor(pickedColor);
      });
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startTime : _endTime;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null) return;

    setState(() {
      final newDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      if (isStart) {
        _startTime = newDateTime;
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1)); // 終了時刻が開始時刻より前なら調整
        }
      } else {
        _endTime = newDateTime;
        if (_endTime.isBefore(_startTime)) {
          _startTime = _endTime.subtract(const Duration(hours: 1)); // 開始時刻が終了時刻より後なら調整
        }
      }
    });
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // 新しいイベントオブジェクトを作成または既存イベントを更新
      final newEvent = (widget.event?.copyWith(
        title: _titleController.text,
        startTime: _startTime,
        endTime: _endTime,
        type: _eventType,
        isFixed: _isFixed,
        isPublic: _isPublic,
        minParticipants: _minParticipants,
        maxParticipants: _maxParticipants,
        recruitmentDeadline: _recruitmentDeadline,
        locationPrefecture: _locationPrefecture,
        locationCity: _locationCity,
        locationRange: _locationRange,
        genres: _genres,
        backgroundColor: _backgroundColor,
        textColor: _textColor,
        // TODO: conditions, invitedFriends
      ) ?? Event(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // 仮ID。Firestoreでdoc().idを使うのがより良い
        ownerId: 'currentUserId', // TODO: 実際のユーザーIDを取得
        title: _titleController.text,
        startTime: _startTime,
        endTime: _endTime,
        type: _eventType,
        isFixed: _isFixed,
        isPublic: _isPublic,
        minParticipants: _minParticipants,
        maxParticipants: _maxParticipants,
        recruitmentDeadline: _recruitmentDeadline,
        locationPrefecture: _locationPrefecture,
        locationCity: _locationCity,
        locationRange: _locationRange,
        genres: _genres,
        backgroundColor: _backgroundColor,
        textColor: _textColor,
        // TODO: conditions, invitedFriends
      ));

      // TODO: Firestoreに保存/更新するロジック
      // 例: ref.read(eventsProvider.notifier).addEvent(newEvent);
      // または: ref.read(eventsProvider.notifier).updateEvent(newEvent);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.event == null ? '予定を作成しました' : '予定を更新しました'}')),
      );
      Navigator.pop(context); // 画面を閉じる
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? '予定を追加' : '予定を編集'),
        actions: [
          if (widget.event != null) // 編集モードで複製ボタン
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                // IDをnullにして新しい予定として扱う
                Navigator.push(context, MaterialPageRoute(builder: (context) => EventFormPage(event: widget.event!.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString())))); // 仮の新しいID
              },
              tooltip: '複製して追加',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEvent,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 0. 空き日程 or 固定予定を選択
            RadioListTile<bool>(
              title: const Text('空き日程（マッチング対象）'),
              value: false,
              groupValue: _isFixed,
              onChanged: (value) {
                setState(() {
                  _isFixed = value!;
                  _eventType = EventType.anyone; // 空き日程ならデフォルト誰でも
                  _backgroundColor = _eventType.defaultBackgroundColor;
                  _textColor = _eventType.defaultTextColor;
                });
              },
            ),
            RadioListTile<bool>(
              title: const Text('固定予定（自分用）'),
              value: true,
              groupValue: _isFixed,
              onChanged: (value) {
                setState(() {
                  _isFixed = value!;
                  _eventType = EventType.fixed; // 固定予定タイプ
                  _backgroundColor = _eventType.defaultBackgroundColor;
                  _textColor = _eventType.defaultTextColor;
                });
              },
            ),
            const Divider(),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'タイトル'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'タイトルを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 日時設定
            ListTile(
              title: Text('開始日時: ${DateFormat('yyyy/MM/dd HH:mm').format(_startTime)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDateTime(context, true),
            ),
            ListTile(
              title: Text('終了日時: ${DateFormat('yyyy/MM/dd HH:mm').format(_endTime)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDateTime(context, false),
            ),
            const SizedBox(height: 16),

            // 背景色選択
            ListTile(
              title: const Text('予定の色'),
              leading: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400)
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _selectBackgroundColor,
            ),
            const SizedBox(height: 16),

            if (!_isFixed) ...[ // 空き日程の場合のみ表示
              // 1. マッチングタイプ
              DropdownButtonFormField<EventType>(
                value: _eventType,
                decoration: const InputDecoration(labelText: 'マッチングタイプ'),
                items: EventType.values.where((e) => e != EventType.fixed).map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (type) {
                  setState(() {
                    _eventType = type!;
                    _backgroundColor = _eventType.defaultBackgroundColor;
                    _textColor = _eventType.defaultTextColor;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 2. 公開範囲
              SwitchListTile(
                title: const Text('公開範囲'),
                subtitle: Text(_isPublic ? '公開（条件一致でマッチング可）' : '非公開（条件一致でマッチング可）'),
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 3. 詳細設定（折りたたみUI）
              ExpansionTile(
                title: const Text('詳細設定', style: TextStyle(fontWeight: FontWeight.bold)),
                initiallyExpanded: _isAdvancedSettingsExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _isAdvancedSettingsExpanded = expanded;
                  });
                },
                children: [
                  TextFormField(
                    initialValue: _minParticipants?.toString(),
                    decoration: const InputDecoration(labelText: '募集人数（下限）'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => _minParticipants = int.tryParse(value ?? ''),
                  ),
                  TextFormField(
                    initialValue: _maxParticipants?.toString(),
                    decoration: const InputDecoration(labelText: '募集人数（上限）'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => _maxParticipants = int.tryParse(value ?? ''),
                  ),
                  ListTile(
                    title: Text('募集期間: ${_recruitmentDeadline != null ? DateFormat('yyyy/MM/dd').format(_recruitmentDeadline!) : '未設定'}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _recruitmentDeadline ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _recruitmentDeadline = pickedDate;
                        });
                      }
                    },
                  ),
                  TextFormField(
                    initialValue: _locationPrefecture,
                    decoration: const InputDecoration(labelText: '場所（都道府県）'),
                    onSaved: (value) => _locationPrefecture = value,
                  ),
                  TextFormField(
                    initialValue: _locationCity,
                    decoration: const InputDecoration(labelText: '場所（市区町村）'),
                    onSaved: (value) => _locationCity = value,
                  ),
                  TextFormField(
                    initialValue: _locationRange,
                    decoration: const InputDecoration(labelText: '場所（範囲指定）'),
                    onSaved: (value) => _locationRange = value,
                  ),
                  // TODO: ジャンル選択 (複数選択UI)
                  // TODO: マッチ条件 (年齢、性別、職業など) のUIとチェックボックス
                  const Text('ジャンル選択やマッチ条件は別途UIを実装'),
                ],
              ),
              const SizedBox(height: 16),

              // 4. 友人の招待（フレンドリストから選択）
              ElevatedButton(
                onPressed: () {
                  // TODO: 友人招待UIを表示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('友人を招待する機能は未実装')),
                  );
                },
                child: const Text('友人を招待'),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}