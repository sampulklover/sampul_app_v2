import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../services/openrouter_service.dart';
import '../controllers/auth_controller.dart';
import '../services/will_service.dart';
import '../models/user_profile.dart';
import '../services/chat_service.dart';
import '../services/file_upload_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ChatConversationScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ChatConversationScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  UserProfile? _userProfile;
  bool _isUploading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _loadUserProfile();
  }

  void _initializeChat() {
    // Add welcome message from Sampul AI if it's the first time
    if (widget.conversation.id == 'sampul_ai') {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: "Hello! I'm Sampul AI, your estate planning assistant. How can I help you today?",
        isFromUser: false,
        timestamp: DateTime.now(),
      ));
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: messageText,
      isFromUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
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

      // Get AI response with context
      final aiResponse = await OpenRouterService.sendMessage(messageText, context: context);
      
      // Add AI response
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse,
        isFromUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });
    } catch (e) {
      // Add error message
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: "Sorry, I'm having trouble connecting right now. Please try again later.",
        isFromUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _pickAndSendAttachments() async {
    // Show source chooser: Photos, Camera, Files
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
    // Else fall-through to file picker
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
      // Upload all files sequentially to keep UI simple and predictable
      for (final f in files) {
        final path = f.path;
        if (path == null) {
          continue;
        }
        final file = File(path);
        final upload = await FileUploadService.uploadAttachment(
          file: file,
          userId: user.id,
          conversationId: widget.conversation.id,
        );
        final isImage = upload.mimeType.startsWith('image/');
        final msg = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
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
          id: DateTime.now().millisecondsSinceEpoch.toString(),
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
        id: DateTime.now().millisecondsSinceEpoch.toString(),
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
              backgroundColor: widget.conversation.id == 'sampul_ai'
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondaryContainer,
              child: widget.conversation.id == 'sampul_ai'
                  ? SvgPicture.asset(
                      'assets/sampul-icon-white.svg',
                      width: 18,
                      height: 18,
                    )
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
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Add more options
            },
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
                16,
                16,
                16 + MediaQuery.of(context).viewPadding.bottom + 80,
              ),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          SafeArea(top: false, child: _buildMessageInput()),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
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
              backgroundColor: widget.conversation.id == 'sampul_ai'
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondaryContainer,
              child: widget.conversation.id == 'sampul_ai'
                  ? SvgPicture.asset(
                      'assets/sampul-icon-white.svg',
                      width: 18,
                      height: 18,
                    )
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
                  if (message.messageType == MessageType.text) ...[
                    Text(
                      message.content,
                      style: TextStyle(
                        color: message.isFromUser
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                  ] else if (message.messageType == MessageType.image) ...[
                    ClipRRect(
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
                    ),
                  ] else if (message.messageType == MessageType.file) ...[
                    InkWell(
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
                          Flexible(
                            child: Text(
                              'Open file',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: message.isFromUser
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isFromUser
                          ? Colors.white70
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
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
                  ? const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: widget.conversation.id == 'sampul_ai'
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
            child: widget.conversation.id == 'sampul_ai'
                ? const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 18,
                  )
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(
              0.3 + (0.7 * ((value + index * 0.2) % 1.0)),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isUploading ? Icons.hourglass_top : Icons.attach_file,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Attach files',
            onPressed: _isUploading ? null : _pickAndSendAttachments,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
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
