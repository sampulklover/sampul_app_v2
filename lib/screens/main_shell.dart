import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'will_management_screen.dart';
import 'notification_screen.dart';
import 'enhanced_chat_conversation_screen.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final GlobalKey<WillManagementScreenState> _willTabKey = GlobalKey<WillManagementScreenState>();
  late final List<Widget> _tabs;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _tabs = <Widget>[
      const HomeScreen(),
      const NotificationScreen(),
      WillManagementScreen(key: _willTabKey),
      const SettingsScreen(),
    ];
    
    // Initialize animation controller with better performance settings
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // Width animation: expands to show text, then contracts with smooth curves
    _widthAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 56.0, end: 140.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 0.35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 140.0, end: 140.0),
        weight: 0.15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 140.0, end: 56.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 0.5,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );
    
    // Text opacity animation: fades in and out smoothly
    _textOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 0.15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.6,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );
    
    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              'last_message': 'Hello! I\'m your estate planning assistant. How can I help you today?',
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
        
        // Add welcome message to the conversation
        final welcomeMessage = ChatMessage(
          id: '',
          content: "Hello! I'm Sampul AI, your estate planning assistant. How can I help you today?",
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() => _currentIndex = index);
          if (index == 2) {
            // Will tab became active; ensure it refreshes its data
            _willTabKey.currentState?.reload();
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        backgroundColor: Theme.of(context).colorScheme.surface,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Will'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
      floatingActionButton: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final width = _widthAnimation.value;
            final showText = width > 80;
            final textOpacity = _textOpacityAnimation.value;
            
            return PhysicalModel(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(28),
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openSampulAI,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: width,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 14),
                          SvgPicture.asset(
                            'assets/sampul-icon-white.svg',
                            width: 28,
                            height: 28,
                            cacheColorFilter: true,
                          ),
                          if (showText)
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8, right: 14),
                                child: Opacity(
                                  opacity: textOpacity,
                                  child: const Text(
                                    'Sampul AI',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}


