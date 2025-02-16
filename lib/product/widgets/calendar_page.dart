import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';


import '../../Utility/globals.dart';
import '../../screens/bireysel/personal_home_screen.dart';

class CalendarWidget extends StatefulWidget {
  late  DateTime selectedDay;
  final Map<DateTime, List<Task>> tasksMap;
  final Map<DateTime, List<Task>> tasksMapForMonth;
  final void Function(DatabaseReference) fetchAndUpdateState;

   CalendarWidget({
    Key? key,
    required this.selectedDay,
    required this.tasksMap,
    required this.tasksMapForMonth,
    required this.fetchAndUpdateState,
  }) : super(key: key);

  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDay;
  }

  void _fetchTasksForTheCurrentMonth() {
    // Implement fetching logic for tasks
  }

  String _formatDate(DateTime date) {
    return DateFormat("yyyy-MM-dd").format(date);
  }

  @override
  Widget build(BuildContext context) {
    _fetchTasksForTheCurrentMonth();

    Map<String, List<Event>> events = {};
    widget.tasksMapForMonth.forEach((date, tasks) {
      String formattedDate = DateFormat("yyyy-MM-dd").format(date);
      events[formattedDate] = [];
      List<Task> nonExpiredTasks = tasks.where((task) => !task.date.isBefore(DateTime.now())).toList();
      if (nonExpiredTasks.isNotEmpty) {
        events[formattedDate]!.add(Event(tasks.first.details));
      }
    });

    List<Event> getMyEvents(day) {
      String formattedStr = DateFormat("yyyy-MM-dd").format(day);
      return events[formattedStr] ?? [];
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          TableCalendar(
            focusedDay: _selectedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            calendarStyle: const CalendarStyle(markersAlignment: Alignment.bottomCenter),
            eventLoader: getMyEvents,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() => _selectedDay = selectedDay);

            },
          ),
          const SizedBox(height: 16),
          if (widget.tasksMap[_selectedDay] != null && widget.tasksMap[_selectedDay]!.isNotEmpty)
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Text('${_formatDate(_selectedDay)} tarihi için görevler :'),
                for (final task in widget.tasksMap[_selectedDay]!)
                  GestureDetector(
                    onTap: () async {
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        String? taskKey = Globals.taskKeysByName[task.details];
                        DatabaseReference userTaskReference = FirebaseDatabase.instance
                            .ref()
                            .child('users')
                            .child(user.uid)
                            .child('tasks')
                            .child(taskKey!);

                        widget.fetchAndUpdateState(userTaskReference);
                      }
                    },
                    child: Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25.0),
                        gradient: LinearGradient(
                          colors: [
                            Colors.cyan[900] ?? Colors.cyan,
                            Colors.green[900] ?? Colors.green
                          ],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25.0),
                        child: ListTile(
                          title: Text(
                            task.details,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            Text('${_formatDate(_selectedDay)} tarihi için görev yok'),
        ],
      ),
    );
  }
}
