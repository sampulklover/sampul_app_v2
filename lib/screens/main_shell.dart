import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'resources_insights_screen.dart';
import 'will_management_screen.dart';
import 'settings_screen.dart';
import 'enhanced_chat_conversation_screen.dart';
import '../models/chat_conversation.dart';
import '../services/chat_service.dart';
import '../services/affiliate_service.dart';
import '../utils/sampul_icons.dart';
import '../config/analytics_screens.dart';
import '../services/analytics_service.dart';

class MainShell extends StatefulWidget {
  final int initialTabIndex;

  const MainShell({super.key, this.initialTabIndex = 0});

  static MainShellState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<MainShellState>();
  }

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _currentIndex;
  late final List<Widget> _tabs;
  final GlobalKey<WillManagementScreenState> _wasiatTabKey =
      GlobalKey<WillManagementScreenState>();
  bool _isOpeningAI = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex.clamp(0, 3);
    _tabs = <Widget>[
      const HomeScreen(),
      const ResourcesInsightsScreen(),   // Learn
      WillManagementScreen(key: _wasiatTabKey), // Wasiat
      const SettingsScreen(),            // Settings
    ];

    // If user entered a referral code during onboarding (or earlier), try to claim it now.
    // Safe to call repeatedly; server enforces constraints.
    Future<void>(() async {
      try {
        await AffiliateService.instance.claimPendingIfAny();
      } catch (_) {
        // Silent fail; user can re-enter in onboarding.
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logTabScreen(_currentIndex);
    });
  }

  String _screenNameForTab(int index) {
    switch (index) {
      case 0:
        return AnalyticsScreens.mainHome;
      case 1:
        return AnalyticsScreens.mainLearn;
      case 2:
        return AnalyticsScreens.mainWasiat;
      case 3:
        return AnalyticsScreens.mainSettings;
      default:
        return AnalyticsScreens.mainHome;
    }
  }

  void selectTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _logTabScreen(index);
  }

  Future<void> openWasiatCertificatePrompt() async {
    if (_currentIndex != 2) {
      setState(() => _currentIndex = 2);
      _logTabScreen(2);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wasiatTabKey.currentState?.openGenerateCertificatePrompt();
    });
  }

  void _logTabScreen(int index) {
    AnalyticsService.logScreen(_screenNameForTab(index));
  }

  Future<void> _openSampulAI() async {
    if (_isOpeningAI) return;
    
    setState(() {
      _isOpeningAI = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        if (mounted) setState(() => _isOpeningAI = false);
        return;
      }

      ChatConversation? aiConversation;
      
      // Try to find existing AI conversation quickly
      try {
        final conversations = await ChatService.getUserConversations(currentUser.id);
        aiConversation = conversations.firstWhere(
          (conv) => conv.conversationType == ConversationType.ai,
        );
      } catch (_) {
        // AI conversation not found - will create in background
      }

      if (!mounted) return;

      if (aiConversation != null) {
        // Navigate immediately with existing conversation
        setState(() => _isOpeningAI = false);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            settings: const RouteSettings(name: AnalyticsScreens.sampulAiChat),
            builder: (context) => EnhancedChatConversationScreen(
              conversation: aiConversation!,
            ),
          ),
        );
      } else {
        // Create new AI conversation
        final response = await Supabase.instance.client
            .from('chat_conversations')
            .insert({
              'name': 'Sampul AI',
              'last_message': '',
              'last_message_time': DateTime.now().toIso8601String(),
              'avatar_url': '',
              'unread_count': 0,
              'is_online': true,
              'conversation_type': 'ai',
              'created_by': currentUser.id,
            })
            .select()
            .single();

        aiConversation = ChatConversation.fromJson(response);
        
        if (!mounted) return;
        
        setState(() => _isOpeningAI = false);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            settings: const RouteSettings(name: AnalyticsScreens.sampulAiChat),
            builder: (context) => EnhancedChatConversationScreen(
              conversation: aiConversation!,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isOpeningAI = false);
      
      // Create temporary conversation as fallback
      final tempConversation = ChatConversation(
        id: 'temp_ai_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Sampul AI',
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        avatarUrl: '',
        unreadCount: 0,
        isOnline: true,
        conversationType: ConversationType.ai,
      );

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          settings: const RouteSettings(name: AnalyticsScreens.sampulAiChat),
          builder: (context) => EnhancedChatConversationScreen(
            conversation: tempConversation,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(context, theme),
    );
  }

  Widget _buildCustomBottomNavBar(BuildContext context, ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    
    return Container(
      padding: EdgeInsets.only(bottom: safeAreaBottom),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  context: context,
                  theme: theme,
                  icon: SampulIcons.home,
                  label: 'Home',
                  index: 0,
                  onTap: () => selectTab(0),
                ),
                _buildNavItem(
                  context: context,
                  theme: theme,
                  icon: SampulIcons.learn,
                  label: 'Learn',
                  index: 1,
                  onTap: () => selectTab(1),
                ),
                // Invisible spacer for center button
                const SizedBox(width: 60),
                _buildNavItem(
                  context: context,
                  theme: theme,
                  icon: SampulIcons.wasiat,
                  label: 'Wasiat',
                  index: 2,
                  onTap: () => selectTab(2),
                ),
                _buildNavItem(
                  context: context,
                  theme: theme,
                  icon: SampulIcons.settings,
                  label: 'Settings',
                  index: 3,
                  onTap: () => selectTab(3),
                ),
              ],
            ),
          ),
          // Center AI Chat Button
          Positioned(
            left: screenWidth / 2 - 30,
            top: -20,
            child: Material(
              color: theme.colorScheme.primary,
              shape: const CircleBorder(),
              elevation: 0,
              child: InkWell(
                onTap: _isOpeningAI ? null : _openSampulAI,
                customBorder: const CircleBorder(),
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.2),
                radius: 30,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isOpeningAI
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : SvgPicture.asset(
                            'assets/sampul-icon-all-white.svg',
                            width: 32,
                            height: 32,
                            cacheColorFilter: true,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required ThemeData theme,
    required String icon,
    required String label,
    required int index,
    required VoidCallback onTap,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          splashColor: Colors.grey.withOpacity(0.12),
          highlightColor: Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          containedInkWell: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SampulIcons.buildBottomNavIcon(
                icon,
                isSelected: isSelected,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
