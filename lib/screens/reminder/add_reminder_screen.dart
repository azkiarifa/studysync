import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/reminder_model.dart';
import '../../utils/app_text.dart';
import '../../utils/date_helper.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _timeController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedRepeat = 'None';
  final List<String> _repeats = ['None', 'Daily', 'Weekly'];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateHelper.formatShortDate(_selectedDate);
    _timeController.text = DateHelper.formatTimeOfDay(_selectedTime.hour, _selectedTime.minute);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateHelper.formatShortDate(_selectedDate);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = DateHelper.formatTimeOfDay(_selectedTime.hour, _selectedTime.minute);
      });
    }
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final reminder = ReminderModel(
        title: _titleController.text.trim(),
        dateTime: finalDateTime,
        isCompleted: false,
        repeatType: _selectedRepeat,
      );

      await DbHelper.insertReminder(reminder);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppText.get('reminderSaved'))),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppText.get('addReminder')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CustomTextField(
              controller: _titleController,
              labelText: AppText.get('reminderName'),
              hintText: AppText.get('reminderHint'),
              prefixIcon: Icons.title_rounded,
              validator: (value) => AppValidator.validateRequired(value, 'Nama Pengingat'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _timeController,
                    labelText: AppText.get('alarmTime'),
                    prefixIcon: Icons.access_time_rounded,
                    readOnly: true,
                    onTap: () => _selectTime(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _dateController,
                    labelText: AppText.get('startDate'),
                    prefixIcon: Icons.calendar_today_rounded,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedRepeat,
              decoration: InputDecoration(
                labelText: AppText.get('repeatReminder'),
                prefixIcon: const Icon(Icons.repeat_rounded),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              items: _repeats.map((String rep) {
                return DropdownMenuItem<String>(
                  value: rep,
                  child: Text(rep),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedRepeat = newValue);
                }
              },
            ),
            const SizedBox(height: 40),

            CustomButton(
              text: AppText.get('saveReminder'),
              onTap: _saveReminder,
              icon: Icons.save_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
