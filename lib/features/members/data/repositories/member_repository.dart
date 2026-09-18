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
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map((s) => s.docs.map((d) => AppUser.fromJson(
      {...d.data(), 'uid': d.id})).toList());

  Future<void> updateRole(String uid, UserRole role) async {
    await _db.collection(AppConstants.usersCollection).doc(uid)
      .update({'role': role.name});
  }
  Future<void> removeUser(String uid) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).delete();
  }
}
