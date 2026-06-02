import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/task_model.dart';
import '../../models/study_session_model.dart';
import '../../models/schedule_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_helper.dart';
import '../../screens/study_session/edit_session_screen.dart';
import '../../screens/study_session/add_session_screen.dart';
import 'edit_task_screen.dart';
import '../../screens/schedule/edit_schedule_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  List<StudySessionModel> _sessions = [];
  bool _isLoading = true;
  late TaskModel _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _loadSessions();
    _loadLinkedSchedule();
  }

  Future<void> _createScheduleFromTask() async {
    // Pre-fill schedule with task data
    final messenger = ScaffoldMessenger.of(context);
    final schedule = ScheduleModel(
      title: _task.title,
      location: '',
      date: _task.dueDate,
      startTime: '09:00',
      endTime: '10:00',
      color: 0xFF6366F1,
      lecturer: '',
    );
    final newId = await DbHelper.insertSchedule(schedule);
    // Update task with linked scheduleId
    final updatedTask = _task.copyWith(scheduleId: newId);
    await DbHelper.updateTask(updatedTask);
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Jadwal berhasil dibuat dan ditautkan')));
    setState(() => _task = updatedTask);
    _loadLinkedSchedule();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final sessions = await DbHelper.getStudySessionsByTaskId(_task.id!);
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  ScheduleModel? _linkedSchedule;

  Future<void> _loadLinkedSchedule() async {
    if (_task.scheduleId == null) return;
    final s = await DbHelper.getScheduleById(_task.scheduleId!);
    setState(() => _linkedSchedule = s);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditTaskScreen(task: widget.task)),
              ).then((_) => _loadSessions());
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.description,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(label: Text(_task.category)),
                const SizedBox(width: 8),
                Chip(label: Text(_task.priority)),
                const Spacer(),
                Text(DateHelper.formatShortDate(_task.dueDate)),
              ],
            ),
            const SizedBox(height: 16),
            // Linked schedule block
            if (_linkedSchedule != null) ...[
              const Text('Jadwal Terkait', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: Text(_linkedSchedule!.title),
                  subtitle: Text('${DateHelper.formatShortDate(_linkedSchedule!.date)} • ${_linkedSchedule!.startTime}-${_linkedSchedule!.endTime}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () async {
                          final localContext = context;
                          await Navigator.push(
                            localContext,
                            MaterialPageRoute(builder: (_) => EditScheduleScreen(schedule: _linkedSchedule!)),
                          );
                          _loadLinkedSchedule();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.link_off_rounded),
                        tooltip: 'Unlink Jadwal',
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          // remove link from task
                          final updated = _task.copyWith(scheduleId: null);
                          await DbHelper.updateTask(updated);
                          if (!mounted) return;
                          setState(() => _task = updated);
                          _linkedSchedule = null;
                          messenger.showSnackBar(const SnackBar(content: Text('Tautan jadwal dihapus')));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Belum ada jadwal terkait', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _createScheduleFromTask,
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: const Text('Buat Jadwal'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            const Text('Sesi Belajar Terkait', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sessions.isEmpty
                      ? Center(child: Text('Belum ada sesi terkait', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)))
                      : ListView.builder(
                          itemCount: _sessions.length,
                          itemBuilder: (context, index) {
                            final s = _sessions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(s.subject),
                                subtitle: Text('${DateHelper.formatShortDate(s.date)} • ${s.durationSeconds ~/ 60} menit'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit_rounded),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => EditSessionScreen(session: s)),
                                    );
                                    _loadSessions();
                                  },
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => EditSessionScreen(session: s)),
                                  );
                                  _loadSessions();
                                },
                              ),
                            );
                          },
                        ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddSessionScreen(initialTaskId: widget.task.id, initialSubject: widget.task.title),
            ),
          );
          _loadSessions();
        },
        icon: const Icon(Icons.menu_book_rounded),
        label: const Text('Tambah Sesi'),
      ),
    );
  }
}
