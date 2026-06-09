import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/deck_model.dart';
import '../../models/flashcard_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'study_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  final DeckModel deck;

  const DeckDetailScreen({super.key, required this.deck});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  List<FlashcardModel> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final cards = await DbHelper.getAllFlashcards(widget.deck.id!);
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCard(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    await DbHelper.deleteFlashcard(id);
    _loadCards();
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Kartu berhasil dihapus')),
    );
  }

  void _showAddCardSheet({FlashcardModel? editCard}) {
    final questionController = TextEditingController(text: editCard?.question ?? '');
    final answerController = TextEditingController(text: editCard?.answer ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  editCard != null ? 'Edit Kartu' : 'Tambah Kartu Baru',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: questionController,
                  labelText: 'Pertanyaan',
                  hintText: 'Tulis pertanyaan di sini...',
                  prefixIcon: Icons.help_outline_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: answerController,
                  labelText: 'Jawaban',
                  hintText: 'Tulis jawaban di sini...',
                  prefixIcon: Icons.lightbulb_outline_rounded,
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: editCard != null ? 'Simpan Perubahan' : 'Tambah Kartu',
                  icon: Icons.save_rounded,
                  onTap: () async {
                    if (questionController.text.trim().isEmpty ||
                        answerController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pertanyaan dan jawaban harus diisi')),
                      );
                      return;
                    }

                    if (editCard != null) {
                      final updated = editCard.copyWith(
                        question: questionController.text.trim(),
                        answer: answerController.text.trim(),
                      );
                      await DbHelper.updateFlashcard(updated);
                    } else {
                      final card = FlashcardModel(
                        deckId: widget.deck.id!,
                        question: questionController.text.trim(),
                        answer: answerController.text.trim(),
                      );
                      await DbHelper.insertFlashcard(card);
                    }

                    if (!mounted) return;
                    Navigator.pop(context);
                    _loadCards();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deckColor = Color(widget.deck.color);
    final learnedCount = _cards.where((c) => c.isLearned).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.title),
        actions: [
          if (_cards.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: 'Reset semua progress',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                for (final card in _cards) {
                  if (card.isLearned) {
                    await DbHelper.updateFlashcard(card.copyWith(isLearned: false));
                  }
                }
                _loadCards();
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Progress telah direset')),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Deck header with stats
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        deckColor,
                        deckColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: deckColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.deck.description.isNotEmpty)
                        Text(
                          widget.deck.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      if (widget.deck.description.isNotEmpty)
                        const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatChip(Icons.style_rounded, '${_cards.length} Kartu'),
                          const SizedBox(width: 12),
                          _buildStatChip(Icons.check_circle_rounded, '$learnedCount Dipahami'),
                          const SizedBox(width: 12),
                          _buildStatChip(Icons.pending_rounded, '${_cards.length - learnedCount} Belum'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Start study button
                      if (_cards.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudyScreen(
                                    deck: widget.deck,
                                    cards: _cards,
                                  ),
                                ),
                              ).then((_) => _loadCards());
                            },
                            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                            label: const Text(
                              'Mulai Belajar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.25),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Card list
                Expanded(
                  child: _cards.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.note_add_rounded,
                                size: 64,
                                color: isDark
                                    ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                                    : AppColors.lightTextSecondary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada kartu flash',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap tombol + untuk menambahkan kartu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _cards.length,
                          itemBuilder: (context, index) {
                            final card = _cards[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: card.isLearned
                                        ? AppColors.success.withValues(alpha: 0.5)
                                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: card.isLearned
                                              ? AppColors.success.withValues(alpha: 0.1)
                                              : deckColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          card.isLearned
                                              ? Icons.check_circle_rounded
                                              : Icons.help_outline_rounded,
                                          color: card.isLearned ? AppColors.success : deckColor,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              card.question,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              card.answer,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _showAddCardSheet(editCard: card);
                                          } else if (value == 'delete') {
                                            _deleteCard(card.id!);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                                        ],
                                        icon: Icon(
                                          Icons.more_vert_rounded,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCardSheet(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
