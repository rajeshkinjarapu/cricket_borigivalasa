import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;
    
  final SupabaseClient _supabase;
  
  User? get currentUser => _supabase.auth.currentUser;

  Stream<AppUser?> authStateChanges() => _supabase.auth.onAuthStateChange.asyncMap((data) async {
    final session = data.session;
    if (session == null || session.user == null) return null;
    
    try {
      final res = await _supabase
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .maybeSingle();
          
      if (res == null) return null;
      return AppUser.fromJson({...res, 'uid': session.user.id});
    } catch (e) {
      return null;
    }
  });

  Future<void> signIn({required String identifier, required String password}) async {
    String authEmail = identifier.trim();
    if (!authEmail.contains('@') && double.tryParse(authEmail) != null) {
      authEmail = '$authEmail@member.cricket.com';
    }
    
    final response = await _supabase.auth.signInWithPassword(
      email: authEmail,
      password: password,
    );
    
    if (authEmail.toLowerCase() == 'rajeshkinjarapu@gmail.com' && response.user != null) {
      await _supabase.from('profiles').upsert({
        'id': response.user!.id,
        'role': UserRole.admin.name,
      });
    }
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
    }
  }

  Future<void> signOut() => _supabase.auth.signOut();

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
          fileOptions: FileOptions(upsert: true),
        );
        photoUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      } catch (e) {
        final base64String = base64Encode(imageBytes);
        photoUrl = 'data:image/$fileExtension;base64,$base64String';
      }
    }

    // Update Supabase Auth metadata
    final Map<String, dynamic> userMetadata = {};
    if (displayName != null) userMetadata['display_name'] = displayName;
    if (photoUrl != null) userMetadata['avatar_url'] = photoUrl;
    
    if (userMetadata.isNotEmpty) {
      await _supabase.auth.updateUser(UserAttributes(
        data: userMetadata,
      ));
    }

    // Update profiles table
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (photoUrl != null) updates['photo_url'] = photoUrl;

    if (updates.isNotEmpty) {
      await _supabase.from('profiles').update(updates).eq('id', user.id);
    }
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
