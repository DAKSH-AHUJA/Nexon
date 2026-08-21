import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompanyAccount {
  const CompanyAccount({
    required this.id,
    required this.name,
    required this.accountCode,
    required this.password,
    required this.businessType,
    required this.gst,
  });

  final String id;
  final String name;
  final String accountCode;
  final String password;
  final String businessType;
  final String gst;
}

class AuthState {
  const AuthState({
    this.currentCompany,
    this.errorMessage,
  });

  final CompanyAccount? currentCompany;
  final String? errorMessage;

  bool get isAuthenticated => currentCompany != null;

  AuthState copyWith({
    CompanyAccount? currentCompany,
    String? errorMessage,
    bool clearCompany = false,
    bool clearError = false,
  }) {
    return AuthState(
      currentCompany:
          clearCompany ? null : (currentCompany ?? this.currentCompany),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

const companyAccounts = [
  CompanyAccount(
    id: 'rajesh-trading-company',
    name: 'Rajesh Trading Company',
    accountCode: 'rajesh',
    password: '12345',
    businessType: 'Wholesale Vegetable Trading',
    gst: 'GSTIN not configured',
  ),
  CompanyAccount(
    id: 'fresh-mart-wholesale',
    name: 'Fresh Mart Wholesale',
    accountCode: 'freshmart',
    password: 'demo123',
    businessType: 'Vegetable Wholesale Buyer',
    gst: '29AABCF1234Z1Z5',
  ),
  CompanyAccount(
    id: 'city-super-bazaar',
    name: 'City Super Bazaar',
    accountCode: 'citybazaar',
    password: 'demo123',
    businessType: 'Retail Grocery Chain',
    gst: '29DDDEI3456Z4Z8',
  ),
];

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  List<CompanyAccount> get accounts => companyAccounts;

  bool login({required String accountCode, required String password}) {
    final normalizedCode = accountCode.trim().toLowerCase();
    final company = companyAccounts.where((account) {
      return account.accountCode.toLowerCase() == normalizedCode ||
          account.name.toLowerCase() == normalizedCode;
    }).firstOrNull;

    if (company == null || company.password != password) {
      state =
          const AuthState(errorMessage: 'Invalid company account or password.');
      return false;
    }

    state = AuthState(currentCompany: company);
    return true;
  }

  void logout() => state = const AuthState();
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
