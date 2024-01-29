import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'DetailsPage.dart';
import '../Utility/firebase_options.dart';

import '../Utility/globals.dart'; // Import the globals.dart file
import '../Utility/login_screen.dart';
import 'newItemScreen.dart';


void mainBireysel() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp()); // Use the root widget (MyApp) here
}

void main() {
  mainBireysel();
}

extension DateTimeExtension on DateTime {
  bool isSameDate(DateTime other) {
    return this.year == other.year && this.month == other.month && this.day == other.day;
  }
}



class Task {
  late String details;
  late DateTime date;

  Task({required this.details, required this.date});
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data as User?;
            if (user == null) {
              // User not signed in, show the login screen
              return LoginScreen();
            } else {
              // User is signed in, show the main screen
              return MyHomePage(user: user);
            }
          } else {
            // Show a loading indicator while checking authentication state
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
class MyHomePage extends StatefulWidget {
  final User? user; // Change the type to User?

  MyHomePage({this.user});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  Map<DateTime, List<Task>> tasksMap = {};
  List<Item> filteredItems = [];
  late ScrollController _scrollController;
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchDataFromDatabase();
  }

  Future<void> _fetchDataFromDatabase() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final firebaseRef = FirebaseDatabase(
        databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
      ).reference();

      // Update the reference to include the user's UID and fetch tasks from the "tasks" branch
      DatabaseReference userTaskReference = firebaseRef.child('users').child(user.uid).child('tasks');

      final snapshot = await userTaskReference.get();

      if (snapshot.value is Map<dynamic, dynamic>) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        Globals.itemsList[0].clear();
        Globals.taskKeysByName.clear();
        data.forEach((key, value) {
          final item = Item(
            name: value['name'],
            description: value['description'],
            date: DateTime.parse(value['date']),
          );
          Globals.taskKeysByName[item.name] = key;

          Globals.itemsList[0].add(item);
        });

        setState(() {});
      }
    }
  }




  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyApp()), // Change here
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _fetchDataFromDatabase();
        setState(() {
          Globals.itemsList[0].sort((a, b) => a.date.compareTo(b.date));
        });
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(

          title: Text("Welcome Serdar"),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'signOut') {
                  _signOut();
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    value: 'signOut',
                    child: Text('Sign Out'),
                  ),
                ];
              },
            ),
          ],
          backgroundColor: Colors.grey, // Set app bar background color
          elevation: 4, // Set the elevation for a shadow effect
          shape: UnderlineInputBorder(

          ),
          // ... other properties
        ),
        body: Column(
          children: [
            _buildTabBar(),
            _currentPage == 0 ? _buildSearchBar() : SizedBox(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    if (index == 1) {
                      _selectedDay = DateTime.now();
                      _fetchTasksForSelectedDay(_selectedDay);
                    }
                  });
                },
                children: [
                  Expanded(
                    child: _buildPage(filteredItems.isNotEmpty ? filteredItems : Globals.itemsList[0]),
                  ),
                  _buildCalendarPage(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton:
        _currentPage == 0 ? _buildFloatingButton(context) : null,
      ),
    );
  }


  Widget _buildTabBar() {
    return Container(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem("First Screen", 0),
          _buildTabItem("Second Screen", 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(String text, int index) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(index,
            duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
      },
      child: Container(
        padding: EdgeInsets.all(10),
        color: _currentPage == index ? Colors.grey : Colors.transparent,
        child: Text(
          text,
          style: TextStyle(
            color: _currentPage == index ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.grey,
                offset: Offset(2, 2), // Set the shadow offset for a 3D effect
                blurRadius: 3, // Set the blur radius for a softer shadow
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildPage(List<Item> items) {
    items.sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _pullRefresh,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  if (items.isEmpty)
                    const Center(
                      child:  Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No tasks for now.',
                          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: Colors.lime[400] ?? Colors.green,
                              width: 4.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey[600] ?? Colors.grey,
                                spreadRadius: 1,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(
                              '${item.name} - ${_formatDate(item.date)}',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              _calculateDaysLeft(item.date) == null ? 'Expired' : 'Active',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailsPage(
                                    title: "Screen ${_currentPage + 1}",
                                    item: item.name,
                                    description: item.description ?? "",
                                    itemDate: item.date,
                                    onRemove: () {
                                      _removeItem(item);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }




  Widget _buildCalendarPage() {
    return Column(
      children: [
        TableCalendar(
          focusedDay: _selectedDay,
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          onDaySelected: (selectedDay, focusedDay) async {
            setState(() {
              _selectedDay = selectedDay;
            });
            // Fetch tasks for the selected day from the database
            await _fetchTasksForSelectedDay(selectedDay);
          },
        ),
        SizedBox(height: 16),
        if (tasksMap[_selectedDay] != null && tasksMap[_selectedDay]!.isNotEmpty)
          Expanded(
            child: ListView(
              children: [
                Text('Tasks for ${_formatDate(_selectedDay)}:'),
                for (final task in tasksMap[_selectedDay]!)
                  GestureDetector(
                    onTap: () async {
                      setState(() async {
                        // Get the current authenticated user
                        User? user = FirebaseAuth.instance.currentUser;

                        // Print statement to check if user is null
                        print("Current user: $user");

                        if (user != null) {
                          final firebaseRef = FirebaseDatabase(
                            databaseURL:
                            "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
                          ).reference();

                          String? taskKey = Globals.taskKeysByName[task.details];

                          // Update the reference to include the user's UID
                          DatabaseReference userTaskReference = firebaseRef
                              .child('users')
                              .child(user.uid)
                              .child(taskKey!);
                          print("KANKAAAA $taskKey");

                          // Fetch the details of the task
                          final snapshot = await userTaskReference.get();

                          // Check if the snapshot value is not null and is of the expected type
                          if (snapshot.value is Map<dynamic, dynamic>?) {
                            // Access the data from the snapshot
                            Map<dynamic, dynamic>? taskData =
                            snapshot.value as Map<dynamic, dynamic>?;

                            if (taskData != null) {
                              // Create a new Item instance using the fetched data
                              Item selectedItem = Item(
                                name: taskData['name'],
                                description: taskData['description'],
                                date: DateTime.parse(taskData['date']),
                              );

                              // Use the 'selectedItem' instance as needed

                              // Navigate to the DetailsPage and pass the selected item
                              _navigateToDetailsPage(selectedItem);
                            }
                          }
                        }
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                        gradient: LinearGradient(
                          colors: [
                            Colors.cyan[900] ?? Colors.cyan,
                            Colors.green[900] ?? Colors.green
                          ],
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          task.details,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          )
        else
          Text('No tasks for ${_formatDate(_selectedDay)}'),
      ],
    );
  }



  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onChanged: (value) {
          _filterItems(value);
        },
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  void _filterItems(String searchTerm) {
    setState(() {
      filteredItems = Globals.itemsList[0]
          .where((item) =>
          item.name.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    });
  }




  Future<void> _fetchTasksForSelectedDay(DateTime selectedDay) async {
    // Clear tasksMap before populating it again
    tasksMap.clear();

    Globals.itemsList.forEach((items) {
      items.forEach((item) {
        if (item.date.isSameDate(selectedDay)) {
          tasksMap[selectedDay] = tasksMap[selectedDay] ?? [];

          // Create a Task object with necessary details
          Task task = Task(details: item.name, date: item.date);

          // Add the Task object to the tasksMap
          tasksMap[selectedDay]!.add(task);
        }
      });
    });

    setState(() {});
  }


  Future<void> _pullRefresh() async {

    setState(() {
      _fetchDataFromDatabase();
    });
  }




  void _navigateToDetailsPage(Item item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsPage(
          title: "Screen ${_currentPage + 1}",
          item: item.name,
          description: item.description ?? "",
          itemDate: item.date,
          onRemove: () {
            _removeItem(item);
          },
        ),
      ),
    );
  }



  Widget _buildFloatingButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        final newItem = await _navigateToNewItemScreen(context);
        if (newItem != null) {
          _addItem(newItem);
        }
      },
      backgroundColor: Colors.green, // Set the background color to green
      child: Icon(Icons.add),
    );
  }

  void _addItem(Item newItem) {
    setState(() {
      Globals.itemsList[0].add(newItem);

      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;

      // Print statement to check if user is null
      print("Current user: $user");

      if (user != null) {
        final firebaseRef = FirebaseDatabase(
          databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
        ).reference();

        // Update the reference to include the user's UID and create a "tasks" branch
        DatabaseReference userTaskReference = firebaseRef.child('users').child(user.uid).child('tasks');

        // Create a map for the new task
        Map<String, dynamic> newTaskData = {
          "name": newItem.name,
          "description": newItem.description ?? "",
          "date": newItem.date.toUtc().toIso8601String(),
          "email": user.email
        };

        // Print statement to check the new task data
        print("New task data: $newTaskData");

        // Use push to generate a unique key for the new task
        DatabaseReference newTaskReference = userTaskReference.push();

        // Set the value of the new task using the generated key
        newTaskReference.set(newTaskData);

        Globals.taskKeysByName[newItem.name] = newTaskReference.key!;
        // Print statement to check if data is added to the database
        print("Task added to the database with key: ${newTaskReference.key}");
      }
    });
  }


  Future<Item?> _navigateToNewItemScreen(BuildContext context) async {
    return await Navigator.push(
      context,
      MaterialPageRoute<Item>(
        builder: (context) => NewItemScreen(),
      ),
    );
  }

  void _removeItem(Item item) {
    setState(() {

      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;

      // Print statement to check if user is null
      print("Current user: $user");

      if (user != null) {
        final firebaseRef = FirebaseDatabase(
          databaseURL:
          "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
        ).reference();

        String? taskKey = Globals.taskKeysByName[item.name];
        // Update the reference to include the user's UID
        DatabaseReference userTaskReference =
        firebaseRef.child('users').child(user.uid).child(taskKey!);
        print("KANKAAAA $taskKey");

        userTaskReference.remove();

      }

      Globals.itemsList[0].remove(item);
      Navigator.popUntil(context, (route) => route.isFirst);
    });
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  int? _calculateDaysLeft(DateTime date) {
    final currentDate = DateTime.now();
    final difference = date.difference(currentDate);
    return difference.isNegative ? null : difference.inDays;
  }



}
