import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/services/data_service.dart';

import '../helpers/fake_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JsonDataService.loadJson', () {
    test('decodes a bundled dummy data file', () async {
      final result = await JsonDataService().loadJson('customers.json');

      expect(result, isA<Map<String, dynamic>>());
      expect(result['customers'], isA<List<dynamic>>());
      expect(result['customers'], isNotEmpty);
    });

    test('throws for a missing asset', () async {
      await expectLater(
        JsonDataService().loadJson('does_not_exist.json'),
        throwsA(anything),
      );
    });
  });

  group('dashboardDataProvider', () {
    test('parses the dashboard payload it loads', () async {
      final service =
          FakeJsonDataService({'dashboard.json': dashboardFixture()});
      final container = ProviderContainer(
        overrides: [jsonDataServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      final data = await container.read(dashboardDataProvider.future);

      expect(service.requestedFiles, ['dashboard.json']);
      expect(data.stats.todaySales, 125000);
      expect(data.stats.todayOrders, 24);
      expect(data.recentBills, isEmpty);
    });

    test('propagates load failures', () async {
      final container = ProviderContainer(
        overrides: [
          jsonDataServiceProvider.overrideWithValue(FakeJsonDataService({})),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(dashboardDataProvider.future),
        throwsStateError,
      );
    });
  });
}
