import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/providers.dart';
import '../main.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _changingPw = false;
  String? _pwError;
  String? _pwSuccess;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final current = _currentPassword.text;
    final newPw = _newPassword.text;
    final confirm = _confirmPassword.text;

    if (current.isEmpty || newPw.isEmpty) {
      setState(() {
        _pwError = 'All fields are required.';
        _pwSuccess = null;
      });
      return;
    }
    if (newPw.length < 6) {
      setState(() {
        _pwError = 'New password must be at least 6 characters.';
        _pwSuccess = null;
      });
      return;
    }
    if (newPw != confirm) {
      setState(() {
        _pwError = 'Passwords do not match.';
        _pwSuccess = null;
      });
      return;
    }

    setState(() {
      _changingPw = true;
      _pwError = null;
      _pwSuccess = null;
    });

    try {
      await ref.read(authStateNotifierProvider.notifier).changePassword(
            currentPassword: current,
            newPassword: newPw,
          );
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      setState(() => _pwSuccess = 'Password changed successfully.');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) {
        setState(() => _pwError = 'Current password is incorrect.');
      } else {
        setState(() => _pwError = 'Failed to change password.');
      }
    } catch (e) {
      setState(() => _pwError = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _changingPw = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final authState = ref.watch(authStateNotifierProvider);
    if (!authState.isAuthed) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = authState.user!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Profile',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: text.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user.name,
                    style: text.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    user.email,
                    style: text.bodyMedium?.copyWith(
                      color: colors.mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _capitalize(user.role),
                      style: text.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Divider(color: colors.border),
                const SizedBox(height: 16),
                Text(
                  'Change Password',
                  style: text.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _PwField(
                  label: 'Current Password',
                  controller: _currentPassword,
                ),
                const SizedBox(height: 10),
                _PwField(
                  label: 'New Password',
                  controller: _newPassword,
                ),
                const SizedBox(height: 10),
                _PwField(
                  label: 'Confirm New Password',
                  controller: _confirmPassword,
                ),
                const SizedBox(height: 12),
                if (_pwError != null) ...[
                  Text(
                    _pwError!,
                    style: text.bodySmall?.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_pwSuccess != null) ...[
                  Text(
                    _pwSuccess!,
                    style: text.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                ElevatedButton(
                  onPressed: _changingPw ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _changingPw
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
                const SizedBox(height: 32),
                Divider(color: colors.border),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authStateNotifierProvider.notifier).logout();
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'UniTrack v1.0.0',
                    style: text.labelSmall?.copyWith(
                      color: colors.mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _PwField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _PwField({required this.label, required this.controller});

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
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: true,
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
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
