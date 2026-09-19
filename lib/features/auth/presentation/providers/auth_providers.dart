import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());
final authStateProvider = StreamProvider<AppUser?>((ref) =>
  ref.watch(authRepositoryProvider).authStateChanges());
final currentUserProvider = Provider<AppUser?>((ref) =>
  ref.watch(authStateProvider).value);
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>(
  (ref) => AuthController(ref.read(authRepositoryProvider)));

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._r) : super(const AsyncValue.data(null));
  final AuthRepository _r;

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try { await _r.signIn(identifier: email, password: password);
      state = const AsyncValue.data(null); return true; }
    catch (e, st) { state = AsyncValue.error(e, st); return false; }
  }

  Future<bool> signUp({required String email, required String password,
      required String displayName}) async {
    state = const AsyncValue.loading();
    try { await _r.signUp(identifier: email, password: password, displayName: displayName);
      state = const AsyncValue.data(null); return true; }
    catch (e, st) { state = AsyncValue.error(e, st); return false; }
  }

  Future<void> signOut() async {
    await _r.signOut();
    state = const AsyncValue.data(null);
  }

  Future<bool> updateProfile({
    String? displayName,
    Uint8List? imageBytes,
    String? fileExtension,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _r.updateProfile(
        displayName: displayName,
        imageBytes: imageBytes,
        fileExtension: fileExtension,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
