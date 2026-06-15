import 'package:ev_navigator/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EV Navigator App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EVNavigatorApp()),
    );
    await tester.pump();

    expect(find.byType(EVNavigatorApp), findsOneWidget);
  });
}
