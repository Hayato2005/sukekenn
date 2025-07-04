// lib/schedule_creation_sheet.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';
import 'dart:async';

class ScheduleCreationSheet extends StatefulWidget {
  final Schedule schedule;
  final bool isQuickAddMode;
  // ★ 親に「閉じる」または「保存」を通知するためのコールバック
  final Function({Schedule? savedSchedule}) onClose;

  const ScheduleCreationSheet({
    super.key,
    required this.schedule,
    required this.isQuickAddMode,
    required this.onClose,
  });

  @override
  State<ScheduleCreationSheet> createState() => _ScheduleCreationSheetState();
}

class _ScheduleCreationSheetState extends State<ScheduleCreationSheet> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isAllDay;
  late Color _selectedColor;
  
  String _scheduleType = '固定予定';
  String _matchingType = 'フレンド';
  bool _isPublic = true;

  final FocusNode _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _updateStateFromWidget();

    if (widget.isQuickAddMode) {
      Timer(const Duration(milliseconds: 100), () {
        if (mounted) FocusScope.of(context).requestFocus(_titleFocusNode);
      });
    }
  }
  
  // ★ widgetが外部から更新されたとき(仮予定のドラッグ時)にStateを同期させる
  @override
  void didUpdateWidget(covariant ScheduleCreationSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.schedule.id != oldWidget.schedule.id ||
        widget.schedule.startHour != oldWidget.schedule.startHour ||
        widget.schedule.endHour != oldWidget.schedule.endHour) {
      // 外部からの変更をフォームに反映する
      setState(() {
         _updateStateFromWidget();
      });
    }
  }

  void _updateStateFromWidget() {
    final schedule = widget.schedule;
    _titleController = TextEditingController(text: schedule.title == '(タイトル未入力)' ? '' : schedule.title);
    _titleController.selection = TextSelection.fromPosition(TextPosition(offset: _titleController.text.length));
    
    _selectedDate = schedule.date;
    _startTime = TimeOfDay(hour: schedule.startHour.floor(), minute: ((schedule.startHour - schedule.startHour.floor()) * 60).round());
    _endTime = TimeOfDay(hour: schedule.endHour.floor(), minute: ((schedule.endHour - schedule.endHour.floor()) * 60).round());
    _isAllDay = schedule.isAllDay;
    _selectedColor = schedule.id.isEmpty ? Colors.blue : schedule.color;
    _scheduleType = schedule.scheduleType ?? '固定予定';
  }


  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  // === 時刻選択の補助ロジック ===
  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null && picked != _startTime) {
      setState(() {
        final duration = _calculateDuration(_startTime, _endTime);
        _startTime = picked;
        final newEndTimeDateTime = DateTime(2000, 1, 1, picked.hour, picked.minute).add(duration);
        _endTime = TimeOfDay.fromDateTime(newEndTimeDateTime);
      });
    }
  }
  
  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) {
      final startInMinutes = _startTime.hour * 60 + _startTime.minute;
      final pickedInMinutes = picked.hour * 60 + picked.minute;
      if (pickedInMinutes <= startInMinutes) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('終了時刻は開始時刻より後に設定してください。')),
          );
        }
        return;
      }
      setState(() => _endTime = picked);
    }
  }

  Duration _calculateDuration(TimeOfDay start, TimeOfDay end) {
    final s = DateTime(2000, 1, 1, start.hour, start.minute);
    final e = DateTime(2000, 1, 1, end.hour, end.minute);
    if (e.isBefore(s)) {
      return e.add(const Duration(days: 1)).difference(s);
    }
    return e.difference(s);
  }

  // === 保存処理 ===
  void _saveSchedule() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('タイトルを入力してください。')));
      return;
    }
    final updatedSchedule = widget.schedule.copyWith(
      title: _titleController.text,
      date: _selectedDate,
      startHour: _isAllDay ? 0 : _startTime.hour + _startTime.minute / 60.0,
      endHour: _isAllDay ? 24 : _endTime.hour + _endTime.minute / 60.0,
      isAllDay: _isAllDay,
      color: _selectedColor,
      scheduleType: _scheduleType,
      matchingType: _scheduleType == '空き日程' ? _matchingType : null,
    );
    // ★ 親に保存したデータを渡して閉じる
    widget.onClose(savedSchedule: updatedSchedule);
  }

  @override
  Widget build(BuildContext context) {
    // このウィジェット自体はモーダルではないため、背景タップで閉じる機能は親のStackで実装
    return Material(
      elevation: 8,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(
        children: [
          // --- ヘッダー ---
          AppBar(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            automaticallyImplyLeading: false,
            // ★ 親に通知して閉じる
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => widget.onClose()),
            title: TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              decoration: const InputDecoration(hintText: '予定のタイトル', border: InputBorder.none),
              // ★ isQuickAddModeはコンストラクタで一度だけ使い、リビルドで毎回フォーカスしないようにする
            ),
            actions: [TextButton(onPressed: _saveSchedule, child: const Text('登録'))],
          ),
          // --- 本体（詳細フォーム） ---
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal:16.0),
                children: _buildFormContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // フォームの中身を生成するメソッド
  List<Widget> _buildFormContent() {
    // 編集時はisQuickAddModeがfalseなので、常にフル表示される前提
    return [
      const SizedBox(height: 16),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: '空き日程', label: Text('空き日程'), icon: Icon(Icons.people_outline)),
          ButtonSegment(value: '固定予定', label: Text('固定予定'), icon: Icon(Icons.lock_outline)),
        ],
        selected: {_scheduleType},
        onSelectionChanged: (newSelection) => setState(() => _scheduleType = newSelection.first),
      ),
      const SizedBox(height: 16),
      ListTile(
        leading: const Icon(Icons.calendar_today_outlined),
        title: Text(DateFormat('y年M月d日 (E)', 'ja').format(_selectedDate)),
        onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
          if(picked != null) setState(() => _selectedDate = picked);
        },
      ),
      if (!_isAllDay)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: _pickStartTime, child: Text(_startTime.format(context), style: Theme.of(context).textTheme.headlineSmall)),
            const Text('〜', style: TextStyle(fontSize: 20)),
            TextButton(onPressed: _pickEndTime, child: Text(_endTime.format(context), style: Theme.of(context).textTheme.headlineSmall)),
          ],
        ),
      CheckboxListTile(
        title: const Text('終日'),
        value: _isAllDay,
        onChanged: (val) => setState(() => _isAllDay = val ?? false),
        secondary: const Icon(Icons.wb_sunny_outlined),
      ),
      const Divider(),
      if (_scheduleType == '空き日程') ...[
        ListTile(
          leading: const Icon(Icons.how_to_reg_outlined),
          title: const Text('マッチングタイプ'),
          trailing: DropdownButton<String>(
            value: _matchingType,
            items: ['フレンド', '誰でも', '異性'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) setState(() => _matchingType = newValue);
            },
          ),
        ),
        SwitchListTile(
          title: const Text('公開する'),
          subtitle: const Text('OFFにすると検索結果に表示されません'),
          value: _isPublic,
          onChanged: (val) => setState(() => _isPublic = val),
          secondary: const Icon(Icons.visibility_outlined),
        ),
        const Divider(),
      ],
      ListTile(
        leading: const Icon(Icons.group_add_outlined),
        title: const Text('招待するメンバーを追加...'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () { /* TODO: 招待ポップアップ表示 */ },
      ),
      ListTile(
        leading: const Icon(Icons.tune_outlined),
        title: const Text('詳細設定...'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () { /* TODO: 詳細設定ポップアップ表示 */ },
      ),
      if (widget.schedule.id.isNotEmpty && !widget.schedule.id.contains('temporary'))
         Padding(
           padding: const EdgeInsets.only(top: 32.0),
           child: TextButton.icon(
             onPressed: () {
                showDialog(context: context, builder: (context) => AlertDialog(
                  title: const Text('予定の削除'),
                  content: const Text('この予定を完全に削除しますか？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // ダイアログを閉じる
                        widget.onClose(savedSchedule: widget.schedule.copyWith(id: 'deleted'));
                      }, 
                      child: const Text('削除', style: TextStyle(color: Colors.red))
                    ),
                  ],
                ));
             },
             icon: const Icon(Icons.delete_outline),
             label: const Text('この予定を削除する'),
             style: TextButton.styleFrom(foregroundColor: Colors.red),
           ),
         ),
    ];
  }
}