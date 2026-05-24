import 'package:flutter_test/flutter_test.dart';
import 'package:disaster_gaussian_splatting_frontend/main.dart';

void main() {
  testWidgets('Disaster Splatting Influx Dashboard Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DisasterSplatApp());

    // Verify that our dashboard starts and displays standard branding text
    expect(find.text('Splatting Hub'), findsOneWidget);
    expect(find.text('ONLINE AI ENGINE'), findsOneWidget);
  });
}
