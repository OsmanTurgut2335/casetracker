import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tuple/tuple.dart';


import 'DetailsPage.dart';
import '../Utility/firebase_options.dart';

import '../Utility/globals.dart'; // Import the globals.dart file
import '../Utility/login_screen.dart';
import 'package:table_calendar/table_calendar.dart';
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
    return year == other.year && month == other.month && day == other.day;
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
            User? user = snapshot.data;
            if (user == null) {
              // User not signed in, show the login screen
              return LoginScreen();
            } else {
              // User is signed in, show the main screen
              return MyHomePage(user: user);
            }
          } else {
            // Show a loading indicator while checking authentication state
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
class Event {
  final String title;

  const Event(this.title);

  @override
  String toString() => title;
}
class MyHomePage extends StatefulWidget {
  final User? user; // Change the type to User?

  MyHomePage({this.user});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Map<DateTime, List<Task>> tasksMap = {};
  Map<DateTime, List<Task>> tasksMapForMonth = {};
  List<Item> filteredItems = [];
  late ScrollController _scrollController;
  DateTime _selectedDay = DateTime.now();
  late List<DateTime> daysWithTasks ;

  final firebaseRef = FirebaseDatabase(
    databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
  ).reference();

  late String username;

  @override
  void initState() {
    super.initState();
    _fetchDataFromDatabase();

    User? user = FirebaseAuth.instance.currentUser;
    DatabaseReference userTaskReference3 = firebaseRef.child('users').child(user!.uid).child("username");


    userTaskReference3.get().then((DataSnapshot dataSnapshot) {
      if (dataSnapshot.value != null) {
        username = dataSnapshot.value as String;

      }
    }).catchError((error) {
      // Handle potential errors
      print("Error: $error");
    });

  }


  Future<bool> isUserKurumsalMember(String userId) async {

    DatabaseReference userTaskReference =
    firebaseRef.child('users').child(userId).child("kurum");

    DataSnapshot snapshot = await userTaskReference.get();

    return snapshot.value != null;
  }

  Future<void> _fetchDataFromDatabase() async {
    Globals.itemsList[0].clear();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {


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
    final navigatorState = Navigator.of(context);

    await FirebaseAuth.instance.signOut();
    if(mounted){
      navigatorState.pushReplacement(MaterialPageRoute(builder: (context) => MyApp()));
    }

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

          title: const Text("Bireysel Ekranı"),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'signOut') {
                  _signOut();
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const  PopupMenuItem(
                    value: 'signOut',
                    child: Text('Sign Out'),
                  ),
                ];
              },
            ),
          ],
          backgroundColor: Colors.grey, // Set app bar background color
          elevation: 4, // Set the elevation for a shadow effect
          shape: const UnderlineInputBorder(

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
                  Container(
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
    return SizedBox(
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
            duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        color: _currentPage == index ? Colors.grey : Colors.transparent,
        child: Text(
          text,
          style: TextStyle(
            color: _currentPage == index ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            shadows: const [
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
        RefreshIndicator(
          onRefresh: _pullRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                           _calculateDaysLeft(item.date),
                            style: const TextStyle(
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
      ],
    );
  }

  Widget _buildCalendarPage() {
    _fetchTasksForTheCurrentMonth();

    Map<String, List<Event>> events = {};

    tasksMapForMonth.forEach((date, tasks) {
      String formattedDate = DateFormat("yyyy-MM-dd").format(date);
      // Check if there is already an event for this date
      if (!events.containsKey(formattedDate)) {
        // If no event exists, create a new list with one event
        events[formattedDate] = [];
      }
      // Filter out expired tasks
      List<Task> nonExpiredTasks = tasks.where((task) => !task.date.isBefore(DateTime.now())).toList();
      if (nonExpiredTasks.isNotEmpty) {
        events[formattedDate]!.add(Event(tasks.first.details));
      }
    });

    List<Event> getMyEvents(day) {
      final DateFormat formatter = DateFormat("yyyy-MM-dd");
      String formattedStr = formatter.format(day);
      return events[formattedStr] ?? [];
    }

    return Column(
      children: [
        TableCalendar(
          focusedDay: _selectedDay,
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          calendarStyle: const CalendarStyle(
            markersAlignment: Alignment.bottomCenter,
          ),
          eventLoader: getMyEvents,
          selectedDayPredicate: (day) {
            // Check if the provided day is the same as the selected day
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) async {
            setState(() {
              _selectedDay = selectedDay;
            });
            // Fetch tasks for the selected day from the database
            await _fetchTasksForSelectedDay(selectedDay);
          },
        ),
        const SizedBox(height: 16),
        if (tasksMap[_selectedDay] != null && tasksMap[_selectedDay]!.isNotEmpty)
          Expanded(
            child: ListView(
              children: [
                Text('Tasks for ${_formatDate(_selectedDay)}:'),
                for (final task in tasksMap[_selectedDay]!)
                  GestureDetector(
                    onTap: () async {
                      // Fetch the current authenticated user
                      User? user = FirebaseAuth.instance.currentUser;

                      // Print statement to check if user is null
                      print("Current user: $user");

                      if (user != null) {
                        String? taskKey = Globals.taskKeysByName[task.details];

                        // Update the reference to include the user's UID
                        DatabaseReference userTaskReference = firebaseRef
                            .child('users')
                            .child(user.uid)
                            .child('tasks')
                            .child(taskKey!);

                        // Perform asynchronous work outside of setState
                        _fetchAndUpdateState(userTaskReference);
                      }
                    },
                    child: Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25.0), // Half of the height to make it round
                        gradient: LinearGradient(
                          colors: [
                            Colors.cyan[900] ?? Colors.cyan,
                            Colors.green[900] ?? Colors.green
                          ],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25.0), // Half of the height to make it round
                        child: ListTile(
                          title: Text(
                            task.details,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
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
        decoration: const InputDecoration(
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

    // Fetch tasks for the selected day from the database
    List<Task> tasksForSelectedDay = Globals.itemsList.expand((items) => items).where((item) => item.date.isSameDate(selectedDay)).map((item) => Task(details: item.name, date: item.date)).toList();

    // Filter out expired tasks
    tasksForSelectedDay = tasksForSelectedDay.where((task) => !task.date.isBefore(DateTime.now())).toList();

    // Populate tasksMap with non-expired tasks
    tasksMap[selectedDay] = tasksForSelectedDay;

    setState(() {});
  }

  Future<void> _fetchTasksForTheCurrentMonth() async {
    // Clear tasksMap before populating it again
    tasksMapForMonth.clear();

    // Get the current date
    DateTime currentDate = DateTime.now();

    // Get the first day of the current month
    DateTime firstDayOfMonth = DateTime(currentDate.year, currentDate.month, 1);

    // Get the last day of the current month
    DateTime lastDayOfMonth = DateTime(currentDate.year, currentDate.month + 1, 0);

    // Iterate through all days in the month
    for (DateTime date = firstDayOfMonth; date.isBefore(lastDayOfMonth.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      for (var items in Globals.itemsList) {
        for (var item in items) {
          if (item.date.isSameDate(date)) {
            tasksMapForMonth[date] = tasksMapForMonth[date] ?? [];

            // Create a Task object with necessary details
            Task task = Task(details: item.name, date: item.date);

            // Add the Task object to the tasksMap
            tasksMapForMonth[date]!.add(task);
          }
        }
      }
    }
    print("RABİA ALLAHINI SİKEYİM: $tasksMapForMonth");
    setState(() {});
  }

  Future<void> _pullRefresh() async {

    setState(() {
      _fetchDataFromDatabase();
    });
  }



  void _navigateToDetailsPage(Item item) {
    Navigator.pushReplacement(
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
      backgroundColor: Colors.green,
      child: const Icon(Icons.add),
    );
  }


  void _addItem(Tuple2<Item, bool> newItemWithShare) {
    setState(() {

      final Item newItem = newItemWithShare.item1;
      final bool shareWithOrganization = newItemWithShare.item2;

      Globals.itemsList[0].add(newItem);

      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Add the item to user's tasks
        DatabaseReference userTaskReference =
        firebaseRef.child('users').child(user.uid).child('tasks');
        Map<String, dynamic> newTaskData = {
          "name": newItem.name,
          "description": newItem.description ?? "",
          "date": newItem.date.toUtc().toIso8601String(),
          "email": user.email
        };
        print("New task data: $newTaskData");
        DatabaseReference newTaskReference =
        userTaskReference.push();
        newTaskReference.set(newTaskData);
        Globals.taskKeysByName[newItem.name] = newTaskReference.key!;
        DatabaseReference userTaskReference2 =
        firebaseRef.child('users').child(user.uid).child("kurum");

        userTaskReference2.get().then((DataSnapshot snapshot) {
          if (snapshot.value != null && snapshot.value is Map<dynamic, dynamic>) {
            Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

            if (data.containsKey('invitationCode') &&
                data.containsKey('name') &&
                data['invitationCode'] is String &&
                data['name'] is String) {
              String invitationCode = data['invitationCode'] as String;
              String name = data['name'] as String;
              String result = ' $name - $invitationCode ';
              CollectionReference kurumlarCollection =
              FirebaseFirestore.instance.collection('kurumlar');

              kurumlarCollection
                  .where(FieldPath.documentId, isEqualTo: result)
                  .get()
                  .then((QuerySnapshot querySnapshot) {
                if (querySnapshot.docs.isNotEmpty) {
                  DocumentReference documentReference =
                      querySnapshot.docs.first.reference;
                  Map<String, dynamic> userData = {
                    'username': username, // replace with actual username
                    'name': newItem.name,
                    'description': newItem.description,
                    "date": newItem.date.toUtc().toIso8601String(),
                  };

                  if (shareWithOrganization) {
                    documentReference.set({
                      'tasks': FieldValue.arrayUnion([userData]),
                    }, SetOptions(merge: true));
                    print('Array field updated/created successfully!');
                  }


                } else {
                  print('Document not found with the specified value.');
                }
              }).catchError((error) {
                print("Error: $error");
              });
            }
          } else {
            print('Snapshot value is null or not a Map<dynamic, dynamic>');
          }
        }).catchError((error) {
          print("Error: $error");
        });
      }
    });
  }

  Future<Tuple2<Item, bool>?> _navigateToNewItemScreen(BuildContext context) async {
    return await Navigator.push(
      context,
      MaterialPageRoute<Tuple2<Item, bool>>(
        builder: (context) => NewItemScreen( showRow: true, changeBehavior: 1,),
      ),
    );
  }
  void _fetchAndUpdateState(DatabaseReference userTaskReference) async {
    // Fetch the details of the task
    final snapshot = await userTaskReference.get();
    print("SEKS ECE SEKS ");
    // Check if the snapshot value is not null and is of the expected type
    if (snapshot.value is Map<dynamic, dynamic>?) {
      // Access the data from the snapshot
      Map<dynamic, dynamic>? taskData = snapshot.value as Map<dynamic, dynamic>?;

      if (taskData != null) {
        // Create a new Item instance using the fetched data
        Item selectedItem = Item(
          name: taskData['name'],
          description: taskData['description'],
          date: DateTime.parse(taskData['date']),
        );

        // Use the 'selectedItem' instance as needed
       print("SEKS ECE SEKS ");
        // Navigate to the DetailsPage and pass the selected item
        _navigateToDetailsPage(selectedItem);
      }
    }
  }

  void _removeItem(Item item) async {
    // Perform asynchronous operations first
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String? taskKey = Globals.taskKeysByName[item.name];

      DatabaseReference userTaskReference =
      firebaseRef.child('users').child(user.uid).child("tasks").child(
          taskKey!);

      await userTaskReference.remove();

      DatabaseReference userKurumRef = firebaseRef.child('users').child(user.uid).child("kurum");

      // Use async/await to handle the asynchronous operation
      try {
        DataSnapshot snapshot = await userKurumRef.get();

        if (snapshot.value != null) {
          print("The 'kurum' child exists under users/${user.uid}");

          // Access data using DataSnapshot methods
          dynamic userData = snapshot.value;

          if (userData != null && userData is Map<dynamic, dynamic>) {
            String? name = userData['name'];
            String? invitationCode = userData['invitationCode'];

            if (name != null && invitationCode != null) {
              String kurumName = " $name - $invitationCode ";

              final FirebaseFirestore firestore = FirebaseFirestore.instance;

              final DocumentReference documentRef = firestore.collection('kurumlar').doc(kurumName);
              DocumentSnapshot documentSnapshot = await documentRef.get();

              if (documentSnapshot.exists) {
                List<dynamic>? tasks = documentSnapshot['tasks'];
                if (tasks != null) {
                  List<dynamic> tasksCopy = List.from(tasks); // Create a copy of the list
                  for (var task in tasksCopy) {
                    if (task['username'] == username &&
                        task['description'] == item.description &&
                        task['name'] == item.name) {
                      tasks.remove(task); // Modify the original list
                    }
                  }

                  await documentRef.update({'tasks': tasks});
                }

                print("Document exists under 'kurumlar/$kurumName'");
                // Proceed with further operations here
                // Update UI state, etc.
              } else {
                print("Document does not exist under 'kurumlar/$kurumName'");
              }
            } else {
              print("Invalid data format for 'name' or 'invitationCode'");
            }
          } else {
            print("Invalid data format for 'userData'");
          }
        } else {
          print("The 'kurum' child does not exist under users/${user.uid}");
        }
      } catch (error) {
        print("Error: $error");
      }

    }

    setState(() {
      Globals.itemsList[0].remove(item);
    });

    }



  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _calculateDaysLeft(DateTime date) {
    final currentDate = DateTime.now();
    final daysLeft = daysBetween(currentDate, date);

    if (daysLeft == 0) {
      return 'Today';
    }else if(daysLeft<1){
       return 'Expired';
    }
    else {
      return '$daysLeft Gün Kaldı';
    }
  }

  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }


}

