import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../database/db_helper.dart';
import '../../models/study_session_model.dart';
import '../../models/task_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_text.dart';
import '../../utils/date_helper.dart';
import 'add_session_screen.dart';
import 'edit_session_screen.dart';
import '../task/add_task_screen.dart';
import '../task/task_detail_screen.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  List<StudySessionModel> _sessions = [];
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  Map<int, String> _taskTitles = {};
  int? _selectedTaskId;

  // Timer State
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isTimerRunning = false;
  final TextEditingController _subjectController = TextEditingController(
    text: 'Pengujian Perangkat Lunak',
  );

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await DbHelper.getAllTasks();
      final sessions = await DbHelper.getAllStudySessions();
      setState(() {
        _tasks = tasks;
        _taskTitles = {
          for (final task in tasks)
            if (task.id != null) task.id!: task.title,
        };
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppText.get('studyTooShort'))));
      _resetTimer();
      return;
    }

    final subject = _subjectController.text.trim().isEmpty
        ? 'Pengujian Perangkat Lunak'
        : _subjectController.text.trim();
    final selectedTaskId = _selectedTaskId;
    _resetTimer();

    // Show quick dialog to add study notes
    final noteController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${AppText.get('studyFinished')} $subject!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${AppText.get('duration')}: ${DateHelper.formatDuration(duration)}',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: AppText.get('studyNotes'),
                  hintText: AppText.get('studyNotesHint'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppText.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final session = StudySessionModel(
                  taskId: selectedTaskId,
                  subject: subject,
                  date: DateTime.now(),
                  durationSeconds: duration,
                  notes: noteController.text.trim(),
                );
                await DbHelper.insertStudySession(session);
                Navigator.pop(context);
                _loadSessions();
              },
              child: Text(AppText.get('saveLog')),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppText.get('studyDeleted'))));
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
        title: Text(AppText.get('studySession')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: AppText.get('addManual'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddSessionScreen(),
                ),
              ).then((_) => _loadSessions());
            },
          ),
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
                // Task-based subject picker
                DropdownButtonFormField<int?>(
                  value: _selectedTaskId,
                  dropdownColor: AppColors.primary,
                  decoration: InputDecoration(
                    labelText: AppText.get('chooseStudyTask'),
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  iconEnabledColor: Colors.white,
                  style: const TextStyle(color: Colors.white),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        AppText.get('noTaskLink'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    ..._tasks.map((task) {
                      return DropdownMenuItem<int?>(
                        value: task.id,
                        child: Text(
                          task.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (int? value) {
                    setState(() {
                      _selectedTaskId = value;
                      if (value != null) {
                        final selectedTask = _tasks.firstWhere(
                          (task) => task.id == value,
                          orElse: () => TaskModel(
                            title: '',
                            description: '',
                            dueDate: DateTime.now(),
                            priority: 'Low',
                            category: 'Lainnya',
                          ),
                        );
                        if (selectedTask.id != null) {
                          _subjectController.text = selectedTask.title;
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 24),
                // Subject Input
                TextFormField(
                  controller: _subjectController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: AppText.get('studySubjectQuestion'),
                    hintText: AppText.get('studySubjectHint'),
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
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
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(
                  AppText.get('studyHistory'),
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
                      AppText.get('noStudyHistory'),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
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
                                onPressed: (context) async {
                                  final newTaskId = await Navigator.push<int?>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddTaskScreen(
                                        initialTitle: session.subject,
                                        initialDescription: session.notes,
                                        initialDate: session.date,
                                      ),
                                    ),
                                  );
                                  if (newTaskId != null) {
                                    final updated = session.copyWith(
                                      taskId: newTaskId,
                                    );
                                    await DbHelper.updateStudySession(updated);
                                    _loadSessions();
                                    if (mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppText.get('sessionLinkedToTask'),
                                          ),
                                        ),
                                      );
                                  }
                                },
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                icon: Icons.post_add_rounded,
                                label: AppText.get('createTask'),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                              SlidableAction(
                                onPressed: (context) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditSessionScreen(session: session),
                                    ),
                                  ).then((_) => _loadSessions());
                                },
                                backgroundColor: AppColors.info,
                                foregroundColor: Colors.white,
                                icon: Icons.edit_rounded,
                                label: AppText.get('edit'),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                              SlidableAction(
                                onPressed: (context) =>
                                    _deleteSession(session.id!),
                                backgroundColor: AppColors.danger,
                                foregroundColor: Colors.white,
                                icon: Icons.delete_rounded,
                                label: AppText.get('delete'),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${AppText.get('duration')}: $durationMins ${AppText.get('minutes')} $durationLeftSecs ${AppText.get('seconds')}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (session.taskId != null)
                                    GestureDetector(
                                      onTap: () async {
                                        final task = await DbHelper.getTaskById(
                                          session.taskId!,
                                        );
                                        if (task != null) {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  TaskDetailScreen(task: task),
                                            ),
                                          );
                                          _loadSessions();
                                        } else {
                                          if (mounted)
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  AppText.get('taskNotFound'),
                                                ),
                                              ),
                                            );
                                        }
                                      },
                                      child: Text(
                                        '${AppText.get('linkedTask')}: ${_taskTitles[session.taskId] ?? AppText.get('deletedTask')}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  if (session.notes.isNotEmpty)
                                    Text(
                                      session.notes,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Text(
                                DateHelper.formatShortDate(session.date),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
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
