import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:collor/main.dart';
import 'package:collor/core/game_state.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => GameState()..reset(),
        child: const CollorApp(),
      ),
    );

    // Verify that the title text is found.
    expect(find.textContaining('컬러 퍼즐 7'), findsOneWidget);
  });
}
