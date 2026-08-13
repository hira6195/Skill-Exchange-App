import 'package:cloud_firestore/cloud_firestore.dart';

class ExpertModel {
  final String uid;
  final String name;
  final String email;
  final String skill; // Teaching / Primary Skill
  final String wantsToLearn; // Learning / Target Skill
  final String category;
  final String level;
  final double rating;
  final String profileImage;
  final bool verified;
  final bool premium;
  final int matchPercentage;
  final String role;
  final String? about;
  final List<String>? skills;
  final double hourlyRate;

  const ExpertModel({
    required this.uid,
    required this.name,
    this.email = '',
    required this.skill,
    this.wantsToLearn = '',
    required this.category,
    this.level = 'Expert',
    required this.rating,
    required this.profileImage,
    this.verified = false,
    this.premium = false,
    this.matchPercentage = 0,
    this.role = 'teacher',
    this.about,
    this.skills,
    this.hourlyRate = 0.0,
  });

  String get id => uid;
  String get title => skill.isNotEmpty ? skill : category;
  String get imageUrl => profileImage;

  static String _parseSkillValue(Map<String, dynamic> map, List<String> keys) {
    for (String key in keys) {
      if (map.containsKey(key) && map[key] != null) {
        var value = map[key];
        if (value is List && value.isNotEmpty) {
          return value.map((e) => e.toString().trim()).join(', ');
        } else if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return '';
  }

  factory ExpertModel.fromMap(Map<String, dynamic> map, String docId) {
    String teachSkill = _parseSkillValue(map, [
      'teachSkills',
      'verifiedSkill',
      'teachingSkill',
      'skill',
      'skillsToTeach',
      'canTeach',
      'Expert at'
    ]);

    String learnSkill = _parseSkillValue(map, [
      'learnSkills',
      'learningSkill',
      'skillsToLearn',
      'targetSkill',
      'wantToLearn',
      'learn'
    ]);

    return ExpertModel(
      uid: docId.isNotEmpty ? docId : (map['uid'] ?? ''),
      name: map['name'] ?? map['fullName'] ?? 'Unknown User',
      email: map['email'] ?? '',
      skill: teachSkill,
      wantsToLearn: learnSkill,
      category: map['category'] ?? 'General',
      level: map['level'] ?? 'Expert',
      rating: (map['rating'] ?? 0.0).toDouble(),
      profileImage: map['profileImage'] ?? map['photoUrl'] ?? map['imageUrl'] ?? map['image'] ?? '',
      verified: map['verified'] ?? false,
      premium: map['premium'] ?? false,
      matchPercentage: map['matchPercentage'] ?? 0,
      role: map['role'] ?? 'teacher',
      about: map['About Me'] ?? map['about'],
      skills: map['skills'] != null ? List<String>.from(map['skills']) : null,
      hourlyRate: (map['hourlyRate'] ?? map['price'] ?? 0.0).toDouble(),
    );
  }

  factory ExpertModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ExpertModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'skill': skill,
      'wantsToLearn': wantsToLearn,
      'category': category,
      'level': level,
      'rating': rating,
      'profileImage': profileImage,
      'verified': verified,
      'premium': premium,
      'matchPercentage': matchPercentage,
      'role': role,
      'about': about,
      'skills': skills,
      'hourlyRate': hourlyRate,
    };
  }

  ExpertModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? skill,
    String? wantsToLearn,
    String? category,
    String? level,
    double? rating,
    String? profileImage,
    bool? verified,
    bool? premium,
    int? matchPercentage,
    String? role,
    String? about,
    List<String>? skills,
    double? hourlyRate,
  }) {
    return ExpertModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      skill: skill ?? this.skill,
      wantsToLearn: wantsToLearn ?? this.wantsToLearn,
      category: category ?? this.category,
      level: level ?? this.level,
      rating: rating ?? this.rating,
      profileImage: profileImage ?? this.profileImage,
      verified: verified ?? this.verified,
      premium: premium ?? this.premium,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      role: role ?? this.role,
      about: about ?? this.about,
      skills: skills ?? this.skills,
      hourlyRate: hourlyRate ?? this.hourlyRate,
    );
  }
}