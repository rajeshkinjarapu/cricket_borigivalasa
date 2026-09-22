import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageService {
  StorageService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;
  final SupabaseClient _supabase;

  Future<String> uploadTeamLogo({
    required String tournamentId,
    required String teamId,
    required File file,
  }) async {
    final path = 'tournaments/$tournamentId/teams/$teamId/logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _supabase.storage.from('logos').upload(path, file);
    return _supabase.storage.from('logos').getPublicUrl(path);
  }
}

final storageServiceProvider = Provider<StorageService>((_) => StorageService());
