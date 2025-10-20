import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/parent_nav.dart';

class AuthPage extends StatefulWidget {
  final String role; // "child" или "parent"
  const AuthPage({super.key, required this.role});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isRegister = false;
  bool _loading = false;
  bool _obscure = true;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  void _toggleMode() => setState(() => _isRegister = !_isRegister);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final auth = FirebaseAuth.instance;
      late UserCredential cred;

      if (_isRegister) {
        cred = await auth.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );

        final user = cred.user!;
        await user.updateDisplayName(_nameCtrl.text.trim());

        if (widget.role == 'child') {
          await FirebaseDatabase.instance.ref('users/${user.uid}').set({
            'uid': user.uid,
            'name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'role': 'child',
            'pocket': 0,
            'balance': 0,
            'createdAt': DateTime.now().toIso8601String(),
          });
        } else {
          await FirebaseDatabase.instance.ref('parent/${user.uid}').set({
            'uid': user.uid,
            'name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'role': 'parent',
            'children': {},
            'pocket': 0,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      } else {
        cred = await auth.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      }

      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 300));

      if (widget.role == 'parent') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ParentNavWrapper()),
              (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ImageBottomNav()),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Ошибка авторизации')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isParent = widget.role == 'parent';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              Container(
                width: double.infinity,
                height: 160,
                decoration: const BoxDecoration(
                  color: Color(0xFFB6FF3B),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(60),
                    bottomRight: Radius.circular(60),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(45),
                        child: Image.asset(
                          'assets/33.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),

              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _isRegister
                          ? (isParent ? 'Регистрация родителя' : 'Регистрация ребёнка')
                          : (isParent ? 'Вход родителя' : 'Вход ребёнка'),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegister
                          ? 'Создайте свой аккаунт, чтобы начать 🌿'
                          : 'Войдите в свой аккаунт',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // 🔹 Форма входа
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_isRegister)
                            Column(
                              children: [
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    labelText: 'Ваше имя',
                                    prefixIcon: const Icon(Icons.person_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  validator: (v) =>
                                  v == null || v.trim().length < 2 ? 'Введите имя' : null,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            validator: (v) =>
                            v == null || !v.contains('@') ? 'Введите корректный email' : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              labelText: 'Пароль (6+ символов)',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            validator: (v) =>
                            v == null || v.length < 6 ? 'Минимум 6 символов' : null,
                          ),
                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Забыли пароль?',
                                style: TextStyle(
                                  color: Color(0xFFB6FF3B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          _loading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              _isRegister ? 'Создать аккаунт' : 'Войти',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextButton(
                            onPressed: _toggleMode,
                            child: Text(
                              _isRegister
                                  ? 'Уже есть аккаунт? Войти'
                                  : 'Нет аккаунта? Зарегистрироваться',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
