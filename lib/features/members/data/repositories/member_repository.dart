import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/data/models/app_user.dart';

class MemberRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUid => _supabase.auth.currentUser?.id;

  Stream<List<AppUser>> watchAll() {
    return _supabase.from('profiles').stream(primaryKey: ['id']).map((data) {
      final list = data
          .map((json) => AppUser.fromJson(json))
          .where((u) => u.email?.toLowerCase() != 'rajeshkinjarapu@gmail.com')
          .toList();
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

  Future<void> updateMemberPhoto(String uid, String photoUrl) async {
    await _supabase.from('profiles').update({'photo_url': photoUrl}).eq('id', uid);
  }

  Future<void> removeUser(String uid) async {
    await _supabase.from('profiles').delete().eq('id', uid);
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
    try {
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
      
      tempClient.dispose();
    } catch (e) {
      // Fallback to direct profiles row update if already exists
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
      final existing = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', authEmail)
          .maybeSingle();
          
      if (existing != null) {
        final existingId = existing['id'] as String;
        final updateMap = <String, dynamic>{
          'display_name': name.trim(),
          'role': role.name,
        };
        if (photoUrl != null && photoUrl.isNotEmpty) {
          updateMap['photo_url'] = photoUrl;
        }
        await _supabase.from('profiles').update(updateMap).eq('id', existingId);
        return existingId;
      } else {
        final newId = const Uuid().v4();
        final map = <String, dynamic>{
          'id': newId,
          'email': authEmail,
          'display_name': name.trim(),
          'role': role.name,
          'created_at': DateTime.now().toIso8601String(),
        };
        if (photoUrl != null && photoUrl.isNotEmpty) {
          map['photo_url'] = photoUrl;
        }
        await _supabase.from('profiles').insert(map);
        return newId;
      }
    }
  }
}
