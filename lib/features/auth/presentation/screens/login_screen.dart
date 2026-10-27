import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_button.dart';
import '../../providers/session_provider.dart';

/// Standalone login screen — independent from Dad-mobile's session (see
/// Dad-mobile/CALL_RECORDING_PLAN.md's "Auth" decision: no deep-link handoff
/// for Phase 1, just the same `POST /api/auth/login` contract). Kept as one
/// file rather than splitting into a separate `login_form.dart` widget
/// like Dad-mobile does — this app's form has no shared reuse to justify
/// that split.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(sessionControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionControllerProvider);
    final isLoading = sessionState.isLoading;

    ref.listen(sessionControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: kBrandSurface,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.mic_none_outlined, size: 40, color: kBrandColor),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                  const SizedBox(height: 20),
                  Text(
                    'PypeCRM Helper',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.15),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in with your PypeCRM account',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.15),
                  const SizedBox(height: 36),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Email is required' : null,
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.15),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Password is required' : null,
                    onFieldSubmitted: (_) => isLoading ? null : _submit(),
                  ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.15),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Sign in',
                    loading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
