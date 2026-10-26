import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'clinic.dart';

void main() => runApp(const TabeebyApp());

class TabeebyApp extends StatelessWidget {
  const TabeebyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Tabeeby',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff087e8b)),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xfff5f8fa),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: const ClinicHome(),
  );
}

class ClinicHome extends StatefulWidget {
  const ClinicHome({super.key});
  @override
  State<ClinicHome> createState() => _ClinicHomeState();
}

class _ClinicHomeState extends State<ClinicHome> {
  Clinic clinic = Clinic();
  SharedPreferences? prefs;
  bool loading = true, busy = false;
  String? error;
  int tab = 0;
  String doctorFilter = doctors.first.id;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final data = p.getString('tabeeby.v1');
      final loaded = data == null ? Clinic() : Clinic.decode(data);
      if (!mounted) return;
      setState(() {
        prefs = p;
        clinic = loaded;
        loading = false;
        error = null;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          loading = false;
          error =
              'Saved appointments could not be loaded. Your data has been preserved. Retry to continue.';
        });
    }
  }

  Future<void> mutate(void Function(Clinic) action) async {
    if (busy || prefs == null) return;
    setState(() => busy = true);
    try {
      final next = Clinic.decode(clinic.encode());
      action(next);
      if (!await prefs!.setString('tabeeby.v1', next.encode())) {
        throw StateError('Could not save changes.');
      }
      if (mounted) setState(() => clinic = next);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> book(Doctor doctor) async {
    final result = await Navigator.of(context).push<Booking>(
      MaterialPageRoute(
        builder: (_) => BookingPage(doctor: doctor, clinic: clinic),
      ),
    );
    if (result == null || !mounted) return;
    await mutate(
      (c) => c.book(doctor.id, result.patient, result.reason, result.time),
    );
  }

  Future<void> cancel(Visit visit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text(
          'The slot will become available for booking again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (confirmed == true)
      await mutate((c) => c.change(visit.id, VisitStatus.cancelled));
  }

  Future<void> complete(Visit visit) async {
    var draft = '';
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete visit'),
        content: TextField(
          onChanged: (value) => draft = value,
          maxLength: 2000,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Demo visit note (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, draft),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (note != null)
      await mutate(
        (c) => c.change(visit.id, VisitStatus.completed, note: note),
      );
  }

  String date(DateTime t) =>
      '${t.day}/${t.month}/${t.year} · ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  Widget appointment(Visit v) {
    final d = doctors.firstWhere((d) => d.id == v.doctorId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    v.patient,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(v.status.name)),
              ],
            ),
            Text('${d.name} · ${d.specialty}'),
            Text(date(v.time)),
            const SizedBox(height: 8),
            Text(v.reason),
            if (v.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Visit note: ${v.note}'),
              ),
            if (v.status == VisitStatus.booked)
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: busy ? null : () => cancel(v),
                    child: const Text('Cancel appointment'),
                  ),
                  if (tab == 2 && !v.time.isAfter(DateTime.now()))
                    FilledButton.tonal(
                      onPressed: busy ? null : () => complete(v),
                      child: const Text('Complete visit'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = clinic.visits
        .where(
          (v) =>
              v.status == VisitStatus.booked && v.time.isAfter(DateTime.now()),
        )
        .length;
    final list =
        clinic.visits
            .where((v) => tab != 2 || v.doctorId == doctorFilter)
            .toList()
          ..sort((a, b) => b.time.compareTo(a.time));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabeeby'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Chip(label: Text(tab == 2 ? 'Doctor demo' : 'Patient demo')),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'OFFLINE PORTFOLIO DEMO',
                      style: TextStyle(
                        letterSpacing: 2,
                        color: Color(0xff087e8b),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      [
                        'Find your next appointment',
                        'Your appointments',
                        'Clinic workspace',
                      ][tab],
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$upcoming upcoming · ${clinic.visits.where((v) => v.status == VisitStatus.completed).length} completed',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Fictional doctors. All records stay on this device. Role switching demonstrates workflows; it is not authentication. Use sample data only.',
                    ),
                    const SizedBox(height: 24),
                    if (busy) const LinearProgressIndicator(),
                    if (tab == 0)
                      ...doctors.map(
                        (d) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.local_hospital_outlined,
                                  size: 30,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  d.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(d.specialty),
                                const SizedBox(height: 12),
                                Text('EGP ${d.fee} · 30-minute appointments'),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: busy ? null : () => book(d),
                                  child: const Text('View availability'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (tab == 2)
                      DropdownButtonFormField<String>(
                        initialValue: doctorFilter,
                        decoration: const InputDecoration(labelText: 'Doctor'),
                        items: doctors
                            .map(
                              (d) => DropdownMenuItem(
                                value: d.id,
                                child: Text(d.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => doctorFilter = v!),
                      ),
                    if (tab != 0) ...[
                      const SizedBox(height: 12),
                      if (list.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(30),
                          child: Text(
                            'No appointments yet. Book an available slot to get started.',
                          ),
                        ),
                      ...list.map(appointment),
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Doctors'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Clinic',
          ),
        ],
      ),
    );
  }
}

class Booking {
  final String patient, reason;
  final DateTime time;
  Booking(this.patient, this.reason, this.time);
}

class BookingPage extends StatefulWidget {
  final Doctor doctor;
  final Clinic clinic;
  const BookingPage({super.key, required this.doctor, required this.clinic});
  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final form = GlobalKey<FormState>();
  final patient = TextEditingController(), reason = TextEditingController();
  DateTime day = DateTime.now().add(const Duration(days: 1));
  DateTime? slot;
  @override
  void dispose() {
    patient.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slots = widget.clinic.slots(day, widget.doctor.id, DateTime.now());
    return Scaffold(
      appBar: AppBar(title: Text(widget.doctor.name)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Book a visit',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: patient,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Sample patient name',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reason,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason for visit',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a reason' : null,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text('${day.day}/${day.month}/${day.year}'),
                  onPressed: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                      context: context,
                      initialDate: day,
                      firstDate: DateTime(now.year, now.month, now.day),
                      lastDate: now.add(const Duration(days: 90)),
                    );
                    if (date != null)
                      setState(() {
                        day = date;
                        slot = null;
                      });
                  },
                ),
                const SizedBox(height: 12),
                Text('Available times · EGP ${widget.doctor.fee}'),
                const SizedBox(height: 12),
                if (slots.isEmpty)
                  const Text('No slots available. Please select another day.'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: slots
                      .map(
                        (t) => ChoiceChip(
                          label: Text(
                            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                          ),
                          selected: slot == t,
                          onSelected: (_) => setState(() => slot = t),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: slot == null
                      ? null
                      : () {
                          if (form.currentState!.validate())
                            Navigator.pop(
                              context,
                              Booking(patient.text, reason.text, slot!),
                            );
                        },
                  child: const Text('Confirm appointment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
