import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompanyAccount {
  const CompanyAccount({
    required this.id,
    required this.name,
    required this.accountCode,
    required this.passwordDigest,
    required this.businessType,
    required this.gst,
  });

  final String id;
  final String name;
  final String accountCode;
  final String passwordDigest;
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
    passwordDigest:
        '5994471abb01112afcc18159f6cc74b4f511b99806da59b3caf5a9c173cacfc5',
    businessType: 'Wholesale Vegetable Trading',
    gst: 'GSTIN not configured',
  ),
  CompanyAccount(
    id: 'fresh-mart-wholesale',
    name: 'Fresh Mart Wholesale',
    accountCode: 'freshmart',
    passwordDigest:
        'd3ad9315b7be5dd53b31a273b3b3aba5defe700808305aa16a3062b76658a791',
    businessType: 'Vegetable Wholesale Buyer',
    gst: '29AABCF1234Z1Z5',
  ),
  CompanyAccount(
    id: 'city-super-bazaar',
    name: 'City Super Bazaar',
    accountCode: 'citybazaar',
    passwordDigest:
        'd3ad9315b7be5dd53b31a273b3b3aba5defe700808305aa16a3062b76658a791',
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
    final passwordDigest = sha256.convert(utf8.encode(password)).toString();

    if (company == null ||
        !_constantTimeEquals(passwordDigest, company.passwordDigest)) {
      state =
          const AuthState(errorMessage: 'Invalid company account or password.');
      return false;
    }

    state = AuthState(currentCompany: company);
    return true;
  }

  void logout() => state = const AuthState();
}

bool _constantTimeEquals(String left, String right) {
  if (left.length != right.length) return false;

  var difference = 0;
  for (var i = 0; i < left.length; i++) {
    difference |= left.codeUnitAt(i) ^ right.codeUnitAt(i);
  }
  return difference == 0;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
