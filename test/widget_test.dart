
import 'package:flutter_test/flutter_test.dart';

import 'package:travelmate/main.dart';

void main() {
  testWidgets('TravelMate home screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify that the main trips screen appears.
    expect(find.text('My Trips'), findsOneWidget);
  });
}
