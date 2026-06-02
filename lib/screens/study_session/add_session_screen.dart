import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/study_session_model.dart';
import '../../models/task_model.dart';
import '../../utils/date_helper.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddSessionScreen extends StatefulWidget {
  final int? initialTaskId;
  final String? initialSubject;

  const AddSessionScreen({super.key, this.initialTaskId, this.initialSubject});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<TaskModel> _availableTasks = [];
  int? _selectedTaskId;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateHelper.formatShortDate(_selectedDate);
    if (widget.initialTaskId != null) {
      _selectedTaskId = widget.initialTaskId;
    }
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await DbHelper.getAllTasks();
    setState(() {
      _availableTasks = tasks;
    });
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
      final selectedTask = _availableTasks.firstWhere((task) => task.id == _selectedTaskId);
      final session = StudySessionModel(
        taskId: _selectedTaskId,
        subject: selectedTask.title,
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
            DropdownButtonFormField<int?>(
              initialValue: _selectedTaskId,
              decoration: InputDecoration(
                labelText: 'Pilih tugas',
                prefixIcon: const Icon(Icons.task_rounded),
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
              validator: (value) {
                if (value == null) {
                  return 'Pilih tugas yang akan dilaporkan dalam sesi belajar';
                }
                return null;
              },
              items: _availableTasks.isNotEmpty
                  ? _availableTasks.map((task) {
                      return DropdownMenuItem<int?>(
                        value: task.id,
                        child: Text(task.title),
                      );
                    }).toList()
                  : [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tidak ada tugas tersedia'),
                      ),
                    ],
              onChanged: (int? value) {
                setState(() {
                  _selectedTaskId = value;
                });
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
