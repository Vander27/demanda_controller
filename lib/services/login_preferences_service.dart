import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPreferences {
  final bool lembrarEmail;
  final bool lembrarSenha;
  final String emailSalvo;
  final String senhaSalva;
  final bool exigirLoginAoAbrir;
  final bool autofillNativoAtivo;

  const LoginPreferences({
    required this.lembrarEmail,
    required this.lembrarSenha,
    required this.emailSalvo,
    required this.senhaSalva,
    required this.exigirLoginAoAbrir,
    required this.autofillNativoAtivo,
  });
}

class LoginPreferencesService {
  static const String _kLembrarEmail = 'login_lembrar_email_v1';
  static const String _kLembrarSenha = 'login_lembrar_senha_v1';
  static const String _kEmailSalvo = 'login_email_salvo_v1';
  static const String _kExigirLoginAoAbrir = 'login_exigir_ao_abrir_v1';
  static const String _kSenhaSegura = 'login_senha_segura_v1';
  static const String _kAutofillNativoAtivo = 'login_autofill_nativo_ativo_v1';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<LoginPreferences> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final lembrarSenha = prefs.getBool(_kLembrarSenha) ?? false;
    final senhaSalva = lembrarSenha
        ? (await _secureStorage.read(key: _kSenhaSegura) ?? '')
        : '';

    return LoginPreferences(
      lembrarEmail: prefs.getBool(_kLembrarEmail) ?? true,
      lembrarSenha: lembrarSenha,
      emailSalvo: prefs.getString(_kEmailSalvo) ?? '',
      senhaSalva: senhaSalva,
      exigirLoginAoAbrir: prefs.getBool(_kExigirLoginAoAbrir) ?? true,
      autofillNativoAtivo: false,
    );
  }

  Future<void> salvar({
    required bool lembrarEmail,
    required bool lembrarSenha,
    required String email,
    required String senha,
    required bool exigirLoginAoAbrir,
    required bool autofillNativoAtivo,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final lembrarEmailEfetivo = lembrarSenha ? true : lembrarEmail;

    await prefs.setBool(_kLembrarEmail, lembrarEmailEfetivo);
    await prefs.setBool(_kLembrarSenha, lembrarSenha);
    await prefs.setBool(_kExigirLoginAoAbrir, exigirLoginAoAbrir);
    await prefs.setBool(_kAutofillNativoAtivo, false);

    if (lembrarEmailEfetivo && email.trim().isNotEmpty) {
      await prefs.setString(_kEmailSalvo, email.trim());
    } else {
      await prefs.remove(_kEmailSalvo);
    }

    if (lembrarSenha && senha.isNotEmpty) {
      await _secureStorage.write(key: _kSenhaSegura, value: senha);
    } else {
      await _secureStorage.delete(key: _kSenhaSegura);
    }
  }

  Future<void> limparDadosSalvosLogin({bool desativarAutofillNativo = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLembrarEmail);
    await prefs.remove(_kLembrarSenha);
    await prefs.remove(_kEmailSalvo);
    await prefs.remove(_kExigirLoginAoAbrir);
    await prefs.setBool(_kAutofillNativoAtivo, !desativarAutofillNativo);
    await _secureStorage.delete(key: _kSenhaSegura);
  }
}
