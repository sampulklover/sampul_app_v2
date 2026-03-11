import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/card_decoration_helper.dart';
import '../models/learning_resource.dart';
import '../services/learning_resources_service.dart';
import 'guide_detail_screen.dart';
import 'podcast_detail_screen.dart';

class ResourcesInsightsScreen extends StatefulWidget {
  const ResourcesInsightsScreen({super.key});

  @override
  State<ResourcesInsightsScreen> createState() => _ResourcesInsightsScreenState();
}

class _ResourcesInsightsScreenState extends State<ResourcesInsightsScreen> {
  String _selectedPodcastCategory = '';
  String _selectedGuideCategory = '';
  String _selectedShortCategory = '';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  List<PodcastItem> _podcasts = <PodcastItem>[];
  List<GuideItem> _guides = <GuideItem>[];
  List<ShortItem> _shorts = <ShortItem>[];
  List<_Category> _podcastCategories = const [_Category('', 'All')];
  List<_Category> _guideCategories = const [_Category('', 'All')];
  List<_Category> _shortCategories = const [_Category('', 'All')];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<LearningResource> resources =
          await LearningResourcesService.instance.listPublishedResources();

      final List<PodcastItem> podcasts = <PodcastItem>[];
      final List<GuideItem> guides = <GuideItem>[];
      final List<ShortItem> shorts = <ShortItem>[];

      for (final LearningResource r in resources) {
        if (r.resourceType == 'podcast') {
          podcasts.add(
            PodcastItem(
              id: r.id,
              categoryId: r.category,
              title: r.title,
              durationLabel: r.durationLabel ?? '',
              description: r.body,
              videoUrl: r.videoUrl,
            ),
          );
        } else if (r.resourceType == 'guide') {
          guides.add(
            GuideItem(
              id: r.id,
              categoryId: r.category,
              title: r.title,
              authorName: r.authorName ?? '',
              readTimeLabel: r.durationLabel ?? '',
              publishedAt: r.publishedAt ?? DateTime.now(),
              body: r.body,
              imageUrl: r.imageUrl,
            ),
          );
        } else if (r.resourceType == 'short') {
          shorts.add(
            ShortItem(
              id: r.id,
              categoryId: r.category,
              title: r.title,
              durationLabel: r.durationLabel ?? '',
              videoUrl: r.videoUrl,
              imageUrl: r.imageUrl,
            ),
          );
        }
      }

      // Build dynamic category lists from the loaded resources
      final podcastCatIds = podcasts.map((p) => p.categoryId).toSet().toList()..sort();
      final guideCatIds = guides.map((g) => g.categoryId).toSet().toList()..sort();
      final shortCatIds = shorts.map((s) => s.categoryId).toSet().toList()..sort();

      if (!mounted) return;
      setState(() {
        _podcasts = podcasts;
        _guides = guides;
        _shorts = shorts;
        _podcastCategories = [
          const _Category('', 'All'),
          ...podcastCatIds.map((c) => _Category(c, c)),
        ];
        _guideCategories = [
          const _Category('', 'All'),
          ...guideCatIds.map((c) => _Category(c, c)),
        ];
        _shortCategories = [
          const _Category('', 'All'),
          ...shortCatIds.map((c) => _Category(c, c)),
        ];
        // Reset selection to 'All' on refresh
        _selectedPodcastCategory = '';
        _selectedGuideCategory = '';
        _selectedShortCategory = '';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  List<PodcastItem> _filterPodcasts(List<PodcastItem> podcasts) {
    var filtered = podcasts;
    
    // Apply category filter
    if (_selectedPodcastCategory.isNotEmpty) {
      filtered = filtered.where((p) => p.categoryId == _selectedPodcastCategory).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final titleMatch = p.title.toLowerCase().contains(query);
        final descriptionMatch = p.description?.toLowerCase().contains(query) ?? false;
        final categoryMatch = p.categoryId.toLowerCase().contains(query);
        return titleMatch || descriptionMatch || categoryMatch;
      }).toList();
    }
    
    return filtered;
  }

  List<GuideItem> _filterGuides(List<GuideItem> guides) {
    var filtered = guides;
    
    // Apply category filter
    if (_selectedGuideCategory.isNotEmpty) {
      filtered = filtered.where((g) => g.categoryId == _selectedGuideCategory).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((g) {
        final titleMatch = g.title.toLowerCase().contains(query);
        final bodyMatch = g.body?.toLowerCase().contains(query) ?? false;
        final authorMatch = g.authorName.toLowerCase().contains(query);
        final categoryMatch = g.categoryId.toLowerCase().contains(query);
        return titleMatch || bodyMatch || authorMatch || categoryMatch;
      }).toList();
    }
    
    return filtered;
  }

