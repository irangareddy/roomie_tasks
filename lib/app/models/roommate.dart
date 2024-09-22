import 'package:uuid/uuid.dart';

class Roommate {
  Roommate({
    required this.name,
    String? id,
    this.email,
    this.phoneNumber,
    this.profilePictureUrl,
  }) : id = id ?? const Uuid().v4();

  // Factory constructor to create a Roommate from a JSON map
  factory Roommate.fromJson(Map<String, dynamic> json) {
    return Roommate(
      id: json['id'] as String?,
      name: json['name'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }
  final String id;
  String name;
  String? email;
  String? phoneNumber;
  String? profilePictureUrl;

  // Method to convert Roommate to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
    };
  }

  // Override toString for easy printing/debugging
  @override
  String toString() {
    return 
    'Roommate(id: $id, name: $name, email: $email, phoneNumber: $phoneNumber)';
  }

  // Create a copy of the Roommate with optional new values
  Roommate copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? profilePictureUrl,
  }) {
    return Roommate(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}
