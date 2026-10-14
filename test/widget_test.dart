import 'package:flutter_test/flutter_test.dart';
import 'package:muzik_duellosu/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MuzikDuellosuApp());
    expect(find.byType(MuzikDuellosuApp), findsOneWidget);
  });
}
