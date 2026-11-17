import 'package:badminton_score/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shows title', (tester) async {
    await tester.pumpWidget(const BadmintonApp());
    expect(find.text('Badminton'), findsOneWidget);
  });
}
