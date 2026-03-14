import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/learning_resource.dart';
import '../services/learning_resources_service.dart';
import '../utils/admin_utils.dart';
import 'podcast_detail_screen.dart';
import 'guide_detail_screen.dart';
import 'resources_insights_screen.dart' show PodcastItem, GuideItem;

class AdminLearningResourcesScreen extends StatefulWidget {
  const AdminLearningResourcesScreen({super.key});

  @override
  State<AdminLearningResourcesScreen> createState() =>
      _AdminLearningResourcesScreenState();
}

class _AdminLearningResourcesScreenState
    extends State<AdminLearningResourcesScreen> {
  bool _isAdmin = false;
  bool _isLoading = true;
  bool _isSaving = false;
  List<LearningResource> _resources = <LearningResource>[];

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoad();
  }

  Future<void> _checkAdminAndLoad() async {
    final bool isAdmin = await AdminUtils.isAdmin();
    if (!mounted) return;
    setState(() => _isAdmin = isAdmin);

    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Admin privileges required.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop();
      return;
    }
    await _loadResources();
  }

  void _openResourceDetail(LearningResource resource) {
    if (resource.resourceType == 'podcast') {
      final podcast = PodcastItem(
        id: resource.id,
        categoryId: resource.category,
        title: resource.title,
        durationLabel: resource.durationLabel ?? '',
        description: resource.body,
        videoUrl: resource.videoUrl,
      );
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PodcastDetailScreen(podcast: podcast),
        ),
      );
    } else if (resource.resourceType == 'guide') {
      final guide = GuideItem(
        id: resource.id,
        categoryId: resource.category,
        title: resource.title,
        authorName: resource.authorName ?? '',
        readTimeLabel: resource.durationLabel ?? '',
        publishedAt: resource.publishedAt ?? DateTime.now(),
        body: resource.body,
        imageUrl: resource.imageUrl,
      );
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GuideDetailScreen(guide: guide),
        ),
      );
    } else if (resource.resourceType == 'short') {
      _openShortVideo(resource.videoUrl);
    }
  }

  Future<void> _openShortVideo(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final uri = Uri.tryParse(urlString);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open video'),
        ),
      );
    }
  }

  Future<void> _loadResources() async {
    setState(() => _isLoading = true);
    try {
      final List<LearningResource> resources =
          await LearningResourcesService.instance.listAllResources();
      if (!mounted) return;
      setState(() {
        _resources = resources;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load resources: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Unique sorted categories from all existing resources (for autocomplete).
  List<String> get _existingCategories => _resources
      .map((r) => r.category)
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  Future<void> _openEditor({LearningResource? resource}) async {
    final bool isEditing = resource != null;

    // All form controllers — category is a proper first-class controller
    final TextEditingController titleController =
        TextEditingController(text: resource?.title ?? '');
    final TextEditingController categoryController =
        TextEditingController(text: resource?.category ?? '');
    final TextEditingController durationController =
        TextEditingController(text: resource?.durationLabel ?? '');
    final TextEditingController authorController =
        TextEditingController(text: resource?.authorName ?? '');
    final TextEditingController bodyController =
        TextEditingController(text: resource?.body ?? '');
    final TextEditingController videoUrlController =
        TextEditingController(text: resource?.videoUrl ?? '');
    final TextEditingController imageUrlController =
        TextEditingController(text: resource?.imageUrl ?? '');
    final TextEditingController sortIndexController = TextEditingController(
      text: resource?.sortIndex != null ? resource!.sortIndex.toString() : '',
    );

    // Local mutable state for the dialog
    String resourceType = resource?.resourceType ?? 'podcast';
    bool isPublished = resource?.isPublished ?? true;
    DateTime? publishedAt = resource?.publishedAt;
    bool isSavingDialog = false;

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final List<String> categoryOptions = _existingCategories;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit resource' : 'New resource'),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // ── Type dropdown ──────────────────────────────
                        DropdownButtonFormField<String>(
                          value: resourceType,
                          decoration: const InputDecoration(
                            labelText: 'Type *',
                            border: OutlineInputBorder(),
                          ),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem(
                              value: 'podcast',
                              child: Row(
                                children: <Widget>[
                                  Icon(Icons.podcasts, size: 18),
                                  SizedBox(width: 8),
                                  Text('Podcast'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'guide',
                              child: Row(
                                children: <Widget>[
                                  Icon(Icons.article_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Guide'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'short',
                              child: Row(
                                children: <Widget>[
                                  Icon(Icons.smartphone, size: 18),
                                  SizedBox(width: 8),
                                  Text('Short (vertical video)'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (String? value) {
                            if (value != null) {
                              setDialogState(() => resourceType = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Title ──────────────────────────────────────
                        TextFormField(
                          controller: titleController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Title *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Title is required'
                                  : null,
                        ),
                        const SizedBox(height: 16),

                        // ── Category text field + suggestion chips ─────
                        TextFormField(
                          controller: categoryController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            hintText: 'e.g. Trusts and Wills',
                            border: OutlineInputBorder(),
                            helperText: 'Or tap a suggestion below',
                          ),
                          validator: (String? v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Category is required'
                                  : null,
                        ),
                        if (categoryOptions.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: categoryOptions
                                .map((String c) => ActionChip(
                                      label: Text(c),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        categoryController.text = c;
                                        // Re-validate the field after picking
                                        formKey.currentState?.validate();
                                      },
                                    ))
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // ── Duration / read-time label ─────────────────
                        TextFormField(
                          controller: durationController,
                          decoration: InputDecoration(
                            labelText: resourceType == 'podcast'
                                ? 'Listen duration'
                                : resourceType == 'guide'
                                    ? 'Read time'
                                    : 'Watch duration',
                            hintText: resourceType == 'podcast'
                                ? 'e.g. 12 min listen'
                                : resourceType == 'guide'
                                    ? 'e.g. 7 min read'
                                    : 'e.g. 30 sec short',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Author (guides only) ───────────────────────
                        if (resourceType == 'guide') ...<Widget>[
                          TextFormField(
                            controller: authorController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Author name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Body / description ─────────────────────────
                        if (resourceType != 'short') ...<Widget>[
                          TextFormField(
                            controller: bodyController,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Description / body',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Video URL (podcasts & shorts) ───────────────
                        if (resourceType == 'podcast' ||
                            resourceType == 'short') ...<Widget>[
                          TextFormField(
                            controller: videoUrlController,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              labelText: 'Video URL',
                              hintText: resourceType == 'short'
                                  ? 'TikTok, Reels, YouTube Shorts, etc.'
                                  : 'YouTube, Vimeo, or direct video URL',
                              border: const OutlineInputBorder(),
                              helperText: resourceType == 'short'
                                  ? 'Required for Shorts: link to the vertical video'
                                  : 'Optional: URL to video content',
                            ),
                            validator: (String? v) {
                              if (resourceType == 'short') {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Video URL is required for Shorts';
                                }
                              }
                              if (v == null || v.trim().isEmpty) return null;
                              final uri = Uri.tryParse(v.trim());
                              if (uri == null || !uri.hasScheme) {
                                return 'Please enter a valid URL';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Image URL (guides & shorts) ─────────────────
                        if (resourceType == 'guide' ||
                            resourceType == 'short') ...<Widget>[
                          TextFormField(
                            controller: imageUrlController,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              labelText: 'Image URL',
                              hintText: resourceType == 'short'
                                  ? 'URL to vertical thumbnail frame (optional)'
                                  : 'URL to thumbnail/cover image',
                              border: const OutlineInputBorder(),
                              helperText: resourceType == 'short'
                                  ? 'Optional: thumbnail for Shorts cards'
                                  : 'Optional: URL to guide thumbnail image',
                            ),
                            validator: (String? v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final uri = Uri.tryParse(v.trim());
                              if (uri == null || !uri.hasScheme) {
                                return 'Please enter a valid URL';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Sort order ─────────────────────────────────
                        TextFormField(
                          controller: sortIndexController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Sort order',
                            hintText: 'Lower numbers appear first',
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? v) {
                            if (v == null || v.trim().isEmpty) return null;
                            if (int.tryParse(v.trim()) == null) {
                              return 'Must be a whole number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // ── Published toggle ───────────────────────────
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Published'),
                          subtitle: Text(isPublished
                              ? 'Visible to users'
                              : 'Hidden (draft)'),
                          value: isPublished,
                          onChanged: (bool v) =>
                              setDialogState(() => isPublished = v),
                        ),

                        // ── Published date ─────────────────────────────
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Published date'),
                          trailing: TextButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              publishedAt != null
                                  ? '${publishedAt!.year}-${publishedAt!.month.toString().padLeft(2, '0')}-${publishedAt!.day.toString().padLeft(2, '0')}'
                                  : 'Set date',
                            ),
                            onPressed: () async {
                              final DateTime now = DateTime.now();
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(now.year + 5),
                                initialDate: publishedAt ?? now,
                              );
                              if (picked != null) {
                                setDialogState(() => publishedAt = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed:
                      isSavingDialog ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSavingDialog
                      ? null
                      : () async {
                          // Validate all registered form fields
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setDialogState(() => isSavingDialog = true);
                          try {
                            final int? sortIndex = int.tryParse(
                              sortIndexController.text.trim(),
                            );
                            final String category =
                                categoryController.text.trim();

                            if (isEditing) {
                              await LearningResourcesService.instance
                                  .updateResource(
                                id: resource.id,
                                resourceType: resourceType,
                                category: category,
                                title: titleController.text.trim(),
                                durationLabel:
                                    durationController.text.trim().isEmpty
                                        ? null
                                        : durationController.text.trim(),
                                authorName:
                                    authorController.text.trim().isEmpty
                                        ? null
                                        : authorController.text.trim(),
                                body: resourceType == 'short'
                                    ? null
                                    : bodyController.text.trim().isEmpty
                                        ? null
                                        : bodyController.text.trim(),
                                videoUrl: (resourceType == 'podcast' ||
                                            resourceType == 'short') &&
                                        videoUrlController.text
                                            .trim()
                                            .isNotEmpty
                                    ? videoUrlController.text.trim()
                                    : null,
                                imageUrl: (resourceType == 'guide' ||
                                            resourceType == 'short') &&
                                        imageUrlController.text
                                            .trim()
                                            .isNotEmpty
                                    ? imageUrlController.text.trim()
                                    : null,
                                isPublished: isPublished,
                                publishedAt: publishedAt,
                                sortIndex: sortIndex,
                              );
                            } else {
                              await LearningResourcesService.instance
                                  .createResource(
                                resourceType: resourceType,
                                category: category,
                                title: titleController.text.trim(),
                                durationLabel:
                                    durationController.text.trim().isEmpty
                                        ? null
                                        : durationController.text.trim(),
                                authorName:
                                    authorController.text.trim().isEmpty
                                        ? null
                                        : authorController.text.trim(),
                                body: resourceType == 'short'
                                    ? null
                                    : bodyController.text.trim().isEmpty
                                        ? null
                                        : bodyController.text.trim(),
                                videoUrl: (resourceType == 'podcast' ||
                                            resourceType == 'short') &&
                                        videoUrlController.text
                                            .trim()
                                            .isNotEmpty
                                    ? videoUrlController.text.trim()
                                    : null,
                                imageUrl: (resourceType == 'guide' ||
                                            resourceType == 'short') &&
                                        imageUrlController.text
                                            .trim()
                                            .isNotEmpty
                                    ? imageUrlController.text.trim()
                                    : null,
                                isPublished: isPublished,
                                publishedAt: publishedAt,
                                sortIndex: sortIndex,
                              );
                            }

                            if (!mounted) return;
                            Navigator.of(context).pop();
                            await _loadResources();
                          } catch (e) {
                            if (!mounted) return;
                            setDialogState(() => isSavingDialog = false);
                            ScaffoldMessenger.of(
                              Navigator.of(context)
                                  .context,
                            ).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isSavingDialog
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? 'Update' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );

  }

  Future<void> _deleteResource(LearningResource resource) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete resource'),
        content: Text('Delete "${resource.title}"? This cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await LearningResourcesService.instance.deleteResource(resource.id);
      if (!mounted) return;
      await _loadResources();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning resources'),
        actions: <Widget>[
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: _isSaving ? null : () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadResources,
              child: _resources.isEmpty
                  ? ListView(
                      children: const <Widget>[
                        SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: <Widget>[
                              Icon(Icons.library_books_outlined,
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No resources yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tap "+ Add resource" to create one.',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: _resources.length,
                      itemBuilder: (BuildContext context, int index) {
                        final LearningResource r = _resources[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: _ResourceThumbnail(
                              resource: r,
                            ),
                            title: Text(
                              r.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const SizedBox(height: 2),
                                Row(
                                  children: <Widget>[
                                    _TypeBadge(type: r.resourceType),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        r.category,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (r.durationLabel != null &&
                                    r.durationLabel!.isNotEmpty)
                                  Text(
                                    r.durationLabel!,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                if (!r.isPublished)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Draft',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Edit',
                                  onPressed: () =>
                                      _openEditor(resource: r),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Delete',
                                  color: theme.colorScheme.error,
                                  onPressed: () => _deleteResource(r),
                                ),
                              ],
                            ),
                            onTap: () => _openResourceDetail(r),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isPodcast = type == 'podcast';
    final bool isGuide = type == 'guide';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPodcast
            ? theme.colorScheme.tertiaryContainer
            : isGuide
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPodcast
            ? 'Podcast'
            : isGuide
                ? 'Guide'
                : 'Short',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isPodcast
              ? theme.colorScheme.onTertiaryContainer
              : isGuide
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ResourceThumbnail extends StatelessWidget {
  final LearningResource resource;

  const _ResourceThumbnail({required this.resource});

  String? _extractYouTubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host.contains('youtube.com')) {
      if (uri.pathSegments.isEmpty || uri.pathSegments.first == 'watch') {
        return uri.queryParameters['v'];
      }
      if (uri.pathSegments.first == 'shorts' && uri.pathSegments.length >= 2) {
        return uri.pathSegments[1];
      }
      if (uri.pathSegments.first == 'embed' && uri.pathSegments.length >= 2) {
        return uri.pathSegments[1];
      }
      return null;
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    return null;
  }

  String? _getYouTubeThumbnail(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String? thumbnailUrl = resource.imageUrl;
    if ((thumbnailUrl == null || thumbnailUrl.isEmpty) &&
        resource.videoUrl != null &&
        resource.videoUrl!.isNotEmpty &&
        (resource.resourceType == 'podcast' ||
            resource.resourceType == 'short')) {
      final youtubeId = _extractYouTubeId(resource.videoUrl!);
      if (youtubeId != null && youtubeId.isNotEmpty) {
        thumbnailUrl = _getYouTubeThumbnail(youtubeId);
      }
    }

    final IconData overlayIcon = resource.resourceType == 'podcast'
        ? Icons.podcasts
        : resource.resourceType == 'guide'
            ? Icons.article_outlined
            : Icons.smartphone;

    return SizedBox(
      width: 48,
      height: 48,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _ThumbnailFallback(icon: overlayIcon, theme: theme);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _ThumbnailFallback(icon: overlayIcon, theme: theme);
                },
              )
            else
              _ThumbnailFallback(icon: overlayIcon, theme: theme),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                margin: const EdgeInsets.all(4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  overlayIcon,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailFallback extends StatelessWidget {
  final IconData icon;
  final ThemeData theme;

  const _ThumbnailFallback({required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
