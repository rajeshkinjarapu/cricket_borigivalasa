import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/data/models/app_user.dart';

class MemberRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUid => _supabase.auth.currentUser?.id;

  Stream<List<AppUser>> watchAll() {
    return _supabase.from('profiles').stream(primaryKey: ['id']).map((data) {
      final list = data.map((json) => AppUser.fromJson(json)).toList();
      list.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  Future<void> updateRole(String uid, UserRole role) async {
    await _supabase.from('profiles').update({'role': role.name}).eq('id', uid);
  }

  Future<void> removeUser(String uid) async {
    await _supabase.from('profiles').delete().eq('id', uid);
    // Note: In Supabase, deleting a profile might not delete the auth user unless
    // there's a trigger, but for now we just delete the profile.
  }

  Future<String?> createMember({
    required String name,
    String? phoneNumber,
    required UserRole role,
    String? photoUrl,
  }) async {
    final rawPhone = phoneNumber?.trim() ?? '';
    final cleanPhone = rawPhone.replaceAll(' ', '').replaceAll('-', '');
    final bool hasPhone = cleanPhone.isNotEmpty;
    final authEmail = hasPhone
        ? '$cleanPhone@member.cricket.com'
        : 'member_${DateTime.now().millisecondsSinceEpoch}@borigivalasa.club';
    final password = hasPhone ? cleanPhone : 'Member@123';

    String? createdUid;
    if (hasPhone) {
      try {
        // Use a temporary client to avoid logging out the current admin
        final tempClient = SupabaseClient(
          'https://qlphckdozxtqhwnpokec.supabase.co',
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFscGhja2Rvenh0cWh3bnBva2VjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk5MDcwNTQsImV4cCI6MjEwNTQ4MzA1NH0.J4I7nbtYXPTzM0FO2eA_7k32g9j-TU1gk3LPBnGsp1c',
        );
        
        final response = await tempClient.auth.signUp(
          email: authEmail,
          password: password,
          data: {'display_name': name.trim()},
        );
        
        if (response.user != null) {
          createdUid = response.user!.id;
        }
        
        // Dispose the temp client
        tempClient.dispose();
      } catch (e) {
        // Check if user already exists
      }
    }

    if (createdUid != null) {
      final appUser = AppUser(
        uid: createdUid,
        email: authEmail,
        displayName: name.trim(),
        role: role,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );
      
      final map = appUser.toJson();
      map['id'] = createdUid;
      map.remove('uid');
      
      await _supabase.from('profiles').upsert(map);
      return createdUid;
    } else {
      if (hasPhone) {
        final existing = await _supabase
            .from('profiles')
            .select('id')
            .eq('email', authEmail)
            .maybeSingle();
            
        if (existing != null) {
          await _supabase.from('profiles').update({
            'display_name': name.trim(),
            'role': role.name,
          }).eq('id', existing['id']);
          return existing['id'] as String;
        }
      }
      return null;
    }
  }
}
