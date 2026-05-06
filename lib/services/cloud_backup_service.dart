import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudBackupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get usuarioAtual => _auth.currentUser;

  DocumentReference<Map<String, dynamic>>? get _docBackupAtual {
    final user = usuarioAtual;
    if (user == null) return null;
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('app_data')
        .doc('demanda_controller_backup');
  }

  Future<void> salvarBackupNuvem(String backupJson) async {
    final doc = _docBackupAtual;
    if (doc == null) {
      throw StateError('Usuário não autenticado.');
    }

    await doc.set({
      'backupJson': backupJson,
      'updatedAt': FieldValue.serverTimestamp(),
      'source': 'mobile_flutter',
      'email': usuarioAtual?.email,
    }, SetOptions(merge: true));
  }

  Future<String?> carregarBackupNuvem() async {
    final doc = _docBackupAtual;
    if (doc == null) {
      throw StateError('Usuário não autenticado.');
    }

    final snap = await doc.get();
    if (!snap.exists) return null;
    final data = snap.data();
    final backup = data?['backupJson'];
    return backup is String && backup.trim().isNotEmpty ? backup : null;
  }

  Future<void> excluirDadosNuvemDoUsuarioAtual() async {
    final user = usuarioAtual;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }

    final appDataRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('app_data');

    final docs = await appDataRef.get();
    for (final doc in docs.docs) {
      await doc.reference.delete();
    }

    await _firestore.collection('users').doc(user.uid).delete();
  }
}
