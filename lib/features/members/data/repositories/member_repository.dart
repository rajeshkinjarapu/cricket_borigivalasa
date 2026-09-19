import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
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
}
