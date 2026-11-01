import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../cubit/account_cubit.dart';
import '../cubit/food_log_cubit.dart';

/// Sign in, back up and restore. Everything else in the app works without it.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _when(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Account and backup')),
      body: BlocConsumer<AccountCubit, AccountState>(
        listenWhen: (a, b) => b.message != null && a.message != b.message,
        listener: (context, s) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(s.message!)));
          if (s.message!.startsWith('Restored')) {
            context.read<FoodLogCubit>().loadDailyLog();
          }
        },
        builder: (context, s) {
          if (!s.available) {
            return Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Text(
                'Cloud backup is not set up in this build yet. Your data stays on this phone.',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: [
              if (s.signedIn) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_circle_outlined, size: 40),
                  title: Text(s.email!),
                  subtitle: Text(s.lastBackup == null
                      ? 'Not backed up yet'
                      : 'Last backup ${_when(s.lastBackup!)}'),
                ),
                const SizedBox(height: Spacing.md),
                FilledButton.icon(
                  onPressed: s.busy ? null : context.read<AccountCubit>().backUp,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Back up now'),
                ),
                const SizedBox(height: Spacing.sm),
                OutlinedButton.icon(
                  onPressed: s.busy ? null : () => _confirmRestore(context),
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('Restore from backup'),
                ),
                const SizedBox(height: Spacing.sm),
                TextButton(
                  onPressed: s.busy ? null : context.read<AccountCubit>().signOut,
                  child: const Text('Sign out'),
                ),
              ] else
                Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Keep your food log safe and move it to a new phone.',
                          style: theme.textTheme.bodyLarge),
                      const SizedBox(height: Spacing.lg),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) => v != null && v.contains('@')
                            ? null
                            : 'Enter a valid email',
                      ),
                      const SizedBox(height: Spacing.md),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        decoration: const InputDecoration(labelText: 'Password'),
                        validator: (v) => v != null && v.length >= 6
                            ? null
                            : 'At least 6 characters',
                      ),
                      const SizedBox(height: Spacing.lg),
                      FilledButton(
                        onPressed: s.busy ? null : () => _submit(context, false),
                        child: s.busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Sign in'),
                      ),
                      const SizedBox(height: Spacing.sm),
                      OutlinedButton(
                        onPressed: s.busy ? null : () => _submit(context, true),
                        child: const Text('Create account'),
                      ),
                      TextButton(
                        onPressed: s.busy ? null : () => _reset(context),
                        child: const Text('Forgot password?'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: Spacing.lg),
              Text(
                'Backups include your food log, water, weight, favourites and settings. They are tied to your account and nobody else can read them.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submit(BuildContext context, bool create) {
    if (!_form.currentState!.validate()) return;
    final cubit = context.read<AccountCubit>();
    create
        ? cubit.register(_email.text, _password.text)
        : cubit.signIn(_email.text, _password.text);
  }

  void _reset(BuildContext context) {
    if (!_email.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter your email above first.')));
      return;
    }
    context.read<AccountCubit>().resetPassword(_email.text);
  }

  Future<void> _confirmRestore(BuildContext context) async {
    final cubit = context.read<AccountCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
            'This replaces the data on this phone with your last backup.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore')),
        ],
      ),
    );
    if (ok == true) cubit.restore();
  }
}
