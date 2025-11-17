// Trust form enum constants based on SAMPLE_ENUM_FROM_WEB.md

class TrustConstants {
  TrustConstants._();

  // Genders
  static const List<Map<String, String>> genders = [
    {'name': 'Male', 'value': 'male'},
    {'name': 'Female', 'value': 'female'},
  ];

  // Resident Status
  static const List<Map<String, String>> residentStatus = [
    {'name': 'Resident', 'value': 'resident'},
    {'name': 'Non-resident', 'value': 'non_resident'},
  ];

  // Countries
  static const List<Map<String, String>> countries = [
    {'name': 'Malaysia', 'value': 'malaysia'},
    {'name': 'Singapore', 'value': 'singapore'},
    {'name': 'Brunei', 'value': 'brunie'},
    {'name': 'Indonesia', 'value': 'indonesia'},
  ];

  // Estimated Net Worth
  static const List<Map<String, String>> estimatedNetWorths = [
    {'name': 'below RM50,000', 'value': 'below_rm_50k'},
    {'name': 'RM50,001 to RM100,000', 'value': 'rm_50k_to_100k'},
    {'name': 'RM100,001 to RM150,000', 'value': 'rm_100k_to_150k'},
    {'name': 'RM150,001 to RM200,000', 'value': 'rm_150k_to_200k'},
    {'name': 'RM200,001 to RM300,000', 'value': 'rm_200k_to_300k'},
    {'name': 'more than RM300,000', 'value': 'above_rm_300k'},
  ];

  // Source of Wealth (from sourceOfWealth)
  static const List<Map<String, String>> sourceOfWealth = [
    {'name': 'Salary', 'value': 'salary'},
    {'name': 'Investment Account', 'value': 'investment_account'},
    {'name': 'Savings', 'value': 'savings'},
    {'name': 'Inheritance', 'value': 'inheritance'},
    {'name': 'Sale of Property/Asset', 'value': 'sale_of_property_asset'},
    {'name': 'Retirement Account (EPF/RPS)', 'value': 'retirement_account'},
    {'name': 'Other', 'value': 'other'},
  ];

  // Relationships
  static const List<Map<String, String>> relationships = [
    {'name': 'Friend', 'value': 'friend'},
    {'name': 'Partner', 'value': 'partner'},
    {'name': 'Sibling', 'value': 'sibling'},
    {'name': 'Parent', 'value': 'parent'},
    {'name': 'Child', 'value': 'child'},
    {'name': 'Colleague', 'value': 'colleague'},
    {'name': 'Acquaintance', 'value': 'acquaintance'},
    {'name': 'Spouse', 'value': 'spouse'},
    {'name': 'Relative', 'value': 'relative'},
    {'name': 'Others', 'value': 'others'},
  ];

  // Donation Categories
  static const List<Map<String, String>> donationCategories = [
    {'name': 'Mosque', 'value': 'mosque'},
    {'name': 'School', 'value': 'school'},
    {'name': 'Hospital', 'value': 'hospital'},
    {'name': 'Qurban', 'value': 'qurban'},
    {'name': 'Other', 'value': 'other'},
  ];

  // Banks
  static const List<Map<String, String>> banks = [
    {'name': 'Affin Bank Berhad', 'value': 'affin_bank'},
    {'name': 'Alliance Bank Malaysia Berhad', 'value': 'alliance_bank'},
    {'name': 'AmBank (M) Berhad', 'value': 'ambank'},
    {'name': 'CIMB Bank Berhad', 'value': 'cimb_bank'},
    {'name': 'Hong Leong Bank Berhad', 'value': 'hong_leong_bank'},
    {'name': 'Malayan Banking Berhad (Maybank)', 'value': 'maybank'},
    {'name': 'Public Bank Berhad', 'value': 'public_bank'},
    {'name': 'RHB Bank Berhad', 'value': 'rhb_bank'},
    {'name': 'Bank Islam Malaysia Berhad', 'value': 'bank_islam'},
    {'name': 'OCBC Bank (Malaysia) Berhad', 'value': 'ocbc_bank_malaysia'},
    {'name': 'HSBC Bank Malaysia Berhad', 'value': 'hsbc_bank_malaysia'},
    {'name': 'United Overseas Bank (Malaysia) Bhd', 'value': 'uob_malaysia'},
    {'name': 'Standard Chartered Bank Malaysia Berhad', 'value': 'standard_chartered_malaysia'},
    {'name': 'Bank Muamalat Malaysia Berhad', 'value': 'bank_muamalat'},
  ];

  // Donation Durations
  static const List<Map<String, String>> donationDurations = [
    {'name': 'One-Time', 'value': 'one_time'},
    {'name': 'Weekly', 'value': 'weekly'},
    {'name': 'Monthly', 'value': 'monthly'},
    {'name': 'Quarterly', 'value': 'quarterly'},
    {'name': 'Yearly', 'value': 'yearly'},
  ];
}

