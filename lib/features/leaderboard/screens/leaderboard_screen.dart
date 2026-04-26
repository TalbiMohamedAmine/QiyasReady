import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/leaderboard_service.dart';

// --- Colors & Aesthetics from WelcomeScreen ---
class _C {
  static const primary       = Color(0xFF1A6BFF);
  static const primaryLight  = Color(0xFFE8F0FF);
  static const bg            = Color(0xFFFFFFFF);
  static const surface       = Color(0xFFF7F8FC);
  static const textPrimary   = Color(0xFF1A1A2E);
  static const textMuted     = Color(0xFF6B7280);
  static const border        = Color(0xFFE0E0E0);
  static const cardBg        = Color(0xFFFFFFFF);
}

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top50Async = ref.watch(top50LeaderboardProvider);
    final currentUserRankAsync = ref.watch(currentUserRankProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text(
          'Global Leaderboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _C.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: _C.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _C.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: _C.border,
            height: 1.0,
          ),
        ),
      ),
      body: top50Async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _C.primary),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error loading leaderboard: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'No practice data available yet.',
                style: TextStyle(color: _C.textMuted),
              ),
            );
          }

          final top3 = entries.take(3).toList();
          final others = entries.skip(3).toList();

          return Stack(
            children: [
              // Main Scrollable Content
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Container(
                        color: _C.surface,
                        padding: const EdgeInsets.fromLTRB(16, 32, 16, 48),
                        child: _PodiumWidget(top3: top3),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = others[index];
                        return _LeaderboardListItem(entry: entry);
                      },
                      childCount: others.length,
                    ),
                  ),
                  // Padding at the bottom to avoid overlap with sticky bar
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
              ),

              // Sticky Bottom Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: currentUserRankAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (userEntry) {
                    if (userEntry == null) return const SizedBox.shrink();
                    return _StickyBottomBar(entry: userEntry);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PodiumWidget extends StatelessWidget {
  const _PodiumWidget({required this.top3});

  final List<LeaderboardEntry> top3;

  @override
  Widget build(BuildContext context) {
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (second != null)
          Expanded(
            child: _PodiumItem(
              entry: second,
              color: const Color(0xFF9CA3AF), // Silver gray
              height: 140,
              icon: '🥈',
            ),
          ),
        if (first != null)
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _PodiumItem(
                entry: first,
                color: const Color(0xFFF59E0B), // Gold / Amber
                height: 180,
                icon: '👑',
                isFirst: true,
              ),
            ),
          ),
        if (third != null)
          Expanded(
            child: _PodiumItem(
              entry: third,
              color: const Color(0xFFD97706), // Bronze
              height: 110,
              icon: '🥉',
            ),
          ),
      ],
    );
  }
}

class _PodiumItem extends StatelessWidget {
  const _PodiumItem({
    required this.entry,
    required this.color,
    required this.height,
    required this.icon,
    this.isFirst = false,
  });

  final LeaderboardEntry entry;
  final Color color;
  final double height;
  final String icon;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar
        Container(
          padding: EdgeInsets.all(isFirst ? 4 : 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isFirst ? 3 : 2),
          ),
          child: CircleAvatar(
            radius: isFirst ? 32 : 24,
            backgroundColor: _C.primaryLight,
            child: Text(
              entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: _C.primary,
                fontWeight: FontWeight.bold,
                fontSize: isFirst ? 24 : 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Name
        Text(
          entry.name,
          style: TextStyle(
            color: _C.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: isFirst ? 16 : 14,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Score & Fire
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${entry.score}',
              style: TextStyle(
                color: _C.primary,
                fontWeight: FontWeight.bold,
                fontSize: isFirst ? 16 : 14,
              ),
            ),
            if (entry.score > 50)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('🔥', style: TextStyle(fontSize: 14)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Podium Block
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color, width: 2), // UNIFORM BORDER FIX
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                icon,
                style: TextStyle(fontSize: isFirst ? 36 : 28),
              ),
              const SizedBox(height: 8),
              Text(
                '${entry.rank}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: isFirst ? 42 : 32,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderboardListItem extends StatelessWidget {
  const _LeaderboardListItem({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = entry.isCurrentUser;
    final bgColor = isCurrentUser ? _C.primaryLight : _C.cardBg;
    final borderColor = isCurrentUser ? _C.primary : _C.border;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isCurrentUser ? 1.5 : 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Rank Number
          SizedBox(
            width: 40,
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: isCurrentUser ? _C.primary : _C.textMuted,
              ),
            ),
          ),
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: isCurrentUser ? Colors.white : _C.surface,
            child: Text(
              entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: _C.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name
          Expanded(
            child: Text(
              entry.name,
              style: TextStyle(
                fontSize: 15,
                color: _C.textPrimary,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Score & Fire Emoji
          if (entry.score > 50)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Text('🔥', style: TextStyle(fontSize: 16)),
            ),
          Text(
            '${entry.score} pts',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isCurrentUser ? _C.primary : _C.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyBottomBar extends StatelessWidget {
  const _StickyBottomBar({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: 20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: _C.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x331A6BFF),
            blurRadius: 32,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'My Rank',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '#${entry.rank}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Questions Answered',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  if (entry.score > 50)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Text('🔥', style: TextStyle(fontSize: 18)),
                    ),
                  Text(
                    '${entry.score}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
