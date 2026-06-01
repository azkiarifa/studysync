import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/main.dart';

void main() {
  testWidgets('StudySyncApp Splash Screen Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StudySyncApp());

    // Verify that the splash screen shows the app name and subtitle.
    expect(find.text('StudySync'), findsOneWidget);
    expect(find.text('Your Personal Academic Hub'), findsOneWidget);
  });
}
