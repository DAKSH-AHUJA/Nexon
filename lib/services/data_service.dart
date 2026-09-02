import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_model.dart';

/// Loads JSON assets from the dummy_data folder.
class JsonDataService {
  Future<Map<String, dynamic>> loadJson(String fileName) async {
    final jsonString =
        await rootBundle.loadString('assets/dummy_data/$fileName');
    final dynamic decoded;
    try {
      decoded = json.decode(jsonString);
    } on FormatException catch (e) {
      throw FormatException('Invalid JSON in $fileName: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected a JSON object in $fileName');
    }
    return decoded;
  }

  /// Loads [fileName] and maps the list stored under [key] into models.
  Future<List<T>> loadList<T>(
    String fileName,
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final data = await loadJson(fileName);
    return (data[key] as List<dynamic>)
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
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
