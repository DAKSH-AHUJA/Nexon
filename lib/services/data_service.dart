import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_model.dart';

/// Loads JSON assets from the dummy_data folder.
class JsonDataService {
  Future<Map<String, dynamic>> loadJson(String fileName) async {
    final jsonString =
        await rootBundle.loadString('assets/dummy_data/$fileName');
    return json.decode(jsonString) as Map<String, dynamic>;
  }
}

final jsonDataServiceProvider = Provider<JsonDataService>((ref) {
  return JsonDataService();
});

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final service = ref.watch(jsonDataServiceProvider);
  final json = await service.loadJson('dashboard.json');
  // Simulate network latency for realistic loading skeleton
  await Future<void>.delayed(const Duration(milliseconds: 800));
  return DashboardData.fromJson(json);
});
