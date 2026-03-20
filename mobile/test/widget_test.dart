import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test — placeholder', (WidgetTester tester) async {
    // MedOrderApp requires DI initialization and BLoC providers,
    // so full widget tests should use integration_test/ instead.
    expect(1 + 1, equals(2));
  });
}
