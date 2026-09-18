import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../models/tournament.dart';

class TournamentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Tournament>> getActiveTournaments() {
    return _db
        .collection('tournaments')
        .where('status', isNotEqualTo: TournamentStatus.completed.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Tournament.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<Tournament>> getAllTournaments() => watchAll();

  Stream<List<Tournament>> watchAll() {
    return _db
        .collection('tournaments')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Tournament.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<Tournament?> watchById(String id) {
    return _db.collection('tournaments').doc(id).snapshots().map((doc) =>
        doc.exists ? Tournament.fromJson({...doc.data()!, 'id': doc.id}) : null);
  }

  Future<String> create(Tournament t) async {
    final doc = await _db.collection('tournaments').add(t.toJson()..remove('id'));
    return doc.id;
  }

  Future<void> update(Tournament t) async {
    await _db.collection('tournaments').doc(t.id).update(t.toJson()..remove('id'));
  }

  Future<void> delete(String id) async {
    await _db.collection('tournaments').doc(id).delete();
  }
}
