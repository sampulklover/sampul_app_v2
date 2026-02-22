import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'asset_info_screen.dart';
import '../controllers/auth_controller.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'assets_list_screen.dart';
import '../services/brandfetch_service.dart';
import 'edit_asset_screen.dart';
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
import 'onboarding_flow_screen.dart';
import 'aftercare_screen.dart';
import '../models/trust.dart';
import '../services/trust_service.dart';
import 'trust_info_screen.dart';
import 'referral_dashboard_screen.dart';
import 'notification_screen.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';

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
        builder: (_) => const OnboardingFlowScreen(),
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: <Widget>[
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            expandedHeight: 110,
            backgroundColor: const Color.fromRGBO(83, 61, 233, 1),
            foregroundColor: Colors.white,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SvgPicture.asset(
                  'assets/sampul-icon-all-white.svg',
                  width: 22,
                  height: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sampul',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            actions: <Widget>[
              Builder(
                builder: (BuildContext context) {
                  final l10n = AppLocalizations.of(context)!;
                  return IconButton(
                    tooltip: l10n.referrals,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const ReferralDashboardScreen()),
                      );
                    },
                    icon: const Icon(Icons.card_giftcard_outlined, color: Colors.white),
                  );
                },
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const NotificationScreen()),
                  );
                },
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
            // Keep the app bar standard (no rounded bottom) for a clean Material look
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const double expanded = 140;
                final double t = ((constraints.maxHeight - kToolbarHeight) / (expanded - kToolbarHeight)).clamp(0.0, 1.0);
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        const Color.fromRGBO(83, 61, 233, 1),
                        const Color.fromRGBO(60, 45, 170, 1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 48),
                  child: Builder(
                    builder: (BuildContext context) {
                      final l10n = AppLocalizations.of(context)!;
                      return Offstage(
                        offstage: t < 0.15,
                        child: Opacity(
                          opacity: t,
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              _isLoadingProfile
                                  ? l10n.assalamualaikum
                                  : l10n.assalamualaikumWithName(_userProfile?.displayName ?? AuthController.instance.currentUser?.email?.split('@')[0] ?? l10n.unknown),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 12),
                _TrustCardsCarousel(
                  isLoading: _isLoadingTrusts,
                  trusts: _trusts,
                  onRefresh: _refreshData,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _ActionsGrid(onRefresh: _refreshData),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
        ),
      ),
    );
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
    final double cardWidth = screenWidth - 32; // Full width minus padding
    final double spacing = 12; // Separator width
    final double itemWidth = cardWidth + spacing;
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
    
    if (widget.isLoading) {
      return SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: 180,
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
                  width: MediaQuery.of(context).size.width - 32,
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      onTap: () async {
                        // Check if user has seen the about page before
                        final SharedPreferences prefs = await SharedPreferences.getInstance();
                        final bool hasSeenAbout = prefs.getBool('trust_about_seen') ?? false;
                        
                        final bool? created = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => hasSeenAbout 
                                ? const TrustCreateScreen() 
                                : const TrustInfoScreen(),
                          ),
                        );
                        if (created == true && widget.onRefresh != null) {
                          widget.onRefresh!();
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Colors.white,
                              theme.colorScheme.primaryContainer.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.add_circle_outline,
                                  color: theme.colorScheme.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Builder(
                                builder: (BuildContext context) {
                                  final l10n = AppLocalizations.of(context)!;
                                  return Text(
                                    widget.trusts.isEmpty ? l10n.createYourFirstTrustFund : l10n.addNewTrustFund,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Builder(
                                builder: (BuildContext context) {
                                  final l10n = AppLocalizations.of(context)!;
                                  return Text(
                                    l10n.tapToGetStarted,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
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
                width: MediaQuery.of(context).size.width - 32, // Full width minus padding
                child: Card(
              elevation: 1,
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
                child: Stack(
                  children: <Widget>[
                    // Background gradient
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            Colors.white,
                            theme.colorScheme.primaryContainer.withOpacity(0.1),
                          ],
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_outward,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () {
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
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
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
                    // Decorative element (purple cube-like graphic)
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        transform: Matrix4.rotationZ(0.2),
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
        if (widget.trusts.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.trusts.length, // Only show dots for trust cards, not the add card
              (index) => GestureDetector(
                onTap: () {
                  final double cardWidth = MediaQuery.of(context).size.width - 32;
                  final double spacing = 12;
                  final double targetOffset = index * (cardWidth + spacing);
                  _scrollController.animateTo(
                    targetOffset,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionsGrid extends StatelessWidget {
  // Main menu items: Will, Hibah, Trust, Others
  List<_ActionItem> _getItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return <_ActionItem>[
      _ActionItem(Icons.description_outlined, l10n.will),
      _ActionItem(Icons.group_outlined, l10n.hibah),
      _ActionItem(Icons.gavel_outlined, l10n.trust),
      _ActionItem(Icons.more_horiz, l10n.others),
    ];
  }

  // Items that go inside "Others" menu
  List<_ActionItem> _getOthersItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return <_ActionItem>[
      _ActionItem(Icons.account_balance_wallet_outlined, l10n.assets),
      _ActionItem(Icons.family_restroom, l10n.family),
      _ActionItem(Icons.checklist_outlined, l10n.checklist),
      _ActionItem(Icons.task_alt_outlined, l10n.execution),
      _ActionItem(Icons.medical_services_outlined, l10n.aftercare),
    ];
  }

  final VoidCallback? onRefresh;
  const _ActionsGrid({this.onRefresh});

  void _handleItemTap(String label, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (label == l10n.will) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const WillManagementScreen(),
        ),
      );
    } else if (label == l10n.hibah) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const HibahManagementScreen(),
        ),
      );
    } else if (label == l10n.trust) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const TrustManagementScreen(),
        ),
      );
    } else if (label == l10n.others) {
      _showOthersMenu(context);
    }
  }

  void _handleOthersItemTap(String label, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).pop(); // Close the bottom sheet first
    
    if (label == l10n.assets) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const AssetsListScreen(),
        ),
      ).then((_) {
        onRefresh?.call();
      });
    } else if (label == l10n.family) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const FamilyListScreen(),
        ),
      ).then((_) {
        onRefresh?.call();
      });
    } else if (label == l10n.checklist) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const ChecklistScreen(),
        ),
      );
    } else if (label == l10n.execution) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const ExecutorManagementScreen(),
        ),
      );
    } else if (label == l10n.aftercare) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const AftercareScreen(),
        ),
      );
    }
  }

  void _showOthersMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewPadding.bottom + 24,
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
                            childAspectRatio: 0.9,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            final _ActionItem item = othersItems[index];
                        return GestureDetector(
                          onTap: () => _handleOthersItemTap(item.label, context),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(item.icon, color: const Color.fromRGBO(83, 61, 233, 1)),
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
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
    final ThemeData theme = Theme.of(context);
    final items = _getItems(context);
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _ActionItem item = items[index];
        return GestureDetector(
          onTap: () => _handleItemTap(item.label, context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: const Color.fromRGBO(83, 61, 233, 1)),
              ),
              const SizedBox(height: 8),
              Text(item.label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  const _ActionItem(this.icon, this.label);
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
          TextButton(onPressed: onAction, child: Text(actionText!)),
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
          .select('id,new_service_platform_name,new_service_platform_logo_url,instructions_after_death')
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
          final String? logoUrl = asset['new_service_platform_logo_url'] as String?;
          final String? category = asset['instructions_after_death'] as String?;
          final String categoryText = _prettyInstruction(category, context);
          return GestureDetector(
            onTap: () async {
              final bool? updated = await Navigator.of(context).push(
                MaterialPageRoute<bool>(builder: (_) => EditAssetScreen(assetId: id)),
              );
              if (updated == true) {
                await _loadAssets();
                widget.onRefresh?.call();
              }
            },
            child: Column(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: (logoUrl != null && logoUrl.isNotEmpty)
                      ? ClipOval(child: _Logo(url: BrandfetchService.instance.addClientIdToUrl(logoUrl) ?? logoUrl, size: 56, fit: BoxFit.cover))
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
            border: Border.all(color: Colors.purple, style: BorderStyle.solid, width: 2),
          ),
          child: const Icon(Icons.add, color: Color.fromRGBO(83, 61, 233, 1)),
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
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}


