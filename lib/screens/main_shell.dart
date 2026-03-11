import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'resources_insights_screen.dart';
import 'will_management_screen.dart';
import 'settings_screen.dart';
import 'enhanced_chat_conversation_screen.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/affiliate_service.dart';
import '../services/ai_chat_settings_service.dart';
import '../utils/sampul_icons.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = <Widget>[
      const HomeScreen(),
      const ResourcesInsightsScreen(),   // Learn
      const WillManagementScreen(),      // Wasiat
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
  }

  Future<void> _openSampulAI() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      // Get or create Sampul AI conversation
      final conversations = await ChatService.getUserConversations(currentUser.id);
      ChatConversation aiConversation;
      
      try {
        aiConversation = conversations.firstWhere(
          (conv) => conv.conversationType == ConversationType.ai,
        );
      } catch (_) {
        // AI conversation not found, create it
        final response = await Supabase.instance.client
            .from('chat_conversations')
            .insert({
              'name': 'Sampul AI',
              'last_message': (await AiChatSettingsService.instance.getActiveSettings()).welcomeMessage,
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
        
        // Add welcome message to the conversation (get from settings)
        final settings = await AiChatSettingsService.instance.getActiveSettings();
        final welcomeMessage = ChatMessage(
          id: '',
          content: settings.welcomeMessage,
          isFromUser: false,
          timestamp: DateTime.now(),
        );
        
        await ChatService.saveMessage(welcomeMessage, aiConversation.id);
      }

      if (!mounted) return;

      // Navigate to AI chat
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EnhancedChatConversationScreen(
            conversation: aiConversation,
          ),
        ),
      );
    } catch (e) {
      // If error, try to create a temporary conversation
      if (!mounted) return;
      final tempConversation = ChatConversation(
        id: 'temp_ai_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Sampul AI',
        lastMessage: 'Hello! I\'m your estate planning assistant. How can I help you today?',
        lastMessageTime: DateTime.now(),
        avatarUrl: '',
        unreadCount: 0,
        isOnline: true,
        conversationType: ConversationType.ai,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
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
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _buildNavItem(
                  context: context,
                  theme: theme,
                  icon: SampulIcons.learn,
                  label: 'Learn',
                  index: 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                // Invisible spacer for center button
                const SizedBox(width: 60),
                _buildNavItem(
                  context: context,
                  theme: theme,
                  icon: SampulIcons.wasiat,
                  label: 'Wasiat',
                  index: 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _buildNavItem(
                  context: context,
                  theme: theme,
                  icon: SampulIcons.settings,
                  label: 'Settings',
                  index: 3,
                  onTap: () => setState(() => _currentIndex = 3),
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
                onTap: _openSampulAI,
                customBorder: const CircleBorder(),
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.2),
                radius: 30,
                child: Container(
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
                    child: SvgPicture.asset(
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
