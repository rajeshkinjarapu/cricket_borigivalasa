import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;
    
  final SupabaseClient _supabase;
  final StreamController<AppUser?> _profileUpdateController = StreamController<AppUser?>.broadcast();
  
  User? get currentUser => _supabase.auth.currentUser;

  Stream<AppUser?> authStateChanges() {
    late StreamController<AppUser?> controller;
    StreamSubscription? authSub;
    StreamSubscription? updateSub;

    controller = StreamController<AppUser?>.broadcast(
      onListen: () async {
        final current = await getProfile();
        if (!controller.isClosed) controller.add(current);

        authSub = _supabase.auth.onAuthStateChange.listen((data) async {
          if (controller.isClosed) return;
          if (data.session == null) {
            controller.add(null);
          } else {
            final p = await getProfile();
            if (!controller.isClosed) controller.add(p);
          }
        });

        updateSub = _profileUpdateController.stream.listen((user) {
          if (!controller.isClosed) controller.add(user);
        });
      },
      onCancel: () {
        authSub?.cancel();
        updateSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<AppUser?> refreshProfile() async {
    final user = await getProfile();
    _profileUpdateController.add(user);
    return user;
  }

  Future<void> signIn({required String identifier, required String password}) async {
    String authEmail = identifier.trim();
    if (authEmail.toLowerCase() == 'rajeshkinjarapu') {
      authEmail = 'rajeshkinjarapu@gmail.com';
    } else if (!authEmail.contains('@') && double.tryParse(authEmail) != null) {
      authEmail = '$authEmail@member.cricket.com';
    }
    
    final response = await _supabase.auth.signInWithPassword(
      email: authEmail,
      password: password,
    );
    
    if (authEmail.toLowerCase() == 'rajeshkinjarapu@gmail.com' && response.user != null) {
      final existing = await _supabase.from('profiles').select().eq('id', response.user!.id).maybeSingle();
      if (existing == null) {
        // Only create profile if it doesn't exist — never overwrite existing role
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': authEmail,
          'display_name': response.user!.userMetadata?['display_name'] as String? ?? 'Rajesh Kinjarapu',
          'role': 'super_admin',
        });
      }
      // If profile already exists, leave role as-is (don't overwrite)
    }
    await refreshProfile();
  }

  Future<void> signUp({required String identifier, required String password,
      required String displayName}) async {
    String authEmail = identifier.trim();
    if (!authEmail.contains('@') && double.tryParse(authEmail) != null) {
      authEmail = '$authEmail@member.cricket.com';
    }
    
    // In Supabase, signUp automatically signs the user in by default, unless configured otherwise.
    // Assuming standard config:
    final response = await _supabase.auth.signUp(
      email: authEmail,
      password: password,
      data: {'display_name': displayName.trim()},
    );
    
    if (response.user != null) {
      final au = AppUser(
        uid: response.user!.id, 
        email: authEmail,
        displayName: displayName.trim(), 
        role: UserRole.member,
        createdAt: DateTime.now()
      );
      
      final map = au.toJson();
      map['id'] = response.user!.id;
      map.remove('uid');
      
      // Upsert profile data
      await _supabase.from('profiles').upsert(map);

      // Automatically add them to the 'players' table so they show up in squads
      try {
        final existingPlayer = await _supabase.from('players').select('id').eq('id', response.user!.id).maybeSingle();
        if (existingPlayer == null) {
          final isPhone = !identifier.trim().contains('@') || authEmail.endsWith('@member.cricket.com');
          final phoneToSave = isPhone ? identifier.trim() : null;
          
          await _supabase.from('players').insert({
            'id': response.user!.id,
            'name': displayName.trim(),
            'phone_number': phoneToSave,
            'role': 'batter',
            'batting_style': 'rightHand',
            'bowling_style': 'none',
            'team_id': 'default_team',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        print('Error adding player on signup: $e');
      }
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _profileUpdateController.add(null);
  }

  Future<AppUser?> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final res = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (res == null) return null;
      return AppUser.fromJson({
        ...res,
        'uid': user.id,
        'photo_url': res['photo_url'] ?? user.userMetadata?['avatar_url'],
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile({
    String? displayName,
    Uint8List? imageBytes,
    String? fileExtension,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    String? photoUrl;

    if (imageBytes != null && fileExtension != null) {
      try {
        final path = 'users/${user.id}/profile.$fileExtension';
        await _supabase.storage.from('avatars').uploadBinary(
          path, 
          imageBytes,
          fileOptions: const FileOptions(upsert: true),
        );
        photoUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      } catch (e) {
        final base64String = base64Encode(imageBytes);
        photoUrl = 'data:image/$fileExtension;base64,$base64String';
      }
    }

    // 1. Update profiles table in Supabase first
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (photoUrl != null) updates['photo_url'] = photoUrl;

    if (updates.isNotEmpty) {
      await _supabase.from('profiles').update(updates).eq('id', user.id);
    }

    // 2. Safely update Supabase Auth metadata (ONLY pass HTTP URL, never large base64)
    try {
      final Map<String, dynamic> userMetadata = {};
      if (displayName != null) userMetadata['display_name'] = displayName;
      if (photoUrl != null && photoUrl.startsWith('http')) {
        userMetadata['avatar_url'] = photoUrl;
      }
      if (userMetadata.isNotEmpty) {
        await _supabase.auth.updateUser(UserAttributes(
          data: userMetadata,
        ));
      }
    } catch (_) {}

    // 3. Immediately refresh and notify all providers & screens
    await refreshProfile();
  }

  Future<void> updatePhotoUrl(String photoUrl) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('profiles').update({'photo_url': photoUrl}).eq('id', user.id);
      if (photoUrl.startsWith('http')) {
        await _supabase.auth.updateUser(UserAttributes(data: {'avatar_url': photoUrl}));
      }
    } catch (_) {}
    await refreshProfile();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    
    // Note: Supabase requires reauthentication for password change or the session to be active.
    // If we need to verify currentPassword, we can try signing in again:
    await _supabase.auth.signInWithPassword(email: user.email!, password: currentPassword);
    
    await _supabase.auth.updateUser(UserAttributes(
      password: newPassword,
    ));
  }

  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _supabase.auth.signInWithPassword(email: user.email!, password: currentPassword);
    
    await _supabase.auth.updateUser(UserAttributes(
      email: newEmail.trim(),
    ));

    await _supabase.from('profiles').update(
      {'email': newEmail.trim()}
    ).eq('id', user.id);
  }
}
