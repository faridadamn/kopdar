import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../providers/community_provider.dart';
import '../widgets/advocacy_stat_card.dart';
import '../widgets/petition_card.dart';

/// Advocacy page with stats, petitions, policy updates, and polls.
class AdvocacyPage extends StatefulWidget {
  const AdvocacyPage({super.key});

  @override
  State<AdvocacyPage> createState() => _AdvocacyPageState();
}

class _AdvocacyPageState extends State<AdvocacyPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().fetchAdvocacyData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('📢 Advokasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<CommunityProvider>(
        builder: (context, provider, _) {
          final data = provider.advocacyData;

          if (data == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchAdvocacyData,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Header ──
                _AdvocacyHeader(),
                const SizedBox(height: 20),

                // ── Collective Stats ──
                _SectionTitle(title: '📊 Data Kolektif'),
                const SizedBox(height: 12),
                _StatsGrid(stats: data['stats']),
                const SizedBox(height: 24),

                // ── Petitions ──
                _SectionTitle(title: '✍️ Petisi Aktif'),
                const SizedBox(height: 12),
                ...(data['petitions'] as List<dynamic>? ?? []).map(
                  (petition) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PetitionCard(
                      title: petition['title'] ?? '',
                      description: petition['description'] ?? '',
                      targetSignatures: petition['target_signatures'] ?? 0,
                      currentSignatures: petition['current_signatures'] ?? 0,
                      hasSigned: petition['has_signed'] ?? false,
                      onSign: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tanda tangan berhasil! ✊'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Policy Updates ──
                _SectionTitle(title: '📋 Update Kebijakan'),
                const SizedBox(height: 12),
                ...(data['policy_updates'] as List<dynamic>? ?? []).map(
                  (update) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PolicyUpdateCard(
                      title: update['title'] ?? '',
                      date: update['date'] ?? '',
                      summary: update['summary'] ?? '',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Polls ──
                _SectionTitle(title: '🗳️ Jajak Pendapat'),
                const SizedBox(height: 12),
                ...(data['polls'] as List<dynamic>? ?? []).map(
                  (poll) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PollCard(
                      question: poll['question'] ?? '',
                      options: (poll['options'] as List<dynamic>? ?? [])
                          .map((o) => {
                                'id': o['id'] ?? '',
                                'text': o['text'] ?? '',
                                'votes': o['votes'] ?? 0,
                              })
                          .toList(),
                      totalVotes: poll['total_votes'] ?? 0,
                      hasVoted: poll['has_voted'] ?? false,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Advocacy page header.
class _AdvocacyHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B1FA2).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bersama Kita Kuat! ✊',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data kolektif, petisi, dan update kebijakan untuk kesejahteraan driver.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title widget.
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.gray900,
      ),
    );
  }
}

/// Stats grid showing 4 stat cards in a 2x2 grid.
class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic>? stats;

  const _StatsGrid({this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: [
        AdvocacyStatCard(
          icon: Icons.people,
          value: _formatNumber(stats!['total_members'] ?? 0),
          label: 'anggota Jabodetabek',
          color: AppColors.primary,
        ),
        AdvocacyStatCard(
          icon: Icons.trending_up,
          value: 'Rp ${_formatCurrency(stats!['avg_profit'] ?? 0)}/bulan',
          label: 'Rata-rata profit',
          color: AppColors.accent,
        ),
        AdvocacyStatCard(
          icon: Icons.account_balance,
          value: '${stats!['pinjol_percentage'] ?? 0}%',
          label: 'Punya pinjol aktif',
          color: AppColors.danger,
        ),
        AdvocacyStatCard(
          icon: Icons.timer,
          value: '${stats!['avg_hours'] ?? 0} jam/hari',
          label: 'Rata-rata narik',
          color: AppColors.blue,
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1).replaceAll('.0', '')}.${(number % 1000).toString().padLeft(3, '0')}';
    }
    return number.toString();
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}jt';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).round()}rb';
    }
    return amount.toString();
  }
}

/// Policy update card.
class _PolicyUpdateCard extends StatelessWidget {
  final String title;
  final String date;
  final String summary;

  const _PolicyUpdateCard({
    required this.title,
    required this.date,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.policy,
                  size: 18,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.gray600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Poll card with voting functionality.
class _PollCard extends StatefulWidget {
  final String question;
  final List<Map<String, dynamic>> options;
  final int totalVotes;
  final bool hasVoted;

  const _PollCard({
    required this.question,
    required this.options,
    required this.totalVotes,
    this.hasVoted = false,
  });

  @override
  State<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard> {
  String? _selectedOption;
  bool _hasVoted = false;

  @override
  void initState() {
    super.initState();
    _hasVoted = widget.hasVoted;
  }

  void _vote() {
    if (_selectedOption == null) return;
    setState(() => _hasVoted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vote berhasil! 🗳️'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.how_to_vote,
                  size: 18,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.question,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...widget.options.map((option) {
            final votes = option['votes'] as int;
            final percentage = widget.totalVotes > 0
                ? (votes / widget.totalVotes * 100).round()
                : 0;
            final isSelected = _selectedOption == option['id'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: _hasVoted ? null : () => setState(() => _selectedOption = option['id']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryBg : AppColors.gray50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.gray200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option['text'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.gray700,
                          ),
                        ),
                      ),
                      if (_hasVoted) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.gray600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 6,
                              backgroundColor: AppColors.gray200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isSelected
                                    ? AppColors.primary
                                    : AppColors.gray400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.totalVotes} suara',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray500,
                ),
              ),
              if (!_hasVoted)
                ElevatedButton(
                  onPressed: _selectedOption != null ? _vote : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Vote',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
