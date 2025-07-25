import 'package:flutter/material.dart';
import 'package:leragora/db/database_helper.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      await DatabaseHelper().insertUser(username, password);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário criado com sucesso!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos corretamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null ||
                      !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value)) {
                    return 'E-mail inválido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha'),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Senha deve ter ao menos 6 caracteres';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // salvar usuário
                  }
                },
                child: const Text('Cadastrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
