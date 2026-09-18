import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/cricket_enums.dart';

class Tournament {
  final String id;
  final String name;
  final TournamentStatus status;
  final TournamentFormat format;
  final String organizerId;
  final DateTime startDate;
  final DateTime? endDate;
  final String? venue;
  final int teamsCount;

  Tournament({
    required this.id,
    required this.name,
    required this.status,
    required this.format,
    required this.organizerId,
    required this.startDate,
    this.endDate,
    this.venue,
    this.teamsCount = 0,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: TournamentStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => TournamentStatus.upcoming,
      ),
      format: TournamentFormat.values.firstWhere(
        (e) => e.name == (json['format'] as String?),
        orElse: () => TournamentFormat.t20,
      ),
      organizerId: json['organizerId'] as String? ?? '',
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate(),
      venue: json['venue'] as String?,
      teamsCount: json['teamsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status.name,
      'format': format.name,
      'organizerId': organizerId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'venue': venue,
      'teamsCount': teamsCount,
    };
  }
  
  Tournament copyWith({
    String? id,
    String? name,
    TournamentStatus? status,
    TournamentFormat? format,
    String? organizerId,
    DateTime? startDate,
    DateTime? endDate,
    String? venue,
    int? teamsCount,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      format: format ?? this.format,
      organizerId: organizerId ?? this.organizerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      venue: venue ?? this.venue,
      teamsCount: teamsCount ?? this.teamsCount,
    );
  }
}
