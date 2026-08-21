import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nexon_erp/app.dart';

void main() {
  testWidgets('Nexon app shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NexonApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
