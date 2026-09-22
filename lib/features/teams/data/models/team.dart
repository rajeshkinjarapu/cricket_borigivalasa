

class Team {
  final String id;
  final String name;
  final String shortName;
  final String? logoUrl;
  final String? captainId;
  final String? captainName;
  final List<String> tournamentIds;
  final bool isCounty;
  final DateTime createdAt;

  Team({
    required this.id,
    required this.name,
    required this.shortName,
    this.logoUrl,
    this.captainId,
    this.captainName,
    this.tournamentIds = const [],
    this.isCounty = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      shortName: json['short_name'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      captainId: json['captain_id'] as String?,
      captainName: json['captain_name'] as String?,
      tournamentIds: (json['tournament_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      isCounty: json['is_county'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_name': shortName,
      'logo_url': logoUrl,
      'captain_id': captainId,
      'captain_name': captainName,
      'tournament_ids': tournamentIds,
      'is_county': isCounty,
      'created_at': createdAt.toIso8601String(),
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
    bool? isCounty,
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
      isCounty: isCounty ?? this.isCounty,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
