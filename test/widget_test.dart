import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakeenah/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Sakeenah App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SakeenahApp(initialIsDark: false));
    await tester.pumpAndSettle();
    expect(find.text('سَكِينة'), findsOneWidget);
  });
}
