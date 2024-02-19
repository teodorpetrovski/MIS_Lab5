import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lab5/map.dart';
import 'awesome_notifications.dart';
import 'examcalendar.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'location_notifications.dart';

//Laboratory exercise 5
//Name and surname: Teodor Petrovski
//Index: 201128

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelGroupKey: "basic_channel_group",
      channelKey: "basic_channel",
      channelName: "basic_notif",
      channelDescription: "basic notification channel",
      defaultColor: Colors.blue,
      ledColor: Colors.blueAccent,
      playSound: true,
      enableVibration: true,
    )
  ], channelGroups: [
    NotificationChannelGroup(
        channelGroupKey: "basic_channel_group", channelGroupName: "basic_group")
  ]);

  bool isAllowedToSendNotification =
      await AwesomeNotifications().isNotificationAllowed();

  if (!isAllowedToSendNotification) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xffc9eafc),
          useMaterial3: true),
      routes: {
        '/login': (context) => const AuthenticationPage(isLogin: true),
        '/register': (context) => const AuthenticationPage(isLogin: false),
      },
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final List<Exam> exams = [
    Exam(
        course: 'VP',
        timestamp: DateTime(2024, 1, 31, 17, 30),
        faculty: Faculty(
            name: "Faculty of Technology & Metallurgy",
            latitude: 42.00466498482014,
            longitude: 21.410006958557577)),
  ];

  @override
  void initState() {
    super.initState();
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceiveMethod,
        onDismissActionReceivedMethod:
            NotificationController.onDismissActionReceiveMethod,
        onNotificationCreatedMethod:
            NotificationController.onNotificationCreateMethod,
        onNotificationDisplayedMethod:
            NotificationController.onNotificationDisplayed);
    _scheduleNotifications();
  }

  void _scheduleNotifications() {
    for (Exam exam in exams) {
      _scheduleNotification(exam);
    }
  }

  void _scheduleNotification(Exam exam) {
    final int notificationId = exams.indexOf(exam);

    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: notificationId,
            channelKey: "basic_channel",
            title: exam.course,
            body:
                "You've got an exam tomorrow at ${DateFormat('kk:mm').format(exam.timestamp)}"),
        schedule: NotificationCalendar(
            day: exam.timestamp.subtract(const Duration(days: 1)).day,
            month: exam.timestamp.month,
            year: exam.timestamp.year,
            hour: 12,
            minute: 00));
  }

  @override
  Widget build(BuildContext context) {
    LocationNotificationService locationNotificationService =
        LocationNotificationService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff4fb2ec),
        title: const Text(
          'Exams Schedule',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (FirebaseAuth.instance.currentUser == null)
            IconButton(
                onPressed: () => _navigateToSignInPage(context),
                icon: const Icon(Icons.login_outlined)),
          if (FirebaseAuth.instance.currentUser != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddExamDialog(context),
            ),
          if (FirebaseAuth.instance.currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout_sharp),
              onPressed: _signOut,
            ),
        ],
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 5.0,
          mainAxisSpacing: 5.0,
        ),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          final course = exams[index].course;
          final timestamp = exams[index].timestamp;
          final location = exams[index].faculty.name;

          return GestureDetector(
            onTap: () {
              _navigateToMapPage(exams[index]);
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      DateFormat('yyyy-MM-dd  kk:mm').format(timestamp),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      "At: $location",
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCalendarPage,
        child: Icon(Icons.calendar_month),
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/');
    });
  }

  void _navigateToCalendarPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarPage(exams: exams),
      ),
    );
  }

  void _navigateToMapPage(Exam exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(exam: exam),
      ),
    );
  }

  void _navigateToSignInPage(BuildContext context) {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  void _showAddExamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Exam'),
          content: AddExamDialogContent(
            addExam: _addExam,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _addExam(Exam exam) {
    setState(() {
      exams.add(exam);
    });
  }
}

class AddExamDialogContent extends StatefulWidget {
  final Function(Exam) addExam;

  const AddExamDialogContent({required this.addExam, super.key});

  @override
  _AddExamDialogContentState createState() => _AddExamDialogContentState();
}

class _AddExamDialogContentState extends State<AddExamDialogContent> {
  final TextEditingController subjectController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final List<Faculty> faculties = [
    Faculty(
        name: "Faculty of Technology & Metallurgy",
        latitude: 42.00466498482014,
        longitude: 21.410006958557577),
    Faculty(
        name: "Faculty of Pedagogy",
        latitude: 42.0003404974511,
        longitude: 21.40580373436277),
    Faculty(
        name: "FEIT",
        latitude: 42.00507393006092,
        longitude: 21.408401071076337),
    Faculty(
        name: "Faculty of Law",
        latitude: 42.00000222959604,
        longitude: 21.443783684100342),
  ];
  late Faculty selectedFaculty = faculties[0];

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                ),
                TextButton(
                  child: const Text('Select Date',
                      style: TextStyle(color: Colors.blue)),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                'Time: ${selectedDate.toLocal().toString().split(' ')[1].substring(0, 5)}',
              ),
              TextButton(
                onPressed: () => _selectTime(context),
                child: const Text('Select Time',
                    style: TextStyle(color: Colors.blue)),
              ),
            ]),
            const SizedBox(height: 16),
            const Text(
              'Where is the exam held?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<Faculty>(
              hint: Text('Select Faculty'),
              value: selectedFaculty,
              onChanged: (Faculty? newValue) {
                setState(() {
                  selectedFaculty = newValue!;
                });
              },
              isExpanded:true,
              items: faculties.map((Faculty faculty) {
                return DropdownMenuItem<Faculty>(
                  value: faculty,
                  child: Text(faculty.name),
                );
              }).toList(),
            ),
            ElevatedButton(
              onPressed: () {
                Exam exam = Exam(
                    course: subjectController.text,
                    timestamp: selectedDate,
                    faculty: selectedFaculty);
                widget.addExam(exam);
                Navigator.pop(context);
              },
              child:
                  const Text('Add Exam', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? datePicked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (datePicked != null && datePicked != selectedDate) {
      setState(() {
        selectedDate = datePicked;
      });
    }
  }

  void _selectTime(BuildContext context) async {
    final TimeOfDay? timePicked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate),
    );

    if (timePicked != null) {
      setState(() {
        selectedDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          timePicked.hour,
          timePicked.minute,
        );
      });
    }
  }
}

