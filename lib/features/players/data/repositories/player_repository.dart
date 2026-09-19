import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player.dart';

class PlayerRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Player>> watchAll() {
    return _db.collection('players').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Player.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Stream<List<Player>> watchByTeam(String teamId) {
    return _db
        .collection('players')
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Player.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return list;
        });
  }

  Stream<Player?> watchById(String id) {
    return _db.collection('players').doc(id).snapshots().map((doc) => doc.exists ? Player.fromJson({...doc.data()!, 'id': doc.id}) : null);
  }

  Future<String> create(Player player) async {
    final doc = await _db.collection('players').add(player.toJson()..remove('id'));
    return doc.id;
  }

  Future<void> update(Player player) async {
    await _db.collection('players').doc(player.id).update(player.toJson()..remove('id'));
  }

  Future<void> delete(String id) async {
    await _db.collection('players').doc(id).delete();
  }
}
