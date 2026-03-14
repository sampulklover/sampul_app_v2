import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'asset_info_screen.dart';
import '../controllers/auth_controller.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'assets_list_screen.dart';
import '../services/brandfetch_service.dart';
import 'add_asset_screen.dart';
import 'family_list_screen.dart';
import 'edit_family_member_screen.dart';
import 'family_info_screen.dart';
import 'add_family_member_screen.dart';
import 'trust_management_screen.dart';
import 'trust_dashboard_screen.dart';
import 'trust_create_screen.dart';
import 'hibah_management_screen.dart';
import 'executor_management_screen.dart';
import 'checklist_screen.dart';
import 'will_management_screen.dart';
import 'onboarding_goal_selection_screen.dart';
import 'aftercare_screen.dart';
import '../models/trust.dart';
import '../services/trust_service.dart';
import 'trust_info_screen.dart';
import '../services/hibah_service.dart';
import '../services/executor_service.dart';
import '../services/will_service.dart';
import 'hibah_info_screen.dart';
import 'executor_info_screen.dart';
import 'referral_dashboard_screen.dart';
import 'notification_screen.dart';
import 'edit_profile_screen.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import '../utils/sampul_icons.dart';
import 'asset_preview_screen.dart';

const Color _trustAccentColor = Color.fromRGBO(83, 61, 233, 1);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _userProfile;
  bool _isLoadingProfile = true;
  bool _hasCheckedOnboarding = false;
  bool _isLoadingTrusts = true;
  List<Trust> _trusts = <Trust>[];
  // Keys to control child lists on pull-to-refresh
  final GlobalKey<_AssetsListState> _assetsListKey = GlobalKey<_AssetsListState>();
  final GlobalKey<_FamilyListState> _familyListKey = GlobalKey<_FamilyListState>();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadTrusts();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    if (_hasCheckedOnboarding) return;
    
    try {
      final isOnboarded = await AuthController.instance.isUserOnboarded();
      if (!isOnboarded && mounted) {
        // Wait a bit for the UI to render first
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _showOnboardingModal();
        }
      }
      _hasCheckedOnboarding = true;
    } catch (e) {
      // Error checking onboarding, continue normally
      _hasCheckedOnboarding = true;
    }
  }

  Future<void> _showOnboardingModal() async {
    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const OnboardingGoalSelectionScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result == true && mounted) {
      await _loadUserProfile();
      await _loadTrusts();
      // Ensure child lists also refresh after onboarding completes
      await Future.wait(<Future<void>>[
        _assetsListKey.currentState?.reload() ?? Future.value(),
        _familyListKey.currentState?.reload() ?? Future.value(),
      ]);
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await AuthController.instance.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadTrusts() async {
    try {
      final trusts = await TrustService.instance.listUserTrusts();
      if (!mounted) return;
      setState(() {
        _trusts = trusts;
        _isLoadingTrusts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTrusts = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadUserProfile(),
      _loadTrusts(),
    ]);
    // Ask child lists to reload their data as well
    await Future.wait(<Future<void>>[
      _assetsListKey.currentState?.reload() ?? Future.value(),
      _familyListKey.currentState?.reload() ?? Future.value(),
    ]);
    // Re-check onboarding status after refresh
    await _checkOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshData,
            child: CustomScrollView(
          slivers: <Widget>[
          // Custom pinned header: exact height with no extra bottom spacing
          SliverPersistentHeader(
            pinned: true,
            delegate: _HomeHeaderDelegate(
              paddingTop: MediaQuery.of(context).padding.top,
              backgroundColor: theme.scaffoldBackgroundColor,
              headerContentKey: _isLoadingProfile ? 'loading' : (_userProfile?.fullImageUrl ?? ''),
              child: Builder(
                builder: (BuildContext context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _isLoadingProfile
                            ? null
                            : () async {
                                final result = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute<bool>(
                                    builder: (_) => const EditProfileScreen(),
                                  ),
                                );
                                // Refresh profile if user saved changes
                                if (result == true) {
                                  await _loadUserProfile();
                                }
                              },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                child: _isLoadingProfile
                                    ? SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _trustAccentColor,
                                        ),
                                      )
                                    : _userProfile?.fullImageUrl != null &&
                                            _userProfile!.fullImageUrl!.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              _userProfile!.fullImageUrl!,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons.person_outline,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.person_outline,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Hi, ${_userProfile?.displayName ?? AuthController.instance.currentUser?.email?.split('@')[0] ?? 'there'}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.referrals,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const ReferralDashboardScreen()),
                          );
                        },
                        icon: SampulIcons.buildIcon(
                          SampulIcons.gift,
                          width: 24,
                          height: 24,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const NotificationScreen()),
                          );
                        },
                        icon: SampulIcons.buildIcon(
                          SampulIcons.notifications,
                          width: 24,
                          height: 24,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Adjust this value to change spacing between "Welcome to Sampul" and trust cards
                const SizedBox(height: 24),
                _TrustCardsCarousel(
                  isLoading: _isLoadingTrusts,
                  trusts: _trusts,
                  onRefresh: _refreshData,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 24),
                  child: _ActionsGrid(
                    trusts: _trusts,
                    onRefresh: _refreshData,
                  ),
                ),
                const SizedBox(height: 24),
                Builder(
                  builder: (BuildContext context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _SectionHeader(
                        title: l10n.myAssets,
                        actionText: l10n.seeAll,
                        onAction: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const AssetsListScreen()),
                          );
                          // Refresh data when returning from assets list
                          await _refreshData();
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _AssetsList(key: _assetsListKey, onRefresh: _refreshData),
                const SizedBox(height: 24),
                Builder(
                  builder: (BuildContext context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _SectionHeader(
                        title: l10n.myFamily,
                        actionText: l10n.seeAll,
                        onAction: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const FamilyListScreen()),
                          );
                          // Refresh data when returning from family list
                          await _refreshData();
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _FamilyList(key: _familyListKey, onRefresh: _refreshData),
                const SizedBox(height: 100), // Extra padding for floating card
              ],
            ),
          ),
        ],
            ),
          ),
          // Floating progress card at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _EstatePlanningProgressCard(
              trusts: _trusts,
              onRefresh: _refreshData,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double paddingTop;
  final Color backgroundColor;
  /// Key that changes when header content (e.g. profile image) should update,
  /// so the sliver rebuilds when profile loads.
  final String headerContentKey;
  final Widget child;

  _HomeHeaderDelegate({
    required this.paddingTop,
    required this.backgroundColor,
    required this.headerContentKey,
    required this.child,
  });

  @override
  double get minExtent => paddingTop + kToolbarHeight;

  @override
  double get maxExtent => paddingTop + kToolbarHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      padding: EdgeInsets.only(top: paddingTop, left: 16, right: 8, bottom: 0),
      child: SizedBox(
        height: kToolbarHeight,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return oldDelegate.paddingTop != paddingTop ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.headerContentKey != headerContentKey;
  }
}

