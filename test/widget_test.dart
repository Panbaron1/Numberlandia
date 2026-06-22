// Smoke test: the app boots to the home screen with its activity cards.
import 'package:flutter_test/flutter_test.dart';

import 'package:numberlandia/main.dart';

void main() {
  testWidgets('App boots and shows the home wordmark', (tester) async {
    await tester.pumpWidget(const NumberlandiaApp());
    await tester.pumpAndSettle();
    expect(find.text('NumBlox'), findsOneWidget);
  });
}
