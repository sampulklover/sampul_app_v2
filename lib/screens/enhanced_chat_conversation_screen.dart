import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../services/openrouter_service.dart';
import '../services/chat_service.dart';
import '../controllers/auth_controller.dart';
import '../services/will_service.dart';
import '../models/user_profile.dart';
import '../services/file_upload_service.dart';
import '../services/ai_chat_settings_service.dart';
import '../services/ai_action_detector.dart';
import '../services/supabase_service.dart';
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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _streamingContent = '';
  UserProfile? _userProfile;
  bool _isUploading = false;
  final ImagePicker _imagePicker = ImagePicker();
  
  late AnimationController _typingAnimationController;
  late AnimationController _messageAnimationController;
  late Animation<double> _typingAnimation;
  late Animation<double> _messageAnimation;
  
  RealtimeChannel? _messagesChannel;
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;
  DateTime? _oldestMessageTime;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeChat();
    _loadUserProfile();
  }

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
    
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingAnimationController, curve: Curves.easeInOut),
    );
    _messageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _messageAnimationController, curve: Curves.easeOut),
    );
  }

  void _initializeChat() async {
    // Set up scroll listener for pagination
    _scrollController.addListener(_onScroll);
    // Load existing messages from Supabase first
    await _loadMessages();
    // Set up real-time subscription
    _setupRealtimeSubscription();
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
  
  Future<void> _loadUserProfile() async {
    try {
      final profile = await AuthController.instance.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (_) {}
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
    _scrollController.dispose();
    _typingAnimationController.dispose();
    _messageAnimationController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isLoading) return;

    _messageController.clear();

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
      // Add delay for human-like response
      await Future.delayed(const Duration(milliseconds: 500));

      // Remove typing indicator
      setState(() {
        _messages.removeWhere((msg) => msg.id == typingMessage.id);
        _streamingContent = '';
      });

      // Create streaming message
      final streamingMessage = ChatMessage(
        id: '', // Let database generate UUID
        content: '',
        isFromUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      );

      setState(() {
        _messages.add(streamingMessage);
      });

      // Build user context from assets (concise)
      String? context;
      try {
        final user = AuthController.instance.currentUser;
        if (user != null) {
          final assets = await WillService.instance.getUserAssets(user.id);
          final int count = assets.length;
          final double total = assets.fold<double>(0.0, (double acc, Map<String, dynamic> a) => acc + ((a['value'] as num?)?.toDouble() ?? 0.0));
          final List<String> names = assets.take(5).map<String>((Map<String, dynamic> a) => (a['new_service_platform_name'] as String?) ?? (a['name'] as String?) ?? 'Asset').toList();
          context = 'Assets count: ' + count.toString() + '; Total value (approx): RM ' + total.toStringAsFixed(2) + '; Recent assets: ' + names.join(', ') + '. Use this context to tailor advice and references.';
        }
      } catch (_) {
        context = null;
      }

      // Stream the response with context
      await for (final chunk in OpenRouterService.sendMessageStream(messageText, context: context)) {
        if (mounted) {
          setState(() {
            _streamingContent += chunk;
            _messages[_messages.length - 1] = streamingMessage.copyWith(
              content: _streamingContent,
            );
          });
          _scrollToBottom();
        }
      }

      // Finalize the message
      setState(() {
        _messages[_messages.length - 1] = streamingMessage.copyWith(
          content: _streamingContent,
          isStreaming: false,
        );
        _isLoading = false;
      });

      await ChatService.saveMessage(_messages[_messages.length - 1], widget.conversation.id);
      
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
      String errorContent = "Sorry, I'm having trouble connecting right now. Please try again later.";
      
      // Provide more specific error messages for common issues
      final errorString = e.toString();
      if (errorString.contains('OPENROUTER_API_KEY') || errorString.contains('OPENROUTER_MODEL')) {
        errorContent = "AI chat is not configured. Please check your environment variables.";
      } else if (errorString.contains('HTTP 401') || errorString.contains('HTTP 403')) {
        errorContent = "Authentication failed. Please check your API key configuration.";
      } else if (errorString.contains('HTTP 429')) {
        errorContent = "Rate limit exceeded. Please try again in a moment.";
      } else if (errorString.contains('HTTP 500') || errorString.contains('HTTP 502') || errorString.contains('HTTP 503')) {
        errorContent = "The AI service is temporarily unavailable. Please try again later.";
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

    _typingAnimationController.stop();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
      
      // Add delay for human-like response
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Remove typing indicator
      setState(() {
        _messages.removeWhere((msg) => msg.id == typingMessage.id);
        _streamingContent = '';
      });
      
      // Create streaming message
      final streamingMessage = ChatMessage(
        id: '', // Let database generate UUID
        content: '',
        isFromUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      
      setState(() {
        _messages.add(streamingMessage);
      });
      
      // Build user context from assets
      String? context;
      try {
        final user = AuthController.instance.currentUser;
        if (user != null) {
          final assets = await WillService.instance.getUserAssets(user.id);
          final int count = assets.length;
          final double total = assets.fold<double>(0.0, (double acc, Map<String, dynamic> a) => acc + ((a['value'] as num?)?.toDouble() ?? 0.0));
          final List<String> names = assets.take(5).map<String>((Map<String, dynamic> a) => (a['new_service_platform_name'] as String?) ?? (a['name'] as String?) ?? 'Asset').toList();
          context = 'Assets count: ' + count.toString() + '; Total value (approx): RM ' + total.toStringAsFixed(2) + '; Recent assets: ' + names.join(', ') + '. Use this context to tailor advice and references.';
        }
      } catch (_) {
        context = null;
      }
      
      // Stream the new response
      await for (final chunk in OpenRouterService.sendMessageStream(userMessage.content, context: context)) {
        if (mounted) {
          setState(() {
            _streamingContent += chunk;
            _messages[_messages.length - 1] = streamingMessage.copyWith(
              content: _streamingContent,
            );
          });
          _scrollToBottom();
        }
      }
      
      // Finalize the message
      setState(() {
        _messages[_messages.length - 1] = streamingMessage.copyWith(
          content: _streamingContent,
          isStreaming: false,
        );
      });
      
      await ChatService.saveMessage(_messages[_messages.length - 1], widget.conversation.id);
      
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
    
    _typingAnimationController.stop();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: widget.conversation.conversationType == ConversationType.ai
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondaryContainer,
              child: widget.conversation.conversationType == ConversationType.ai
                  ? SvgPicture.asset('assets/sampul-icon-white.svg', width: 18, height: 18)
                  : Text(
                      widget.conversation.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  widget.conversation.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.conversation.isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _clearConversation();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                (_hasMoreMessages && _isLoadingMore) ? 60 : 16,
                16,
                16 + MediaQuery.of(context).viewPadding.bottom + 80,
              ),
              itemCount: _messages.length + (_hasMoreMessages ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the top if loading more
                if (index == 0 && _hasMoreMessages) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: _isLoadingMore
                          ? const SizedBox(
                              height: 40,
                              child: CircularProgressIndicator(),
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                }
                
                final messageIndex = _hasMoreMessages ? index - 1 : index;
                final message = _messages[messageIndex];
                final showDateSeparator = messageIndex == 0 || 
                    _shouldShowDateSeparator(_messages[messageIndex - 1].timestamp, message.timestamp);
                
                return Column(
                  children: [
                    if (showDateSeparator)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _formatDate(message.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    _buildMessageBubble(message, _messageAnimation),
                  ],
                );
              },
            ),
          ),
          SafeArea(top: false, bottom: false, child: _buildQuickSuggestions()),
          SafeArea(top: false, child: _buildMessageInput()),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, Animation<double> animation) {
    return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: message.isFromUser 
                ? MainAxisAlignment.end 
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isFromUser) ...[
                CircleAvatar(
                    radius: 16,
                  backgroundColor: widget.conversation.conversationType == ConversationType.ai
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondaryContainer,
                    child: widget.conversation.conversationType == ConversationType.ai
                      ? SvgPicture.asset('assets/sampul-icon-white.svg', width: 18, height: 18)
                        : Text(
                          widget.conversation.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: () => _showMessageContextMenu(message),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: message.isFromUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18).copyWith(
                        bottomLeft: message.isFromUser 
                            ? const Radius.circular(18) 
                            : const Radius.circular(4),
                        bottomRight: message.isFromUser 
                            ? const Radius.circular(4) 
                            : const Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.isTyping)
                          _buildTypingIndicator()
                        else if (message.isRegenerating)
                          Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: _buildMessageContent(message)),
                            ],
                          )
                        else if (message.hasError)
                          _buildErrorMessage(message)
                        else
                          _buildMessageContent(message),
                        // Show action buttons for AI messages
                        if (!message.isFromUser && 
                            !message.isTyping && 
                            !message.hasError &&
                            !message.isRegenerating)
                          _buildActionButtons(message),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                color: message.isFromUser
                                    ? Colors.white70
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                ),
              ),
              if (message.isFromUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  backgroundImage: _userProfile?.fullImageUrl != null
                      ? NetworkImage(_userProfile!.fullImageUrl!)
                      : null,
                  child: _userProfile?.fullImageUrl == null
                      ? const Icon(Icons.person, color: Colors.white, size: 18)
                      : null,
                ),
              ],
            ],
          ),
        );
  }

  Widget _buildMessageContent(ChatMessage message) {
    // Images
    if (message.messageType == MessageType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          message.content,
          width: 220,
          fit: BoxFit.cover,
          errorBuilder: (context, _, __) => Icon(
            Icons.broken_image,
            color: message.isFromUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
    }
    // Files
    if (message.messageType == MessageType.file) {
      return InkWell(
        onTap: () async {
          final uri = Uri.tryParse(message.content);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: message.isFromUser ? Colors.white : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Open file',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      );
    }
    // Text (user vs AI markdown)
    if (message.isFromUser) {
      return Text(
        message.content,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
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
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
        strong: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        code: TextStyle(
          backgroundColor: Theme.of(context).colorScheme.surface,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href));
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
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: () => _handleAction(action),
      icon: Icon(
        _getActionIcon(action.actionType, action.parameters?['route']),
        size: 16,
      ),
      label: Text(action.label),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
      ),
    );
  }

  IconData _getActionIcon(String actionType, String? route) {
    switch (route) {
      case 'trust_create':
      case 'trust_management':
        return Icons.gavel_outlined;
      case 'hibah_management':
        return Icons.group_outlined;
      case 'will_management':
        return Icons.description_outlined;
      case 'add_asset':
      case 'assets_list':
        return Icons.account_balance_wallet_outlined;
      case 'add_family':
      case 'family_list':
        return Icons.family_restroom;
      case 'executor_management':
        return Icons.person_outline;
      case 'checklist':
        return Icons.checklist_outlined;
      case 'extra_wishes':
        return Icons.favorite_outline;
      default:
        return Icons.arrow_forward;
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
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _retryFailedMessage(message),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
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
      // Add delay for human-like response
      await Future.delayed(const Duration(milliseconds: 500));

      // Remove typing indicator
      setState(() {
        _messages.removeWhere((msg) => msg.id == typingMessage.id);
        _streamingContent = '';
      });

      // Create streaming message
      final streamingMessage = ChatMessage(
        id: '', // Let database generate UUID
        content: '',
        isFromUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      );

      setState(() {
        _messages.add(streamingMessage);
      });

      // Build user context from assets (concise)
      String? context;
      try {
        final user = AuthController.instance.currentUser;
        if (user != null) {
          final assets = await WillService.instance.getUserAssets(user.id);
          final int count = assets.length;
          final double total = assets.fold<double>(0.0, (double acc, Map<String, dynamic> a) => acc + ((a['value'] as num?)?.toDouble() ?? 0.0));
          final List<String> names = assets.take(5).map<String>((Map<String, dynamic> a) => (a['new_service_platform_name'] as String?) ?? (a['name'] as String?) ?? 'Asset').toList();
          context = 'Assets count: ' + count.toString() + '; Total value (approx): RM ' + total.toStringAsFixed(2) + '; Recent assets: ' + names.join(', ') + '. Use this context to tailor advice and references.';
        }
      } catch (_) {
        context = null;
      }

      // Stream the response with context
      await for (final chunk in OpenRouterService.sendMessageStream(messageText, context: context)) {
        if (mounted) {
          setState(() {
            _streamingContent += chunk;
            _messages[_messages.length - 1] = streamingMessage.copyWith(
              content: _streamingContent,
            );
          });
          _scrollToBottom();
        }
      }

      // Finalize the message
      setState(() {
        _messages[_messages.length - 1] = streamingMessage.copyWith(
          content: _streamingContent,
          isStreaming: false,
        );
        _isLoading = false;
      });

      await ChatService.saveMessage(_messages[_messages.length - 1], widget.conversation.id);
      
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
      String errorContent = "Sorry, I'm having trouble connecting right now. Please try again later.";
      
      final errorString = e.toString();
      if (errorString.contains('OPENROUTER_API_KEY') || errorString.contains('OPENROUTER_MODEL')) {
        errorContent = "AI chat is not configured. Please check your environment variables.";
      } else if (errorString.contains('HTTP 401') || errorString.contains('HTTP 403')) {
        errorContent = "Authentication failed. Please check your API key configuration.";
      } else if (errorString.contains('HTTP 429')) {
        errorContent = "Rate limit exceeded. Please try again in a moment.";
      } else if (errorString.contains('HTTP 500') || errorString.contains('HTTP 502') || errorString.contains('HTTP 503')) {
        errorContent = "The AI service is temporarily unavailable. Please try again later.";
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

    _typingAnimationController.stop();
    _scrollToBottom();
  }

  Widget _buildMessageActions(ChatMessage message) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () => _copyMessage(message),
          tooltip: 'Copy',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        if (!message.isFromUser && !message.hasError)
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            onPressed: () => _regenerateResponse(message),
            tooltip: 'Regenerate response',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isLoading,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isLoading ? null : _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isLoading 
                        ? theme.colorScheme.outline.withOpacity(0.3)
                        : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'Sampul AI can make mistakes. Check important info.',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    // Only show suggestions if there are no user messages yet
    final hasUserMessages = _messages.any((msg) => msg.isFromUser);
    if (hasUserMessages || _isLoading) {
      return const SizedBox.shrink();
    }
    
    final List<String> suggestions = <String>[
      'Summarize my assets',
      'How to start my will?',
      'What is Hibah and how to use it?',
      'Checklist for estate planning',
    ];

    return Container(
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions
              .map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                    child: ActionChip(
                      label: Text(s),
                      onPressed: _isLoading
                          ? null
                          : () {
                              _messageController.text = s;
                              _sendMessage();
                            },
                    ),
                  ))
              .toList(),
        ),
      ),
    );
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

  bool _shouldShowDateSeparator(DateTime previous, DateTime current) {
    final prevDate = DateTime(previous.year, previous.month, previous.day);
    final currDate = DateTime(current.year, current.month, current.day);
    return prevDate != currDate;
  }

  String _formatDate(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year}';
    }
  }
}
