import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabeeby_clinic_app/main.dart';

void main() {
  testWidgets('clinic dashboard updates when doctor filter changes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TabeebyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clinic').last);
    await tester.pumpAndSettle();

    expect(find.text('Appointment overview'), findsOneWidget);
    expect(find.text('Completed visit fees: EGP 0'), findsOneWidget);
    expect(find.text('Demo totals for the selected doctor · no patient details'),
        findsOneWidget);

    final doctorSelector = find.byType(DropdownButtonFormField<String>);
    expect(doctorSelector, findsOneWidget);
    await tester.ensureVisible(doctorSelector);
    await tester.pumpAndSettle();
    await tester.tap(doctorSelector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dr. Omar Ali').last);
    await tester.pumpAndSettle();

    expect(find.text('Appointment overview'), findsOneWidget);
    expect(find.text('Completed visit fees: EGP 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
