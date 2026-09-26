import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:cratetrack_ng/core/auth/auth_repository.dart';

void main() {
  late Directory tempDir;
  late AuthRepository authRepository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cratetrack_auth_test');
    authRepository = AuthRepository();
    await authRepository.init(testDirectoryPath: tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('a new user is not logged in until they sign up or log in', () {
    expect(authRepository.isLoggedIn(), isFalse);
    expect(authRepository.currentUser, isNull);
  });

  test('signUp creates an account and logs the user in', () async {
    final user = await authRepository.signUp(
      businessName: 'Ade Produce Logistics',
      email: 'Ade@Example.com',
      password: 'password123',
    );

    expect(user.businessName, 'Ade Produce Logistics');
    expect(user.email, 'ade@example.com');
    expect(authRepository.isLoggedIn(), isTrue);
    expect(authRepository.currentUser?.email, 'ade@example.com');
  });

  test('signUp rejects a duplicate email', () async {
    await authRepository.signUp(businessName: 'Biz One', email: 'dupe@example.com', password: 'password123');

    expect(
      () => authRepository.signUp(businessName: 'Biz Two', email: 'dupe@example.com', password: 'another123'),
      throwsA(isA<AuthException>()),
    );
  });

  test('signUp rejects a short password', () async {
    expect(
      () => authRepository.signUp(businessName: 'Biz', email: 'short@example.com', password: '123'),
      throwsA(isA<AuthException>()),
    );
  });

  test('logIn succeeds with correct credentials and fails with the wrong password', () async {
    await authRepository.signUp(businessName: 'Biz', email: 'user@example.com', password: 'correcthorse');
    await authRepository.logOut();
    expect(authRepository.isLoggedIn(), isFalse);

    final user = await authRepository.logIn(email: 'user@example.com', password: 'correcthorse');
    expect(user.email, 'user@example.com');
    expect(authRepository.isLoggedIn(), isTrue);

    await authRepository.logOut();
    expect(
      () => authRepository.logIn(email: 'user@example.com', password: 'wrongpassword'),
      throwsA(isA<AuthException>()),
    );
  });

  test('logIn fails for an email with no account', () async {
    expect(
      () => authRepository.logIn(email: 'nobody@example.com', password: 'whatever1'),
      throwsA(isA<AuthException>()),
    );
  });

  test('logOut clears the session but keeps the stored account', () async {
    await authRepository.signUp(businessName: 'Biz', email: 'persist@example.com', password: 'password123');
    await authRepository.logOut();
    expect(authRepository.isLoggedIn(), isFalse);

    final user = await authRepository.logIn(email: 'persist@example.com', password: 'password123');
    expect(user.businessName, 'Biz');
  });
}
