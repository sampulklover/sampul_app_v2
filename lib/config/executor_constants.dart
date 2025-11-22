// Executor form enum constants based on SAMPLE_ENUM_FROM_WEB.md and DB_STRUCTURE.md

class ExecutorConstants {
  ExecutorConstants._();

  // Executor Relationships with Deceased
  static const List<Map<String, String>> executorRelationships = [
    {'name': 'Husband', 'value': 'husband'},
    {'name': 'Wife', 'value': 'wife'},
    {'name': 'Father', 'value': 'father'},
    {'name': 'Mother', 'value': 'mother'},
    {'name': 'Child', 'value': 'child'},
    {'name': 'Others', 'value': 'others'},
  ];

  // Death Causes
  static const List<Map<String, String>> deathCauses = [
    {'name': 'Natural Cause', 'value': 'natural'},
    {'name': 'Accident', 'value': 'accident'},
  ];

  // Marital Status
  static const List<Map<String, String>> maritalStatus = [
    {'name': 'Single', 'value': 'single'},
    {'name': 'Married', 'value': 'married'},
    {'name': 'Divorced', 'value': 'divorced'},
    {'name': 'Widowed', 'value': 'widowed'},
  ];

  // Citizenship
  static const List<Map<String, String>> citizenship = [
    {'name': 'Malaysian', 'value': 'malaysian'},
    {'name': 'Singaporean', 'value': 'singaporean'},
    {'name': 'Indonesian', 'value': 'indonesian'},
    {'name': 'Other', 'value': 'other'},
  ];

  // Religion
  static const List<Map<String, String>> religions = [
    {'name': 'Islam', 'value': 'islam'},
    {'name': 'Christianity', 'value': 'christianity'},
    {'name': 'Buddhism', 'value': 'buddhism'},
    {'name': 'Hinduism', 'value': 'hinduism'},
    {'name': 'Sikhism', 'value': 'sikhism'},
    {'name': 'Confucianism', 'value': 'confucianism'},
    {'name': 'Taoism', 'value': 'taoism'},
    {'name': 'Others', 'value': 'others'},
  ];

  // Race/Ethnicity
  static const List<Map<String, String>> races = [
    {'name': 'Malay', 'value': 'malay'},
    {'name': 'Chinese', 'value': 'chinese'},
    {'name': 'Indian', 'value': 'indian'},
    {'name': 'Others', 'value': 'others'},
  ];

  // Countries (reuse from TrustConstants)
  static const List<Map<String, String>> countries = [
    {'name': 'Malaysia', 'value': 'malaysia'},
    {'name': 'Singapore', 'value': 'singapore'},
    {'name': 'Brunei', 'value': 'brunie'},
    {'name': 'Indonesia', 'value': 'indonesia'},
  ];

  // Guardian Relationships
  static const List<Map<String, String>> guardianRelationships = [
    {'name': 'Parent', 'value': 'parent'},
    {'name': 'Guardian', 'value': 'guardian'},
    {'name': 'Relative', 'value': 'relative'},
    {'name': 'Others', 'value': 'others'},
  ];
}