class AuthenticationPage extends StatefulWidget {
  final bool isLogin;

  const AuthenticationPage({super.key, required this.isLogin});

  @override
  AuthenticationPageState createState() => AuthenticationPageState();
}

class AuthenticationPageState extends State<AuthenticationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  Future<void> _authAction() async {
    try {
      if (widget.isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        _showSuccessDialog(
            "Login Successful", "You have successfully logged in!");
        _navigateToHome();
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        _showSuccessDialog(
            "Registration Successful", "You have successfully registered!");
        _navigateToLogin();
      }
    } catch (e) {
      _showErrorDialog(
          "Authentication Error", "Error during authentication: $e");
    }
  }

  void _showSuccessDialog(String title, String message) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToHome() {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/');
    });
  }

  void _navigateToLogin() {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  void _navigateToRegister() {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/register');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff4fb2ec),
        title: widget.isLogin ? const Text("Login") : const Text("Register"),
        leading: IconButton(
            onPressed: _navigateToHome,
            icon: const Icon(Icons.arrow_back_ios_sharp)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authAction,
              child: Text(
                widget.isLogin ? "Sign In" : "Register",
                style: TextStyle(color: Colors.blue),
              ),
            ),
            if (!widget.isLogin)
              TextButton(
                onPressed: _navigateToLogin,
                child: const Text(
                  'If you already have an account, log in.',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            if (widget.isLogin)
              TextButton(
                onPressed: _navigateToRegister,
                child: const Text(
                  'Create an account',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Exam {
  String course;
  DateTime timestamp;
  Faculty faculty;

  Exam({
    required this.course,
    required this.timestamp,
    required this.faculty,
  });
}

class Faculty {
  String name;
  double longitude;
  double latitude;

  Faculty({
    required this.name,
    required this.longitude,
    required this.latitude,
  });
}
