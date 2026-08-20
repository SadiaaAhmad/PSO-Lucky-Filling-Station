import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('FuelStationApp Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const FuelStationApp());
    expect(find.byType(FuelStationApp), findsOneWidget);
  });
}
