import 'package:flutter_test/flutter_test.dart';
import 'package:tabeeby_clinic_app/clinic.dart';

void main() {
  final now = DateTime(2026, 10, 22, 8);
  final time = DateTime(2026, 10, 22, 9);
  test(
    'booking removes only the selected doctor slot and survives storage',
    () {
      final c = Clinic();
      c.book('d1', 'Demo Patient', 'Checkup', time, now: now);
      expect(c.slots(time, 'd1', now), isNot(contains(time)));
      expect(c.slots(time, 'd2', now), contains(time));
      expect(Clinic.decode(c.encode()).visits.single.patient, 'Demo Patient');
      expect(
        () => c.book('d1', 'Other', 'Checkup', time, now: now),
        throwsArgumentError,
      );
      expect(
        () => c.book('d2', 'Demo Patient', 'Checkup', time, now: now),
        throwsArgumentError,
      );
    },
  );
  test('cancel releases slot and terminal states cannot change', () {
    final c = Clinic();
    final v = c.book('d1', 'Demo', 'Checkup', time, now: now);
    c.change(v.id, VisitStatus.cancelled);
    expect(c.slots(time, 'd1', now), contains(time));
    expect(() => c.change(v.id, VisitStatus.completed), throwsStateError);
  });
  test('past and invalid bookings rejected, future completion rejected', () {
    final c = Clinic();
    expect(() => c.book('d1', '', 'Test', time, now: now), throwsArgumentError);
    expect(
      () => c.book('unknown', 'Demo', 'Test', time, now: now),
      throwsArgumentError,
    );
    expect(
      () => c.book('d1', 'Demo', 'Test', time, now: time),
      throwsArgumentError,
    );
    final v = c.book('d1', 'Demo', 'Test', time, now: now);
    expect(
      () => c.change(v.id, VisitStatus.completed, now: now),
      throwsStateError,
    );
    c.change(v.id, VisitStatus.completed, now: time, note: 'Demo note');
    expect(Clinic.decode(c.encode()).visits.single.note, 'Demo note');
  });
  test('corrupt storage is rejected', () {
    expect(
      () => Clinic.decode('{"version":2,"visits":[]}'),
      throwsFormatException,
    );
    expect(() => Clinic.decode('broken'), throwsFormatException);
  });
}
