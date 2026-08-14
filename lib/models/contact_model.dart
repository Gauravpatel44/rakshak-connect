/// Model representing an emergency contact
class ContactModel {
  final String contactId;
  final String userId;
  final String name;
  final String phone;
  final String relationship;
  final bool isFavorite;

  const ContactModel({
    required this.contactId,
    required this.userId,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isFavorite = false,
  });

  /// Create from Firestore document
  factory ContactModel.fromMap(Map<String, dynamic> map, String id) {
    return ContactModel(
      contactId: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relationship: map['relationship'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'isFavorite': isFavorite,
    };
  }

  /// Copy with updated fields
  ContactModel copyWith({
    String? name,
    String? phone,
    String? relationship,
    bool? isFavorite,
  }) {
    return ContactModel(
      contactId: contactId,
      userId: userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Get initials for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  @override
  String toString() => 'ContactModel(id: $contactId, name: $name, phone: $phone)';
}
