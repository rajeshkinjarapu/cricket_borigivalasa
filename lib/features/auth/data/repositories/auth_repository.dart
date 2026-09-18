import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _a = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseAuth _a;
  final FirebaseFirestore _db;
  User? get currentFirebaseUser => _a.currentUser;

  Stream<AppUser?> authStateChanges() => _a.authStateChanges().asyncExpand((u) {
    if (u == null) return Stream<AppUser?>.value(null);
    return _db.collection(AppConstants.usersCollection).doc(u.uid)
      .snapshots().map((d) {
        if (!d.exists || d.data() == null) return null;
        return AppUser.fromJson({...d.data()!, 'uid': d.id});
      });
  });

  Future<void> signIn({required String identifier, required String password}) async {
    String authEmail = identifier.trim();
    if (!authEmail.contains('@') && double.tryParse(authEmail) != null) {
      // Treat as mobile number login for members
      authEmail = '$authEmail@member.cricket.com';
    }
    await _a.signInWithEmailAndPassword(email: authEmail, password: password);
  }

  Future<void> signUp({required String identifier, required String password,
      required String displayName}) async {
    String authEmail = identifier.trim();
    if (!authEmail.contains('@') && double.tryParse(authEmail) != null) {
      // Treat as mobile number signup for members
      authEmail = '$authEmail@member.cricket.com';
    }
    
    // Use a temporary Firebase App so that the main instance isn't automatically logged in.
    final tempApp = await Firebase.initializeApp(
        name: 'temp_signup_${DateTime.now().millisecondsSinceEpoch}', 
        options: Firebase.app().options);
    
    try {
      final c = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: authEmail, password: password);
      final u = c.user!;
      await u.updateDisplayName(displayName.trim());
      
      final au = AppUser(uid: u.uid, email: authEmail,
        displayName: displayName.trim(), role: UserRole.member,
        createdAt: DateTime.now());
      
      await _db.collection(AppConstants.usersCollection).doc(u.uid)
        .set(au.toJson()..remove('uid'));
    } finally {
      await tempApp.delete();
    }
  }

  Future<void> signOut() => _a.signOut();
}
