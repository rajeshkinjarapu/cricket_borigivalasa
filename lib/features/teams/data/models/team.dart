import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String id;
  final String name;
  final String shortName;
  final String? logoUrl;
  final String? captainId;
  final String? captainName;
  final List<String> tournamentIds;
  final DateTime createdAt;

  Team({
    required this.id,
    required this.name,
    required this.shortName,
    this.logoUrl,
    this.captainId,
    this.captainName,
    this.tournamentIds = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      shortName: json['shortName'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      captainId: json['captainId'] as String?,
      captainName: json['captainName'] as String?,
      tournamentIds: (json['tournamentIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'logoUrl': logoUrl,
      'captainId': captainId,
      'captainName': captainName,
      'tournamentIds': tournamentIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Team copyWith({
    String? id,
    String? name,
    String? shortName,
    String? logoUrl,
    String? captainId,
    String? captainName,
    List<String>? tournamentIds,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      logoUrl: logoUrl ?? this.logoUrl,
      captainId: captainId ?? this.captainId,
      captainName: captainName ?? this.captainName,
      tournamentIds: tournamentIds ?? this.tournamentIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
