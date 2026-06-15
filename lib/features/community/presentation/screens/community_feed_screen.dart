import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/community_entity.dart';
import '../providers/community_providers.dart';

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() =>
      _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  final _scrollController = ScrollController();
  final List<CommunityPostEntity> _morePosts = [];
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('tr', timeago.TrMessages());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final posts = ref.read(communityPostsProvider).valueOrNull ?? [];
    final all = [...posts, ..._morePosts];
    if (all.isEmpty) return;

    setState(() => _loadingMore = true);
    try {
      final more = await ref.read(communityRepositoryProvider).fetchMorePosts(
            startAfter: all.last.createdAt,
          );
      setState(() {
        _morePosts.addAll(more);
        _hasMore = more.length >= 20;
      });
    } finally {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _toggleLike(CommunityPostEntity post) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    // Mock postlarda like işlemi Firestore'a gitmez
    if (post.id.startsWith('mock_')) return;
    await ref.read(communityRepositoryProvider).toggleLike(
          post.id,
          user.uid,
          post.likedBy,
        );
  }

  Future<void> _showCreatePost() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final titleController = TextEditingController();
    final contentController = TextEditingController();
    var brand = 'Genel';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gönderi Paylaş',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: brand,
              decoration: const InputDecoration(labelText: 'Marka'),
              items: ['Genel', 'Tesla', 'Togg', 'BMW', 'Hyundai', 'MG']
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (v) => brand = v ?? 'Genel',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Başlık'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'İçerik'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    contentController.text.trim().isEmpty) {
                  return;
                }
                await ref.read(communityRepositoryProvider).createPost(
                      authorId: user.uid,
                      authorName: user.displayName,
                      authorPhoto: user.photoUrl,
                      brand: brand,
                      title: titleController.text.trim(),
                      content: contentController.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Paylaş'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    contentController.dispose();
  }

  Future<void> _showComments(CommunityPostEntity post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _CommentsSheet(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(communityPostsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Topluluk')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePost,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: postsAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (e, _) => AppErrorView(message: e.toString()),
        data: (posts) {
          final all = [...posts, ..._morePosts];
          // Sadece mock postlar varsa (gerçek post yok) banner göster
          final realPosts =
              all.where((p) => !p.id.startsWith('mock_')).toList();
          final isMockOnly = realPosts.isEmpty;

          if (all.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Henüz gönderi yok'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showCreatePost,
                    child: const Text('İlk Gönderiyi Paylaş'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(communityPostsProvider);
              setState(() {
                _morePosts.clear();
                _hasMore = true;
              });
            },
            child: Column(
              children: [
                // Demo veri bilgi bandı
                if (isMockOnly)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Şu an örnek gönderiler gösteriliyor. İlk gönderiyi sen paylaş!',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: all.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= all.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final post = all[i];
                      final liked = user != null && post.isLikedBy(user.uid);
                      final isMock = post.id.startsWith('mock_');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Yazar satırı
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primary,
                                    backgroundImage: post.authorPhoto != null
                                        ? NetworkImage(post.authorPhoto!)
                                        : null,
                                    child: post.authorPhoto == null
                                        ? Text(
                                            post.authorName[0].toUpperCase(),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post.authorName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${post.brand} • ${timeago.format(post.createdAt, locale: 'tr')}',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Örnek rozeti
                                  if (isMock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Örnek',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Başlık
                              Text(
                                post.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // İçerik
                              Text(post.content),
                              // Fotoğraf
                              if (post.photoUrls.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: AppRadius.cardBorder,
                                  child: CachedNetworkImage(
                                    imageUrl: post.photoUrls.first,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              // Beğeni & Yorum butonları
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      liked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: liked ? Colors.red : null,
                                    ),
                                    onPressed:
                                        isMock ? null : () => _toggleLike(post),
                                  ),
                                  Text('${post.likeCount}'),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    onPressed: () => _showComments(post),
                                  ),
                                  Text('${post.commentCount}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Yorumlar alt sayfası
// ---------------------------------------------------------------------------

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.post});
  final CommunityPostEntity post;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _controller.text.trim().isEmpty) return;
    if (widget.post.id.startsWith('mock_')) return;

    await ref.read(communityRepositoryProvider).addComment(
          postId: widget.post.id,
          authorId: user.uid,
          authorName: user.displayName,
          content: _controller.text.trim(),
        );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.post.id));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              widget.post.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: commentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Hata: $e'),
                data: (comments) {
                  if (comments.isEmpty) {
                    return const Center(child: Text('Henüz yorum yok'));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: comments.length,
                    itemBuilder: (_, i) {
                      final c = comments[i];
                      return ListTile(
                        title: Text(c.authorName),
                        subtitle: Text(c.content),
                        trailing: Text(
                          timeago.format(c.createdAt, locale: 'tr'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Yorum yazma alanı (mock postlarda gösterilmez)
            if (!widget.post.id.startsWith('mock_'))
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Yorum yaz...',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _submit,
                    icon: const Icon(Icons.send, color: AppColors.primary),
                  ),
                ],
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Örnek gönderiye yorum yapılamaz.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
