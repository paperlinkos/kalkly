import 'package:flutter_test/flutter_test.dart';
import 'package:kalkly/main.dart';

void main() {
  testWidgets('DynamoApp renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const DynamoApp());
    expect(find.text('Kalkly'), findsOneWidget);
    expect(find.text('CALC'), findsOneWidget);
  });
}
