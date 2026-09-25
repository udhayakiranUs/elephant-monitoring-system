import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/constants/mock_data.dart';
import '../../core/utils/validators.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();

  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthService>();

      final err = await auth.login(
        _user.text.trim(),
        _pass.text,
      );

      if (!mounted) return;

      if (err != null) {
        setState(() {
          _busy = false;
          _error = err;
        });
        return;
      }

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.homeFor(auth.user!.role),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _busy = false;
        _error = 'Login failed. Please try again.';
      });
    }
  }

  void _fill(String username) {
    _user.text = username;
    _pass.text = MockData.demoPassword;

    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.green3,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.green,
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          '🐘',
                          style: TextStyle(
                            fontSize: 34,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // APPLICATION TITLE
                    Text(
                      AppText.appTitle,
                      textAlign: TextAlign.center,
                      style: AppText.heading(
                        size: 22,
                        color: AppColors.green,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      AppText.division,
                      textAlign: TextAlign.center,
                      style: AppText.body(
                        size: 10,
                        color: AppColors.text3,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // USERNAME
                    TextFormField(
                      controller: _user,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          size: 18,
                        ),
                      ),
                      validator: (v) => Validators.required(
                        v,
                        'Username',
                      ),
                    ),

                    const SizedBox(height: 12),

                    // PASSWORD
                    TextFormField(
                      controller: _pass,
                      obscureText: _obscure,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          size: 18,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscure = !_obscure;
                            });
                          },
                        ),
                      ),
                      validator: Validators.password,
                    ),

                    // ERROR MESSAGE
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(
                            alpha: .12,
                          ),
                          border: Border.all(
                            color: AppColors.red2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: AppText.body(
                            size: 12,
                            color: AppColors.red,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // SIGN IN BUTTON
                    ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.bg,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.bg,
                              ),
                            )
                          : Text(
                              'SIGN IN',
                              style: AppText.heading(
                                size: 16,
                                color: AppColors.bg,
                                letterSpacing: 1,
                              ),
                            ),
                    ),

                    // DEMO ACCOUNTS
                    if (ApiConstants.useMock) ...[
                      const SizedBox(height: 26),
                      Text(
                        'DEMO ACCOUNTS '
                        '(password: '
                        '${MockData.demoPassword})',
                        textAlign: TextAlign.center,
                        style: AppText.body(
                          size: 10,
                          color: AppColors.text3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _fill('murugan'),
                              child: const Text(
                                '📱 Field Staff',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _fill('vel'),
                              child: const Text(
                                '🖥 Command',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
