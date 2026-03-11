import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

import 'resources_insights_screen.dart' show PodcastItem;

class PodcastDetailScreen extends StatelessWidget {
  final PodcastItem podcast;

  const PodcastDetailScreen({super.key, required this.podcast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Podcast'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            Text(
              podcast.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (podcast.videoUrl != null && podcast.videoUrl!.isNotEmpty)
              _VideoPlayerSection(
                videoUrl: podcast.videoUrl!,
              )
            else
              _AudioOnlyPlayer(theme: theme),
            const SizedBox(height: 16),
            Row(
              children: [
                _Chip(
                  icon: Icons.schedule,
                  label: podcast.durationLabel,
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: Icons.library_books_outlined,
                  label: 'Trusts and Wills',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              podcast.description?.isNotEmpty == true
                  ? podcast.description!
                  : 'This episode gives you a concise, practical overview of the topic. In the future, this description can be populated from your content backend.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerSection extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerSection({required this.videoUrl});

  @override
  State<_VideoPlayerSection> createState() => _VideoPlayerSectionState();
}

class _VideoPlayerSectionState extends State<_VideoPlayerSection> {
  VideoPlayerController? _videoController;
  bool _isYouTube = false;
  String? _youtubeVideoId;
  String? _youtubeThumbnailUrl;
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    final url = widget.videoUrl;
    
    // Check if it's a YouTube URL
    _youtubeVideoId = _extractYouTubeId(url);
    if (_youtubeVideoId != null && _youtubeVideoId!.isNotEmpty) {
      _isYouTube = true;
      _youtubeThumbnailUrl =
          'https://img.youtube.com/vi/${_youtubeVideoId!}/maxresdefault.jpg';
      // We don't need to initialize a player here; we'll open an in-app browser when tapped.
      setState(() => _isInitialized = true);
    } else {
      // Direct video URL
      _isYouTube = false;
      try {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
          ..initialize().then((_) {
            if (mounted) {
              setState(() => _isInitialized = true);
            }
          }).catchError((e) {
            debugPrint('Error initializing video player: $e');
            if (mounted) {
              setState(() {
                _isInitialized = true;
                _errorMessage = 'Failed to load video';
              });
            }
          });
      } catch (e) {
        debugPrint('Error creating video controller: $e');
        setState(() {
          _isInitialized = true;
          _errorMessage = 'Invalid video URL';
        });
      }
    }
  }

  String? _extractYouTubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // Handle various YouTube URL formats
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    return null;
  }

  Future<void> _openYouTubeInModal(String videoId) async {
    final url = Uri.parse('https://www.youtube.com/watch?v=$videoId');

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        // This uses SFSafariViewController / Chrome Custom Tab
        // so user stays in app, but it's very stable.
        mode: LaunchMode.inAppBrowserView,
      );
    } else {
      setState(() {
        _errorMessage = 'Could not open video';
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surfaceVariant,
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error message if there was an error
    if (_errorMessage != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.errorContainer,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.onErrorContainer,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_isYouTube && _youtubeVideoId != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GestureDetector(
          onTap: () => _openYouTubeInModal(_youtubeVideoId!),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Thumbnail background or gradient fallback
                Positioned.fill(
                  child: _youtubeThumbnailUrl != null
                      ? Image.network(
                          _youtubeThumbnailUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withOpacity(0.8),
                                    theme.colorScheme.primary.withOpacity(0.5),
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
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withOpacity(0.8),
                                    theme.colorScheme.primary.withOpacity(0.5),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.8),
                                theme.colorScheme.primary.withOpacity(0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                ),
                // Play button
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                // YouTube badge
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'YouTube',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
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
      );
    }

    // Direct video URL
    if (_videoController != null && _videoController!.value.isInitialized) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 200,
          color: Colors.black,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                        _isPlaying = false;
                      } else {
                        _videoController!.play();
                        _isPlaying = true;
                      }
                    });
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback for unsupported video formats
    return _AudioOnlyPlayer(theme: theme);
  }
}

class _AudioOnlyPlayer extends StatelessWidget {
  final ThemeData theme;

  const _AudioOnlyPlayer({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.95),
            theme.colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            size: 38,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }
}

