import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/demanda_controller.dart';
import '../services/auth_service.dart';
import '../services/login_preferences_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final DemandaController controller;

  const LoginScreen({super.key, required this.controller});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final LoginPreferencesService _loginPrefsService = LoginPreferencesService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController = TextEditingController();
  final FocusNode _senhaFocusNode = FocusNode();

  bool _carregando = false;
  bool _obscureSenha = true;
  bool _obscureConfirmarSenha = true;
  bool _modoCriarConta = false;
  bool _lembrarEmail = true;
  bool _lembrarSenha = false;
  bool _exigirLoginAoAbrir = true;
  bool _autofillNativoAtivo = false;

  @override
  void initState() {
    super.initState();
    _carregarPreferenciasLogin();
  }

  Future<void> _carregarPreferenciasLogin() async {
    final loginPrefs = await _loginPrefsService.carregar();
    if (!mounted) return;

    setState(() {
      _lembrarEmail = loginPrefs.lembrarEmail;
      _lembrarSenha = loginPrefs.lembrarSenha;
      _exigirLoginAoAbrir = loginPrefs.exigirLoginAoAbrir;
      _autofillNativoAtivo = loginPrefs.autofillNativoAtivo;
      if (loginPrefs.lembrarEmail && loginPrefs.emailSalvo.isNotEmpty) {
        _emailController.text = loginPrefs.emailSalvo;
      }
      if (loginPrefs.lembrarSenha && loginPrefs.senhaSalva.isNotEmpty) {
        _senhaController.text = loginPrefs.senhaSalva;
      }
    });
  }

  Future<void> _salvarPreferenciasLogin(String email) async {
    await _loginPrefsService.salvar(
      lembrarEmail: _lembrarEmail,
      lembrarSenha: _lembrarSenha,
      email: email,
      senha: _senhaController.text,
      exigirLoginAoAbrir: _exigirLoginAoAbrir,
      autofillNativoAtivo: _autofillNativoAtivo,
    );
  }

  Future<void> _limparDadosSalvosLogin() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar dados salvos?'),
        content: const Text(
          'Isso vai remover e-mail e senha salvos neste aparelho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await _loginPrefsService.limparDadosSalvosLogin();
    TextInput.finishAutofillContext(shouldSave: false);
    if (!mounted) return;

    setState(() {
      _lembrarEmail = true;
      _lembrarSenha = false;
      _exigirLoginAoAbrir = true;
      _autofillNativoAtivo = false;
      _emailController.clear();
      _senhaController.clear();
    });

    _mostrarMensagem('Dados salvos de login foram removidos deste aparelho.');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _senhaFocusNode.dispose();
    super.dispose();
  }

  void _focarSenhaParaEdicao() {
    if (!mounted) return;
    _senhaFocusNode.requestFocus();
    _senhaController.selection = TextSelection.collapsed(
      offset: _senhaController.text.length,
    );
  }

  Future<void> _entrar() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      _mostrarMensagem('Informe e-mail e senha.', erro: true);
      return;
    }

    setState(() => _carregando = true);
    try {
      await _authService.entrarComEmailSenha(email: email, senha: senha);
      await _salvarPreferenciasLogin(email);
      TextInput.finishAutofillContext(shouldSave: false);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(controller: widget.controller),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _focarSenhaParaEdicao();
      _mostrarMensagem(_traduzirCodigoFirebase(e.code), erro: true);
    } on Exception catch (e) {
      _focarSenhaParaEdicao();
      _mostrarMensagem(_traduzirErro(e.toString()), erro: true);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _criarConta() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confirmarSenha = _confirmarSenhaController.text;

    if (email.isEmpty) {
      _mostrarMensagem('Informe seu e-mail.', erro: true);
      return;
    }

    if (!_emailValido(email)) {
      _mostrarMensagem('E-mail inválido.', erro: true);
      return;
    }

    if (senha.length < 6) {
      _mostrarMensagem('Senha deve ter no mínimo 6 caracteres.', erro: true);
      return;
    }

    if (senha != confirmarSenha) {
      _mostrarMensagem('As senhas não conferem.', erro: true);
      return;
    }

    setState(() => _carregando = true);
    try {
      await _authService.criarContaComEmailSenha(email: email, senha: senha);
      await _salvarPreferenciasLogin(email);
      TextInput.finishAutofillContext(shouldSave: false);
      _mostrarMensagem('Conta criada com sucesso. Entrando...');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(controller: widget.controller),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _mostrarMensagem(_traduzirCodigoFirebase(e.code), erro: true);
    } on Exception catch (e) {
      _mostrarMensagem(_traduzirErro(e.toString()), erro: true);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _esqueciSenha() async {
    final controller = TextEditingController(text: _emailController.text.trim());
    bool emailValido = _emailValido(controller.text.trim());

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Recuperar acesso'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              setDialogState(() {
                emailValido = _emailValido(value.trim());
              });
            },
            decoration: InputDecoration(
              labelText: 'Seu e-mail',
              helperText: 'Confira tambem as pastas Spam e Lixo eletronico.',
              errorText: controller.text.trim().isEmpty || emailValido
                  ? null
                  : 'Digite um e-mail valido.',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: emailValido && controller.text.trim().isNotEmpty
                  ? () async {
                      final email = controller.text.trim();
                      try {
                        await _authService.enviarRecuperacaoSenha(email);
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        _mostrarMensagem(
                          'Se este e-mail estiver cadastrado, voce recebera as instrucoes de recuperacao em instantes.',
                        );
                      } on FirebaseAuthException catch (e) {
                        _mostrarMensagem(_traduzirCodigoFirebase(e.code), erro: true);
                      } on Exception catch (e) {
                        _mostrarMensagem(_traduzirErro(e.toString()), erro: true);
                      }
                    }
                  : null,
              child: const Text('Enviar recuperação'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
  }

  void _mostrarMensagem(String msg, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: erro ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _emailValido(String email) {
    final pattern =
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    final regExp = RegExp(pattern);
    return regExp.hasMatch(email);
  }

  String _traduzirCodigoFirebase(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'E-mail ou senha inválidos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado. Faça login.';
      case 'weak-password':
        return 'Senha muito fraca. Use no mínimo 6 caracteres.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'operation-not-allowed':
        return 'Login por e-mail não está ativado. Contate o suporte.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      default:
        return 'Erro: $code. Tente novamente.';
    }
  }

  String _traduzirErro(String raw) {
    final msg = raw.toLowerCase();
    if (msg.contains('invalid-credential')) return 'E-mail ou senha inválidos.';
    if (msg.contains('email-already-in-use')) return 'Este e-mail já está em uso.';
    if (msg.contains('weak-password')) return 'Senha fraca. Use no mínimo 6 caracteres.';
    if (msg.contains('invalid-email')) return 'E-mail inválido.';
    if (msg.contains('too-many-requests')) return 'Muitas tentativas. Tente novamente depois.';
    if (msg.contains('network-request-failed')) return 'Sem conexão com a internet.';
    return 'Não foi possível concluir a operação. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_person, size: 56, color: AppTheme.primaryColor),
                    const SizedBox(height: 12),
                    Text(
                      _modoCriarConta ? 'Criar Conta' : 'Acesso Seguro',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _modoCriarConta
                          ? 'Crie uma conta para proteger seus dados.'
                          : 'Entre com seu e-mail para acessar.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Toggle entre Login e Criar Conta
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                label: Text('Login'),
                                icon: Icon(Icons.login),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('Criar'),
                                icon: Icon(Icons.person_add),
                              ),
                            ],
                            selected: {_modoCriarConta},
                            onSelectionChanged: (value) {
                              setState(() {
                                _modoCriarConta = value.first;
                                _emailController.clear();
                                _senhaController.clear();
                                _confirmarSenhaController.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // E-mail
                    AutofillGroup(
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: null,
                            enableSuggestions: false,
                            autocorrect: false,
                            selectAllOnFocus: false,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.alternate_email),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Senha
                          TextField(
                            controller: _senhaController,
                            focusNode: _senhaFocusNode,
                            obscureText: _obscureSenha,
                            autofillHints: null,
                            enableSuggestions: false,
                            autocorrect: false,
                            selectAllOnFocus: false,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: const Icon(Icons.password),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscureSenha = !_obscureSenha),
                                icon: Icon(
                                  _obscureSenha
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Confirmar Senha (apenas em modo Criar Conta)
                    if (_modoCriarConta) ...[
                      TextField(
                        controller: _confirmarSenhaController,
                        obscureText: _obscureConfirmarSenha,
                        selectAllOnFocus: false,
                        decoration: InputDecoration(
                          labelText: 'Confirmar Senha',
                          prefixIcon: const Icon(Icons.password),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscureConfirmarSenha = !_obscureConfirmarSenha),
                            icon: Icon(_obscureConfirmarSenha
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Botão Esqueci Senha (apenas em modo Login)
                    if (!_modoCriarConta)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _esqueciSenha,
                          child: const Text('Esqueci minha senha'),
                        ),
                      ),
                      CheckboxListTile(
                        value: _lembrarEmail,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Lembrar e-mail neste aparelho'),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _lembrarEmail = value;
                            if (!_lembrarEmail) {
                              _lembrarSenha = false;
                            }
                          });
                        },
                      ),
                    if (!_modoCriarConta)
                      CheckboxListTile(
                        value: _lembrarSenha,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Lembrar senha com segurança'),
                        subtitle: const Text(
                          'Salva criptografada neste aparelho.',
                          style: TextStyle(fontSize: 12),
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _lembrarSenha = value;
                            if (_lembrarSenha) {
                              _lembrarEmail = true;
                            }
                          });
                        },
                      ),
                    if (!_modoCriarConta)
                      CheckboxListTile(
                        value: _exigirLoginAoAbrir,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Pedir login ao abrir o app'),
                        subtitle: const Text(
                          'Desative para manter acesso automático neste aparelho.',
                          style: TextStyle(fontSize: 12),
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _exigirLoginAoAbrir = value);
                        },
                      ),
                    if (!_modoCriarConta)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _limparDadosSalvosLogin,
                          icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                          label: const Text('Limpar dados salvos'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Botão Entrar/Criar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _carregando ? null : (_modoCriarConta ? _criarConta : _entrar),
                        icon: _carregando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(_modoCriarConta ? Icons.person_add : Icons.login),
                        label: Text(_modoCriarConta ? 'Criar Conta' : 'Entrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
