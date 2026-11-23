import 'package:flutter_test/flutter_test.dart';
import 'package:tabeeby_clinic_app/clinic.dart';

void main() {
  test('summary counts statuses and only completed fees', () {
    final day = DateTime(2026, 10, 22);
    final visits = [
      Visit(id: '1', doctorId: 'd1', patient: 'A', reason: 'Check',
          time: DateTime(2026, 10, 22, 9)),
      Visit(id: '2', doctorId: 'd2', patient: 'B', reason: 'Check',
          time: DateTime(2026, 10, 22, 10),
          status: VisitStatus.completed),
      Visit(id: '3', doctorId: 'd1', patient: 'C', reason: 'Check',
          time: DateTime(2026, 10, 23, 9),
          status: VisitStatus.cancelled),
    ];
    final clinic = Clinic(visits);
    final all = clinic.summary();
    expect(all.toJson(), {
      'booked': 1, 'completed': 1, 'cancelled': 1,
      'total': 3, 'completedRevenue': 600,
    });
    final today = clinic.summary(from: day, until: day.add(const Duration(days: 1)));
    expect(today.total, 2);
    expect(today.cancelled, 0);
    final doctor = clinic.summary(doctorId: 'd1');
    expect(doctor.completedRevenue, 0);
    expect(doctor.total, 2);
    expect(() => clinic.summary(doctorId: 'missing'), throwsArgumentError);
    expect(() => clinic.summary(from: day, until: day), throwsArgumentError);
  });
}