  List<ShortItem> _filterShorts(List<ShortItem> shorts) {
    var filtered = shorts;

    // Apply category filter
    if (_selectedShortCategory.isNotEmpty) {
      filtered =
          filtered.where((s) => s.categoryId == _selectedShortCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        final titleMatch = s.title.toLowerCase().contains(query);
        final categoryMatch = s.categoryId.toLowerCase().contains(query);
        return titleMatch || categoryMatch;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredPodcasts = _filterPodcasts(_podcasts);
    final filteredGuides = _filterGuides(_guides);
    final filteredShorts = _filterShorts(_shorts);

    Widget bodyChild;
    if (_isLoading) {
      bodyChild = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      bodyChild = _ErrorState(message: _error!, onRetry: _loadResources);
    } else if (_podcasts.isEmpty && _guides.isEmpty && _shorts.isEmpty) {
      bodyChild = RefreshIndicator(
        onRefresh: _loadResources,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            _EmptyState(onRetry: _loadResources),
          ],
        ),
      );
    } else if (filteredPodcasts.isEmpty &&
        filteredGuides.isEmpty &&
        filteredShorts.isEmpty) {
      bodyChild = RefreshIndicator(
        onRefresh: _loadResources,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SearchField(
                        controller: _searchController,
                        onChanged: (query) {
                          setState(() {
                            _searchQuery = query;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    _EmptySearchState(searchQuery: _searchQuery),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      bodyChild = RefreshIndicator(
        onRefresh: _loadResources,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SearchField(
                        controller: _searchController,
                        onChanged: (query) {
                          setState(() {
                            _searchQuery = query;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (filteredShorts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Shorts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _CategoryChipsRow(
                          categories: _shortCategories,
                          selectedId: _selectedShortCategory,
                          onSelected: (id) =>
                              setState(() => _selectedShortCategory = id),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 280,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: filteredShorts.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final item = filteredShorts[index];
                            return _ShortCard(item: item);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Podcast',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _CategoryChipsRow(
                      categories: _podcastCategories,
                      selectedId: _selectedPodcastCategory,
                      onSelected: (id) => setState(() => _selectedPodcastCategory = id),
                    ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 230,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredPodcasts.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final item = filteredPodcasts[index];
                          return _PodcastCard(item: item);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Guides',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _CategoryChipsRow(
                      categories: _guideCategories,
                      selectedId: _selectedGuideCategory,
                      onSelected: (id) => setState(() => _selectedGuideCategory = id),
                    ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            SliverList.separated(
              itemCount: filteredGuides.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = filteredGuides[index];
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    index == filteredGuides.length - 1 ? 24 : 0,
                  ),
                  child: _GuideCard(item: item),
                );
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Resources and insights'),
      ),
      body: SafeArea(child: bodyChild),
    );
  }
}

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Search podcasts and guides...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _Category {
  final String id;
  final String label;

  const _Category(this.id, this.label);
}


class _CategoryChipsRow extends StatelessWidget {
  final List<_Category> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const _CategoryChipsRow({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in categories) ...[
            _SegmentChip(
              label: category.label,
              selected: category.id == selectedId,
              onTap: () => onSelected(category.id),
            ),
            if (category != categories.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.08)
              : theme.colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class PodcastItem {
  final String id;
  final String categoryId;
  final String title;
  final String durationLabel;
  final String? description;
  final String? videoUrl;

  const PodcastItem({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.durationLabel,
    this.description,
    this.videoUrl,
  });
}

class ShortItem {
  final String id;
  final String categoryId;
  final String title;
  final String durationLabel;
  final String? videoUrl;
  final String? imageUrl;

  const ShortItem({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.durationLabel,
    this.videoUrl,
    this.imageUrl,
  });
}

class _PodcastCard extends StatelessWidget {
  final PodcastItem item;

  const _PodcastCard({required this.item});

  String? _extractYouTubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // Handle various YouTube URL formats
    if (uri.host.contains('youtube.com')) {
      // Standard watch URL: https://www.youtube.com/watch?v=VIDEO_ID
      if (uri.pathSegments.isEmpty || uri.pathSegments.first == 'watch') {
        return uri.queryParameters['v'];
      }
      // Shorts URL: https://www.youtube.com/shorts/VIDEO_ID
      if (uri.pathSegments.first == 'shorts' &&
          uri.pathSegments.length >= 2) {
        return uri.pathSegments[1];
      }
      // Embed URL: https://www.youtube.com/embed/VIDEO_ID
      if (uri.pathSegments.first == 'embed' &&
          uri.pathSegments.length >= 2) {
        return uri.pathSegments[1];
      }
      return null;
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    return null;
  }

  String? _getYouTubeThumbnail(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width * 0.7;
    final bool hasVideo = item.videoUrl != null && item.videoUrl!.isNotEmpty;
    final String? youtubeVideoId = hasVideo ? _extractYouTubeId(item.videoUrl!) : null;
    final String? thumbnailUrl = youtubeVideoId != null ? _getYouTubeThumbnail(youtubeVideoId) : null;

    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PodcastDetailScreen(podcast: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: thumbnailUrl == null
                      ? LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.9),
                            theme.colorScheme.primary.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: thumbnailUrl != null ? Colors.black : null,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // YouTube thumbnail or gradient background
                    if (thumbnailUrl != null)
                      Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to gradient if thumbnail fails
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withOpacity(0.9),
                                  theme.colorScheme.primary.withOpacity(0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          // Show gradient while loading
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withOpacity(0.9),
                                  theme.colorScheme.primary.withOpacity(0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      )
                    else
                      // Decorative circles for gradient background
                      ...[
                        Positioned(
                          left: -40,
                          bottom: -10,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
                      ],
                    // Play button and duration overlay
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 24,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.durationLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortCard extends StatelessWidget {
  final ShortItem item;

  const _ShortCard({required this.item});

  String? _extractYouTubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host.contains('youtube.com')) {
      // Standard watch URL: https://www.youtube.com/watch?v=VIDEO_ID
      if (uri.pathSegments.isEmpty || uri.pathSegments.first == 'watch') {
        return uri.queryParameters['v'];
      }
      // Shorts URL: https://www.youtube.com/shorts/VIDEO_ID
      if (uri.pathSegments.first == 'shorts' &&
          uri.pathSegments.length >= 2) {
        return uri.pathSegments[1];
      }
      // Embed URL: https://www.youtube.com/embed/VIDEO_ID
      if (uri.pathSegments.first == 'embed' &&
          uri.pathSegments.length >= 2) {
        return uri.pathSegments[1];
      }
      return null;
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    return null;
  }

  String? _getYouTubeThumbnail(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  Future<void> _openShort(BuildContext context) async {
    final urlString = item.videoUrl;
    if (urlString == null || urlString.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(urlString);
    if (uri == null) {
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open video'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double cardHeight = 220;
    final double cardWidth = cardHeight * 9 / 16;

    // Decide thumbnail source: explicit imageUrl first, then YouTube thumbnail, else gradient.
    String? effectiveThumbnailUrl = item.imageUrl;
    if ((effectiveThumbnailUrl == null || effectiveThumbnailUrl.isEmpty) &&
        item.videoUrl != null &&
        item.videoUrl!.isNotEmpty) {
      final youtubeId = _extractYouTubeId(item.videoUrl!);
      if (youtubeId != null && youtubeId.isNotEmpty) {
        effectiveThumbnailUrl = _getYouTubeThumbnail(youtubeId);
      }
    }

    return SizedBox(
      width: cardWidth,
      child: GestureDetector(
        onTap: () => _openShort(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: cardHeight,
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (effectiveThumbnailUrl != null &&
                          effectiveThumbnailUrl.isNotEmpty)
                        Image.network(
                          effectiveThumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _ShortGradientBackground(theme: theme);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _ShortGradientBackground(theme: theme);
                          },
                        )
                      else
                        _ShortGradientBackground(theme: theme),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 24,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            if (item.durationLabel.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.durationLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortGradientBackground extends StatelessWidget {
  final ThemeData theme;

  const _ShortGradientBackground({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.9),
            theme.colorScheme.primary.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class GuideItem {
  final String id;
  final String categoryId;
  final String title;
  final String authorName;
  final String readTimeLabel;
  final DateTime publishedAt;
  final String? body;
  final String? imageUrl;

  const GuideItem({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.authorName,
    required this.readTimeLabel,
    required this.publishedAt,
    this.body,
    this.imageUrl,
  });
}

class _GuideCard extends StatelessWidget {
  final GuideItem item;

  const _GuideCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = screenWidth * 0.24; // around one quarter of card width

    return CardDecorationHelper.styledCard(
      context: context,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(CardDecorationHelper.cardBorderRadius),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GuideDetailScreen(guide: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (item.body != null && item.body!.isNotEmpty)
                        Expanded(
                          child: Text(
                            item.body!,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: imageWidth.clamp(80, 110),
                    height: double.infinity,
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            width: imageWidth.clamp(80, 120),
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to gradient if image fails to load
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary.withOpacity(0.9),
                                      theme.colorScheme.primary.withOpacity(0.6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Container(
                                        width: 56,
                                        height: 40,
                                        margin: const EdgeInsets.only(right: 4, bottom: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              // Show gradient while loading
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary.withOpacity(0.9),
                                      theme.colorScheme.primary.withOpacity(0.6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                child: child,
                              );
                            },
                          )
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withOpacity(0.9),
                                  theme.colorScheme.primary.withOpacity(0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Container(
                                    width: 56,
                                    height: 40,
                                    margin: const EdgeInsets.only(right: 4, bottom: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to load resources',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No resources yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no resources to show right now. Please check back later.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final String searchQuery;

  const _EmptySearchState({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No results found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No resources match "$searchQuery". Try a different search term.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
