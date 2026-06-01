import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../database/db_helper.dart';
import '../../models/study_session_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_helper.dart';
import 'add_session_screen.dart';
import 'edit_session_screen.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  List<StudySessionModel> _sessions = [];
  bool _isLoading = true;

  // Timer State
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isTimerRunning = false;
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
    _loadSessions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await DbHelper.getAllStudySessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    if (_isTimerRunning) return;
    setState(() {
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _secondsElapsed = 0;
    });
  }

  Future<void> _stopAndSaveTimer() async {
    _timer?.cancel();
    final duration = _secondsElapsed;
    if (duration < 5) {
      // Too short to log
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi belajar terlalu singkat untuk disimpan')),
      );
      _resetTimer();
      return;
    }

    final subject = _selectedSubject;
    _resetTimer();

    // Show quick dialog to add study notes
    final noteController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selesai Belajar $subject!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Durasi: ${DateHelper.formatDuration(duration)}'),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan Belajar',
                  hintText: 'Mempelajari materi bab 3...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final session = StudySessionModel(
                  subject: subject,
                  date: DateTime.now(),
                  durationSeconds: duration,
                  notes: noteController.text.trim(),
                );
                await DbHelper.insertStudySession(session);
                Navigator.pop(context);
                _loadSessions();
              },
              child: const Text('Simpan Log'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSession(int id) async {
    await DbHelper.deleteStudySession(id);
    _loadSessions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi belajar berhasil dihapus')),
      );
    }
  }

  String _formatStopwatch(int totalSecs) {
    final hrs = totalSecs ~/ 3600;
    final mins = (totalSecs % 3600) ~/ 60;
    final secs = totalSecs % 60;
    return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah manual',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddSessionScreen()),
              ).then((_) => _loadSessions());
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Timer Widget Card
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Subject Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  dropdownColor: AppColors.darkCard,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Mata Kuliah Belajar',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _subjects.map((sub) {
                    return DropdownMenuItem<String>(
                      value: sub,
                      child: Text(sub),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedSubject = val);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Stopwatch Display
                Text(
                  _formatStopwatch(_secondsElapsed),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 24),

                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isTimerRunning)
                      IconButton.filledTonal(
                        onPressed: _pauseTimer,
                        icon: const Icon(Icons.pause_rounded, size: 28),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(60, 60),
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      IconButton.filledTonal(
                        onPressed: _startTimer,
                        icon: const Icon(Icons.play_arrow_rounded, size: 32),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(60, 60),
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    const SizedBox(width: 16),
                    IconButton.filledTonal(
                      onPressed: _secondsElapsed > 0 ? _stopAndSaveTimer : null,
                      icon: const Icon(Icons.stop_rounded, size: 28),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(60, 60),
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Riwayat Belajar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Session Logs History List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sessions.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada riwayat sesi belajar',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          final durationMins = session.durationSeconds ~/ 60;
                          final durationLeftSecs = session.durationSeconds % 60;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Slidable(
                              key: ValueKey(session.id),
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(),
                                extentRatio: 0.5,
                                children: [
                                  SlidableAction(
                                    onPressed: (context) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditSessionScreen(session: session),
                                        ),
                                      ).then((_) => _loadSessions());
                                    },
                                    backgroundColor: AppColors.info,
                                    foregroundColor: Colors.white,
                                    icon: Icons.edit_rounded,
                                    label: 'Edit',
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                  SlidableAction(
                                    onPressed: (context) => _deleteSession(session.id!),
                                    backgroundColor: AppColors.danger,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete_rounded,
                                    label: 'Hapus',
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                ],
                              ),
                              child: Card(
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.menu_book_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  title: Text(
                                    session.subject,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Durasi: $durationMins menit $durationLeftSecs detik',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      if (session.notes.isNotEmpty)
                                        Text(
                                          session.notes,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Text(
                                    DateHelper.formatShortDate(session.date),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
