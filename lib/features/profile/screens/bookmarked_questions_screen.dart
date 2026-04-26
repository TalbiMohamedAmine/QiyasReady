import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adaptive_practice/adaptive_practice_service.dart';
import '../../practice/services/bookmark_service.dart';

class BookmarkedQuestionsScreen extends ConsumerWidget {
  const BookmarkedQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final bookmarksAsync = ref.watch(bookmarkedQuestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Questions'),
      ),
      body: SafeArea(
        child: bookmarksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load saved questions.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (bookmarks) {
            if (bookmarks.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 64,
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "You haven't saved any questions yet.",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the bookmark icon on any question during practice to save it for later review.',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: bookmarks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _BookmarkCard(
                      bookmark: bookmarks[index],
                      colorScheme: colorScheme,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BookmarkCard extends ConsumerStatefulWidget {
  const _BookmarkCard({
    required this.bookmark,
    required this.colorScheme,
  });

  final BookmarkedQuestion bookmark;
  final ColorScheme colorScheme;

  @override
  ConsumerState<_BookmarkCard> createState() => _BookmarkCardState();
}

class _BookmarkCardState extends ConsumerState<_BookmarkCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bm = widget.bookmark;
    final colorScheme = widget.colorScheme;

    final correctOption = bm.options
        .where((o) => o.id == bm.correctOptionId)
        .firstOrNull;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (bm.subject.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        bm.subject,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      await ref
                          .read(bookmarkServiceProvider)
                          .removeBookmark(bm.questionId);

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Question removed from saved.'),
                          ),
                        );
                    },
                    icon: Icon(
                      Icons.bookmark_remove_rounded,
                      color: colorScheme.error,
                    ),
                    tooltip: 'Remove bookmark',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                bm.stem,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isExpanded ? 'Hide details' : 'Show answer & explanation',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                for (final option in bm.options) ...[
                  _OptionRow(
                    option: option,
                    isCorrect: option.id == bm.correctOptionId,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 6),
                ],
                if (correctOption != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F7F0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF9FD8AE),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF1B7F5B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Correct: ${correctOption.text}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B7F5B),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (bm.staticExplanation.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Explanation',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bm.staticExplanation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.isCorrect,
    required this.colorScheme,
  });

  final PracticeOption option;
  final bool isCorrect;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCorrect
            ? const Color(0xFFE7F7F0)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF1B7F5B)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: isCorrect
                ? const Color(0xFF1B7F5B)
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              option.text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
