import 'package:flutter_test/flutter_test.dart';
import 'package:pdftool/main.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const PdftoolApp());

    expect(find.byType(PdftoolApp), findsOneWidget);
  });
}
