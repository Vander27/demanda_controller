import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get usuarioAtual => _auth.currentUser;

  Future<UserCredential> entrarComEmailSenha({
    required String email,
    required String senha,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  Future<UserCredential> criarContaComEmailSenha({
    required String email,
    required String senha,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  Future<void> enviarRecuperacaoSenha(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sair() {
    return _auth.signOut();
  }

  Future<void> reautenticarComSenhaAtual(String senhaAtual) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw StateError('Usuário não autenticado.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: senhaAtual,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> excluirContaAtual() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }
    await user.delete();
  }

  String mascararEmail(String email) {
    final valor = email.trim();
    final arroba = valor.indexOf('@');
    if (arroba <= 1) return valor;

    final usuario = valor.substring(0, arroba);
    final dominio = valor.substring(arroba);
    final prefixo = usuario.substring(0, 2);
    return '$prefixo***$dominio';
  }
}
