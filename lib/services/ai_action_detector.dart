class AiAction {
  final String label;
  final String actionType;
  final Map<String, dynamic>? parameters;

  AiAction({
    required this.label,
    required this.actionType,
    this.parameters,
  });
}

class AiActionDetector {
  /// Detect actionable items from AI response text
  /// Supports structured format: [ACTION:route:label] or [ACTION:route]
  /// Example: [ACTION:trust_create:Create Trust Fund]
  /// Example: [ACTION:trust_create] (will use default label)
  static List<AiAction> detectActions(String message) {
    final actions = <AiAction>[];
    
    // Parse structured action markers: [ACTION:route:label] or [ACTION:route]
    final actionPattern = RegExp(r'\[ACTION:([^:\]]+)(?::([^\]]+))?\]', caseSensitive: false);
    final matches = actionPattern.allMatches(message);
    
    for (final match in matches) {
      final route = match.group(1)?.trim();
      final customLabel = match.group(2)?.trim();
      
      if (route != null && _isValidRoute(route)) {
        actions.add(AiAction(
          label: customLabel ?? _getDefaultLabel(route),
          actionType: 'navigate',
          parameters: {'route': route},
        ));
      }
    }
    
    // Fallback: Also check for keywords in multiple languages (backup detection)
    if (actions.isEmpty) {
      actions.addAll(_detectByKeywords(message));
    }
    
    return actions;
  }

  /// Check if route is valid
  static bool _isValidRoute(String route) {
    const validRoutes = [
      'trust_create',
      'trust_management',
      'hibah_management',
      'will_management',
      'add_asset',
      'assets_list',
      'add_family',
      'family_list',
      'executor_management',
      'checklist',
      'extra_wishes',
    ];
    return validRoutes.contains(route);
  }

  /// Get default label for route
  static String _getDefaultLabel(String route) {
    switch (route) {
      case 'trust_create':
        return 'Create Trust Fund';
      case 'trust_management':
        return 'View Trust Funds';
      case 'hibah_management':
        return 'View Hibah';
      case 'will_management':
        return 'View Will';
      case 'add_asset':
        return 'Add Asset';
      case 'assets_list':
        return 'View Assets';
      case 'add_family':
        return 'Add Family Member';
      case 'family_list':
        return 'View Family';
      case 'executor_management':
        return 'Manage Executors';
      case 'checklist':
        return 'View Checklist';
      case 'extra_wishes':
        return 'Extra Wishes';
      default:
        return 'Open';
    }
  }

  /// Fallback keyword detection (works in multiple languages)
  static List<AiAction> _detectByKeywords(String message) {
    final actions = <AiAction>[];
    final lowerMessage = message.toLowerCase();
    
    // Multi-language keyword detection
    // Trust keywords: English + Malay
    if (_matchesAny(lowerMessage, [
      'create trust', 'set up trust', 'new trust', 'trust fund',
      'cipta amanah', 'buat amanah', 'amanah baru', 'dana amanah'
    ])) {
      actions.add(AiAction(
        label: 'Create Trust Fund',
        actionType: 'navigate',
        parameters: {'route': 'trust_create'},
      ));
    }

    if (_matchesAny(lowerMessage, [
      'view trust', 'my trust', 'trusts', 'trust fund',
      'lihat amanah', 'amanah saya', 'senarai amanah'
    ])) {
      actions.add(AiAction(
        label: 'View Trust Funds',
        actionType: 'navigate',
        parameters: {'route': 'trust_management'},
      ));
    }

    // Hibah keywords
    if (_matchesAny(lowerMessage, [
      'create hibah', 'set up hibah', 'new hibah', 'make hibah',
      'cipta hibah', 'buat hibah', 'hibah baru'
    ])) {
      actions.add(AiAction(
        label: 'Create Hibah',
        actionType: 'navigate',
        parameters: {'route': 'hibah_management'},
      ));
    }

    if (_matchesAny(lowerMessage, [
      'view hibah', 'my hibah', 'hibah',
      'lihat hibah', 'hibah saya'
    ])) {
      actions.add(AiAction(
        label: 'View Hibah',
        actionType: 'navigate',
        parameters: {'route': 'hibah_management'},
      ));
    }

    // Will keywords
    if (_matchesAny(lowerMessage, [
      'create will', 'set up will', 'new will', 'make will', 'write will',
      'cipta wasiat', 'buat wasiat', 'wasiat baru'
    ])) {
      actions.add(AiAction(
        label: 'Create Will',
        actionType: 'navigate',
        parameters: {'route': 'will_management'},
      ));
    }

    // Assets keywords
    if (_matchesAny(lowerMessage, [
      'add asset', 'create asset', 'new asset', 'register asset',
      'tambah aset', 'cipta aset', 'aset baru', 'daftar aset'
    ])) {
      actions.add(AiAction(
        label: 'Add Asset',
        actionType: 'navigate',
        parameters: {'route': 'add_asset'},
      ));
    }

    if (_matchesAny(lowerMessage, [
      'view assets', 'my assets', 'assets', 'asset list',
      'lihat aset', 'aset saya', 'senarai aset'
    ])) {
      actions.add(AiAction(
        label: 'View Assets',
        actionType: 'navigate',
        parameters: {'route': 'assets_list'},
      ));
    }

    // Family keywords
    if (_matchesAny(lowerMessage, [
      'add family', 'add beneficiary', 'add member', 'family member',
      'tambah keluarga', 'tambah benefisiari', 'tambah ahli keluarga'
    ])) {
      actions.add(AiAction(
        label: 'Add Family Member',
        actionType: 'navigate',
        parameters: {'route': 'add_family'},
      ));
    }

    if (_matchesAny(lowerMessage, [
      'view family', 'my family', 'family list', 'beneficiaries',
      'lihat keluarga', 'keluarga saya', 'senarai keluarga'
    ])) {
      actions.add(AiAction(
        label: 'View Family',
        actionType: 'navigate',
        parameters: {'route': 'family_list'},
      ));
    }

    return actions;
  }

  /// Check if message contains any of the keywords
  static bool _matchesAny(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }
}
