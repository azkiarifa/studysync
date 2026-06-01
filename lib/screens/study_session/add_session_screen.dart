import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/study_session_model.dart';
import '../../utils/date_helper.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddSessionScreen extends StatefulWidget {
  const AddSessionScreen({super.key});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedSubject = 'Pengujian Perangkat Lunak';

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

  Future<void> _saveSession() async {
    if (_formKey.currentState!.validate()) {
      final minutes = int.parse(_durationController.text);
      final session = StudySessionModel(
        subject: _selectedSubject,
        date: _selectedDate,
        durationSeconds: minutes * 60,
        notes: _notesController.text.trim(),
      );

      await DbHelper.insertStudySession(session);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi belajar berhasil ditambahkan')),
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
        title: const Text('Add Study Log'),
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
              text: 'Simpan Log Belajar',
              onTap: _saveSession,
              icon: Icons.save_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
