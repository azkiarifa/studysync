import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/study_session_model.dart';
import '../../utils/date_helper.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class EditSessionScreen extends StatefulWidget {
  final StudySessionModel session;

  const EditSessionScreen({super.key, required this.session});

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _durationController;
  late TextEditingController _notesController;
  late TextEditingController _dateController;

  late DateTime _selectedDate;
  late String _selectedSubject;

  final List<String> _subjects = [
    'Pengujian Perangkat Lunak',
    'Proyek SI',
    'Dasar Ilmu Data',
    'Agama',
    'Pengembangan Profesional',
    'Bahasa Inggris',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(text: '${widget.session.durationSeconds ~/ 60}');
    _notesController = TextEditingController(text: widget.session.notes);
    _dateController = TextEditingController();

    _selectedDate = widget.session.date;
    _selectedSubject = widget.session.subject;

    _dateController.text = DateHelper.formatShortDate(_selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateHelper.formatShortDate(_selectedDate);
      });
    }
  }

  Future<void> _updateSession() async {
    if (_formKey.currentState!.validate()) {
      final minutes = int.parse(_durationController.text);
      final updatedSession = widget.session.copyWith(
        subject: _selectedSubject,
        date: _selectedDate,
        durationSeconds: minutes * 60,
        notes: _notesController.text.trim(),
      );

      await DbHelper.updateStudySession(updatedSession);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi belajar berhasil diperbarui')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Study Log'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: InputDecoration(
                labelText: 'Mata Kuliah',
                prefixIcon: const Icon(Icons.menu_book_rounded),
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
              items: _subjects.map((String sub) {
                return DropdownMenuItem<String>(
                  value: sub,
                  child: Text(sub),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedSubject = newValue);
                }
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _durationController,
              labelText: 'Durasi Belajar (Menit)',
              hintText: 'Misal: 60',
              prefixIcon: Icons.timer_rounded,
              keyboardType: TextInputType.number,
              validator: (value) => AppValidator.validateNumber(value, 'Durasi'),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _dateController,
              labelText: 'Tanggal Sesi Belajar',
              prefixIcon: Icons.calendar_today_rounded,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _notesController,
              labelText: 'Catatan Belajar',
              hintText: 'Membahas latihan soal bab 2 (opsional)...',
              prefixIcon: Icons.note_add_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 40),

            CustomButton(
              text: 'Simpan Perubahan',
              onTap: _updateSession,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
