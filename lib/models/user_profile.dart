import '../config/supabase_config.dart';

class UserProfile {
  final String uuid;
  final String email;
  final String? username;
  final String? nricName;
  final String? nricNo;
  final DateTime? dob;
  final String? phoneNo;
  final String? imagePath;
  final String? address1;
  final String? address2;
  final String? city;
  final String? state;
  final String? postcode;
  final DateTime createdAt;
  final bool isOnboard;

  UserProfile({
    required this.uuid,
    required this.email,
    this.username,
    this.nricName,
    this.nricNo,
    this.dob,
    this.phoneNo,
    this.imagePath,
    this.address1,
    this.address2,
    this.city,
    this.state,
    this.postcode,
    required this.createdAt,
    this.isOnboard = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uuid: json['uuid'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      nricName: json['nric_name'] as String?,
      nricNo: json['nric_no'] as String?,
      dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
      phoneNo: json['phone_no'] as String?,
      imagePath: json['image_path'] as String?,
      address1: json['address_1'] as String?,
      address2: json['address_2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postcode: json['postcode'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isOnboard: json['isOnboard'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'email': email,
      'username': username,
      'nric_name': nricName,
      'nric_no': nricNo,
      'dob': dob?.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
      'phone_no': phoneNo,
      'image_path': imagePath,
      'address_1': address1,
      'address_2': address2,
      'city': city,
      'state': state,
      'postcode': postcode,
      'created_at': createdAt.toIso8601String(),
      'isOnboard': isOnboard,
    };
  }

  // Helper method to get display name
  String get displayName {
    return username ?? nricName ?? email.split('@')[0];
  }

  // Helper method to get full image URL
  String? get fullImageUrl {
    return SupabaseConfig.getFullImageUrl(imagePath);
  }
}
