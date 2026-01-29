import '../models/ai_chat_settings.dart';
import '../services/supabase_service.dart';

class AiChatSettingsService {
  static final AiChatSettingsService _instance = AiChatSettingsService._();
  static AiChatSettingsService get instance => _instance;
  AiChatSettingsService._();

  // Cache for active settings
  AiChatSettings? _cachedActiveSettings;
  DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Get the active AI chat settings (for app usage)
  Future<AiChatSettings> getActiveSettings() async {
    // Check cache first
    if (_cachedActiveSettings != null && 
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedActiveSettings!;
    }

    try {
      final response = await SupabaseService.instance.client
          .from('ai_chat_settings')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        // Return default settings if none found
        return AiChatSettings(
          id: 'default',
          systemPrompt: 'You are Sampul AI, a helpful assistant for estate planning and will management. You help users with questions about creating wills, managing assets, family planning, and estate planning. Be friendly, professional, and knowledgeable about these topics. Keep answers concise (2–4 short sentences). Use bullet points only when listing items. Avoid long paragraphs.',
          maxTokens: 220,
          temperature: 0.5,
          welcomeMessage: 'Hello! I\'m Sampul AI, your estate planning assistant. How can I help you today?',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      final settings = AiChatSettings.fromJson(response);
      
      // Update cache
      _cachedActiveSettings = settings;
      _cacheTimestamp = DateTime.now();
      
      return settings;
    } catch (e) {
      // Return default settings on error
      return AiChatSettings(
        id: 'default',
        systemPrompt: 'You are Sampul AI, a helpful assistant for estate planning and will management. You help users with questions about creating wills, managing assets, family planning, and estate planning. Be friendly, professional, and knowledgeable about these topics. Keep answers concise (2–4 short sentences). Use bullet points only when listing items. Avoid long paragraphs.',
        maxTokens: 220,
        temperature: 0.5,
        welcomeMessage: 'Hello! I\'m Sampul AI, your estate planning assistant. How can I help you today?',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Get all settings (admin only)
  Future<List<AiChatSettings>> getAllSettings() async {
    try {
      final response = await SupabaseService.instance.client
          .from('ai_chat_settings')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AiChatSettings.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch AI chat settings: $e');
    }
  }

  /// Create new settings (admin only)
  Future<AiChatSettings> createSettings({
    required String systemPrompt,
    required int maxTokens,
    required double temperature,
    String? model,
    required String welcomeMessage,
    List<Map<String, dynamic>>? resources,
    String? contextResources,
    bool isActive = false,
  }) async {
    try {
      final currentUser = SupabaseService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final Map<String, dynamic> insertData = {
        'system_prompt': systemPrompt,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'model': model,
        'welcome_message': welcomeMessage,
        'is_active': isActive,
        'created_by': currentUser.id,
      };

      if (resources != null && resources.isNotEmpty) {
        insertData['resources'] = resources;
      }
      if (contextResources != null && contextResources.isNotEmpty) {
        insertData['context_resources'] = contextResources;
      }

      final response = await SupabaseService.instance.client
          .from('ai_chat_settings')
          .insert(insertData)
          .select()
          .single();

      // Clear cache when new settings are created
      _cachedActiveSettings = null;
      _cacheTimestamp = null;

      return AiChatSettings.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create AI chat settings: $e');
    }
  }

  /// Update settings (admin only)
  Future<AiChatSettings> updateSettings({
    required String id,
    String? systemPrompt,
    int? maxTokens,
    double? temperature,
    String? model,
    String? welcomeMessage,
    List<Map<String, dynamic>>? resources,
    String? contextResources,
    bool? isActive,
  }) async {
    try {
      final currentUser = SupabaseService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final Map<String, dynamic> updates = {};
      if (systemPrompt != null) updates['system_prompt'] = systemPrompt;
      if (maxTokens != null) updates['max_tokens'] = maxTokens;
      if (temperature != null) updates['temperature'] = temperature;
      if (model != null) updates['model'] = model;
      if (welcomeMessage != null) updates['welcome_message'] = welcomeMessage;
      if (resources != null) updates['resources'] = resources;
      if (contextResources != null) updates['context_resources'] = contextResources;
      if (isActive != null) updates['is_active'] = isActive;

      if (updates.isEmpty) {
        throw Exception('No updates provided');
      }

      final response = await SupabaseService.instance.client
          .from('ai_chat_settings')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      // Clear cache when settings are updated
      _cachedActiveSettings = null;
      _cacheTimestamp = null;

      return AiChatSettings.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update AI chat settings: $e');
    }
  }

  /// Delete settings (admin only)
  Future<void> deleteSettings(String id) async {
    try {
      await SupabaseService.instance.client
          .from('ai_chat_settings')
          .delete()
          .eq('id', id);

      // Clear cache when settings are deleted
      _cachedActiveSettings = null;
      _cacheTimestamp = null;
    } catch (e) {
      throw Exception('Failed to delete AI chat settings: $e');
    }
  }

  /// Clear cache (useful for testing or when settings change externally)
  void clearCache() {
    _cachedActiveSettings = null;
    _cacheTimestamp = null;
  }
}
