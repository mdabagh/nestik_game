import 'package:flutter_test/flutter_test.dart';

import 'package:nestik_game/main.dart';
import 'package:nestik_game/ui/splash_screen.dart';

void main() {
  testWidgets('App shows animated splash then navigates home',
      (WidgetTester tester) async {
    await tester.pumpWidget(const NestikGameApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('نستیک گیم'), findsOneWidget);

    // Advance past the splash duration + route transition
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('دنیای نستیک'), findsOneWidget);
    expect(find.text('جاسوس'), findsWidgets);
  });
}