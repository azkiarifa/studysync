import 'dart:async';
import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/pomodoro_model.dart';
import '../../services/sharedpref_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_text.dart';
import '../../utils/date_helper.dart';
import 'pomodoro_history_screen.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  // Configs
  int _focusDurationMins = 25;
  int _breakDurationMins = 5;

  // Timer State
  Timer? _timer;
  int _secondsLeft = 25 * 60;
  bool _isRunning = false;
  bool _isFocusMode = true; // true = Focus, false = Break

  String _selectedCategory = 'Belajar';
  final List<String> _categories = ['Belajar', 'Tugas', 'Projek', 'Lainnya'];

  bool get _notificationsEnabled => SharedPrefService.notification;
  bool get _focusModeEnabled => SharedPrefService.focusMode;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _focusDurationMins * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timerCompleted();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsLeft =
          (_isFocusMode ? _focusDurationMins : _breakDurationMins) * 60;
    });
  }

  Future<void> _timerCompleted() async {
    _timer?.cancel();
    setState(() => _isRunning = false);

    if (_isFocusMode) {
      // Log Focus Session to Database
      final pomodoro = PomodoroModel(
        durationMinutes: _focusDurationMins,
        dateTime: DateTime.now(),
        category: _selectedCategory,
      );
      await DbHelper.insertPomodoroHistory(pomodoro);

      if (mounted && _notificationsEnabled) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Fokus Selesai! 🎉'),
            content: Text(
              'Selamat! Anda telah menyelesaikan $_focusDurationMins menit fokus untuk kategori $_selectedCategory. Waktunya istirahat sejenak.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _switchToBreak();
                },
                child: const Text('Mulai Istirahat'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted && _notificationsEnabled) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Istirahat Selesai! ☕'),
            content: const Text(
              'Istirahat Anda sudah habis. Siap untuk fokus kembali?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _switchToFocus();
                },
                child: const Text('Mulai Fokus'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _switchToBreak() {
    setState(() {
      _isFocusMode = false;
      _secondsLeft = _breakDurationMins * 60;
    });
    _startTimer();
  }

  void _switchToFocus() {
    setState(() {
      _isFocusMode = true;
      _secondsLeft = _focusDurationMins * 60;
    });
    _startTimer();
  }

  // Developer Cheat: skip timer instantly
  void _cheatFastForward() {
    if (_focusModeEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppText.get('focusDisabled'))));
      return;
    }
    setState(() {
      _secondsLeft = 3; // Jump to 3 seconds remaining
    });
  }

  double get _progressPercent {
    final totalSecs =
        (_isFocusMode ? _focusDurationMins : _breakDurationMins) * 60;
    return 1 - (_secondsLeft / totalSecs);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppText.get('pomodoro')),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Riwayat Pomodoro',
            onPressed: _focusModeEnabled && _isRunning
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PomodoroHistoryScreen(),
                      ),
                    );
                  },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              if (_focusModeEnabled) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.do_not_disturb_on_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppText.get('focusActive'),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _isFocusMode
                      ? AppColors.accent.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isFocusMode
                          ? Icons.my_location_rounded
                          : Icons.coffee_rounded,
                      color: _isFocusMode
                          ? AppColors.accent
                          : AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isFocusMode ? 'WAKTUNYA FOKUS' : 'ISTIRAHAT SEJENAK',
                      style: TextStyle(
                        color: _isFocusMode
                            ? AppColors.accent
                            : AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Visual Countdown Ring Stack
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow Ring
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: _progressPercent,
                      strokeWidth: 10,
                      backgroundColor: isDark
                          ? AppColors.darkCard
                          : const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isFocusMode ? AppColors.accent : AppColors.success,
                      ),
                    ),
                  ),
                  // Time Counter Text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateHelper.formatDuration(_secondsLeft),
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isFocusMode ? 'Focus Session' : 'Take a Break',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Category Selector (If in Focus Mode)
              if (_isFocusMode) ...[
                const Text(
                  'Fokus Untuk Kategori:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            if (!_focusModeEnabled || !_isRunning) {
                              setState(() => _selectedCategory = cat);
                            }
                          }
                        },
                        selectedColor: AppColors.accent,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Controls Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset Button
                  IconButton.filledTonal(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.replay_rounded),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(54, 54),
                      backgroundColor: isDark
                          ? AppColors.darkCard
                          : Colors.white,
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Start/Pause Button
                  IconButton.filled(
                    onPressed: _toggleTimer,
                    icon: Icon(
                      _isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 32,
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(70, 70),
                      backgroundColor: _isFocusMode
                          ? AppColors.accent
                          : AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Fast Forward Cheat (Double Arrow)
                  IconButton.filledTonal(
                    onPressed: _isRunning && !_focusModeEnabled
                        ? _cheatFastForward
                        : null,
                    icon: const Icon(Icons.fast_forward_rounded),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(54, 54),
                      backgroundColor: isDark
                          ? AppColors.darkCard
                          : Colors.white,
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
