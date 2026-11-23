import 'dart:convert';

class Doctor {
  final String id, name, specialty;
  final int fee;
  const Doctor(this.id, this.name, this.specialty, this.fee);
}

const doctors = [
  Doctor('d1', 'Dr. Sara Hassan', 'General medicine', 450),
  Doctor('d2', 'Dr. Omar Ali', 'Dermatology', 600),
  Doctor('d3', 'Dr. Nour Ahmed', 'Orthopedics', 550),
];

enum VisitStatus { booked, completed, cancelled }

class Visit {
  final String id, doctorId, patient, reason, note;
  final DateTime time;
  final VisitStatus status;
  const Visit({
    required this.id,
    required this.doctorId,
    required this.patient,
    required this.reason,
    required this.time,
    this.note = '',
    this.status = VisitStatus.booked,
  });
  Visit update(VisitStatus status, String note) => Visit(
    id: id,
    doctorId: doctorId,
    patient: patient,
    reason: reason,
    time: time,
    status: status,
    note: note,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'doctorId': doctorId,
    'patient': patient,
    'reason': reason,
    'time': time.toIso8601String(),
    'status': status.name,
    'note': note,
  };
  factory Visit.fromJson(Map<String, dynamic> j) {
    final visit = Visit(
      id: j['id'] as String,
      doctorId: j['doctorId'] as String,
      patient: j['patient'] as String,
      reason: j['reason'] as String,
      time: DateTime.parse(j['time'] as String),
      note: j['note'] as String,
      status: VisitStatus.values.byName(j['status'] as String),
    );
    if (!doctors.any((d) => d.id == visit.doctorId) ||
        visit.patient.trim().isEmpty ||
        visit.reason.trim().isEmpty) {
      throw const FormatException('Invalid visit record');
    }
    return visit;
  }
}


class ClinicSummary {
  final int booked, completed, cancelled, completedRevenue;
  const ClinicSummary({
    required this.booked,
    required this.completed,
    required this.cancelled,
    required this.completedRevenue,
  });
  int get total => booked + completed + cancelled;
  Map<String, int> toJson() => {
    'booked': booked,
    'completed': completed,
    'cancelled': cancelled,
    'total': total,
    'completedRevenue': completedRevenue,
  };
}

class Clinic {
  final List<Visit> _visits;
  Clinic([List<Visit>? visits]) : _visits = List.of(visits ?? []);
  List<Visit> get visits => List.unmodifiable(_visits);

  /// Aggregate appointment counts without exposing patient identifiers.
  /// Optional [from] and [until] are inclusive/exclusive visit-time bounds.
  ClinicSummary summary({DateTime? from, DateTime? until, String? doctorId}) {
    if (from != null && until != null && !from.isBefore(until)) {
      throw ArgumentError('from must be earlier than until');
    }
    if (doctorId != null && !doctors.any((d) => d.id == doctorId)) {
      throw ArgumentError('Unknown doctor');
    }
    var booked = 0, completed = 0, cancelled = 0, revenue = 0;
    for (final visit in _visits) {
      if (doctorId != null && visit.doctorId != doctorId) continue;
      if (from != null && visit.time.isBefore(from)) continue;
      if (until != null && !visit.time.isBefore(until)) continue;
      switch (visit.status) {
        case VisitStatus.booked:
          booked++;
        case VisitStatus.completed:
          completed++;
          revenue += doctors.firstWhere((d) => d.id == visit.doctorId).fee;
        case VisitStatus.cancelled:
          cancelled++;
      }
    }
    return ClinicSummary(
      booked: booked, completed: completed,
      cancelled: cancelled, completedRevenue: revenue,
    );
  }
  List<DateTime> slots(DateTime day, String doctorId, DateTime now) =>
      [
            for (var h = 9; h < 17; h++)
              for (final m in [0, 30])
                DateTime(day.year, day.month, day.day, h, m),
          ]
          .where(
            (t) =>
                t.isAfter(now) &&
                !_visits.any(
                  (v) =>
                      v.doctorId == doctorId &&
                      v.time == t &&
                      v.status != VisitStatus.cancelled,
                ),
          )
          .toList();
  Visit book(
    String doctorId,
    String patient,
    String reason,
    DateTime time, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    if (!doctors.any((d) => d.id == doctorId) ||
        patient.trim().isEmpty ||
        patient.trim().length > 80 ||
        reason.trim().isEmpty ||
        reason.trim().length > 500 ||
        !slots(time, doctorId, current).contains(time)) {
      throw ArgumentError(
        'Choose an available future slot and fill all fields.',
      );
    }
    if (_visits.any(
      (v) =>
          v.patient.toLowerCase() == patient.trim().toLowerCase() &&
          v.time == time &&
          v.status != VisitStatus.cancelled,
    )) {
      throw ArgumentError(
        'This patient already has an appointment at that time.',
      );
    }
    final visit = Visit(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_visits.length}',
      doctorId: doctorId,
      patient: patient.trim(),
      reason: reason.trim(),
      time: time,
    );
    _visits.add(visit);
    return visit;
  }

  void change(
    String id,
    VisitStatus status, {
    String note = '',
    DateTime? now,
  }) {
    final i = _visits.indexWhere((v) => v.id == id);
    if (i < 0 ||
        _visits[i].status != VisitStatus.booked ||
        status == VisitStatus.booked) {
      throw StateError(
        'Only booked appointments can be completed or cancelled.',
      );
    }
    if (status == VisitStatus.completed &&
        _visits[i].time.isAfter(now ?? DateTime.now())) {
      throw StateError('A future appointment cannot be completed.');
    }
    if (note.trim().length > 2000) throw ArgumentError('Note is too long.');
    _visits[i] = _visits[i].update(status, note.trim());
  }

  String encode() => jsonEncode({
    'version': 1,
    'visits': _visits.map((v) => v.toJson()).toList(),
  });
  factory Clinic.decode(String data) {
    final j = jsonDecode(data) as Map<String, dynamic>;
    if (j['version'] != 1) {
      throw const FormatException('Unsupported saved data');
    }
    final visits = (j['visits'] as List)
        .map((v) => Visit.fromJson(v as Map<String, dynamic>))
        .toList();
    if (visits.map((v) => v.id).toSet().length != visits.length) {
      throw const FormatException('Duplicate visit IDs');
    }
    return Clinic(visits);
  }
}
