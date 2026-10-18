import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_queue_manament/main.dart';

void main() {
  testWidgets('Hospital Queue app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const HospitalQueueApp());

    expect(find.byType(HospitalQueueApp), findsOneWidget);
  });
}