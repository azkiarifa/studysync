import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../database/db_helper.dart';
import '../../services/sharedpref_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_text.dart';
import '../../widgets/custom_bottom_navbar.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/progress_painter.dart';

// Import target screens for shortcuts
import '../task/task_screen.dart';
import '../schedule/schedule_screen.dart';
import '../notes/notes_screen.dart';
import '../notes/review_materi_screen.dart';
import '../habit/habit_screen.dart';
import '../target/target_screen.dart';
import '../study_session/session_screen.dart';
import '../pomodoro/pomodoro_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Dashboard Stats State
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;
  String _username = '';
  double _semesterProgress = 0.75;
  List<double> _weeklyProductivity = [0, 0, 0, 0, 0, 0, 0];
  double _maxY = 10.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    // Load Username & Semester Info from SharedPreferences
    _username = SharedPrefService.username;
    final semString = SharedPrefService.semester;

    // Calculate semester progress dynamically (assuming standard 8-semester course)
    final semesterNum =
        int.tryParse(semString.replaceAll(RegExp(r'[^0-9]'), '')) ?? 4;
    _semesterProgress = semesterNum / 8.0;

    // Load Task Stats and Productivity from DB
    try {
      final tasks = await DbHelper.getAllTasks();
      _totalTasks = tasks.length;
      _completedTasks = tasks.where((t) => t.isCompleted).length;
      _pendingTasks = _totalTasks - _completedTasks;

      // Load Study Sessions and Pomodoros
      final studySessions = await DbHelper.getAllStudySessions();
      final pomodoros = await DbHelper.getAllPomodoroHistory();

      // Calculate Weekly Productivity (Monday - Sunday of the current week)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final monday = today.subtract(Duration(days: today.weekday - 1));

      _weeklyProductivity = List.generate(7, (i) {
        final targetDay = monday.add(Duration(days: i));

        bool isSameDay(DateTime d1, DateTime d2) {
          return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
        }

        // Score formulation:
        // Completed Tasks due today = 2.0 pts each
        final completedTasksOnDay = tasks
            .where((t) => t.isCompleted && isSameDay(t.dueDate, targetDay))
            .length;
        double dayScore = completedTasksOnDay * 2.0;

        // Study sessions today = 3.0 pts per hour of study
        final sessionsOnDay = studySessions.where(
          (s) => isSameDay(s.date, targetDay),
        );
        double studyHours = 0;
        for (var s in sessionsOnDay) {
          studyHours += s.durationSeconds / 3600.0;
        }
        dayScore += studyHours * 3.0;

        // Completed Pomodoros today = 1.5 pts each
        final pomodorosOnDay = pomodoros
            .where((p) => isSameDay(p.dateTime, targetDay))
            .length;
        dayScore += pomodorosOnDay * 1.5;

        return double.parse(dayScore.toStringAsFixed(1));
      });

      // Adjust maxY dynamically based on the highest productivity day, minimum 10.0
      double maxScore = 10.0;
      for (var score in _weeklyProductivity) {
        if (score > maxScore) {
          maxScore = score;
        }
      }
      _maxY =
          (maxScore / 5.0).ceil() * 5.0; // Round to nearest upper multiple of 5
    } catch (e) {
      // In case table doesn't exist yet, handle gracefully
      _totalTasks = 15;
      _completedTasks = 10;
      _pendingTasks = 5;
      _weeklyProductivity = [5.0, 7.0, 4.0, 8.0, 3.0, 6.0, 9.0];
      _maxY = 10.0;
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: _currentIndex,
                children: [
                  _buildDashboardTab(isDark),
                  _buildPlannerTab(isDark),
                  _buildMoreTab(isDark),
                ],
              ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Refresh dashboard data when navigating back to it
          if (index == 0) {
            _loadDashboardData();
          }
        },
      ),
    );
  }

  // --- TAB 1: DASHBOARD ---
  Widget _buildDashboardTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Greeting
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi $_username 👋',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppText.get('welcomeBack'),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    ).then((_) => _loadDashboardData());
                  },
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Icon(
                      SharedPrefService.profileImage.isEmpty
                          ? Icons.person_rounded
                          : Icons.account_circle_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Semester Progress Card (75%)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppText.get('semesterProgress'),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          SharedPrefService.semester,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppText.get('keepPerformance'),
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Custom Circular Progress Painter
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CustomPaint(
                      painter: ProgressPainter(
                        progress: _semesterProgress,
                        trackColor: Colors.white.withOpacity(0.15),
                        progressColors: [Colors.white, AppColors.secondary],
                        strokeWidth: 8,
                      ),
                      child: Center(
                        child: Text(
                          '${(_semesterProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Cards Row
            Row(
              children: [
                DashboardCard(
                  title: AppText.get('totalTasks'),
                  value: '$_totalTasks',
                  icon: Icons.assignment_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                DashboardCard(
                  title: AppText.get('completed'),
                  value: '$_completedTasks',
                  icon: Icons.task_alt_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(width: 12),
                DashboardCard(
                  title: AppText.get('pending'),
                  value: '$_pendingTasks',
                  icon: Icons.pending_actions_rounded,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Weekly Productivity Title
            Text(
              AppText.get('weeklyProductivity'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Chart Container
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder.withOpacity(0.5)
                      : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          );
                          Widget text;
                          switch (value.toInt()) {
                            case 0:
                              text = const Text('M', style: style);
                              break;
                            case 1:
                              text = const Text('T', style: style);
                              break;
                            case 2:
                              text = const Text('W', style: style);
                              break;
                            case 3:
                              text = const Text('T', style: style);
                              break;
                            case 4:
                              text = const Text('F', style: style);
                              break;
                            case 5:
                              text = const Text('S', style: style);
                              break;
                            case 6:
                              text = const Text('S', style: style);
                              break;
                            default:
                              text = const Text('', style: style);
                              break;
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: text,
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark
                            ? AppColors.darkBorder.withOpacity(0.5)
                            : AppColors.lightBorder,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    return _buildBarGroup(
                      index,
                      _weeklyProductivity[index],
                      isDark,
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, bool isDark) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: AppColors.primaryGradient,
          width: 14,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: _maxY,
            color: isDark ? AppColors.darkBg : const Color(0xFFF1F5F9),
          ),
        ),
      ],
    );
  }

  // --- TAB 2: PLANNER ---
  Widget _buildPlannerTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.get('planner'),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            AppText.get('plannerDesc'),
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 28),

          _buildShortcutCard(
            title: AppText.get('tasks'),
            subtitle: AppText.get('taskDesc'),
            icon: Icons.checklist_rounded,
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TaskScreen()),
            ),
          ),
          _buildShortcutCard(
            title: AppText.get('schedule'),
            subtitle: AppText.get('scheduleDesc'),
            icon: Icons.calendar_today_rounded,
            color: AppColors.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScheduleScreen()),
            ),
          ),
          _buildShortcutCard(
            title: AppText.get('notes'),
            subtitle: AppText.get('notesDesc'),
            icon: Icons.note_alt_rounded,
            color: AppColors.accent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotesScreen()),
            ),
          ),
          _buildShortcutCard(
            title: AppText.get('habits'),
            subtitle: AppText.get('habitsDesc'),
            icon: Icons.repeat_rounded,
            color: AppColors.success,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HabitScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: MORE ---
  Widget _buildMoreTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.get('more'),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            AppText.get('moreDesc'),
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 28),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildMoreGridItem(
                title: AppText.get('courseTarget'),
                icon: Icons.my_location_rounded,
                color: AppColors.danger,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TargetScreen()),
                ),
              ),
              _buildMoreGridItem(
                title: AppText.get('studySession'),
                icon: Icons.menu_book_rounded,
                color: AppColors.info,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SessionScreen(),
                  ),
                ),
              ),
              _buildMoreGridItem(
                title: AppText.get('reviewMateri'),
                icon: Icons.fact_check_rounded,
                color: AppColors.info,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReviewMateriScreen(),
                  ),
                ),
              ),
              _buildMoreGridItem(
                title: AppText.get('pomodoroShort'),
                icon: Icons.timer_rounded,
                color: AppColors.accent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PomodoroScreen(),
                  ),
                ),
              ),
              _buildMoreGridItem(
                title: AppText.get('profile'),
                icon: Icons.person_outline_rounded,
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                ).then((_) => _loadDashboardData()),
              ),
              _buildMoreGridItem(
                title: AppText.get('settings'),
                icon: Icons.settings_rounded,
                color: Colors.grey,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ).then((_) => _loadDashboardData()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withOpacity(0.5)
              : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextSecondary.withOpacity(0.6)
                      : AppColors.lightTextSecondary.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreGridItem({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withOpacity(0.5)
              : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
