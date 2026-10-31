import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../cubit/reminders_cubit.dart';
import '../widgets/common.dart';

/// Turn the daily meal reminders on or off and choose when they fire.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  Future<void> _toggle(BuildContext context, ReminderConfig r, bool on) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<RemindersCubit>().setEnabled(r.key, on);
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text(
              'Notifications are off for Calorie Lens. Enable them in Settings.'),
          action: SnackBarAction(
              label: 'Open Settings', onPressed: openAppSettings),
        ));
    }
  }

  Future<void> _pickTime(BuildContext context, ReminderConfig r) async {
    final cubit = context.read<RemindersCubit>();
    final picked = await showTimePicker(context: context, initialTime: r.time);
    if (picked != null) await cubit.setTime(r.key, picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reminders = context.watch<RemindersCubit>().state;
    final gutter = Spacing.pageGutter(MediaQuery.of(context).size.width);
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 32),
        children: [
          Text(
            'Gentle nudges to log your meals. They are scheduled on this device and work offline.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          for (final r in reminders)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(r.icon, color: theme.colorScheme.primary)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.label,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          TextButton(
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 32),
                                alignment: Alignment.centerLeft),
                            onPressed: () => _pickTime(context, r),
                            child: Text(r.time.format(context),
                                style: theme.textTheme.titleMedium?.copyWith(
                                    color: r.enabled
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                        value: r.enabled,
                        onChanged: (v) => _toggle(context, r, v)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
