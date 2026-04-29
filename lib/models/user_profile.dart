import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final int age;
  final String bio;
  final String photoUrl;
  final List<String> interests;
  final String city;
  final bool published;
  final bool profilePaused;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool liked;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.age,
    required this.bio,
    required this.photoUrl,
    required this.interests,
    required this.city,
    required this.published,
    required this.profilePaused,
    this.createdAt,
    this.updatedAt,
    this.liked = false,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return UserProfile(
      uid: doc.id,
      name: (data['name'] as String?) ?? '',
      age: (data['age'] as num?)?.toInt() ?? 0,
      bio: (data['bio'] as String?) ?? '',
      photoUrl: (data['photoUrl'] as String?) ?? '',
      interests: ((data['interests'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      city: (data['city'] as String?) ?? '',
      published: (data['published'] as bool?) ?? false,
      profilePaused: (data['profilePaused'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'bio': bio,
      'photoUrl': photoUrl,
      'interests': interests,
      'city': city,
      'published': published,
      'profilePaused': profilePaused,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    int? age,
    String? bio,
    String? photoUrl,
    List<String>? interests,
    String? city,
    bool? published,
    bool? profilePaused,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? liked,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      interests: interests ?? this.interests,
      city: city ?? this.city,
      published: published ?? this.published,
      profilePaused: profilePaused ?? this.profilePaused,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      liked: liked ?? this.liked,
    );
  }
}
