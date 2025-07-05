import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'models/attendance_record.dart';


class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final TextEditingController _commentController = TextEditingController();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final double boxLatitude = 50.0630;
  final double boxLongitude = 19.9286;
  final double allowedDistanceMeters = 300.0;

  late final FirestoreService _fs;
  late Stream<List<AttendanceRecord>> _attendanceStream;
  List<AttendanceRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _fs = FirestoreService();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _attendanceStream = _fs.watchAttendance(uid);
    _attendanceStream.listen((list) {
      setState(() => _records = list);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _markAttendance() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showMessage('Location permission denied.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showMessage('Location permission permanently denied.');
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      boxLatitude,
      boxLongitude,
    );

    if (distance > allowedDistanceMeters) {
      _showMessage('You must be near your box to mark attendance.');
      return;
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(now);

    // 이미 출석한 경우 방지
    if (_records.any((r) => DateFormat('yyyy-MM-dd').format(r.date) == formattedDate)) {
      _showMessage('You already marked attendance for today.');
      return;
    }

    await _fs.saveAttendance(
      formattedDate,
      _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );
    _commentController.clear();

    _showMessage('Another day, Another WOD.');
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _markAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Mark Attendance'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  _records.any((r) => isSameDay(r.date, day)),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final match = _records.any((r) => isSameDay(r.date, date));
                  if (match) {
                    return const Positioned(
                      bottom: 1,
                      child: Icon(Icons.check, color: Colors.white70, size: 16),
                    );
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedDay != null)
              Builder(
                builder: (context) {
                  final record = _records.firstWhere(
                    (r) => isSameDay(r.date, _selectedDay!),
                    orElse: () => AttendanceRecord(date: _selectedDay!, comment: null),
                  );
                  return _records.any((r) => isSameDay(r.date, _selectedDay!))
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd').format(record.date),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              record.comment ?? 'No comment',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        )
                      : const Text(
                          'No attendance for selected day.',
                          style: TextStyle(color: Colors.white70),
                        );
                },
              )
            else
              const Text('Select a day to view attendance record.', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
