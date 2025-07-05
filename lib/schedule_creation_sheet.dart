// lib/schedule_creation_sheet.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';
import 'dart:async';

// クイック登録モードで表示される、下から出てくる小さなパネル
class ScheduleSheetHeader extends StatefulWidget {
  final Schedule schedule;
  final Function({bool isDeleted}) onClose;
  final Function(Schedule updatedSchedule) onSave;

  const ScheduleSheetHeader({
    super.key,
    required this.schedule,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<ScheduleSheetHeader> createState() => _ScheduleSheetHeaderState();
}

class _ScheduleSheetHeaderState extends State<ScheduleSheetHeader> {
  late TextEditingController _titleController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _updateTitle();
    _titleController.addListener(() {
      if(mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant ScheduleSheetHeader oldWidget) {
      super.didUpdateWidget(oldWidget);
      if (widget.schedule.title != oldWidget.schedule.title) {
        // 親ウィジェットから渡されるスケジュール情報が更新されたら、コントローラーも更新
        if(_titleController.text != widget.schedule.title) {
          _titleController.text = widget.schedule.title;
        }
      }
  }
  
  void _updateTitle(){
     _titleController = TextEditingController(text: widget.schedule.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    final updatedSchedule = widget.schedule.copyWith(title: _titleController.text.trim());
    widget.onSave(updatedSchedule);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: Container(
        color: Theme.of(context).cardColor,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: kToolbarHeight + 10,
            child: AppBar(
              backgroundColor: Theme.of(context).cardColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: '閉じる',
                onPressed: () => widget.onClose(isDeleted: false),
              ),
              title: TextField(
                controller: _titleController,
                // ★★★★★ 修正点 ★★★★★
                // autofocusを削除し、自動でキーボードが開かないようにする
                // autofocus: true, 
                decoration: const InputDecoration.collapsed(hintText: '予定のタイトル'),
                textInputAction: TextInputAction.done,
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton(
                    onPressed: _titleController.text.trim().isEmpty || _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('登録'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// フル表示モードの本体
class ScheduleCreationSheet extends StatefulWidget {
  final Schedule schedule;
  final ScrollController scrollController;

  const ScheduleCreationSheet({
    super.key,
    required this.schedule,
    required this.scrollController,
  });

  @override
  State<ScheduleCreationSheet> createState() => _ScheduleCreationSheetState();
}

class _ScheduleCreationSheetState extends State<ScheduleCreationSheet> {
  late Schedule _currentSchedule;
  late TextEditingController _titleController;
  final FocusNode _titleFocusNode = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentSchedule = widget.schedule;
    _titleController = TextEditingController(text: _currentSchedule.title);
    _titleController.addListener(() {
      if(mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant ScheduleCreationSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.schedule != oldWidget.schedule) {
      setState(() {
        _currentSchedule = widget.schedule;
        if(_titleController.text != _currentSchedule.title) {
          _titleController.text = _currentSchedule.title;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _close({Schedule? savedSchedule, bool isDeleted = false}) {
    if (!mounted) return;
    Navigator.of(context).pop({
      'savedSchedule': savedSchedule,
      'isDeleted': isDeleted,
      'originalId': widget.schedule.id,
    });
  }

  void _saveSchedule() async {
    if (_titleController.text.trim().isEmpty || _isSaving) return;
    setState(() => _isSaving = true);

    final finalSchedule = _currentSchedule.copyWith(title: _titleController.text.trim());

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _close(savedSchedule: finalSchedule);
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
      setState(() => _isSaving = false);
    }
  }

  void _deleteSchedule() {
      showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('予定の削除'),
        content: const Text('この予定を完全に削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _close(isDeleted: true);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      clipBehavior: Clip.antiAlias,
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        body: CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).cardColor,
              elevation: 1,
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: '閉じる',
                onPressed: _close,
              ),
              title: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                decoration: const InputDecoration.collapsed(hintText: '予定のタイトル'),
                textInputAction: TextInputAction.done,
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton(
                    onPressed: _titleController.text.trim().isEmpty || _isSaving ? null : _saveSchedule,
                    child: _isSaving 
                      ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2,)) 
                      : const Text('登録'),
                  ),
                )
              ],
            ),
            SliverList(delegate: SliverChildListDelegate(
              [
                _FullDisplayContent(
                  schedule: _currentSchedule,
                  onChanged: (newSchedule) {
                    setState(() => _currentSchedule = newSchedule);
                  },
                  onDelete: _deleteSchedule,
                )
              ]
            )),
          ],
        ),
      ),
    );
  }
}

// フル表示モードの詳細入力エリア
class _FullDisplayContent extends StatelessWidget {
  final Schedule schedule;
  final Function(Schedule) onChanged;
  final VoidCallback onDelete;

  const _FullDisplayContent({
    required this.schedule,
    required this.onChanged,
    required this.onDelete,
  });
  
  DateTime _getDateTimeFromHour(double hour) {
    final date = schedule.date;
    final baseDate = DateTime(date.year, date.month, date.day);
    return baseDate.add(Duration(minutes: (hour * 60).round()));
  }

  @override
  Widget build(BuildContext context) {
    final startDateTime = _getDateTimeFromHour(schedule.startHour);
    final endDateTime = _getDateTimeFromHour(schedule.endHour);
    bool isEditing = !schedule.id.startsWith('temporary');

    Future<void> pickStartTime() async {
      final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(startDateTime));
      if (picked != null) {
        final duration = endDateTime.difference(startDateTime);
        final newStartDateTime = DateTime(schedule.date.year, schedule.date.month, schedule.date.day, picked.hour, picked.minute);
        final newEndDateTime = newStartDateTime.add(duration);
        onChanged(schedule.copyWith(
          startHour: newStartDateTime.hour + newStartDateTime.minute / 60.0,
          endHour: newEndDateTime.hour + newEndDateTime.minute / 60.0,
        ));
      }
    }

    Future<void> pickEndTime() async {
      final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(endDateTime));
      if (picked != null) {
        final newEndDateTime = DateTime(schedule.date.year, schedule.date.month, schedule.date.day, picked.hour, picked.minute);
        if (newEndDateTime.isBefore(startDateTime) || newEndDateTime.isAtSameMomentAs(startDateTime)) {
          if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('終了時刻は開始時刻より後に設定してください。')));
          return;
        }
        onChanged(schedule.copyWith(endHour: picked.hour + picked.minute / 60.0));
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Center(
            child: SegmentedButton<ScheduleType>(
              segments: const [
                ButtonSegment(value: ScheduleType.available, label: Text('空き日程'), icon: Icon(Icons.people_outline)),
                ButtonSegment(value: ScheduleType.fixed, label: Text('固定予定'), icon: Icon(Icons.lock_outline)),
              ],
              selected: {schedule.scheduleType},
              onSelectionChanged: (newSelection) => onChanged(schedule.copyWith(scheduleType: newSelection.first)),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(DateFormat('y年M月d日 (E)', 'ja').format(schedule.date)),
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: schedule.date, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (picked != null) onChanged(schedule.copyWith(date: picked));
            },
          ),
          if (!schedule.isAllDay)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: pickStartTime, child: Text(DateFormat('HH:mm').format(startDateTime), style: Theme.of(context).textTheme.headlineSmall)),
                const Text('〜', style: TextStyle(fontSize: 20)),
                TextButton(onPressed: pickEndTime, child: Text(DateFormat('HH:mm').format(endDateTime), style: Theme.of(context).textTheme.headlineSmall)),
              ],
            ),
          CheckboxListTile(
            title: const Text('終日'),
            value: schedule.isAllDay,
            onChanged: (val) => onChanged(schedule.copyWith(isAllDay: val ?? false)),
            secondary: const Icon(Icons.wb_sunny_outlined),
          ),
          const Divider(),
          if (schedule.scheduleType == ScheduleType.available) ...[
            ListTile(
              leading: const Icon(Icons.how_to_reg_outlined),
              title: const Text('マッチングタイプ'),
              trailing: DropdownButton<MatchingType>(
                value: schedule.matchingType,
                items: MatchingType.values.map((MatchingType value) {
                  return DropdownMenuItem<MatchingType>(value: value, child: Text(value.displayName));
                }).toList(),
                onChanged: (MatchingType? newValue) {
                  if (newValue != null) onChanged(schedule.copyWith(matchingType: newValue));
                },
              ),
            ),
            SwitchListTile(
              title: const Text('公開する'),
              subtitle: const Text('OFFにすると検索結果に表示されません'),
              value: schedule.isPublic,
              onChanged: (val) => onChanged(schedule.copyWith(isPublic: val)),
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
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('この予定を削除する'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}