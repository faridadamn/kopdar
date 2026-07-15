import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../providers/community_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/zone_info_card.dart';

/// Main community page with tab bar and post feed.
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final tabs = CommunityTab.values;
        context.read<CommunityProvider>().setActiveTab(tabs[_tabController.index]);
      }
    });

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CommunityProvider>();
      provider.fetchPosts(refresh: true);
      provider.fetchZoneInfo();
    });
  }

  void _onScroll() {
    final provider = context.read<CommunityProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        provider.hasMore &&
        !provider.isLoadingMore) {
      provider.loadMore();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('👥 Komunitas'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray500,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Zona Saya'),
            Tab(text: 'Advokasi'),
          ],
        ),
      ),
      body: Consumer<CommunityProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              // ── Tab: Semua ──
              _PostFeedTab(
                provider: provider,
                scrollController: _scrollController,
                showZoneCard: true,
              ),
              // ── Tab: Zona Saya ──
              _PostFeedTab(
                provider: provider,
                scrollController: _scrollController,
                showZoneCard: true,
              ),
              // ── Tab: Advokasi ──
              _AdvocacyPreviewTab(provider: provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/community/create'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Buat Post',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Post feed tab with zone info card and post list.
class _PostFeedTab extends StatelessWidget {
  final CommunityProvider provider;
  final ScrollController scrollController;
  final bool showZoneCard;

  const _PostFeedTab({
    required this.provider,
    required this.scrollController,
    this.showZoneCard = false,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.posts.isEmpty) {
      return const _LoadingState();
    }

    if (provider.status == CommunityStatus.error && provider.posts.isEmpty) {
      return _ErrorState(
        message: provider.errorMessage ?? 'Terjadi kesalahan',
        onRetry: () => provider.fetchPosts(refresh: true),
      );
    }

    if (provider.posts.isEmpty) {
      return _EmptyState(
        onCreate: () => context.push('/community/create'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchPosts(refresh: true),
      color: AppColors.primary,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: provider.posts.length +
            (showZoneCard && provider.zoneInfo != null ? 1 : 0) +
            (provider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Zone info card at top
          if (showZoneCard && provider.zoneInfo != null && index == 0) {
            final zone = provider.zoneInfo!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ZoneInfoCard(
                zoneName: zone['zone_name'] ?? 'Jakarta Selatan',
                memberCount: zone['member_count'] ?? 0,
                activeToday: zone['active_today'] ?? 0,
                tip: zone['tip'],
              ),
            );
          }

          final postIndex = showZoneCard && provider.zoneInfo != null
              ? index - 1
              : index;

          // Loading more indicator
          if (postIndex >= provider.posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          }

          final post = provider.posts[postIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PostCard(
              post: post,
              onTap: () => context.push('/community/${post.id}'),
              onLike: () => provider.toggleLike(post.id),
              onComment: () => context.push('/community/${post.id}'),
            ),
          );
        },
      ),
    );
  }
}

/// Advocacy preview tab shown within the main community page.
class _AdvocacyPreviewTab extends StatelessWidget {
  final CommunityProvider provider;

  const _AdvocacyPreviewTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📢', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Advokasi Driver',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Bersama kita kuat! Lihat data, petisi, dan kebijakan terbaru.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/community/advocacy'),
              icon: const Icon(Icons.campaign),
              label: const Text('Buka Halaman Advokasi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Memuat postingan...',
            style: TextStyle(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😵', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👥', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Belum ada post',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Jadilah yang pertama! Berbagi tips, pertanyaan, atau keluhanmu.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat Post Pertama'),
            ),
          ],
        ),
      ),
    );
  }
}
