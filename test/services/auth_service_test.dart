import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/services/auth_service.dart';

void main() {
  group('AuthState', () {
    test('is unauthenticated by default', () {
      const state = AuthState();

      expect(state.isAuthenticated, isFalse);
      expect(state.currentCompany, isNull);
      expect(state.errorMessage, isNull);
    });

    test('copyWith keeps existing values when nothing is passed', () {
      final state = AuthState(
        currentCompany: companyAccounts.first,
        errorMessage: 'boom',
      );
      final copy = state.copyWith();

      expect(copy.currentCompany, companyAccounts.first);
      expect(copy.errorMessage, 'boom');
      expect(copy.isAuthenticated, isTrue);
    });

    test('copyWith clears the company and the error on request', () {
      final state = AuthState(
        currentCompany: companyAccounts.first,
        errorMessage: 'boom',
      );

      expect(state.copyWith(clearCompany: true).currentCompany, isNull);
      expect(state.copyWith(clearCompany: true).isAuthenticated, isFalse);
      expect(state.copyWith(clearError: true).errorMessage, isNull);
    });

    test('copyWith overrides provided values', () {
      const state = AuthState();
      final updated = state.copyWith(currentCompany: companyAccounts.last);

      expect(updated.currentCompany, companyAccounts.last);
      expect(updated.isAuthenticated, isTrue);
    });
  });

  group('AuthNotifier.login', () {
    late AuthNotifier notifier;

    setUp(() => notifier = AuthNotifier());
    tearDown(() => notifier.dispose());

    test('exposes the demo accounts', () {
      expect(notifier.accounts, companyAccounts);
      expect(notifier.accounts, isNotEmpty);
    });

    test('authenticates with a matching account code and password', () {
      final result =
          notifier.login(accountCode: 'rajesh', password: '12345');

      expect(result, isTrue);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.currentCompany?.id, 'rajesh-trading-company');
      expect(notifier.state.errorMessage, isNull);
    });

    test('accepts the company name as the account code', () {
      final result = notifier.login(
        accountCode: 'Fresh Mart Wholesale',
        password: 'demo123',
      );

      expect(result, isTrue);
      expect(notifier.state.currentCompany?.accountCode, 'freshmart');
    });

    test('normalizes case and surrounding whitespace', () {
      final result =
          notifier.login(accountCode: '  RaJesh  ', password: '12345');

      expect(result, isTrue);
      expect(notifier.state.currentCompany?.accountCode, 'rajesh');
    });

    test('rejects an unknown account code', () {
      final result =
          notifier.login(accountCode: 'nobody', password: '12345');

      expect(result, isFalse);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(
        notifier.state.errorMessage,
        'Invalid company account or password.',
      );
    });

    test('rejects a wrong password', () {
      final result =
          notifier.login(accountCode: 'rajesh', password: 'wrong');

      expect(result, isFalse);
      expect(notifier.state.currentCompany, isNull);
      expect(notifier.state.errorMessage, isNotNull);
    });

    test('password comparison is case sensitive', () {
      expect(
        notifier.login(accountCode: 'freshmart', password: 'DEMO123'),
        isFalse,
      );
    });

    test('clears a previous error after a successful login', () {
      notifier.login(accountCode: 'rajesh', password: 'wrong');
      expect(notifier.state.errorMessage, isNotNull);

      notifier.login(accountCode: 'rajesh', password: '12345');

      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.isAuthenticated, isTrue);
    });
  });

  group('AuthNotifier.logout', () {
    test('resets the state', () {
      final notifier = AuthNotifier()
        ..login(accountCode: 'rajesh', password: '12345');

      notifier.logout();

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.currentCompany, isNull);
      expect(notifier.state.errorMessage, isNull);
      notifier.dispose();
    });
  });

  group('companyAccounts', () {
    test('account codes are unique', () {
      final codes = companyAccounts.map((a) => a.accountCode).toList();

      expect(codes.toSet(), hasLength(codes.length));
    });
  });
}
