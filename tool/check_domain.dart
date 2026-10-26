import '../lib/clinic.dart';

void check(bool value) {
  if (!value) throw StateError('Domain check failed');
}

void rejects(void Function() fn) {
  var rejected = false;
  try {
    fn();
  } catch (_) {
    rejected = true;
  }
  check(rejected);
}

void main() {
  final now = DateTime(2026, 10, 22, 8);
  final time = DateTime(2026, 10, 22, 9);
  final c = Clinic();
  final v = c.book('d1', 'Demo', 'Checkup', time, now: now);
  check(!c.slots(time, 'd1', now).contains(time));
  check(c.slots(time, 'd2', now).contains(time));
  rejects(() => c.book('d1', 'Other', 'Checkup', time, now: now));
  rejects(() => c.book('d2', 'Demo', 'Checkup', time, now: now));
  rejects(() => c.change(v.id, VisitStatus.completed, now: now));
  check(Clinic.decode(c.encode()).visits.single.patient == 'Demo');
  c.change(v.id, VisitStatus.cancelled);
  check(c.slots(time, 'd1', now).contains(time));
  rejects(() => c.change(v.id, VisitStatus.completed));
  rejects(() => Clinic.decode('{"version":2,"visits":[]}'));
  final done = c.book('d1', 'Other', 'Followup', time, now: now);
  c.change(done.id, VisitStatus.completed, now: time, note: 'Demo note');
  check(Clinic.decode(c.encode()).visits.last.note == 'Demo note');
  print(
    'PASS: booking, conflicts, doctor availability, cancellation, completion, persistence and malformed data.',
  );
}
