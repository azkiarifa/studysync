import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/schedule_model.dart';
import '../../utils/date_helper.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class EditScheduleScreen extends StatefulWidget {
  final ScheduleModel schedule;

  const EditScheduleScreen({super.key, required this.schedule});

  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _lecturerController;
  late TextEditingController _dateController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _selectedColorValue;

  final List<int> _colorOptions = const [
    0xFF6366F1,
    0xFF06B6D4,
    0xFFEC4899,
    0xFF10B981,
    0xFFF59E0B,
    0xFFEF4444,
    0xFFFB923C,
    0xFF14B8A6,
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.schedule.title);
    _locationController = TextEditingController(text: widget.schedule.location);
    _lecturerController = TextEditingController(text: widget.schedule.lecturer);
    _dateController = TextEditingController();
    _startTimeController = TextEditingController(text: widget.schedule.startTime);
    _endTimeController = TextEditingController(text: widget.schedule.endTime);

    _selectedDate = widget.schedule.date;
    final startParts = widget.schedule.startTime.split(':');
    _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
    final endParts = widget.schedule.endTime.split(':');
    _endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
    _selectedColorValue = widget.schedule.color;
    
    _dateController.text = DateHelper.formatShortDate(_selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateHelper.formatShortDate(_selectedDate);
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _startTimeController.text = DateHelper.formatTimeOfDay(picked.hour, picked.minute);
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _endTimeController.text = DateHelper.formatTimeOfDay(picked.hour, picked.minute);
      });
    }
  }

  Future<void> _updateSchedule() async {
    if (_formKey.currentState!.validate()) {
      final updatedSchedule = widget.schedule.copyWith(
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        date: _selectedDate,
        startTime: _startTimeController.text,
        endTime: _endTimeController.text,
        color: _selectedColorValue,
        lecturer: _lecturerController.text.trim(),
      );

      await DbHelper.updateSchedule(updatedSchedule);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal berhasil diperbarui')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _lecturerController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Schedule'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CustomTextField(
              controller: _titleController,
              labelText: 'Nama Kegiatan / Kuliah',
              hintText: 'Masukkan nama jadwal...',
              prefixIcon: Icons.title_rounded,
              validator: (value) => AppValidator.validateRequired(value, 'Nama Jadwal'),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _locationController,
              labelText: 'Ruangan / Lokasi',
              hintText: 'Gedung A-302 / Zoom...',
              prefixIcon: Icons.location_on_rounded,
              validator: (value) => AppValidator.validateRequired(value, 'Lokasi'),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _lecturerController,
              labelText: 'Dosen Pengampu',
              hintText: 'Nama dosen (opsional)...',
              prefixIcon: Icons.person_rounded,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _dateController,
              labelText: 'Tanggal',
              prefixIcon: Icons.calendar_today_rounded,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _startTimeController,
                    labelText: 'Mulai',
                    prefixIcon: Icons.access_time_rounded,
                    readOnly: true,
                    onTap: () => _selectStartTime(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _endTimeController,
                    labelText: 'Selesai',
                    prefixIcon: Icons.access_time_rounded,
                    readOnly: true,
                    onTap: () => _selectEndTime(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Color Selector
            const Text(
              'Pilih Warna Penanda',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colorOptions.length,
                itemBuilder: (context, index) {
                  final colorValue = _colorOptions[index];
                  final isSelected = _selectedColorValue == colorValue;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColorValue = colorValue);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(colorValue),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(colorValue).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),

            CustomButton(
              text: 'Simpan Perubahan',
              onTap: _updateSchedule,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
