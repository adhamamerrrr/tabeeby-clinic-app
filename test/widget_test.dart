import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabeeby_clinic_app/main.dart';

void main() {
  testWidgets('book, view, cancel and reopen an appointment', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TabeebyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('View availability').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Demo Patient');
    await tester.enterText(find.byType(TextFormField).at(1), 'Sample checkup');
    await tester.tap(find.text('09:00'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Confirm appointment'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Confirm appointment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appointments').last);
    await tester.pumpAndSettle();
    expect(find.text('Demo Patient'), findsOneWidget);
    await tester.tap(find.text('Cancel appointment'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel appointment'));
    await tester.pumpAndSettle();
    expect(find.text('cancelled'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const TabeebyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appointments').last);
    await tester.pumpAndSettle();
    expect(find.text('cancelled'), findsOneWidget);
  });
}
