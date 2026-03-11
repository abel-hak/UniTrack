import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/providers.dart';
import '../main.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _selectedBatchId;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final confirm = _confirmPassword.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (_selectedBatchId == null) {
      setState(() => _error = 'Please select a batch.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authStateNotifierProvider.notifier).register(
            name: name,
            email: email,
            password: password,
            batchId: _selectedBatchId!,
          );
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      String msg;
      if (status == 409) {
        msg = 'This email is already registered.';
      } else if (status == 400 && data is Map && data['error'] is String) {
        msg = data['error'] as String;
      } else if (status != null) {
        msg = 'Registration failed (HTTP $status).';
      } else {
        msg = 'Network error: ${e.message}';
      }
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final batchesAsync = ref.watch(batchesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Create Account',
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Join UniTrack to manage your academics',
                  style: text.bodyMedium?.copyWith(
                    color: colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _Field(label: 'Full Name', controller: _name),
                const SizedBox(height: 12),
                _Field(label: 'Email', controller: _email),
                const SizedBox(height: 12),
                _Field(
                  label: 'Password',
                  controller: _password,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Confirm Password',
                  controller: _confirmPassword,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                Text(
                  'Batch',
                  style: text.labelMedium?.copyWith(
                    color: colors.mutedForeground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                batchesAsync.when(
                  data: (batches) {
                    if (batches.isEmpty) {
                      return Text(
                        'No batches available.',
                        style: text.bodySmall
                            ?.copyWith(color: colors.mutedForeground),
                      );
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedBatchId,
                        hint: Text(
                          'Select your batch',
                          style: text.bodyMedium
                              ?.copyWith(color: colors.mutedForeground),
                        ),
                        items: batches
                            .map((b) => DropdownMenuItem(
                                  value: b.id,
                                  child: Text(b.displayName),
                                ))
                            .toList(),
                        onChanged: _loading
                            ? null
                            : (v) => setState(() => _selectedBatchId = v),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, __) => Text(
                    'Failed to load batches. Check your connection.',
                    style: text.bodySmall?.copyWith(color: Colors.red.shade700),
                  ),
                ),
                const SizedBox(height: 18),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: text.bodySmall?.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;

  const _Field({
    required this.label,
    required this.controller,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelMedium?.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}
