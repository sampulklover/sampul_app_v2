import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../services/openrouter_service.dart';
import '../services/chat_service.dart';
import '../controllers/auth_controller.dart';
import '../services/will_service.dart';
import '../services/file_upload_service.dart';
import '../services/ai_chat_settings_service.dart';
import '../services/ai_action_detector.dart';
import '../services/supabase_service.dart';
import '../services/ai_kb_service.dart';
import '../utils/sampul_icons.dart';
import '../utils/url_launch_helper.dart';
import 'trust_create_screen.dart';
import 'trust_management_screen.dart';
import 'trust_info_screen.dart';
import 'hibah_management_screen.dart';
import 'will_management_screen.dart';
import 'asset_info_screen.dart';
import 'assets_list_screen.dart';
import 'add_asset_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'family_info_screen.dart';
import 'family_list_screen.dart';
import 'add_family_member_screen.dart';
import 'executor_management_screen.dart';
import 'checklist_screen.dart';
import 'extra_wishes_screen.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';

class EnhancedChatConversationScreen extends StatefulWidget {
  final ChatConversation conversation;

  const EnhancedChatConversationScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<EnhancedChatConversationScreen> createState() => _EnhancedChatConversationScreenState();
}

class _EnhancedChatConversationScreenState extends State<EnhancedChatConversationScreen>
    with TickerProviderStateMixin {
  static const Color _chatGradientTop = Color(0xFF6D5EF7);
  static const Color _chatGradientBottom = Color(0xFFB5AEEA);
  static const Color _chatGradientDeep = Color(0xFF2C1B63);
  /// Soft bloom tones for mesh-style background (Sampul purple family).
  static const Color _meshBloomLavender = Color(0xFFE8E0FF);
  static const Color _meshBloomViolet = Color(0xFF9B84FF);
  static const Color _meshBloomMist = Color(0xFFD4CCF8);
  static const Color _chatTextLight = Color(0xFFF4F1FF);
  static const Color _chatTextMuted = Color(0xFFE3DDF9);

  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String _streamingContent = '';
  bool _isUploading = false;
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _relatedQuestions = const <String>[];
  
  late AnimationController _typingAnimationController;
  late AnimationController _messageAnimationController;
  late AnimationController _backgroundAnimationController;
  late Animation<double> _typingAnimation;
  late Animation<double> _messageAnimation;
  
  RealtimeChannel? _messagesChannel;
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;
  DateTime? _oldestMessageTime;
  Future<List<String>>? _suggestedQuestionsFuture;
  String? _suggestedQuestionsLanguage;
  DateTime? _lastStreamAutoScrollAt;
  bool _isComposerExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scrollController.addListener(_onScroll);
    // Defer heavy initialization to after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    final language = (locale.languageCode == 'ms' || locale.languageCode == 'bm') ? 'bm' : 'en';
    if (_suggestedQuestionsFuture == null || _suggestedQuestionsLanguage != language) {
      _suggestedQuestionsLanguage = language;
      _suggestedQuestionsFuture = AiKbService.instance.getSuggestedQuestions(
        language: language,
        limit: 6,
      );
    }
  }

  /// Attachments are hidden from the composer for now; restore the attach control to use this.
  // ignore: unused_element
  Future<void> _pickAndSendAttachments() async {
    // Show bottom sheet to choose source: Photos, Camera, Files
    if (_isUploading) return;
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photos'),
              onTap: () => Navigator.pop(context, 'photos'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Files'),
              onTap: () => Navigator.pop(context, 'files'),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    if (source == 'photos') {
      await _pickImagesFromGallery();
      return;
    } else if (source == 'camera') {
      await _captureImageFromCamera();
      return;
    }
    // Default to file picker
    if (_isUploading) return;
    try {
      setState(() {
        _isUploading = true;
      });
      final files = await FileUploadService.pickMultipleFiles();
      if (files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No files selected')),
          );
          setState(() {
            _isUploading = false;
          });
        }
        return;
      }
      final user = AuthController.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You need to be signed in to upload.')),
          );
          setState(() {
            _isUploading = false;
          });
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploading ' + files.length.toString() + ' file(s)...')),
        );
      }
      for (final f in files) {
        final path = f.path;
        if (path == null) continue;
        final file = File(path);
        final upload = await FileUploadService.uploadAttachment(
          file: file,
          userId: user.id,
          conversationId: widget.conversation.id,
        );
        final isImage = upload.mimeType.startsWith('image/');
        final msg = ChatMessage(
          id: '', // Let database generate UUID
          content: upload.publicUrl,
          isFromUser: true,
          timestamp: DateTime.now(),
          messageType: isImage ? MessageType.image : MessageType.file,
        );
        setState(() {
          _messages.add(msg);
        });
        await ChatService.saveMessage(msg, widget.conversation.id);
        _scrollToBottom();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload complete')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ' + e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _pickImagesFromGallery() async {
    if (_isUploading) return;
    try {
      setState(() {
        _isUploading = true;
      });
      final List<XFile> picked = await _imagePicker.pickMultiImage(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (picked.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No images selected')),
          );
          setState(() {
            _isUploading = false;
          });
        }
        return;
      }
      final user = AuthController.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You need to be signed in to upload.')),
          );
          setState(() {
            _isUploading = false;
          });
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploading ' + picked.length.toString() + ' image(s)...')),
        );
      }
      for (final x in picked) {
        final file = File(x.path);
        final upload = await FileUploadService.uploadAttachment(
          file: file,
          userId: user.id,
          conversationId: widget.conversation.id,
        );
        final msg = ChatMessage(
          id: '', // Let database generate UUID
          content: upload.publicUrl,
          isFromUser: true,
          timestamp: DateTime.now(),
          messageType: MessageType.image,
        );
        setState(() {
          _messages.add(msg);
        });
        await ChatService.saveMessage(msg, widget.conversation.id);
        _scrollToBottom();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload complete')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ' + e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _captureImageFromCamera() async {
    if (_isUploading) return;
    try {
      setState(() {
        _isUploading = true;
      });
      final XFile? shot = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (shot == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image captured')),
          );
          setState(() {
            _isUploading = false;
          });
        }
        return;
      }
      final user = AuthController.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You need to be signed in to upload.')),
          );
          setState(() {
            _isUploading = false;
          });
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading image...')),
        );
      }
      final file = File(shot.path);
      final upload = await FileUploadService.uploadAttachment(
        file: file,
        userId: user.id,
        conversationId: widget.conversation.id,
      );
      final msg = ChatMessage(
        id: '', // Let database generate UUID
        content: upload.publicUrl,
        isFromUser: true,
        timestamp: DateTime.now(),
        messageType: MessageType.image,
      );
      setState(() {
        _messages.add(msg);
      });
      await ChatService.saveMessage(msg, widget.conversation.id);
      _scrollToBottom();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload complete')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ' + e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _initializeAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 14),
      vsync: this,
    )..repeat(reverse: true);
    
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingAnimationController, curve: Curves.easeInOut),
    );
    _messageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _messageAnimationController, curve: Curves.easeOut),
    );
  }

  void _initializeChat() async {
    // Load existing messages from Supabase
    await _loadMessages();
    // Set up real-time subscription
    _setupRealtimeSubscription();
    // Mark initial loading as complete
    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }
  
  void _onScroll() {
    // Load more messages when scrolling near the top
    if (_scrollController.position.pixels < 200 && 
        _hasMoreMessages && 
        !_isLoadingMore) {
      _loadOlderMessages();
    }
  }
  
  void _setupRealtimeSubscription() {
    try {
      _messagesChannel = SupabaseService.instance.client
          .channel('chat_messages_${widget.conversation.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'chat_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: widget.conversation.id,
            ),
            callback: (payload) {
              // Only add message if it's not already in the list
              final newMessage = ChatMessage.fromJson(payload.newRecord);
              if (!_messages.any((msg) => msg.id == newMessage.id)) {
                setState(() {
                  // Insert message in correct position (sorted by timestamp)
                  int insertIndex = _messages.length;
                  for (int i = 0; i < _messages.length; i++) {
                    if (_messages[i].timestamp.isAfter(newMessage.timestamp)) {
                      insertIndex = i;
                      break;
                    }
                  }
                  _messages.insert(insertIndex, newMessage);
                  
                  // Update oldest message time for pagination if needed
                  if (_oldestMessageTime == null || 
                      newMessage.timestamp.isBefore(_oldestMessageTime!)) {
                    _oldestMessageTime = newMessage.timestamp;
                  }
                });
                
                // Only auto-scroll if it's a new message (not an old one being loaded)
                if (newMessage.timestamp.isAfter(DateTime.now().subtract(const Duration(seconds: 5)))) {
                  _scrollToBottom();
                }
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'chat_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: widget.conversation.id,
            ),
            callback: (payload) {
              // Update existing message
              final updatedMessage = ChatMessage.fromJson(payload.newRecord);
              setState(() {
                final index = _messages.indexWhere((msg) => msg.id == updatedMessage.id);
                if (index != -1) {
                  _messages[index] = updatedMessage;
                }
              });
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'chat_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: widget.conversation.id,
            ),
            callback: (payload) {
              // Remove deleted message
              setState(() {
                _messages.removeWhere((msg) => msg.id == payload.oldRecord['id']);
              });
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error setting up real-time subscription: $e');
    }
  }
  
  Future<void> _loadMessages({bool loadMore = false}) async {
    try {
      if (_isLoadingMore && loadMore) return;
      
      if (loadMore) {
        setState(() {
          _isLoadingMore = true;
        });
      }
      
      final messages = await ChatService.getMessages(
        widget.conversation.id,
        before: loadMore ? _oldestMessageTime : null,
        limit: 50,
      );
      
      if (messages.isEmpty && !loadMore && widget.conversation.conversationType == ConversationType.ai) {
        // If no messages in database for AI conversation, add welcome message
        final settings = await AiChatSettingsService.instance.getActiveSettings();
        final welcomeMessage = ChatMessage(
          id: '', // Let database generate UUID
          content: settings.welcomeMessage,
          isFromUser: false,
          timestamp: DateTime.now(),
        );
        
        setState(() {
          _messages.clear();
          _messages.add(welcomeMessage);
          _oldestMessageTime = welcomeMessage.timestamp;
        });
        
        // Save to database
        await ChatService.saveMessage(welcomeMessage, widget.conversation.id);
        return;
      }
      
      if (messages.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
          _isLoadingMore = false;
        });
        return;
      }
      
      if (loadMore) {
        // Insert older messages at the beginning
        setState(() {
          _messages.insertAll(0, messages);
          _oldestMessageTime = messages.first.timestamp;
          _hasMoreMessages = messages.length >= 50;
        });
      } else {
        // Initial load
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          if (messages.isNotEmpty) {
            _oldestMessageTime = messages.first.timestamp;
            _hasMoreMessages = messages.length >= 50;
          }
        });
      }
      
      setState(() {
        _isLoadingMore = false;
      });
      
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }
  
  Future<void> _loadOlderMessages() async {
    if (!_hasMoreMessages || _isLoadingMore) return;
    
    // Save current scroll position
    final currentScrollPosition = _scrollController.hasClients 
        ? _scrollController.position.pixels 
        : 0;
    final currentItemCount = _messages.length;
    
    await _loadMessages(loadMore: true);
    
    // Restore scroll position after loading
    if (_scrollController.hasClients && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final newItemCount = _messages.length;
          final itemHeight = 100.0; // Approximate height per message
          final newScrollPosition = currentScrollPosition + 
              ((newItemCount - currentItemCount) * itemHeight);
          _scrollController.jumpTo(newScrollPosition);
        }
      });
    }
  }

  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    _messageAnimationController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() {
      _relatedQuestions = const <String>[];
    });

    // Add user message
    final userMessage = ChatMessage(
      id: '', // Will be generated by database
      content: messageText,
      isFromUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    await ChatService.saveMessage(userMessage, widget.conversation.id);
    _scrollToBottom();
    _messageAnimationController.forward();

    // Add typing indicator
    final typingMessage = ChatMessage(
      id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      isFromUser: false,
      timestamp: DateTime.now(),
      isTyping: true,
    );

    setState(() {
      _messages.add(typingMessage);
    });

    _typingAnimationController.repeat(reverse: true);
    _scrollToBottom();

    try {
      _streamingContent = '';

      // Create streaming message (only shown after first token)
      final streamingMessage = ChatMessage(
        id: '', // Let database generate UUID
        content: '',
        isFromUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      bool hasStartedStreaming = false;

      // Build user context from assets (concise)
      String? userContext;
      try {
        final user = AuthController.instance.currentUser;
        if (user != null) {
          final assets = await WillService.instance.getUserAssets(user.id);
          final int count = assets.length;
          final double total = assets.fold<double>(0.0, (double acc, Map<String, dynamic> a) => acc + ((a['value'] as num?)?.toDouble() ?? 0.0));
          final List<String> names = assets.take(5).map<String>((Map<String, dynamic> a) => (a['new_service_platform_name'] as String?) ?? (a['name'] as String?) ?? 'Asset').toList();
          userContext = 'Assets count: ' + count.toString() + '; Total value (approx): RM ' + total.toStringAsFixed(2) + '; Recent assets: ' + names.join(', ') + '. Use this context to tailor advice and references.';
        }
      } catch (_) {
        userContext = null;
      }

      // Retrieve KB matches once (used for both AI context + related questions)
      final locale = Localizations.localeOf(context);
      final language = (locale.languageCode == 'ms' || locale.languageCode == 'bm') ? 'bm' : 'en';
      final kbMatches = await AiKbService.instance.searchKeyword(
        queryText: messageText,
        language: language,
        limit: 4,
      );
      final kbContext = AiKbService.instance.buildKbContext(kbMatches);

      // Stream the response with context + KB
      await for (final chunk in OpenRouterService.sendMessageStream(
        messageText,
        context: userContext,
        kbContextOverride: kbContext,
      )) {
        if (mounted) {
          setState(() {
            _streamingContent += chunk;
            if (!hasStartedStreaming) {
              hasStartedStreaming = true;
              _messages.removeWhere((msg) => msg.id == typingMessage.id);
              _messages.add(streamingMessage.copyWith(content: _streamingContent));
              _typingAnimationController.stop();
            } else {
              _messages[_messages.length - 1] = streamingMessage.copyWith(
                content: _streamingContent,
              );
            }
          });
          _scrollToBottom(animated: false, throttleForStreaming: true);
        }
      }

      // Finalize the message
      setState(() {
        if (!hasStartedStreaming) {
          _messages.removeWhere((msg) => msg.id == typingMessage.id);
          _messages.add(streamingMessage.copyWith(
            content: _streamingContent,
            isStreaming: false,
          ));
        } else {
          _messages[_messages.length - 1] = streamingMessage.copyWith(
            content: _streamingContent,
            isStreaming: false,
          );
        }
        _isLoading = false;
      });

      await ChatService.saveMessage(_messages[_messages.length - 1], widget.conversation.id);

      // Prepare related questions based on the same KB matches
      final related = await AiKbService.instance.getRelatedQuestionsForMatches(
        matches: kbMatches,
        limit: 6,
      );
      if (mounted) {
        setState(() {
          _relatedQuestions = related;
        });
      }
      
      // Haptic feedback when AI finishes replying
      HapticFeedback.mediumImpact();

    } catch (e, stackTrace) {
      // Log the actual error for debugging
      debugPrint('AI Chat Error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Remove typing indicator
      setState(() {
        _messages.removeWhere((msg) => msg.id == typingMessage.id);
      });

      // Add error message with more details
      final l10n = AppLocalizations.of(context)!;
      String errorContent = l10n.chatErrorConnection;
      
      // Provide more specific error messages for common issues
      final errorString = e.toString();
      if (errorString.contains('OPENROUTER_API_KEY') || errorString.contains('OPENROUTER_MODEL')) {
        errorContent = l10n.chatErrorNotConfigured;
      } else if (errorString.contains('HTTP 401') || errorString.contains('HTTP 403')) {
        errorContent = l10n.chatErrorAuthFailed;
      } else if (errorString.contains('HTTP 429')) {
        errorContent = l10n.chatErrorRateLimit;
      } else if (errorString.contains('HTTP 500') || errorString.contains('HTTP 502') || errorString.contains('HTTP 503')) {
        errorContent = l10n.chatErrorServiceUnavailable;
      }
      
      final errorMessage = ChatMessage(
        id: '', // Let database generate UUID
        content: errorContent,
        isFromUser: false,
        timestamp: DateTime.now(),
        hasError: true,
        errorMessage: e.toString(),
      );

      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });

      await ChatService.saveMessage(errorMessage, widget.conversation.id);
    }

    _scrollToBottom();
  }

  void _scrollToBottom({bool animated = true, bool throttleForStreaming = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (throttleForStreaming) {
          final now = DateTime.now();
          final last = _lastStreamAutoScrollAt;
          if (last != null && now.difference(last).inMilliseconds < 80) {
            return;
          }
          _lastStreamAutoScrollAt = now;
        }

        final maxExtent = _scrollController.position.maxScrollExtent;
        if (animated) {
          _scrollController.animateTo(
            maxExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(maxExtent);
        }
      }
    });
  }

  void _copyMessage(ChatMessage message) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
  }


  void _deleteMessage(ChatMessage message) {
    setState(() {
      _messages.removeWhere((msg) => msg.id == message.id);
    });
    ChatService.deleteMessage(message.id);
  }

  Future<void> _regenerateResponse(ChatMessage message) async {
    // Find the user message that prompted this response
    final messageIndex = _messages.indexWhere((msg) => msg.id == message.id);
    if (messageIndex == -1 || messageIndex == 0) return;
    
    // Find the previous user message
    ChatMessage? userMessage;
    for (int i = messageIndex - 1; i >= 0; i--) {
      if (_messages[i].isFromUser) {
        userMessage = _messages[i];
        break;
      }
    }
    
    if (userMessage == null) return;
    
    // Mark message as regenerating
    setState(() {
      _messages[messageIndex] = message.copyWith(isRegenerating: true);
    });
    
    try {
      // Remove the old response
      setState(() {
        _messages.removeAt(messageIndex);
      });
      
      // Add typing indicator
      final typingMessage = ChatMessage(
        id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
        content: '',
        isFromUser: false,
        timestamp: DateTime.now(),
        isTyping: true,
      );
      
      setState(() {
        _messages.add(typingMessage);
      });
      
      _typingAnimationController.repeat(reverse: true);
      _scrollToBottom();

      _streamingContent = '';

      // Create streaming message (only shown after first token)
      final streamingMessage = ChatMessage(
        id: '', // Let database generate UUID
        content: '',
        isFromUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      bool hasStartedStreaming = false;
      
      // Build user context from assets
      String? userContext;
      try {
        final user = AuthController.instance.currentUser;
        if (user != null) {
          final assets = await WillService.instance.getUserAssets(user.id);
          final int count = assets.length;
          final double total = assets.fold<double>(0.0, (double acc, Map<String, dynamic> a) => acc + ((a['value'] as num?)?.toDouble() ?? 0.0));
          final List<String> names = assets.take(5).map<String>((Map<String, dynamic> a) => (a['new_service_platform_name'] as String?) ?? (a['name'] as String?) ?? 'Asset').toList();
          userContext = 'Assets count: ' + count.toString() + '; Total value (approx): RM ' + total.toStringAsFixed(2) + '; Recent assets: ' + names.join(', ') + '. Use this context to tailor advice and references.';
        }
      } catch (_) {
        userContext = null;
      }
      
      // Retrieve KB matches once (used for both AI context + related questions)
      final locale = Localizations.localeOf(context);
      final language = (locale.languageCode == 'ms' || locale.languageCode == 'bm') ? 'bm' : 'en';
      final kbMatches = await AiKbService.instance.searchKeyword(
        queryText: userMessage.content,
        language: language,
        limit: 4,
      );
      final kbContext = AiKbService.instance.buildKbContext(kbMatches);

      // Stream the new response
      await for (final chunk in OpenRouterService.sendMessageStream(
        userMessage.content,
        context: userContext,
        kbContextOverride: kbContext,
      )) {
        if (mounted) {
          setState(() {
            _streamingContent += chunk;
            if (!hasStartedStreaming) {
              hasStartedStreaming = true;
              _messages.removeWhere((msg) => msg.id == typingMessage.id);
              _messages.add(streamingMessage.copyWith(content: _streamingContent));
              _typingAnimationController.stop();
            } else {
              _messages[_messages.length - 1] = streamingMessage.copyWith(
                content: _streamingContent,
              );
            }
          });
          _scrollToBottom(animated: false, throttleForStreaming: true);
        }
      }
      
      // Finalize the message
      setState(() {
        if (!hasStartedStreaming) {
          _messages.removeWhere((msg) => msg.id == typingMessage.id);
          _messages.add(streamingMessage.copyWith(
            content: _streamingContent,
            isStreaming: false,
          ));
        } else {
          _messages[_messages.length - 1] = streamingMessage.copyWith(
            content: _streamingContent,
            isStreaming: false,
          );
        }
      });
      
      await ChatService.saveMessage(_messages[_messages.length - 1], widget.conversation.id);

      // Prepare related questions based on the same KB matches
      final related = await AiKbService.instance.getRelatedQuestionsForMatches(
        matches: kbMatches,
        limit: 6,
      );
      if (mounted) {
        setState(() {
          _relatedQuestions = related;
        });
      }
      
      // Haptic feedback when AI finishes regenerating
      HapticFeedback.mediumImpact();
      
    } catch (e, stackTrace) {
      debugPrint('Regenerate error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Restore original message if regeneration fails
      setState(() {
        if (messageIndex < _messages.length) {
          _messages.insert(messageIndex, message.copyWith(isRegenerating: false));
        } else {
          _messages.add(message.copyWith(isRegenerating: false));
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to regenerate response. Please try again.')),
      );
    }
    
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _backgroundAnimationController,
        builder: (context, child) {
          final double p = _backgroundAnimationController.value;
          final double t = p * 2 * math.pi;
          // Second frequency so blobs don’t feel synced / repetitive (clearer “living” motion).
          final double tAlt = p * 2 * math.pi * 1.37 + 0.9;
          final double driftX =
              0.34 * math.sin(t * 0.88) + 0.14 * math.sin(tAlt * 1.05);
          final double driftY =
              0.30 * math.cos(t * 0.74) + 0.11 * math.cos(tAlt * 0.92);
          final double midStop = 0.46 + 0.12 * math.sin(t * 0.48);
          final double topTint = 0.10 + 0.08 * math.sin(tAlt * 0.61);
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      -0.52 + driftX * 0.62,
                      -1.12 + driftY * 0.22,
                    ),
                    end: Alignment(
                      0.58 - driftX * 0.52,
                      1.22 - driftY * 0.18,
                    ),
                    colors: [
                      Color.lerp(_chatGradientTop, _meshBloomLavender, topTint)!,
                      Color.lerp(_chatGradientTop, _chatGradientBottom, 0.5 + 0.06 * math.sin(t * 0.35))!,
                      Color.lerp(_chatGradientBottom, _chatGradientDeep,
                          0.24 + 0.12 * math.sin(tAlt * 0.42))!,
                    ],
                    stops: [0.0, midStop.clamp(0.34, 0.62), 1.0],
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        -0.52 + 0.44 * math.sin(t * 0.92),
                        -0.76 + 0.34 * math.cos(t * 0.68 + 0.3 * math.sin(tAlt)),
                      ),
                      radius: 0.92 + 0.14 * math.sin(t * 0.4),
                      colors: [
                        _meshBloomLavender.withOpacity(0.38 + 0.22 * math.sin(t * 0.55).abs()),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.58],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        0.66 + 0.38 * math.cos(t * 1.05 + 1.0),
                        0.45 + 0.36 * math.sin(t * 1.1 + 0.45 * math.cos(tAlt)),
                      ),
                      radius: 1.05 + 0.2 * math.sin(tAlt * 0.5),
                      colors: [
                        _meshBloomViolet.withOpacity(0.28 + 0.18 * math.sin(t * 0.62).abs()),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.62],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        0.18 * math.sin(t * 0.58) + 0.1 * math.sin(tAlt * 1.2),
                        0.86 + 0.16 * math.cos(t * 0.76),
                      ),
                      radius: 0.88 + 0.18 * math.cos(tAlt * 0.44),
                      colors: [
                        _meshBloomMist.withOpacity(0.22 + 0.16 * math.sin(t * 0.71).abs()),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.68],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(
                        0.22 + driftY * 0.72,
                        -0.94 + 0.1 * math.sin(tAlt),
                      ),
                      end: Alignment(
                        -0.2 - driftX * 0.58,
                        1.02 - 0.08 * math.cos(t * 0.5),
                      ),
                      colors: [
                        Colors.white.withOpacity(0.06 + 0.06 * math.sin(t * 0.9).abs()),
                        Colors.transparent,
                        _chatGradientDeep.withOpacity(0.07 + 0.08 * math.sin(tAlt * 0.7).abs()),
                      ],
                      stops: [
                        0.0,
                        0.38 + 0.14 * math.sin(t * 0.67),
                        1.0,
                      ],
                    ),
                  ),
                ),
              ),
              if (child != null) child,
            ],
          );
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _isInitialLoading
                            ? _buildInitialLoadingState()
                            : ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.fromLTRB(
                                  18,
                                  (_hasMoreMessages && _isLoadingMore) ? 100 : 76,
                                  18,
                                  16,
                                ),
                                itemCount: _messages.length + (_hasMoreMessages ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == 0 && _hasMoreMessages) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Center(
                                        child: _isLoadingMore
                                            ? SizedBox(
                                                height: 28,
                                                width: 28,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.4,
                                                  color: _chatTextLight.withOpacity(0.8),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    );
                                  }

                                  final messageIndex = _hasMoreMessages ? index - 1 : index;
                                  final message = _messages[messageIndex];
                                  return _buildMessageBubble(message, _messageAnimation);
                                },
                              ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: IgnorePointer(
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _chatGradientTop.withOpacity(0.98),
                                  _chatGradientTop.withOpacity(0.8),
                                  _chatGradientTop.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        top: 4,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'Sampul AI',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  color: _chatTextLight.withOpacity(0.96),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close, color: _chatTextLight.withOpacity(0.9)),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: _chatTextLight.withOpacity(0.9)),
                              onSelected: (value) {
                                if (value == 'clear') {
                                  _clearConversation();
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'clear',
                                  child: Row(
                                    children: [
                                      Icon(Icons.clear_all),
                                      SizedBox(width: 8),
                                      Text('Clear Conversation'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(top: false, bottom: false, child: _buildQuickSuggestions()),
                SafeArea(top: false, bottom: false, child: _buildRelatedQuestions()),
                SafeArea(top: false, child: _buildMessageInput()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, Animation<double> animation) {
    final double chatContentWidth = MediaQuery.sizeOf(context).width - 36;
    final Widget bubble = GestureDetector(
      onLongPress: () => _showMessageContextMenu(message),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: message.isFromUser ? chatContentWidth : chatContentWidth * 0.75,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: message.isFromUser ? 2 : 14,
          vertical: message.isFromUser ? 0 : 12,
        ),
        decoration: BoxDecoration(
          color: message.isFromUser
              ? Colors.transparent
              : Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(12),
          boxShadow: !message.isFromUser
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment:
              message.isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
                    if (message.isTyping)
                      _buildTypingIndicator()
                    else if (message.isRegenerating)
                      Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _chatTextLight.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: _buildMessageContent(message)),
                        ],
                      )
                    else if (message.hasError)
                      _buildErrorMessage(message)
                    else
                      _buildMessageContent(message),
                    if (!message.isFromUser &&
                        !message.isTyping &&
                        !message.hasError &&
                        !message.isRegenerating)
                      _buildActionButtons(message),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: message.isFromUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: _chatTextMuted.withOpacity(0.88),
                            fontSize: 12,
                          ),
                        ),
                        if (!message.isFromUser && !message.isTyping && !message.isRegenerating)
                          _buildMessageActions(message),
                      ],
                    ),
                  ],
                ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: message.isFromUser
          ? Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: chatContentWidth,
                child: bubble,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(child: bubble),
              ],
            ),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    // Images
    if (message.messageType == MessageType.image) {
      final Widget image = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          message.content,
          width: 220,
          fit: BoxFit.cover,
          errorBuilder: (context, _, __) => Icon(
            Icons.broken_image,
            color: _chatTextLight.withOpacity(0.85),
          ),
        ),
      );
      if (message.isFromUser) {
        return Align(
          alignment: Alignment.centerRight,
          child: image,
        );
      }
      return image;
    }
    // Files
    if (message.messageType == MessageType.file) {
      final Widget fileRow = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file,
            color: _chatTextLight.withOpacity(0.92),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Open file',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                decoration: TextDecoration.underline,
                color: Colors.white.withOpacity(0.92),
              ),
            ),
          ),
        ],
      );
      return InkWell(
        onTap: () async {
          final uri = Uri.tryParse(message.content);
          if (uri != null) {
            await launchUriPreferInAppBrowser(uri);
          }
        },
        child: message.isFromUser
            ? Align(
                alignment: Alignment.centerRight,
                child: fileRow,
              )
            : fileRow,
      );
    }
    // Text (user vs AI markdown)
    if (message.isFromUser) {
      return Text(
        message.content,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: Colors.white.withOpacity(0.96),
          fontSize: 16.5,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    // Remove action markers from display (they're only for button generation)
    String displayContent = message.content;
    displayContent = displayContent.replaceAll(
      RegExp(r'\[ACTION:[^\]]+\]', caseSensitive: false),
      '',
    ).trim();

    return MarkdownBody(
      data: displayContent,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: _chatTextLight.withOpacity(0.95),
          fontSize: 16.5,
          height: 1.42,
          fontWeight: FontWeight.w500,
        ),
        strong: TextStyle(
          color: _chatTextLight,
          fontWeight: FontWeight.bold,
        ),
        code: TextStyle(
          backgroundColor: Colors.white.withOpacity(0.14),
          color: _chatTextLight,
        ),
        a: TextStyle(
          color: _chatTextLight.withOpacity(0.95),
          decoration: TextDecoration.underline,
        ),
      ),
      onTapLink: (text, href, title) {
        if (href == null) return;
        final Uri? uri = Uri.tryParse(href);
        if (uri != null) {
          launchUriPreferInAppBrowser(uri);
        }
      },
    );
  }

  Widget _buildActionButtons(ChatMessage message) {
    final actions = AiActionDetector.detectActions(message.content);
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions.map((action) {
          return _buildActionButton(action);
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton(AiAction action) {
    final Color iconColor = _chatTextLight.withOpacity(0.95);
    return OutlinedButton.icon(
      onPressed: () => _handleAction(action),
      icon: SampulIcons.buildIcon(
        _getActionIcon(action.actionType, action.parameters?['route']),
        width: 16,
        height: 16,
        color: iconColor,
      ),
      label: Text(action.label),
      style: _themedChatActionButtonStyle(),
    );
  }

  String _getActionIcon(String actionType, String? route) {
    switch (route) {
      case 'trust_create':
      case 'trust_management':
        return SampulIcons.trust;
      case 'hibah_management':
        return SampulIcons.property;
      case 'will_management':
        return SampulIcons.wasiat;
      case 'add_asset':
      case 'assets_list':
        return SampulIcons.assets;
      case 'add_family':
      case 'family_list':
        return SampulIcons.family;
      case 'executor_management':
        return SampulIcons.person;
      case 'checklist':
        return SampulIcons.checklist;
      case 'extra_wishes':
        return SampulIcons.favorite;
      default:
        return SampulIcons.arrowRight;
    }
  }

  Future<void> _handleAction(AiAction action) async {
    if (action.actionType == 'navigate') {
      final route = action.parameters?['route'] as String?;
      if (route == null) return;

      switch (route) {
        case 'trust_create':
          // Check if user has seen the about page before
          final SharedPreferences prefs3 = await SharedPreferences.getInstance();
          final bool hasSeenTrustAbout = prefs3.getBool('trust_about_seen') ?? false;
          
          Navigator.of(context).push(
            MaterialPageRoute<bool>(
              builder: (_) => hasSeenTrustAbout 
                  ? const TrustCreateScreen() 
                  : const TrustInfoScreen(),
            ),
          );
          break;
        case 'trust_management':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TrustManagementScreen(),
            ),
          );
          break;
        case 'hibah_management':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const HibahManagementScreen(),
            ),
          );
          break;
        case 'will_management':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const WillManagementScreen(),
            ),
          );
          break;
        case 'add_asset':
          // Check if user has seen the about page before
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final bool hasSeenAbout = prefs.getBool('assets_about_seen') ?? false;
          
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => hasSeenAbout 
                  ? const AddAssetScreen() 
                  : const AssetInfoScreen(),
            ),
          );
          break;
        case 'assets_list':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AssetsListScreen(),
            ),
          );
          break;
        case 'add_family':
          // Check if user has seen the about page before
          final SharedPreferences prefs2 = await SharedPreferences.getInstance();
          final bool hasSeenFamilyAbout = prefs2.getBool('family_about_seen') ?? false;
          
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => hasSeenFamilyAbout 
                  ? const AddFamilyMemberScreen() 
                  : const FamilyInfoScreen(),
            ),
          );
          break;
        case 'family_list':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const FamilyListScreen(),
            ),
          );
          break;
        case 'executor_management':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ExecutorManagementScreen(),
            ),
          );
          break;
        case 'checklist':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ChecklistScreen(),
            ),
          );
          break;
        case 'extra_wishes':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ExtraWishesScreen(),
            ),
          );
          break;
      }
    }
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypingDot(0),
            const SizedBox(width: 4),
            _buildTypingDot(1),
            const SizedBox(width: 4),
            _buildTypingDot(2),
          ],
        );
      },
    );
  }

  Widget _buildTypingDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(
          0.3 + (0.7 * ((_typingAnimation.value + index * 0.2) % 1.0)),
        ),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildErrorMessage(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.content,
          style: TextStyle(
            color: _chatTextLight.withOpacity(0.95),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _retryFailedMessage(message),
          icon: Icon(
            Icons.refresh,
            size: 16,
            color: _chatTextLight.withOpacity(0.96),
          ),
          label: const Text('Retry'),
          style: _themedChatActionButtonStyle(),
        ),
      ],
    );
  }

  Future<void> _retryFailedMessage(ChatMessage message) async {
    // Find the user message that caused this error
    final errorIndex = _messages.indexWhere((msg) => msg.id == message.id);
    if (errorIndex == -1 || errorIndex == 0) return;
    
    // Find the previous user message
    ChatMessage? userMessage;
    for (int i = errorIndex - 1; i >= 0; i--) {
      if (_messages[i].isFromUser) {
        userMessage = _messages[i];
        break;
      }
    }
    
    if (userMessage == null) return;
    
    // Remove the error message
    setState(() {
      _messages.removeAt(errorIndex);
      _isLoading = true;
    });
    
    // Retry sending the message
    await _sendMessageWithText(userMessage.content);
  }

  Future<void> _sendMessageWithText(String messageText) async {
    if (messageText.isEmpty || _isLoading) return;

    // Add typing indicator
    final typingMessage = ChatMessage(
      id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      isFromUser: false,
      timestamp: DateTime.now(),
      isTyping: true,
    );

    setState(() {
      _messages.add(typingMessage);
    });

    _typingAnimationController.repeat(reverse: true);
    _scrollToBottom();

    try {
      _streamingContent = '';

      // Create streaming message (only shown after first token)
      final streamingMessage = ChatMessage(
        id: '', // Let database generate UUID
        content: '',
        isFromUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      bool hasStartedStreaming = false;

      // Build user context from assets (concise)
      String? userContext;
      try {
        final user = AuthController.instance.currentUser;
        if (user != null) {
          final assets = await WillService.instance.getUserAssets(user.id);
          final int count = assets.length;
          final double total = assets.fold<double>(0.0, (double acc, Map<String, dynamic> a) => acc + ((a['value'] as num?)?.toDouble() ?? 0.0));
          final List<String> names = assets.take(5).map<String>((Map<String, dynamic> a) => (a['new_service_platform_name'] as String?) ?? (a['name'] as String?) ?? 'Asset').toList();
          userContext = 'Assets count: ' + count.toString() + '; Total value (approx): RM ' + total.toStringAsFixed(2) + '; Recent assets: ' + names.join(', ') + '. Use this context to tailor advice and references.';
        }
      } catch (_) {
        userContext = null;
      }

      // Retrieve KB matches once (used for both AI context + related questions)
      final locale = Localizations.localeOf(context);
      final language = (locale.languageCode == 'ms' || locale.languageCode == 'bm') ? 'bm' : 'en';
      final kbMatches = await AiKbService.instance.searchKeyword(
        queryText: messageText,
        language: language,
        limit: 4,
      );
      final kbContext = AiKbService.instance.buildKbContext(kbMatches);

      // Stream the response with context + KB
      await for (final chunk in OpenRouterService.sendMessageStream(
        messageText,
        context: userContext,
        kbContextOverride: kbContext,
      )) {
        if (mounted) {
          setState(() {
            _streamingContent += chunk;
            if (!hasStartedStreaming) {
              hasStartedStreaming = true;
              _messages.removeWhere((msg) => msg.id == typingMessage.id);
              _messages.add(streamingMessage.copyWith(content: _streamingContent));
              _typingAnimationController.stop();
            } else {
              _messages[_messages.length - 1] = streamingMessage.copyWith(
                content: _streamingContent,
              );
            }
          });
          _scrollToBottom(animated: false, throttleForStreaming: true);
        }
      }

      // Finalize the message
      setState(() {
        if (!hasStartedStreaming) {
          _messages.removeWhere((msg) => msg.id == typingMessage.id);
          _messages.add(streamingMessage.copyWith(
            content: _streamingContent,
            isStreaming: false,
          ));
        } else {
          _messages[_messages.length - 1] = streamingMessage.copyWith(
            content: _streamingContent,
            isStreaming: false,
          );
        }
        _isLoading = false;
      });

      await ChatService.saveMessage(_messages[_messages.length - 1], widget.conversation.id);

      // Prepare related questions based on the same KB matches
      final related = await AiKbService.instance.getRelatedQuestionsForMatches(
        matches: kbMatches,
        limit: 6,
      );
      if (mounted) {
        setState(() {
          _relatedQuestions = related;
        });
      }
      
      // Haptic feedback when AI finishes replying (retry)
      HapticFeedback.mediumImpact();

    } catch (e, stackTrace) {
      debugPrint('Retry error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Remove typing indicator
      setState(() {
        _messages.removeWhere((msg) => msg.id == typingMessage.id);
      });

      // Add error message with more details
      final l10n = AppLocalizations.of(context)!;
      String errorContent = l10n.chatErrorConnection;
      
      final errorString = e.toString();
      if (errorString.contains('OPENROUTER_API_KEY') || errorString.contains('OPENROUTER_MODEL')) {
        errorContent = l10n.chatErrorNotConfigured;
      } else if (errorString.contains('HTTP 401') || errorString.contains('HTTP 403')) {
        errorContent = l10n.chatErrorAuthFailed;
      } else if (errorString.contains('HTTP 429')) {
        errorContent = l10n.chatErrorRateLimit;
      } else if (errorString.contains('HTTP 500') || errorString.contains('HTTP 502') || errorString.contains('HTTP 503')) {
        errorContent = l10n.chatErrorServiceUnavailable;
      }
      
      final errorMessage = ChatMessage(
        id: '', // Let database generate UUID
        content: errorContent,
        isFromUser: false,
        timestamp: DateTime.now(),
        hasError: true,
        errorMessage: e.toString(),
      );

      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });

      await ChatService.saveMessage(errorMessage, widget.conversation.id);
    }

    _scrollToBottom();
  }

  Widget _buildMessageActions(ChatMessage message) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.copy, size: 16, color: _chatTextMuted.withOpacity(0.9)),
          onPressed: () => _copyMessage(message),
          tooltip: 'Copy',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        if (!message.isFromUser && !message.hasError)
          IconButton(
            icon: Icon(Icons.refresh, size: 16, color: _chatTextMuted.withOpacity(0.9)),
            onPressed: () => _regenerateResponse(message),
            tooltip: 'Regenerate response',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.bottomCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            );
          },
          child: (!_isComposerExpanded && _messageController.text.trim().isEmpty)
              ? _buildCollapsedComposer()
              : _buildExpandedComposer(),
        ),
      ),
    );
  }

  Widget _buildCollapsedComposer() {
    return Material(
      key: const ValueKey<String>('collapsed-composer'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: (_isLoading || _isInitialLoading)
            ? null
            : () {
                setState(() {
                  _isComposerExpanded = true;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    FocusScope.of(context).requestFocus(_messageFocusNode);
                  }
                });
              },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF6C5CFF).withOpacity(0.9),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8D79FF).withOpacity(0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: _chatTextLight.withOpacity(0.98),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Tap anywhere to type',
                  style: TextStyle(
                    color: _chatTextLight.withOpacity(0.92),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedComposer() {
    return Container(
      key: const ValueKey<String>('expanded-composer'),
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  enabled: !_isLoading && !_isInitialLoading,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(
                    color: _chatTextLight.withOpacity(0.96),
                    fontSize: 16,
                    height: 1.35,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.chatComposerPlaceholder,
                    hintStyle: TextStyle(
                      color: _chatTextLight.withOpacity(0.62),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(
                      left: 4,
                      right: 8,
                      top: 8,
                      bottom: 10,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: IconButton(
                  onPressed: (_isLoading || _isInitialLoading)
                      ? null
                      : () async {
                          await _sendMessage();
                          if (mounted && _messageController.text.trim().isEmpty) {
                            setState(() {
                              _isComposerExpanded = false;
                            });
                          }
                        },
                  style: IconButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    padding: const EdgeInsets.all(0),
                    backgroundColor: Colors.white.withOpacity(0.12),
                    disabledBackgroundColor: Colors.white.withOpacity(0.07),
                    side: BorderSide(color: Colors.white.withOpacity(0.24)),
                  ),
                  icon: Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: _chatTextLight.withOpacity(0.98),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 12,
                color: _chatTextLight.withOpacity(0.62),
              ),
              const SizedBox(width: 4),
              Text(
                'Sampul AI can make mistakes. Check important info.',
                style: TextStyle(
                  fontSize: 10,
                  color: _chatTextLight.withOpacity(0.62),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(_chatTextLight.withOpacity(0.95)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading conversation...',
            style: TextStyle(
              fontSize: 14,
              color: _chatTextMuted.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// Frosted pill chips that match the gradient chat theme (no solid white Material box).
  Widget _buildThemedSuggestionChip(String label, VoidCallback? onPressed) {
    return ActionChip(
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 170),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _chatTextLight.withOpacity(0.95),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
      ),
      onPressed: onPressed,
      backgroundColor: _chatGradientDeep.withOpacity(0.55),
      disabledColor: _chatGradientDeep.withOpacity(0.3),
      side: BorderSide(color: Colors.white.withOpacity(0.2)),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      pressElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    );
  }

  /// Frosted outline pills for AI action CTAs (view assets, open trust, etc.) — matches suggestion chips.
  ButtonStyle _themedChatActionButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _chatTextLight.withOpacity(0.96),
      backgroundColor: Colors.white.withOpacity(0.14),
      disabledForegroundColor: _chatTextLight.withOpacity(0.45),
      disabledBackgroundColor: Colors.white.withOpacity(0.07),
      side: BorderSide(color: Colors.white.withOpacity(0.26)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      minimumSize: const Size(0, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        height: 1.2,
      ),
    );
  }

  Widget _buildRelatedQuestionButton(String label, VoidCallback? onPressed) {
    return OutlinedButton(
      onPressed: () => _showRelatedQuestionPreview(label),
      style: _themedChatActionButtonStyle(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 170),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showRelatedQuestionPreview(String label) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'Related question preview',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, _) {
        final CurvedAnimation curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _chatGradientDeep.withOpacity(0.88),
                          _chatGradientTop.withOpacity(0.58),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _chatTextLight.withOpacity(0.98),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                _messageController.text = label;
                                await _sendMessage();
                              },
                              icon: Icon(
                                Icons.send_rounded,
                                size: 20,
                                color: _chatTextLight.withOpacity(0.98),
                              ),
                              tooltip: 'Send',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.12),
                                side: BorderSide(color: Colors.white.withOpacity(0.24)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                setState(() {
                                  _isComposerExpanded = true;
                                  _messageController.text = label;
                                  _messageController.selection = TextSelection.fromPosition(
                                    TextPosition(offset: _messageController.text.length),
                                  );
                                });
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    FocusScope.of(this.context).requestFocus(_messageFocusNode);
                                  }
                                });
                              },
                              icon: Icon(
                                Icons.edit_rounded,
                                size: 19,
                                color: _chatTextLight.withOpacity(0.98),
                              ),
                              tooltip: 'Edit',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.12),
                                side: BorderSide(color: Colors.white.withOpacity(0.24)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickSuggestions() {
    // Only show suggestions if there are no user messages yet
    final hasUserMessages = _messages.any((msg) => msg.isFromUser);
    if (hasUserMessages || _isLoading || _isInitialLoading) {
      return const SizedBox.shrink();
    }

    final List<String> fallbackSuggestions = <String>[
      'How do I start my will?',
      'What is Hibah Hartanah?',
      'How does Sampul Executor work?',
      'What should I do first for estate planning?',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      alignment: Alignment.centerLeft,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _chatGradientDeep.withOpacity(0.36),
            _chatGradientTop.withOpacity(0.16),
          ],
        ),
      ),
      child: FutureBuilder<List<String>>(
        future: _suggestedQuestionsFuture,
        builder: (context, snapshot) {
          final suggestions = (snapshot.data != null && snapshot.data!.isNotEmpty)
              ? snapshot.data!
              : fallbackSuggestions;

          return Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 2),
                    ...suggestions
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(right: 8, bottom: 2),
                              child: _buildThemedSuggestionChip(
                                s,
                                _isLoading
                                    ? null
                                    : () {
                                        _messageController.text = s;
                                        _sendMessage();
                                      },
                              ),
                            ))
                        .toList(),
                    const SizedBox(width: 2),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRelatedQuestions() {
    final hasUserMessages = _messages.any((msg) => msg.isFromUser);
    if (!hasUserMessages || _isLoading || _isInitialLoading || _relatedQuestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _chatGradientDeep.withOpacity(0.34),
            _chatGradientTop.withOpacity(0.14),
          ],
        ),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 0, 8),
          child: Text(
            'Related questions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _chatTextMuted.withOpacity(0.9),
            ),
          ),
        ),
        Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.hardEdge,
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  ..._relatedQuestions.map((q) => Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 2),
                        child: _buildRelatedQuestionButton(
                          q,
                          null,
                        ),
                      )),
                  const SizedBox(width: 2),
                ],
              ),
            ),
          ],
        ),
      ],
    ));
  }

  void _showMessageContextMenu(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                _copyMessage(message);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                _deleteMessage(message);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text('Are you sure you want to clear this conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              ChatService.clearConversation(widget.conversation.id);
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

}
