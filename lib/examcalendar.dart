import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'main.dart';
import 'package:intl/intl.dart';


class CalendarPage extends StatefulWidget {
  final List<Exam> exams;

  const CalendarPage({Key? key, required this.exams}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Map<DateTime, List<Event>> _events;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _events = _getEvents();
    _selectedDate = _focusedDay;
  }

  Map<DateTime, List<Event>> _getEvents() {
    Map<DateTime, List<Event>> events = {};
    for (Exam exam in widget.exams) {
      DateTime date = DateTime(
        exam.timestamp.year,
        exam.timestamp.month,
        exam.timestamp.day,
      );
      if (events.containsKey(date)) {
        events[date]!.add(Event(exam.course,DateFormat('kk:mm').format(exam.timestamp)));
      } else {
        events[date] = [Event(exam.course,DateFormat('kk:mm').format(exam.timestamp))];
      }
    }
    return events;
  }

  List<Event> _getEventForDay(DateTime day)
  {
    DateTime dateOnly = DateTime(day.year, day.month, day.day);

    if (_events[dateOnly] != null) {
      return _events[dateOnly]!;
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Calendar'),
      ),
      body: Column(
    children:[ TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2025),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDate, selectedDay)) {
            // Call `setState()` when updating the selected day
            setState(() {
              _selectedDate = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDate, day);
        },
        onPageChanged: (focusedDay) {
          // No need to call `setState()` here
          _focusedDay = focusedDay;
        },
        eventLoader: _getEventForDay,
      ),
      ListView(
        shrinkWrap: true,
        children: _getEventForDay(_selectedDate!)
            .map((event) => ListTile(
          title: Text("Subject: $event",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
          subtitle: Text("Time: ${event.time}",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
        ))
            .toList(),
      )

]
    )
    );
  }
}

class Event {
  final String title;
  final String time;

  const Event(this.title,this.time);

  @override
  String toString() => title;
}
