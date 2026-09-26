import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../models/player.dart';

class PlayerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Player _enrichWithProfile(Player player, List<dynamic> profiles) {
    if (profiles.isEmpty) return player;

    Map<String, dynamic>? match;
    // 1. Match by UID
    for (final raw in profiles) {
      final p = raw as Map<String, dynamic>;
      if (p['id'] == player.id) {
        match = p;
        break;
      }
    }

    // 2. Match by normalized Name
    if (match == null) {
      final pName = player.name.trim().toLowerCase();
      if (pName.isNotEmpty) {
        for (final raw in profiles) {
          final p = raw as Map<String, dynamic>;
          final dName = (p['display_name'] as String? ?? '').trim().toLowerCase();
          if (dName == pName) {
            match = p;
            break;
          }
        }
      }
    }

    if (match != null) {
      final photo = match['photo_url'] as String?;
      final email = match['email'] as String? ?? '';
      String? phone;
      if (email.endsWith('@member.cricket.com')) {
        phone = email.split('@').first;
      }
      return player.copyWith(
        profilePicUrl: (photo != null && photo.isNotEmpty) ? photo : player.profilePicUrl,
        phoneNumber: (phone != null && phone.isNotEmpty) ? phone : player.phoneNumber,
      );
    }

    return player;
  }

  Future<List<Player>> getAll() async {
    try {
      final data = await _supabase.from('players').select();
      List<dynamic> profilesData = [];
      try {
        profilesData = await _supabase.from('profiles').select('id, display_name, email, photo_url');
      } catch (_) {}

      final list = (data as List).map((json) {
        final player = Player.fromJson(json as Map<String, dynamic>);
        return _enrichWithProfile(player, profilesData);
      }).toList();

      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    } catch (e) {
      debugPrint('Error in PlayerRepository.getAll: $e');
      return [];
    }
  }

  Stream<List<Player>> watchAll() {
    return _supabase.from('players').stream(primaryKey: ['id']).asyncMap((data) async {
      List<dynamic> profilesData = [];
      try {
        profilesData = await _supabase.from('profiles').select('id, display_name, email, photo_url');
      } catch (_) {}

      final list = data.map((json) {
        final player = Player.fromJson(json);
        return _enrichWithProfile(player, profilesData);
      }).toList();

      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Stream<List<Player>> watchByTeam(String teamId) {
    return watchAll().map((list) {
      return list
          .where((p) => p.teamId == teamId || p.teamIds.contains(teamId))
          .toList();
    });
  }

  Stream<Player?> watchById(String id) {
    return _supabase
        .from('players')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .asyncMap((data) async {
      if (data.isEmpty) return null;
      final player = Player.fromJson(data.first);
      try {
        final profilesData = await _supabase.from('profiles').select('id, display_name, email, photo_url');
        return _enrichWithProfile(player, profilesData);
      } catch (_) {
        return player;
      }
    });
  }

  Map<String, dynamic> _toDbMap(Player player, {required String id}) {
    String roleStr;
    switch (player.role) {
      case PlayerRole.batter:
        roleStr = 'batsman';
        break;
      case PlayerRole.bowler:
        roleStr = 'bowler';
        break;
      case PlayerRole.allRounder:
        roleStr = 'allRounder';
        break;
      case PlayerRole.wicketKeeper:
        roleStr = 'wicketKeeper';
        break;
    }

    String batStr = player.battingStyle == BattingStyle.leftHand ? 'leftHanded' : 'rightHanded';
    
    String bowlStr;
    switch (player.bowlingStyle) {
      case BowlingStyle.rightArmFast:
        bowlStr = 'rightArmFast';
        break;
      case BowlingStyle.rightArmMedium:
        bowlStr = 'rightArmMedium';
        break;
      case BowlingStyle.rightArmOffSpin:
      case BowlingStyle.rightArmLegSpin:
        bowlStr = 'rightArmSpin';
        break;
      case BowlingStyle.leftArmFast:
        bowlStr = 'leftArmFast';
        break;
      case BowlingStyle.leftArmMedium:
        bowlStr = 'leftArmMedium';
        break;
      case BowlingStyle.leftArmOrthodox:
      case BowlingStyle.leftArmChinaman:
        bowlStr = 'leftArmSpin';
        break;
      default:
        bowlStr = 'rightArmMedium';
        break;
    }

    return {
      'id': id,
      'name': player.name,
      'team_id': player.teamId.isNotEmpty ? player.teamId : null,
      'role': roleStr,
      'batting_style': batStr,
      'bowling_style': bowlStr,
      'matches_played': player.stats.matchesPlayed,
      'runs_scored': player.stats.runsScored,
      'highest_score': player.stats.highestScore,
      'wickets': player.stats.wicketsTaken,
      'created_at': player.createdAt.toIso8601String(),
    };
  }

  Future<String> create(Player player) async {
    final id = player.id.isEmpty ? const Uuid().v4() : player.id;
    final map = _toDbMap(player, id: id);
    
    await _supabase.from('players').insert(map);

    // Try saving extended columns directly on players table if they exist
    if (player.profilePicUrl != null || player.jerseyNumber != null || player.phoneNumber != null) {
      try {
        final extMap = <String, dynamic>{};
        if (player.profilePicUrl != null) extMap['profile_pic_url'] = player.profilePicUrl;
        if (player.jerseyNumber != null) extMap['jersey_number'] = player.jerseyNumber;
        if (player.phoneNumber != null) extMap['phone_number'] = player.phoneNumber;
        await _supabase.from('players').update(extMap).eq('id', id);
      } catch (_) {}
    }

    // Always sync photo to profiles table if photo exists
    if (player.profilePicUrl != null && player.profilePicUrl!.isNotEmpty) {
      try {
        await _supabase.from('profiles').update({
          'photo_url': player.profilePicUrl,
        }).or('id.eq.$id,display_name.eq.${player.name.trim()}');
      } catch (_) {}
    }

    return id;
  }

  Future<void> update(Player player) async {
    final map = _toDbMap(player, id: player.id);
    map.remove('id');
    
    // 1. Update core fields in players table
    await _supabase.from('players').update(map).eq('id', player.id);

    // 2. Try extended columns on players table if they exist
    if (player.profilePicUrl != null || player.jerseyNumber != null || player.phoneNumber != null) {
      try {
        final extMap = <String, dynamic>{};
        if (player.profilePicUrl != null) extMap['profile_pic_url'] = player.profilePicUrl;
        if (player.jerseyNumber != null) extMap['jersey_number'] = player.jerseyNumber;
        if (player.phoneNumber != null) extMap['phone_number'] = player.phoneNumber;
        await _supabase.from('players').update(extMap).eq('id', player.id);
      } catch (_) {}
    }

    // 3. ALWAYS sync photo to profiles table so it persists permanently in database!
    if (player.profilePicUrl != null && player.profilePicUrl!.isNotEmpty) {
      try {
        await _supabase.from('profiles').update({
          'photo_url': player.profilePicUrl,
        }).or('id.eq.${player.id},display_name.eq.${player.name.trim()}');
      } catch (e) {
        debugPrint('Error updating photo in profiles: $e');
      }
    }
  }

  Future<void> delete(String id) async {
    await _supabase.from('players').delete().eq('id', id);
  }

  Future<void> addPlayerToTeam(String playerId, String teamId) async {
    await _supabase.from('players').update({
      'team_id': teamId,
    }).eq('id', playerId);
  }

  Future<void> removePlayerFromTeam(String playerId, String teamId) async {
    await _supabase.from('players').update({
      'team_id': null,
    }).eq('id', playerId);
  }
}