class _TrustCardsCarousel extends StatefulWidget {
  final bool isLoading;
  final List<Trust> trusts;
  final VoidCallback? onRefresh;

  const _TrustCardsCarousel({
    this.isLoading = false,
    required this.trusts,
    this.onRefresh,
  });

  @override
  State<_TrustCardsCarousel> createState() => _TrustCardsCarouselState();
}

class _TrustCardsCarouselState extends State<_TrustCardsCarousel> {
  late ScrollController _scrollController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateCurrentPage);
  }

  void _updateCurrentPage() {
    if (!_scrollController.hasClients || widget.trusts.isEmpty) return;
    final double scrollPosition = _scrollController.offset;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double mainCardWidth = (screenWidth - 32) * 0.7; // 70% of available width
    final double spacing = 12; // Separator width
    final double itemWidth = mainCardWidth + spacing;
    final int newPage = (scrollPosition / itemWidth).round();
    // Clamp to valid trust card indices (exclude the add card at the end)
    final int clampedPage = newPage.clamp(0, widget.trusts.length - 1);
    if (clampedPage != _currentPage) {
      setState(() {
        _currentPage = clampedPage;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateCurrentPage);
    _scrollController.dispose();
    super.dispose();
  }

  String _statusLabel(TrustStatus s, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (s) {
      case TrustStatus.submitted:
        return l10n.submitted;
      case TrustStatus.approved:
        return l10n.approved;
      case TrustStatus.rejected:
        return l10n.rejected;
      case TrustStatus.draft:
        return l10n.draft;
    }
  }

  Color _statusColor(TrustStatus s) {
    switch (s) {
      case TrustStatus.submitted:
        return Colors.blue.shade600;
      case TrustStatus.approved:
        return Colors.green.shade700;
      case TrustStatus.rejected:
        return Colors.red.shade700;
      case TrustStatus.draft:
        return Colors.grey.shade600;
    }
  }

  String _formatAmount(String? estimatedNetWorth) {
    if (estimatedNetWorth == null || estimatedNetWorth.isEmpty) {
      return 'RM0.00';
    }
    // Match the formatting used on the Trust Details page
    // (see _formatEstimatedNetWorth in trust_dashboard_screen.dart)
    try {
      final double? numValue = double.tryParse(estimatedNetWorth);
      if (numValue != null) {
        return 'RM${numValue.toStringAsFixed(2)}';
      }
    } catch (_) {}
    // If it's a string like "below_rm_50k", format it nicely
    return estimatedNetWorth.replaceAll('_', ' ').replaceAllMapped(
      RegExp(r'\brm\b', caseSensitive: false),
      (Match match) => 'RM',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    // Calculate card width: show ~1.5 cards visible (main card + peek of next)
    // Main card takes ~70% of screen, add card is smaller
    final double mainCardWidth = (screenWidth - 32) * 0.7; // 70% of available width
    final double addCardWidth = (screenWidth - 32) * 0.5; // 50% of available width for add card
    const double cardHeight = 200;
    const double sectionHeight = cardHeight + 16; // small breathing space for shadow, padding
    
    if (widget.isLoading) {
      return SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Empty state: user has no trusts yet -> show a single, larger centered add card
    if (widget.trusts.isEmpty) {
      return SizedBox(
        height: sectionHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: SizedBox(
              width: screenWidth - 64, // a bit narrower than full width for a bolder look
              height: cardHeight,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () async {
                    // Check if user has seen the about page before
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    final bool hasSeenAbout = prefs.getBool('trust_about_seen') ?? false;

                    // Navigate to the trust creation flow. When the user finishes
                    // successfully, the flow returns the created Trust instance.
                    final Trust? createdTrust = await Navigator.of(context).push<Trust>(
                      MaterialPageRoute<Trust>(
                        builder: (_) =>
                            hasSeenAbout ? const TrustCreateScreen() : const TrustInfoScreen(),
                      ),
                    );
                    if (createdTrust != null && widget.onRefresh != null) {
                      widget.onRefresh!();
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: <Widget>[
                        // Background with dashed border
                        CustomPaint(
                          painter: _DashedBorderPainter(
                            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                            strokeWidth: 2,
                            borderRadius: 16,
                          ),
                          child: Container(),
                        ),
                        // Decorative coin image (matching trust cards)
                        Positioned(
                          right: -20,
                          bottom: 0,
                          child: Opacity(
                            opacity: 0.5,
                            child: Image.asset(
                              'assets/trust-three-coin.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.contain,
                              cacheWidth: 240,
                              cacheHeight: 240,
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _trustAccentColor.withOpacity(0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: _trustAccentColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.add,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: _trustAccentColor,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                AppLocalizations.of(context)!.createYourFirstTrustFund,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: sectionHeight,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.trusts.length + 1, // +1 for the add new trust card
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) {
              // Show add new trust card at the end
              if (index == widget.trusts.length) {
                return SizedBox(
                  width: addCardWidth,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () async {
                        // Check if user has seen the about page before
                        final SharedPreferences prefs = await SharedPreferences.getInstance();
                        final bool hasSeenAbout = prefs.getBool('trust_about_seen') ?? false;

                        // Navigate to the trust creation flow. When the user finishes
                        // successfully, the flow returns the created Trust instance.
                        final Trust? createdTrust = await Navigator.of(context).push<Trust>(
                          MaterialPageRoute<Trust>(
                            builder: (_) => hasSeenAbout
                                ? const TrustCreateScreen()
                                : const TrustInfoScreen(),
                          ),
                        );
                        if (createdTrust != null && widget.onRefresh != null) {
                          widget.onRefresh!();
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        painter: _DashedBorderPainter(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                          strokeWidth: 2,
                          borderRadius: 16,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _trustAccentColor.withOpacity(0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: _trustAccentColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Builder(
                                    builder: (BuildContext context) {
                                      final l10n = AppLocalizations.of(context)!;
                                      return Text(
                                        l10n.add,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: _trustAccentColor,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Builder(
                                builder: (BuildContext context) {
                                  return Text(
                                    widget.trusts.isEmpty
                                        ? AppLocalizations.of(context)!.createYourFirstTrustFund
                                        : AppLocalizations.of(context)!.addNewTrustFund,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              
              // Show trust card
              final Trust trust = widget.trusts[index];
              final String trustCode = trust.trustCode ?? 'N/A';
              final String amount = _formatAmount(trust.estimatedNetWorth);
              final TrustStatus status = trust.computedStatus;
              final bool isActive = status == TrustStatus.approved;
              
              return SizedBox(
                width: mainCardWidth,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => TrustDashboardScreen(trust: trust),
                        ),
                      ).then((_) {
                        if (widget.onRefresh != null) {
                          widget.onRefresh!();
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: <Widget>[
                        // Background gradient
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey.shade200,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 0,
                            ),
                          ),
                        ),
                        // Decorative image (book-like graphic) - behind content
                        Positioned(
                          right: -20,
                          bottom: -0,
                          child: Transform.rotate(
                            angle: 0,
                            child: Opacity(
                              opacity: 0.9,
                              child: Image.asset(
                                'assets/trust-three-coin.png',
                                width: 120,
                                height: 120,
                                fit: BoxFit.contain,
                                cacheWidth: 240,
                                cacheHeight: 240,
                              ),
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Builder(
                                          builder: (BuildContext context) {
                                            final l10n = AppLocalizations.of(context)!;
                                            return Text(
                                              l10n.familyAccount,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: const Color.fromRGBO(83, 61, 233, 1),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          trustCode,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.north_east,
                                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                    size: 20,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                amount,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.green : _statusColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Builder(
                                    builder: (BuildContext context) {
                                      final l10n = AppLocalizations.of(context)!;
                                      return Text(
                                        isActive ? l10n.yourPlanIsActive : _statusLabel(status, context),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isActive ? Colors.green.shade700 : _statusColor(status),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Remove page indicators since multiple cards are now visible
      ],
    );
  }
}

class _EstatePlanningProgressCard extends StatefulWidget {
  final List<Trust> trusts;
  final VoidCallback? onRefresh;

  const _EstatePlanningProgressCard({
    required this.trusts,
    this.onRefresh,
  });

  @override
  State<_EstatePlanningProgressCard> createState() => _EstatePlanningProgressCardState();
}

class _FeatureStatus {
  final String name;
  final bool isComplete;
  final IconData icon;
  const _FeatureStatus(this.name, this.isComplete, this.icon);
}

class _EstatePlanningProgressCardState extends State<_EstatePlanningProgressCard> {
  bool _isLoading = true;
  bool _isDismissed = false;
  bool _hasProfile = false;
  bool _hasAssets = false;
  bool _hasFamily = false;
  bool _hasWill = false;
  bool _hasExecutors = false;
  bool _hasTrusts = false;
  bool _hasHibah = false;

  @override
  void initState() {
    super.initState();
    _calculateProgress();
  }

  @override
  void didUpdateWidget(_EstatePlanningProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate if trusts list changed
    if (oldWidget.trusts.length != widget.trusts.length) {
      _calculateProgress();
    }
  }

  Future<void> _calculateProgress() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Check profile
      final profile = await AuthController.instance.getUserProfile();
      _hasProfile = profile != null && 
          ((profile.username != null && profile.username!.isNotEmpty) ||
           (profile.nricName != null && profile.nricName!.isNotEmpty));

      // Check assets
      final assetsResponse = await SupabaseService.instance.client
          .from('digital_assets')
          .select('id')
          .eq('uuid', user.id)
          .limit(1);
      _hasAssets = assetsResponse.isNotEmpty;

      // Check family members
      final familyResponse = await SupabaseService.instance.client
          .from('beloved')
          .select('id')
          .eq('uuid', user.id)
          .limit(1);
      _hasFamily = familyResponse.isNotEmpty;

      // Check will
      try {
        final will = await WillService.instance.getUserWill(user.id);
        _hasWill = will != null;
      } catch (_) {
        _hasWill = false;
      }

      // Check executors
      try {
        final executors = await ExecutorService.instance.listUserExecutors();
        _hasExecutors = executors.isNotEmpty;
      } catch (_) {
        _hasExecutors = false;
      }

      // Check trusts
      _hasTrusts = widget.trusts.isNotEmpty;

      // Check hibah
      try {
        final hibahResponse = await SupabaseService.instance.client
            .from('hibah')
            .select('id')
            .eq('uuid', user.id)
            .limit(1);
        _hasHibah = hibahResponse.isNotEmpty;
      } catch (_) {
        _hasHibah = false;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  List<_FeatureStatus> get _features => [
    _FeatureStatus('Profile', _hasProfile, Icons.person_outline),
    _FeatureStatus('Family', _hasFamily, Icons.family_restroom),
    _FeatureStatus('Assets', _hasAssets, Icons.account_balance_wallet_outlined),
    _FeatureStatus('Wasiat', _hasWill, Icons.description_outlined),
    _FeatureStatus('Pusaka', _hasExecutors, Icons.assignment_turned_in_outlined),
    _FeatureStatus('Trust', _hasTrusts, Icons.account_balance_outlined),
    _FeatureStatus('Hibah', _hasHibah, Icons.home_outlined),
  ];

  String _getLocalizedFeatureName(AppLocalizations l10n, String featureName) {
    switch (featureName) {
      case 'Profile':
        return l10n.profile;
      case 'Family':
        return l10n.family;
      case 'Assets':
        return l10n.assets;
      case 'Wasiat':
        return l10n.will;
      case 'Pusaka':
        return l10n.pusaka;
      case 'Trust':
        return l10n.trust;
      case 'Hibah':
        return l10n.propertyTrust;
      default:
        return featureName;
    }
  }

  int get _completedCount => _features.where((f) => f.isComplete).length;
  int get _totalCount => _features.length;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    // Hide when 100% complete
    if (!_isLoading && _completedCount == _totalCount) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final percentage = _isLoading ? 0.0 : (_completedCount / _totalCount);
    final percentageText = (percentage * 100).round();
    
    // Get the next incomplete feature for the CTA
    final nextFeature = _features.where((f) => !f.isComplete).firstOrNull;
    final ctaText = nextFeature != null 
        ? l10n.continueWithFeature(_getLocalizedFeatureName(l10n, nextFeature.name))
        : l10n.completeSetup;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _trustAccentColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context)
                .push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => const OnboardingGoalSelectionScreen(),
                fullscreenDialog: true,
              ),
            )
                .then((bool? completed) {
              _calculateProgress();
              widget.onRefresh?.call();
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              // Circular progress indicator
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(
                      value: _isLoading ? null : percentage,
                      strokeWidth: 4,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(_trustAccentColor),
                    ),
                    if (!_isLoading)
                      Text(
                        '$percentageText%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.accountSetup,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isLoading ? l10n.loading : ctaText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _trustAccentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow and dismiss
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDismissed = true;
                      });
                    },
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _ActionsGrid extends StatelessWidget {
  final List<Trust> trusts;

  // Main menu items: Will, Property, Pusaka (execution), Others
  List<_ActionItem> _getItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return <_ActionItem>[
      // Wasiat (Will) – same 3D picture as About Your Will page
      _ActionItem('assets/will-certificate-scroll.png', l10n.will),
      // Property (Hibah) – same 3D picture as About Property Trust page
      _ActionItem('assets/property-colour-key.png', l10n.hibah),
      // Pusaka – same 3D picture as About Pusaka/Executor page
      _ActionItem('assets/pusaka-transfer.png', l10n.pusaka),
      _ActionItem('assets/more-button-three.png', l10n.others),
    ];
  }

  // Items that go inside "Others" menu – use same 3D pictures as their about/feature screens
  List<_ActionItem> _getOthersItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return <_ActionItem>[
      _ActionItem('assets/assets-vault.png', l10n.assets),
      _ActionItem('assets/family-relationship.png', l10n.family),
      _ActionItem('assets/checklist-tick.png', l10n.checklist),
      _ActionItem('assets/trust-family-card.png', l10n.trust),
      _ActionItem('assets/onboard-emotion.png', l10n.aftercare),
    ];
  }

  final VoidCallback? onRefresh;
  const _ActionsGrid({
    required this.trusts,
    this.onRefresh,
  });

  Future<void> _handleItemTap(String label, BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (label == l10n.will) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const WillManagementScreen(),
        ),
      );
    } else if (label == l10n.hibah) {
      // When user taps Property (Hibah) from home:
      // - If they have no property trusts yet, go to the About Property Trust page first
      //   so they can immediately start creating from there.
      // - If they already have submissions, go to the Hibah Management screen.
      try {
        final hibahs = await HibahService.instance.listUserHibahs();
        if (!context.mounted) return;

        if (hibahs.isEmpty) {
          final bool? created = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (context) => const HibahInfoScreen(),
            ),
          );
          if (created == true) {
            onRefresh?.call();
          }
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const HibahManagementScreen(),
            ),
          );
          onRefresh?.call();
        }
      } catch (_) {
        // Fallback: if we can't load hibahs for some reason, keep existing behavior
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const HibahManagementScreen(),
          ),
        );
        onRefresh?.call();
      }
    } else if (label == l10n.pusaka) {
      // Pusaka (execution): executor flow — About Executors first if none, else management screen.
      try {
        final executors = await ExecutorService.instance.listUserExecutors();
        if (!context.mounted) return;
        if (executors.isEmpty) {
          final bool? created = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (context) => const ExecutorInfoScreen(),
            ),
          );
          if (created == true) {
            onRefresh?.call();
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const ExecutorManagementScreen(),
              ),
            );
          }
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const ExecutorManagementScreen(),
            ),
          );
          onRefresh?.call();
        }
      } catch (_) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const ExecutorManagementScreen(),
          ),
        );
        onRefresh?.call();
      }
    } else if (label == l10n.others) {
      _showOthersMenu(context);
    }
  }

  Future<void> _handleOthersItemTap(String label, BuildContext rootContext) async {
    final l10n = AppLocalizations.of(rootContext)!;
    Navigator.of(rootContext).pop(); // Close the bottom sheet first
    
    if (label == l10n.assets) {
      Navigator.of(rootContext).push(
        MaterialPageRoute<void>(
          builder: (context) => const AssetsListScreen(),
        ),
      ).then((_) {
        onRefresh?.call();
      });
    } else if (label == l10n.family) {
      Navigator.of(rootContext).push(
        MaterialPageRoute<void>(
          builder: (context) => const FamilyListScreen(),
        ),
      ).then((_) {
        onRefresh?.call();
      });
    } else if (label == l10n.checklist) {
      Navigator.of(rootContext).push(
        MaterialPageRoute<void>(
          builder: (context) => const ChecklistScreen(),
        ),
      );
    } else if (label == l10n.trust) {
      // Trust is in Others modal: same flow as before (About Trust first if no trusts, else Management).
      if (trusts.isEmpty) {
        Navigator.of(rootContext).push(
          MaterialPageRoute<void>(
            builder: (context) => const TrustInfoScreen(),
          ),
        ).then((_) {
          onRefresh?.call();
        });
      } else {
        Navigator.of(rootContext).push(
          MaterialPageRoute<void>(
            builder: (context) => const TrustManagementScreen(),
          ),
        ).then((_) {
          onRefresh?.call();
        });
      }
    } else if (label == l10n.aftercare) {
      Navigator.of(rootContext).push(
        MaterialPageRoute<void>(
          builder: (context) => const AftercareScreen(),
        ),
      );
    }
  }

  void _showOthersMenu(BuildContext rootContext) {
    showModalBottomSheet<void>(
      context: rootContext,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) {
        final ThemeData theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewPadding.bottom + 24,
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: <Widget>[
                        Builder(
                          builder: (BuildContext context) {
                            final l10n = AppLocalizations.of(context)!;
                            return Text(
                              l10n.others,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Builder(
                      builder: (BuildContext context) {
                        final othersItems = _getOthersItems(context);
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: othersItems.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            final _ActionItem item = othersItems[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _handleOthersItemTap(item.label, rootContext),
                                splashColor: theme.colorScheme.primary.withOpacity(0.08),
                                highlightColor: theme.colorScheme.primary.withOpacity(0.04),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: Center(
                                          child: item.iconAssetPath.endsWith('.png')
                                              ? Image.asset(
                                                  item.iconAssetPath,
                                                  width: 44,
                                                  height: 44,
                                                  fit: BoxFit.contain,
                                                  cacheWidth: 88,
                                                  cacheHeight: 88,
                                                )
                                              : SampulIcons.buildIcon(item.iconAssetPath, width: 24, height: 24),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Flexible(
                                        child: Text(
                                          item.label,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final items = _getItems(context);
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 8),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _ActionItem item = items[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _handleItemTap(item.label, context),
            splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Center(
                      child: item.iconAssetPath.endsWith('.png')
                          ? Image.asset(
                              item.iconAssetPath,
                              width: 44,
                              height: 44,
                              fit: BoxFit.contain,
                              cacheWidth: 88,
                              cacheHeight: 88,
                            )
                          : SampulIcons.buildIcon(item.iconAssetPath, width: 24, height: 24),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(item.label, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionItem {
  final String iconAssetPath;
  final String label;
  const _ActionItem(this.iconAssetPath, this.label);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromRGBO(83, 61, 233, 1),
            ),
            child: Text(actionText!),
          ),
      ],
    );
  }
}

class _AssetsList extends StatefulWidget {
  final VoidCallback? onRefresh;
  const _AssetsList({super.key, this.onRefresh});

  @override
  State<_AssetsList> createState() => _AssetsListState();
}

class _AssetsListState extends State<_AssetsList> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _assets = <Map<String, dynamic>>[];

  String _prettyInstruction(String? key, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch ((key ?? '').toLowerCase()) {
      case 'faraid':
        return l10n.faraid;
      case 'terminate':
        return l10n.terminateSubscriptions;
      case 'transfer_as_gift':
        return l10n.transferAsGift;
      case 'settle':
        return l10n.settleDebts;
      default:
        return '';
    }
  }

  Color _badgeBg(String? key, BuildContext context) {
    final String k = (key ?? '').toLowerCase();
    switch (k) {
      case 'faraid':
        return Colors.indigo.shade50;
      case 'terminate':
        return Colors.red.shade50;
      case 'transfer_as_gift':
        return Colors.teal.shade50;
      case 'settle':
        return Colors.orange.shade50;
      default:
        return Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5);
    }
  }

  Color _badgeFg(String? key, BuildContext context) {
    final String k = (key ?? '').toLowerCase();
    switch (k) {
      case 'faraid':
        return Colors.indigo.shade700;
      case 'terminate':
        return Colors.red.shade700;
      case 'transfer_as_gift':
        return Colors.teal.shade800;
      case 'settle':
        return Colors.orange.shade800;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final List<dynamic> rows = await SupabaseService.instance.client
          .from('digital_assets')
          .select('id,new_service_platform_name,new_service_platform_logo_url,instructions_after_death,asset_type,physical_asset_category')
          .eq('uuid', user.id)
          .order('created_at', ascending: false)
          .limit(20);
      if (!mounted) return;
      setState(() {
        _assets = rows.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Public method to allow parent to trigger reloads
  Future<void> reload() => _loadAssets();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 1 + (_assets.length),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return GestureDetector(
              onTap: () async {
                // Check if user has seen the about page before
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                final bool hasSeenAbout = prefs.getBool('assets_about_seen') ?? false;
                
                // If user hasn't seen about page, show it first
                // Otherwise, go directly to add asset page
                final bool? result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => hasSeenAbout 
                        ? const AddAssetScreen() 
                        : const AssetInfoScreen(),
                  ),
                );
                if (result == true) {
                  await _loadAssets();
                  widget.onRefresh?.call();
                }
              },
              child: Builder(
                builder: (BuildContext context) {
                  final l10n = AppLocalizations.of(context)!;
                  return _AddCircle(label: l10n.add);
                },
              ),
            );
          }

          if (_isLoading) {
            return Builder(
              builder: (BuildContext context) {
                final l10n = AppLocalizations.of(context)!;
                return Column(
                  children: <Widget>[
                    const SizedBox(width: 56, height: 56, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(height: 6),
                    SizedBox(width: 76, child: Text(l10n.loading, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                  ],
                );
              },
            );
          }

          final Map<String, dynamic> asset = _assets[index - 1];
          final int id = (asset['id'] as num).toInt();
          final l10n = AppLocalizations.of(context)!;
          final String name = (asset['new_service_platform_name'] as String?) ?? l10n.unknown;
          final String assetType = (asset['asset_type'] as String?) ?? 'digital';
          final String? physicalCategory = asset['physical_asset_category'] as String?;
          final String? logoUrl = asset['new_service_platform_logo_url'] as String?;
          final String? category = asset['instructions_after_death'] as String?;
          final String categoryText = _prettyInstruction(category, context);
          return GestureDetector(
            onTap: () async {
              final bool? changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => AssetPreviewScreen(assetId: id),
                ),
              );
              if (changed == true) {
                await _loadAssets();
                widget.onRefresh?.call();
              }
            },
            child: Column(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAEAEA),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: assetType == 'physical'
                      ? _PhysicalAssetIconHome(category: physicalCategory, size: 32)
                      : (logoUrl != null && logoUrl.isNotEmpty)
                          ? ClipOval(
                              child: _Logo(
                                url: BrandfetchService.instance.addClientIdToUrl(logoUrl) ?? logoUrl,
                                size: 56,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.apps),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 76,
                  child: Column(
                    children: <Widget>[
                      Text(name, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                      if (categoryText.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: _badgeBg(category, context),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            categoryText,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 9.5, color: _badgeFg(category, context), fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
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

class _FamilyList extends StatefulWidget {
  final VoidCallback? onRefresh;
  const _FamilyList({super.key, this.onRefresh});

  @override
  State<_FamilyList> createState() => _FamilyListState();
}

class _FamilyListState extends State<_FamilyList> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _family = <Map<String, dynamic>>[];

  String _prettyType(String? t, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch ((t ?? '').toLowerCase()) {
      case 'co_sampul':
        return l10n.coSampul;
      case 'future_owner':
        return l10n.beneficiary;
      case 'guardian':
        return l10n.guardian;
      default:
        return '';
    }
  }

  Color _badgeBg(String? key, BuildContext context) {
    final String k = (key ?? '').toLowerCase();
    switch (k) {
      case 'co_sampul':
        return Colors.indigo.shade50;
      case 'future_owner':
        return Colors.teal.shade50;
      case 'guardian':
        return Colors.orange.shade50;
      default:
        return Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5);
    }
  }

  Color _badgeFg(String? key, BuildContext context) {
    final String k = (key ?? '').toLowerCase();
    switch (k) {
      case 'co_sampul':
        return Colors.indigo.shade700;
      case 'future_owner':
        return Colors.teal.shade800;
      case 'guardian':
        return Colors.orange.shade800;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final List<dynamic> rows = await SupabaseService.instance.client
          .from('beloved')
          .select('id,name,image_path,type')
          .eq('uuid', user.id)
          .order('created_at', ascending: false)
          .limit(20);
      if (!mounted) return;
      setState(() {
        _family = rows.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Public method to allow parent to trigger reloads
  Future<void> reload() => _loadFamily();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 1 + _family.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return GestureDetector(
              onTap: () async {
                // Check if user has seen the about page before
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                final bool hasSeenAbout = prefs.getBool('family_about_seen') ?? false;
                
                // If user hasn't seen about page, show it first
                // Otherwise, go directly to add family member page
                final bool? created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => hasSeenAbout 
                        ? const AddFamilyMemberScreen() 
                        : const FamilyInfoScreen(),
                  ),
                );
                if (created == true) {
                  await _loadFamily();
                  widget.onRefresh?.call();
                }
              },
              child: Builder(
                builder: (BuildContext context) {
                  final l10n = AppLocalizations.of(context)!;
                  return _AddCircle(label: l10n.add);
                },
              ),
            );
          }
          if (_isLoading) {
            return Builder(
              builder: (BuildContext context) {
                final l10n = AppLocalizations.of(context)!;
                return Column(
                  children: <Widget>[
                    const SizedBox(width: 56, height: 56, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(height: 6),
                    SizedBox(width: 72, child: Text(l10n.loading, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                  ],
                );
              },
            );
          }
          final Map<String, dynamic> f = _family[index - 1];
          final l10n = AppLocalizations.of(context)!;
          final String name = (f['name'] as String?) ?? l10n.unknown;
          final String? imagePath = f['image_path'] as String?;
          final String? type = f['type'] as String?;
          final String typeText = _prettyType(type, context);
          return GestureDetector(
            onTap: () async {
              final bool? updated = await Navigator.of(context).push(
                MaterialPageRoute<bool>(builder: (_) => EditFamilyMemberScreen(belovedId: (f['id'] as num).toInt())),
              );
              if (updated == true) {
                await _loadFamily();
                widget.onRefresh?.call();
              }
            },
            child: Column(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEAEAEA),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: (imagePath != null && imagePath.isNotEmpty)
                    ? Image.network(
                        SupabaseService.instance.getFullImageUrl(imagePath) ?? '',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        cacheWidth: 112,
                        cacheHeight: 112,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person),
                      )
                    : const Icon(Icons.person),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 72,
                child: Column(
                  children: <Widget>[
                    Text(name, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                    if (typeText.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _badgeBg(type, context),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          typeText,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 9.5, color: _badgeFg(type, context), fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ));
        },
      ),
    );
  }
}

class _AddCircle extends StatelessWidget {
  final String label;
  const _AddCircle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _trustAccentColor.withOpacity(0.4),
              style: BorderStyle.solid,
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.add,
            color: _trustAccentColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 60,
          child: Text(label, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  final String url;
  final double size;
  final BoxFit fit;
  const _Logo({required this.url, required this.size, this.fit = BoxFit.contain});

  bool get _isSvg => url.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Icon(Icons.image_outlined, size: size);
    if (_isSvg) {
      return SvgPicture.network(
        url,
        width: size,
        height: size,
        fit: fit,
        placeholderBuilder: (_) => SizedBox(width: size, height: size, child: const CircularProgressIndicator(strokeWidth: 1.5)),
      );
    }
    return Image.network(
      url,
      width: size,
      height: size,
      fit: fit,
      cacheWidth: (size * 2).toInt(),
      cacheHeight: (size * 2).toInt(),
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _PhysicalAssetIconHome extends StatelessWidget {
  final String? category;
  final double size;

  const _PhysicalAssetIconHome({required this.category, required this.size});

  String _iconPathForCategory() {
    switch (category) {
      case 'land':
        return SampulIcons.land;
      case 'houses_buildings':
        return SampulIcons.home;
      case 'farms_plantations':
        return SampulIcons.farm;
      case 'cash':
        return SampulIcons.payment;
      case 'vehicles':
        return SampulIcons.car;
      case 'jewellery':
        return SampulIcons.diamond;
      case 'furniture_household':
        return SampulIcons.furniture;
      case 'financial_instruments':
        return SampulIcons.assets;
      case 'other':
        return SampulIcons.category;
      default:
        return SampulIcons.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SampulIcons.buildIcon(
      _iconPathForCategory(),
      width: size,
      height: size,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Inset the rect slightly so the dashes sit nicely inside the card edges
    final Rect rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    // Draw dashed border
    final Path path = Path();
    path.addRRect(rrect);

    final ui.PathMetrics pathMetrics = path.computeMetrics();
    for (final ui.PathMetric pathMetric in pathMetrics) {
      double distance = 0;
      const double dashWidth = 5.0;
      const double dashSpace = 3.0;
      while (distance < pathMetric.length) {
        final double end = (distance + dashWidth).clamp(0.0, pathMetric.length);
        final Path extractPath = pathMetric.extractPath(distance, end);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


