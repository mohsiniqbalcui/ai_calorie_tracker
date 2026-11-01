import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calorie_lens/data/cloud/backup_codec.dart';
import 'package:calorie_lens/data/cloud/cloud_backend.dart';
import 'package:calorie_lens/presentation/cubit/account_cubit.dart';

class FakeBackend implements CloudBackend {
  @override
  bool available = true;
  @override
  String? email;
  Map<String, dynamic>? stored;
  bool failNext = false;

  void _maybeFail() {
    if (failNext) {
      failNext = false;
      throw Exception('offline');
    }
  }

  @override
  Future<void> signIn(String e, String p) async {
    _maybeFail();
    email = e;
  }

  @override
  Future<void> register(String e, String p) async => email = e;
  @override
  Future<void> resetPassword(String e) async {}
  @override
  Future<void> signOut() async => email = null;
  @override
  Future<void> upload(Map<String, dynamic> data) async {
    _maybeFail();
    stored = data;
  }

  @override
  Future<Map<String, dynamic>?> download() async => stored;
}

void main() {
  late SharedPreferences prefs;
  late FakeBackend backend;
  late AccountCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'water_2026-11-01': 500,
      'weight_log': '[{"w":70}]',
      'onboarding_draft_name': 'skip me',
      'flag': true,
    });
    prefs = await SharedPreferences.getInstance();
    backend = FakeBackend();
    cubit = AccountCubit(backend, prefs);
  });

  test('codec leaves out device-only keys', () {
    final values = BackupCodec.encode(prefs)['values'] as Map;
    expect(values.keys, containsAll(['water_2026-11-01', 'weight_log', 'flag']));
    expect(values.containsKey('onboarding_draft_name'), isFalse);
  });

  test('sign in sets the email and sign out clears it', () async {
    await cubit.signIn('a@b.com', 'secret1');
    expect(cubit.state.signedIn, isTrue);
    expect(cubit.state.email, 'a@b.com');
    await cubit.signOut();
    expect(cubit.state.signedIn, isFalse);
  });

  test('failed sign in shows a friendly error and stays signed out', () async {
    backend.failNext = true;
    await cubit.signIn('a@b.com', 'secret1');
    expect(cubit.state.isError, isTrue);
    expect(cubit.state.signedIn, isFalse);
    expect(cubit.state.busy, isFalse);
  });

  test('back up then restore on a fresh phone brings data back', () async {
    await cubit.signIn('a@b.com', 'secret1');
    await cubit.backUp();
    expect(cubit.state.lastBackup, isNotNull);

    SharedPreferences.setMockInitialValues({});
    final fresh = await SharedPreferences.getInstance();
    final other = AccountCubit(backend, fresh);
    await other.restore();
    expect(fresh.getInt('water_2026-11-01'), 500);
    expect(fresh.getString('weight_log'), '[{"w":70}]');
    expect(fresh.getBool('flag'), isTrue);
    expect(other.state.isError, isFalse);
  });

  test('restore with no backup says so and changes nothing', () async {
    await cubit.signIn('a@b.com', 'secret1');
    await cubit.restore();
    expect(cubit.state.message, contains('No backup'));
    expect(prefs.getInt('water_2026-11-01'), 500);
  });

  test('upload failure does not record a backup time', () async {
    await cubit.signIn('a@b.com', 'secret1');
    backend.failNext = true;
    await cubit.backUp();
    expect(cubit.state.isError, isTrue);
    expect(cubit.state.lastBackup, isNull);
  });

  test('unavailable backend is reported', () {
    backend.available = false;
    expect(AccountCubit(backend, prefs).state.available, isFalse);
  });
}
