import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/core/utils/responsive.dart';

void main() {
  Future<Responsive> responsiveFor(WidgetTester tester, Size size) async {
    late Responsive responsive;

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size),
        child: Builder(
          builder: (context) {
            responsive = Responsive(context);
            return const SizedBox();
          },
        ),
      ),
    );

    return responsive;
  }

  group('breakpoints', () {
    testWidgets('classifies mobile widths', (tester) async {
      final responsive =
          await responsiveFor(tester, const Size(599, 800));

      expect(responsive.width, 599);
      expect(responsive.height, 800);
      expect(responsive.isMobile, isTrue);
      expect(responsive.isTablet, isFalse);
      expect(responsive.isDesktop, isFalse);
    });

    testWidgets('classifies tablet widths inclusively at 600',
        (tester) async {
      final responsive = await responsiveFor(tester, const Size(600, 900));

      expect(responsive.isMobile, isFalse);
      expect(responsive.isTablet, isTrue);
      expect(responsive.isDesktop, isFalse);
    });

    testWidgets('classifies widths just below the desktop breakpoint as tablet',
        (tester) async {
      final responsive = await responsiveFor(tester, const Size(1279, 900));

      expect(responsive.isTablet, isTrue);
      expect(responsive.isDesktop, isFalse);
    });

    testWidgets('classifies desktop widths inclusively at 1280',
        (tester) async {
      final responsive = await responsiveFor(tester, const Size(1280, 900));

      expect(responsive.isMobile, isFalse);
      expect(responsive.isTablet, isFalse);
      expect(responsive.isDesktop, isTrue);
    });
  });

  group('gridColumns', () {
    testWidgets('grows with the screen size', (tester) async {
      expect((await responsiveFor(tester, const Size(400, 800))).gridColumns, 1);
      expect((await responsiveFor(tester, const Size(800, 800))).gridColumns, 2);
      expect(
        (await responsiveFor(tester, const Size(1400, 900))).gridColumns,
        4,
      );
    });
  });

  group('contentPadding', () {
    testWidgets('grows with the screen size', (tester) async {
      expect(
        (await responsiveFor(tester, const Size(400, 800))).contentPadding,
        16,
      );
      expect(
        (await responsiveFor(tester, const Size(800, 800))).contentPadding,
        24,
      );
      expect(
        (await responsiveFor(tester, const Size(1400, 900))).contentPadding,
        32,
      );
    });
  });

  group('value', () {
    testWidgets('returns the mobile value on mobile', (tester) async {
      final responsive = await responsiveFor(tester, const Size(400, 800));

      expect(
        responsive.value(mobile: 'm', tablet: 't', desktop: 'd'),
        'm',
      );
      expect(responsive.value(mobile: 'm', desktop: 'd'), 'm');
    });

    testWidgets('returns the tablet value on tablet when provided',
        (tester) async {
      final responsive = await responsiveFor(tester, const Size(800, 800));

      expect(responsive.value(mobile: 'm', tablet: 't', desktop: 'd'), 't');
    });

    testWidgets('falls back to the mobile value on tablet without a tablet '
        'value', (tester) async {
      final responsive = await responsiveFor(tester, const Size(800, 800));

      expect(responsive.value(mobile: 'm', desktop: 'd'), 'm');
    });

    testWidgets('returns the desktop value on desktop', (tester) async {
      final responsive = await responsiveFor(tester, const Size(1400, 900));

      expect(responsive.value(mobile: 'm', desktop: 'd'), 'd');
    });
  });
}
