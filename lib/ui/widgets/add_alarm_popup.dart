import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/contest.dart';
import '../../services/alarm_service.dart';
import '../../services/api_service.dart';
import '../../services/tutorial_service.dart';

class AddAlarmPopup extends StatefulWidget {
  final Contest? initialContest;
  final DateTime? initialDate;
  const AddAlarmPopup({super.key, this.initialContest, this.initialDate});

  @override
  State<AddAlarmPopup> createState() => _AddAlarmPopupState();
}

class _AddAlarmPopupState extends State<AddAlarmPopup> {
  final GlobalKey _formKey = GlobalKey();
  bool _tutorialShown = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }

    if (widget.initialContest != null) {
      _titleController.text = widget.initialContest!.name;
      _descController.text = widget.initialContest!.description;
      _selectedDate = widget.initialContest!.startTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.initialContest!.startTime);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial();
    });
  }

  Future<void> _checkAndShowTutorial() async {
    if (_tutorialShown) return;
    _tutorialShown = true;
    final hasSeen = await TutorialService.hasSeenPopupTutorial();
    if (!hasSeen && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          TutorialService.showPopupTutorial(
            context: context,
            formKey: _formKey,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1CD065),
              onPrimary: Colors.black,
              surface: Color(0xFF1C1E22),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1CD065),
              onPrimary: Colors.black,
              surface: Color(0xFF1C1E22),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _schedule() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (startDateTime.isBefore(
      DateTime.now().add(const Duration(minutes: 1)),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time must be in the future')),
      );
      return;
    }

    try {
      final id =
          widget.initialContest?.id ??
          'manual_${DateTime.now().millisecondsSinceEpoch}';

      final dummyContest = Contest(
        id: id,
        name: _titleController.text,
        description: _descController.text,
        url: 'Manual',
        startTime: startDateTime,
        endTime: startDateTime.add(const Duration(hours: 1)),
        duration: '3600',
        site: 'Manual',
        status: 'BEFORE',
      );

      // 1. Stop technical alarm if editing (prevents ghost alarms)
      if (widget.initialContest != null) {
        await AlarmService.stopAlarm(widget.initialContest!.alarmId);
      }

      // 2. Schedule technical alarm
      await AlarmService.scheduleCustomAlarm(dummyContest);

      // 3. Save for UI visibility
      await ApiService.saveManualAlarm(dummyContest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialContest != null
                  ? 'Alarm updated successfully!'
                  : 'Alarm scheduled successfully!',
            ),
            backgroundColor: const Color(0xFF1CD065),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 32,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF111214).withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(
                color: const Color(0xFF1CD065).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.initialContest != null ? 'Edit Alarm' : 'Manual Alarm',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                _buildField(_titleController, 'Title', Icons.title),
                const SizedBox(height: 16),
                _buildField(
                  _descController,
                  'Description',
                  Icons.description,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildPicker(
                        label:
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        icon: Icons.calendar_today,
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPicker(
                        label: _selectedTime.format(context),
                        icon: Icons.access_time,
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1CD065),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _schedule,
                    child: Text(
                      widget.initialContest != null
                          ? 'UPDATE ALARM'
                          : 'SCHEDULE ALARM',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: const Color(0xFF1CD065), size: 20),
        filled: true,
        fillColor: const Color(0xFF1C1E22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPicker({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1E22),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1CD065), size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
