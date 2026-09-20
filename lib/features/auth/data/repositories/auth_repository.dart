import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
    final cred = await _a.signInWithEmailAndPassword(email: authEmail, password: password);
    
    if (authEmail.toLowerCase() == 'rajeshkinjarapu@gmail.com' && cred.user != null) {
      await _db.collection(AppConstants.usersCollection).doc(cred.user!.uid)
          .set({'role': UserRole.admin.name}, SetOptions(merge: true));
    }
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

  Future<void> updateProfile({
    String? displayName,
    Uint8List? imageBytes,
    String? fileExtension,
  }) async {
    final user = _a.currentUser;
    if (user == null) throw Exception('Not logged in');

    String? photoUrl;

    if (imageBytes != null && fileExtension != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('users/profile_images/${user.uid}.$fileExtension');
        
        final uploadTask = await ref.putData(
          imageBytes,
          SettableMetadata(contentType: 'image/$fileExtension'),
        );
        photoUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        // Fallback to base64 Data URI if Firebase Storage fails/restricted
        final base64String = base64Encode(imageBytes);
        photoUrl = 'data:image/$fileExtension;base64,$base64String';
      }
    }

    // Update Firebase Auth
    if (displayName != null) await user.updateDisplayName(displayName);
    if (photoUrl != null && photoUrl.startsWith('http')) {
      try {
        await user.updatePhotoURL(photoUrl);
      } catch (_) {}
    }

    // Update Firestore
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isNotEmpty) {
      await _db.collection(AppConstants.usersCollection).doc(user.uid).set(
        updates,
        SetOptions(merge: true),
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _a.currentUser;
    if (user == null) throw Exception('Not logged in');

    // Re-authenticate first (Firebase requires this before sensitive operations)
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Now update password
    await user.updatePassword(newPassword);
  }

  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final user = _a.currentUser;
    if (user == null) throw Exception('Not logged in');

    // Re-authenticate before changing email
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Update Firebase Auth email
    await user.verifyBeforeUpdateEmail(newEmail.trim());

    // Update Firestore email field
    await _db.collection(AppConstants.usersCollection).doc(user.uid).set(
      {'email': newEmail.trim()},
      SetOptions(merge: true),
    );
  }
}
