import 'package:flutter/material.dart';
import '../controllers/demanda_controller.dart';
import '../services/auth_service.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _carregando = false;
  bool _obscureSenha = true;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
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
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(controller: widget.controller),
        ),
      );
    } on Exception catch (e) {
      _mostrarMensagem(_traduzirErro(e.toString()), erro: true);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _criarConta() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.length < 6) {
      _mostrarMensagem('Para criar conta, informe e-mail e senha com 6+ caracteres.', erro: true);
      return;
    }

    setState(() => _carregando = true);
    try {
      await _authService.criarContaComEmailSenha(email: email, senha: senha);
      _mostrarMensagem('Conta criada com sucesso. Entrando...');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(controller: widget.controller),
        ),
      );
    } on Exception catch (e) {
      _mostrarMensagem(_traduzirErro(e.toString()), erro: true);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _esqueciSenha() async {
    final controller = TextEditingController(text: _emailController.text.trim());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar acesso'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Seu e-mail',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = controller.text.trim();
              if (email.isEmpty) {
                _mostrarMensagem('Informe o e-mail para recuperar a senha.', erro: true);
                return;
              }

              try {
                await _authService.enviarRecuperacaoSenha(email);
                if (!mounted) return;
                Navigator.pop(ctx);
                final emailMascarado = _authService.mascararEmail(email);
                _mostrarMensagem('E-mail de recuperação enviado para $emailMascarado.');
              } on Exception catch (e) {
                _mostrarMensagem(_traduzirErro(e.toString()), erro: true);
              }
            },
            child: const Text('Enviar recuperação'),
          ),
        ],
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
                    const Text(
                      'Acesso Seguro',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Entre com seu e-mail para proteger e recuperar seus dados.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.alternate_email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _senhaController,
                      obscureText: _obscureSenha,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.password),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
                          icon: Icon(_obscureSenha ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _esqueciSenha,
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _carregando ? null : _entrar,
                        icon: _carregando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.login),
                        label: const Text('Entrar'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _carregando ? null : _criarConta,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Criar conta'),
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
