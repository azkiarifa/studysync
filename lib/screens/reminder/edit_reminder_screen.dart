import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/reminder_model.dart';
import '../../utils/date_helper.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class EditReminderScreen extends StatefulWidget {
  final ReminderModel reminder;

  const EditReminderScreen({super.key, required this.reminder});

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _timeController;
  late TextEditingController _dateController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedRepeat;
  final List<String> _repeats = ['None', 'Daily', 'Weekly'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder.title);
    _timeController = TextEditingController();
    _dateController = TextEditingController();

    _selectedDate = widget.reminder.dateTime;
    _selectedTime = TimeOfDay(hour: widget.reminder.dateTime.hour, minute: widget.reminder.dateTime.minute);
    _selectedRepeat = widget.reminder.repeatType;

    _dateController.text = DateHelper.formatShortDate(_selectedDate);
    _timeController.text = DateHelper.formatTimeOfDay(_selectedTime.hour, _selectedTime.minute);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

  Future<void> _updateReminder() async {
    if (_formKey.currentState!.validate()) {
      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final updatedReminder = widget.reminder.copyWith(
        title: _titleController.text.trim(),
        dateTime: finalDateTime,
        repeatType: _selectedRepeat,
      );

      await DbHelper.updateReminder(updatedReminder);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengingat berhasil diperbarui')),
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
        title: const Text('Edit Reminder'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CustomTextField(
              controller: _titleController,
              labelText: 'Nama Pengingat',
              hintText: 'Belajar kalkulus / Review materi...',
              prefixIcon: Icons.title_rounded,
              validator: (value) => AppValidator.validateRequired(value, 'Nama Pengingat'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _timeController,
                    labelText: 'Waktu Alaram',
                    prefixIcon: Icons.access_time_rounded,
                    readOnly: true,
                    onTap: () => _selectTime(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _dateController,
                    labelText: 'Tanggal Mulai',
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
                labelText: 'Ulangi Pengingat',
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
              text: 'Simpan Perubahan',
              onTap: _updateReminder,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
