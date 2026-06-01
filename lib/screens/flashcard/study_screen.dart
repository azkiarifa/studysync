import 'dart:math';
import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/deck_model.dart';
import '../../models/flashcard_model.dart';
import '../../theme/app_colors.dart';

class StudyScreen extends StatefulWidget {
  final DeckModel deck;
  final List<FlashcardModel> cards;

  const StudyScreen({super.key, required this.deck, required this.cards});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFlipped = false;
  int _learnedInSession = 0;
  int _reviewedInSession = 0;
  bool _isCompleted = false;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  Future<void> _markLearned() async {
    final card = widget.cards[_currentIndex];
    if (!card.isLearned) {
      await DbHelper.updateFlashcard(card.copyWith(isLearned: true));
    }
    setState(() => _learnedInSession++);
    _nextCard();
  }

  void _markReview() {
    setState(() => _reviewedInSession++);
    _nextCard();
  }

  Future<void> _nextCard() async {
    // Reset flip state
    if (_isFlipped) {
      _flipController.reverse();
      _isFlipped = false;
    }

    // Slide out animation
    await _slideController.forward();

    if (_currentIndex < widget.cards.length - 1) {
      setState(() => _currentIndex++);
      _slideController.reset();
    } else {
      setState(() => _isCompleted = true);
    }
  }

  void _restartStudy() {
    setState(() {
      _currentIndex = 0;
      _isFlipped = false;
      _learnedInSession = 0;
      _reviewedInSession = 0;
      _isCompleted = false;
    });
    _flipController.reset();
    _slideController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deckColor = Color(widget.deck.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.title),
        actions: [
          if (!_isCompleted)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: deckColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.cards.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: deckColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isCompleted ? _buildCompletionScreen(isDark, deckColor) : _buildStudyCard(isDark, deckColor),
    );
  }

  Widget _buildStudyCard(bool isDark, Color deckColor) {
    final card = widget.cards[_currentIndex];

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.cards.length,
              minHeight: 5,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation<Color>(deckColor),
            ),
          ),
        ),

        // Card area
        Expanded(
          child: SlideTransition(
            position: _slideAnimation,
            child: GestureDetector(
              onTap: _flipCard,
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * pi;
                  final isFront = angle < pi / 2;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // perspective
                      ..rotateY(angle),
                    child: isFront
                        ? _buildCardFace(
                            card.question,
                            'PERTANYAAN',
                            Icons.help_outline_rounded,
                            deckColor,
                            isDark,
                          )
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(pi),
                            child: _buildCardFace(
                              card.answer,
                              'JAWABAN',
                              Icons.lightbulb_rounded,
                              AppColors.success,
                              isDark,
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
        ),

        // Tap hint
        if (!_isFlipped)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Tap kartu untuk melihat jawaban',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // Action buttons (only when flipped)
        if (_isFlipped)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Pelajari Lagi',
                    icon: Icons.refresh_rounded,
                    color: AppColors.warning,
                    onTap: _markReview,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    label: 'Sudah Paham',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    onTap: _markLearned,
                  ),
                ),
              ],
            ),
          ),

        if (!_isFlipped) const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCardFace(String text, String label, IconData icon, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionScreen(bool isDark, Color deckColor) {
    final total = widget.cards.length;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Trophy / success icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.success,
                    AppColors.success.withValues(alpha: 0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Sesi Selesai! 🎉',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamu sudah menyelesaikan $total kartu',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatCard(
                  icon: Icons.check_circle_rounded,
                  label: 'Paham',
                  value: _learnedInSession.toString(),
                  color: AppColors.success,
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  icon: Icons.refresh_rounded,
                  label: 'Review',
                  value: _reviewedInSession.toString(),
                  color: AppColors.warning,
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  icon: Icons.style_rounded,
                  label: 'Total',
                  value: total.toString(),
                  color: deckColor,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _restartStudy,
                icon: const Icon(Icons.replay_rounded),
                label: const Text(
                  'Ulangi Sesi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text(
                  'Kembali ke Deck',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

