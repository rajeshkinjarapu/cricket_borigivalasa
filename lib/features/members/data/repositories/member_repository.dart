import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/data/models/app_user.dart';

class MemberRepository {
  MemberRepository({FirebaseFirestore? f, FirebaseAuth? a})
    : _db = f ?? FirebaseFirestore.instance,
      _auth = a ?? FirebaseAuth.instance;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  String? get currentUid => _auth.currentUser?.uid;

  Stream<List<AppUser>> watchAll() => _db
      .collection(AppConstants.usersCollection)
      .snapshots()
      .map((s) {
        final list = s.docs
            .map((d) => AppUser.fromJson({...d.data(), 'uid': d.id}))
            .toList();
        list.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        return list;
      });

  Future<void> updateRole(String uid, UserRole role) async {
    await _db.collection(AppConstants.usersCollection).doc(uid)
      .update({'role': role.name});
  }

  Future<void> removeUser(String uid) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).delete();
  }

  Future<String?> createMember({
    required String name,
    required String phoneNumber,
    required UserRole role,
    String? photoUrl,
  }) async {
    final cleanPhone = phoneNumber.trim().replaceAll(' ', '').replaceAll('-', '');
    final authEmail = '$cleanPhone@member.cricket.com';
    final password = cleanPhone;

    String? createdUid;
    try {
      final tempApp = await Firebase.initializeApp(
        name: 'temp_add_member_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      try {
        final cred = await FirebaseAuth.instanceFor(app: tempApp)
            .createUserWithEmailAndPassword(email: authEmail, password: password);
        final u = cred.user!;
        await u.updateDisplayName(name.trim());
        createdUid = u.uid;
      } catch (_) {
      } finally {
        await tempApp.delete();
      }
    } catch (_) {}

    final appUser = AppUser(
      uid: createdUid ?? '',
      email: authEmail,
      displayName: name.trim(),
      role: role,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );

    if (createdUid != null) {
      await _db.collection(AppConstants.usersCollection).doc(createdUid).set(
        appUser.toJson()..remove('uid'),
        SetOptions(merge: true),
      );
      return createdUid;
    } else {
      final existing = await _db.collection(AppConstants.usersCollection)
          .where('email', isEqualTo: authEmail)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        await _db.collection(AppConstants.usersCollection).doc(existing.docs.first.id).update({
          'displayName': name.trim(),
          'role': role.name,
        });
        return existing.docs.first.id;
      } else {
        final doc = await _db.collection(AppConstants.usersCollection).add(
          appUser.toJson()..remove('uid'),
        );
        return doc.id;
      }
    }
  }
}
