import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/schedule_model.dart';
import '../../utils/date_helper.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddScheduleScreen extends StatefulWidget {
  final DateTime initialDate;

  const AddScheduleScreen({super.key, required this.initialDate});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _lecturerController = TextEditingController();
  final _dateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  late DateTime _selectedDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 30);
  int _selectedColorValue = 0xFF6366F1;

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
    _selectedDate = widget.initialDate;
    _dateController.text = DateHelper.formatShortDate(_selectedDate);
    _startTimeController.text = DateHelper.formatTimeOfDay(_startTime.hour, _startTime.minute);
    _endTimeController.text = DateHelper.formatTimeOfDay(_endTime.hour, _endTime.minute);
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
        _startTimeController.text = DateHelper.formatTimeOfDay(_startTime.hour, _startTime.minute);
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
        _endTimeController.text = DateHelper.formatTimeOfDay(_endTime.hour, _endTime.minute);
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (_formKey.currentState!.validate()) {
      final schedule = ScheduleModel(
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        date: _selectedDate,
        startTime: _startTimeController.text,
        endTime: _endTimeController.text,
        color: _selectedColorValue,
        lecturer: _lecturerController.text.trim(),
      );

      await DbHelper.insertSchedule(schedule);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal berhasil ditambahkan')),
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
        title: const Text('Add Schedule'),
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
              text: 'Simpan Jadwal',
              onTap: _saveSchedule,
              icon: Icons.save_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
