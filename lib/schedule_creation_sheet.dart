// lib/schedule_creation_sheet.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';
import 'dart:async';

class ScheduleCreationSheet extends StatefulWidget {
  final Schedule schedule;
  final Function({Schedule? savedSchedule, bool isDeleted}) onClose;
  final ScrollController scrollController;

  const ScheduleCreationSheet({
    super.key,
    required this.schedule,
    required this.onClose,
    required this.scrollController,
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

  late ScheduleType _scheduleType;
  late MatchingType _matchingType;
  late bool _isPublic;

  final FocusNode _titleFocusNode = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _updateStateFromWidget();

    // ★★★ クイック登録時の自動フォーカス機能を削除 ★★★
    /*
    if (widget.schedule.title.isEmpty) {
      Timer(const Duration(milliseconds: 300), () {
        if (mounted) FocusScope.of(context).requestFocus(_titleFocusNode);
      });
    }
    */

    _titleController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant ScheduleCreationSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.schedule.id != oldWidget.schedule.id ||
        widget.schedule.startHour != oldWidget.schedule.startHour ||
        widget.schedule.endHour != oldWidget.schedule.endHour ||
        widget.schedule.date != oldWidget.schedule.date
        ) {
      setState(() {
        _updateStateFromWidget();
      });
    }
  }

  void _updateStateFromWidget() {
    final schedule = widget.schedule;
    _titleController = TextEditingController(text: schedule.title);
    _selectedDate = schedule.date;
    _startTime = TimeOfDay(hour: schedule.startHour.floor(), minute: ((schedule.startHour % 1) * 60).round());
    _endTime = TimeOfDay(hour: schedule.endHour.floor(), minute: ((schedule.endHour % 1) * 60).round());
    _isAllDay = schedule.isAllDay;
    _scheduleType = schedule.scheduleType;
    _matchingType = schedule.matchingType;
    _isPublic = schedule.isPublic;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

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
        if (mounted) {
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
    return e.isAfter(s) ? e.difference(s) : e.add(const Duration(days: 1)).difference(s);
  }

  void _saveSchedule() async {
    if (_titleController.text.trim().isEmpty || _isSaving) return;
    setState(() => _isSaving = true);

    final updatedSchedule = widget.schedule.copyWith(
      title: _titleController.text.trim(),
      date: _selectedDate,
      startHour: _isAllDay ? 0 : _startTime.hour + _startTime.minute / 60.0,
      endHour: _isAllDay ? 24 : _endTime.hour + _endTime.minute / 60.0,
      isAllDay: _isAllDay,
      scheduleType: _scheduleType,
      matchingType: _scheduleType == ScheduleType.available ? _matchingType : MatchingType.friend,
      isPublic: _scheduleType == ScheduleType.available ? _isPublic : true,
    );

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      widget.onClose(savedSchedule: updatedSchedule, isDeleted: false);
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
      }
      setState(() => _isSaving = false);
    }
  }

  void _deleteSchedule() {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予定の削除'),
        content: const Text('この予定を完全に削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onClose(isDeleted: true);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTitleEmpty = _titleController.text.trim().isEmpty;
    return Material(
      elevation: 8,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      clipBehavior: Clip.antiAlias,
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: AppBar(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          backgroundColor: Theme.of(context).cardColor,
          elevation: 1,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: '閉じる',
            onPressed: () => widget.onClose(isDeleted: false),
          ),
          title: TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            decoration: const InputDecoration.collapsed(hintText: '予定のタイトル'),
            textInputAction: TextInputAction.done,
            onChanged: (text) => setState((){}),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: isTitleEmpty || _isSaving ? null : _saveSchedule,
                child: _isSaving ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2,)) : const Text('登録'),
              ),
            )
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: _buildFormContent(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormContent() {
    bool isEditing = !widget.schedule.id.startsWith('temporary');
    return [
      const SizedBox(height: 16),
      Center(
        child: SegmentedButton<ScheduleType>(
          segments: const [
            ButtonSegment(value: ScheduleType.available, label: Text('空き日程'), icon: Icon(Icons.people_outline)),
            ButtonSegment(value: ScheduleType.fixed, label: Text('固定予定'), icon: Icon(Icons.lock_outline)),
          ],
          selected: {_scheduleType},
          onSelectionChanged: (newSelection) => setState(() => _scheduleType = newSelection.first),
        ),
      ),
      const SizedBox(height: 16),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.calendar_today_outlined),
        title: Text(DateFormat('y年M月d日 (E)', 'ja').format(_selectedDate)),
        onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
          if (picked != null) setState(() => _selectedDate = picked);
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
      if (_scheduleType == ScheduleType.available) ...[
        ListTile(
          leading: const Icon(Icons.how_to_reg_outlined),
          title: const Text('マッチングタイプ'),
          trailing: DropdownButton<MatchingType>(
            value: _matchingType,
            items: MatchingType.values.map((MatchingType value) {
              return DropdownMenuItem<MatchingType>(value: value, child: Text(value.displayName));
            }).toList(),
            onChanged: (MatchingType? newValue) {
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
      if (isEditing)
         Padding(
           padding: const EdgeInsets.only(top: 32.0, bottom: 32.0),
           child: Center(
             child: TextButton.icon(
               onPressed: _deleteSchedule,
               icon: const Icon(Icons.delete_outline),
               label: const Text('この予定を削除する'),
               style: TextButton.styleFrom(foregroundColor: Colors.red),
             ),
           ),
         ),
    ];
  }
}