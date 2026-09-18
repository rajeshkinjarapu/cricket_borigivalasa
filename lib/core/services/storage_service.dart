import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
    : _s = storage ?? FirebaseStorage.instance;
  final FirebaseStorage _s;
  Future<String> uploadTeamLogo({required String tournamentId,
      required String teamId, required File file}) async {
    final ref = _s.ref('tournaments/$tournamentId/teams/$teamId/logo_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
final storageServiceProvider = Provider<StorageService>((_) => StorageService());
