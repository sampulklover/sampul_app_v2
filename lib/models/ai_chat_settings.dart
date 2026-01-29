class AiResource {
  final String url;
  final String title;
  final String? description;
  final String? type; // e.g., 'link', 'pdf', 'doc', 'article', 'webpage'

  AiResource({
    required this.url,
    required this.title,
    this.description,
    this.type,
  });

  factory AiResource.fromJson(Map<String, dynamic> json) {
    return AiResource(
      url: json['url'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
    };
  }
}

class AiChatSettings {
  final String id;
  final String systemPrompt;
  final int maxTokens;
  final double temperature;
  final String? model;
  final String welcomeMessage;
  final List<AiResource> resources;
  final String? contextResources;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? updatedBy;

  AiChatSettings({
    required this.id,
    required this.systemPrompt,
    required this.maxTokens,
    required this.temperature,
    this.model,
    required this.welcomeMessage,
    List<AiResource>? resources,
    this.contextResources,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.updatedBy,
  })  : resources = resources ?? const [];

  factory AiChatSettings.fromJson(Map<String, dynamic> json) {
    // Parse resources (unified knowledge base)
    List<AiResource> resourcesList = [];
    if (json['resources'] != null) {
      final resourcesJson = json['resources'];
      if (resourcesJson is List) {
        resourcesList = resourcesJson
            .map((resource) => AiResource.fromJson(resource as Map<String, dynamic>))
            .toList();
      }
    }

    return AiChatSettings(
      id: json['id'] as String,
      systemPrompt: json['system_prompt'] as String,
      maxTokens: json['max_tokens'] as int,
      temperature: (json['temperature'] as num).toDouble(),
      model: json['model'] as String?,
      welcomeMessage: json['welcome_message'] as String,
      resources: resourcesList,
      contextResources: json['context_resources'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'system_prompt': systemPrompt,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'model': model,
      'welcome_message': welcomeMessage,
      'resources': resources.map((resource) => resource.toJson()).toList(),
      'context_resources': contextResources,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'updated_by': updatedBy,
    };
  }

  AiChatSettings copyWith({
    String? id,
    String? systemPrompt,
    int? maxTokens,
    double? temperature,
    String? model,
    String? welcomeMessage,
    List<AiResource>? resources,
    String? contextResources,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return AiChatSettings(
      id: id ?? this.id,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      model: model ?? this.model,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      resources: resources ?? this.resources,
      contextResources: contextResources ?? this.contextResources,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// Get formatted resources context for AI prompts
  String getResourcesContext() {
    final buffer = StringBuffer();
    
    if (resources.isNotEmpty) {
      buffer.writeln('Knowledge Base Resources (prioritize these sources):');
      for (final resource in resources) {
        buffer.write('- ${resource.title}: ${resource.url}');
        if (resource.type != null) {
          buffer.write(' [${resource.type}]');
        }
        if (resource.description != null && resource.description!.isNotEmpty) {
          buffer.write(' - ${resource.description}');
        }
        buffer.writeln();
      }
      buffer.writeln();
    }

    if (contextResources != null && contextResources!.isNotEmpty) {
      buffer.writeln('Additional Context:');
      buffer.writeln(contextResources);
      buffer.writeln();
    }

    // Add action button instructions
    buffer.writeln('ACTION BUTTONS:');
    buffer.writeln('When relevant, include action buttons using this format: [ACTION:route:label]');
    buffer.writeln('Available routes: trust_create, trust_management, hibah_management, will_management, add_asset, assets_list, add_family, family_list, executor_management, checklist, extra_wishes');
    buffer.writeln('Examples:');
    buffer.writeln('- [ACTION:trust_create:Create Trust Fund]');
    buffer.writeln('- [ACTION:add_asset:Tambah Aset]');
    buffer.writeln('- [ACTION:hibah_management]');
    buffer.writeln('Include action buttons when user asks about creating or viewing these features.');
    buffer.writeln('Remove the [ACTION:...] markers from the visible text - they are only for button generation.');
    buffer.writeln();

    return buffer.toString();
  }
}
