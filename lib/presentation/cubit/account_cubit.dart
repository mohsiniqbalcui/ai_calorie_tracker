import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/cloud/backup_codec.dart';
import '../../data/cloud/cloud_backend.dart';

class AccountState {
  final bool available;
  final String? email;
  final bool busy;
  final String? message;
  final bool isError;
  final DateTime? lastBackup;

  const AccountState({
    this.available = false,
    this.email,
    this.busy = false,
    this.message,
    this.isError = false,
    this.lastBackup,
  });

  bool get signedIn => email != null;

  AccountState copyWith({
    String? email,
    bool clearEmail = false,
    bool? busy,
    String? message,
    bool isError = false,
    DateTime? lastBackup,
  }) =>
      AccountState(
        available: available,
        email: clearEmail ? null : (email ?? this.email),
        busy: busy ?? this.busy,
        message: message,
        isError: isError,
        lastBackup: lastBackup ?? this.lastBackup,
      );
}

class AccountCubit extends Cubit<AccountState> {
  final CloudBackend backend;
  final SharedPreferences prefs;
  static const _lastBackupKey = 'last_cloud_backup';

  /// Called after a restore so the screens reload what they show.
  final void Function()? onRestored;

  AccountCubit(this.backend, this.prefs, {this.onRestored})
      : super(AccountState(
          available: backend.available,
          email: backend.email,
          lastBackup: DateTime.tryParse(prefs.getString(_lastBackupKey) ?? ''),
        ));

  static String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address does not look right.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password is wrong.';
        case 'email-already-in-use':
          return 'An account with this email already exists. Sign in instead.';
        case 'weak-password':
          return 'Choose a password with at least 6 characters.';
        case 'network-request-failed':
          return 'No internet connection. Try again when you are online.';
        case 'too-many-requests':
          return 'Too many attempts. Wait a moment and try again.';
      }
    }
    return 'Something went wrong. Check your connection and try again.';
  }

  Future<void> _run(Future<void> Function() action,
      {String? success, bool signedInAfter = false}) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      await action();
      emit(state.copyWith(
          busy: false,
          message: success,
          email: signedInAfter ? backend.email : null));
    } catch (e) {
      emit(state.copyWith(
          busy: false, message: friendlyError(e), isError: true));
    }
  }

  Future<void> signIn(String email, String password) => _run(
      () => backend.signIn(email, password),
      success: 'Signed in.',
      signedInAfter: true);

  Future<void> register(String email, String password) => _run(
      () => backend.register(email, password),
      success: 'Account created.',
      signedInAfter: true);

  Future<void> resetPassword(String email) => _run(
      () => backend.resetPassword(email),
      success: 'Password reset email sent.');

  Future<void> signOut() async {
    await _run(backend.signOut);
    if (!state.isError) emit(state.copyWith(clearEmail: true, message: 'Signed out.'));
  }

  Future<void> backUp() => _run(() async {
        await backend.upload(BackupCodec.encode(prefs));
        final now = DateTime.now();
        await prefs.setString(_lastBackupKey, now.toIso8601String());
        emit(state.copyWith(lastBackup: now));
      }, success: 'Backed up.');

  Future<void> restore() async {
    var found = true;
    await _run(() async {
      final data = await backend.download();
      if (data == null) {
        found = false;
        return;
      }
      await BackupCodec.restore(prefs, data);
      onRestored?.call();
    });
    if (state.isError) return;
    emit(state.copyWith(
        message: found
            ? 'Restored your backup. Restart the app to apply every setting.'
            : 'No backup found for this account yet.'));
  }
}
