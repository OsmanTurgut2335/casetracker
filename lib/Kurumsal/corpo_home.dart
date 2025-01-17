import 'dart:core';
import 'dart:ffi';
import 'package:casetracker/Kurumsal/corpo_details.dart';
import 'package:casetracker/core/util/corpoUtil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:share/share.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_core/firebase_core.dart';

import '../Bireysel/newItemScreen.dart';
import '../Utility/firebase_options.dart';

import '../Utility/globals.dart'; // Import the globals.dart file
import '../Utility/login_screen.dart';

void KurumsalMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp()); // Use the root widget (MyApp) here
}

void main() {
  KurumsalMain();
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
              return MyHomePage(user: user, documentName: '',);
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




class MyHomePage extends StatefulWidget {
  final User? user; // Change the type to User?
  final String documentName; // Add this line

  MyHomePage({this.user, required this.documentName});

  @override
  _MyHomePageState createState() => _MyHomePageState();



}


class Event {
  final String title;

  const Event(this.title);

  @override
  String toString() => title;
}
class _MyHomePageState extends State<MyHomePage> {


  final PageController _pageController = PageController();
  int _currentPage = 0;
  Map<DateTime, List<Task>> tasksMap = {};
  List<KurumsalItem> filteredItems = [];
  DateTime _selectedDay = DateTime.now();
  late String username;
  late String actualUsername;

  final CorpoUtil corpoUtil = CorpoUtil();
  Map<DateTime, List<Task>> tasksMapForMonth = {};
  bool isFoundingMember = false;
  final firebaseRef = FirebaseDatabase(
    databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
  ).reference();

  @override
  void initState() {
    super.initState();
    corpoUtil.fetchKurumsalItemsFromDatabase();
    getUserUsername();
  }

  void getUserUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userTaskReference3 = firebaseRef.child('users').child(user.uid).child("username");
      try {
        DataSnapshot snapshot = await userTaskReference3.get();

        // Check if the snapshot exists and contains a value
        if (snapshot.exists && snapshot.value != null) {
          String username = snapshot.value.toString(); // Convert the value to a String
          actualUsername= username;

          // Here you can use the username value as needed.
        } else {
          print("Username not found or null.");
        }
      } catch (error) {
        print("Failed to retrieve username: $error");
      }
    } else {
      print("User not signed in.");
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
    String yarrak = widget.documentName;

    return WillPopScope(
      onWillPop: () async {
        corpoUtil.fetchKurumsalItemsFromDatabase();
        setState(() {
          Globals.kurumsalItemsList[0].sort((a, b) => a.date.compareTo(b.date));
        });
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text("Kurumsal Ekranı"),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'signOut') {
                  _signOut();
                } else if (value == 'showInvitationCode') {
                  _showInvitationCode();
                } else if (value == 'shareInvitationCode') {
                  _shareInvitationCode();
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem(
                    value: 'signOut',
                    child: Text('Çıkış'),
                  ),
                  const PopupMenuItem(
                    value: 'showInvitationCode',
                    child: Text('Davet Kodunu Göster'),
                  ),
                  const PopupMenuItem(
                    value: 'shareInvitationCode',
                    child: Text('Davet Kodunu Paylaş'),
                  ),
                ];
              },
            ),
          ],
          backgroundColor: Colors.grey,
          elevation: 4,
          shape: const UnderlineInputBorder(),
        ),
        body: Column(
          children: [
            _buildTabBar(),
            _currentPage == 0 ? _buildSearchBar() : const SizedBox(),
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
                    child: _buildPage(filteredItems.isNotEmpty ? filteredItems : Globals.kurumsalItemsList[0]),
                  ),
                  _buildCalendarPage(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _currentPage == 0
            ? StreamBuilder<DocumentSnapshot>(
          stream: yarrak.isNotEmpty ? FirebaseFirestore.instance.collection('kurumlar').doc(yarrak).snapshots() : null,
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              if (snapshot.hasData && snapshot.data!.exists) {
                final Map<String, dynamic>? data = snapshot.data!.data() as Map<String, dynamic>?;

                if (data != null && data.containsKey('members')) {
                  final members = data['members'] as List<dynamic>;
                  if (members.isNotEmpty) {
                    final firstMember = members[0] as Map<String, dynamic>;
                    final name = firstMember['name'] as String;
                    if (name == FirebaseAuth.instance.currentUser?.uid) {
                      return FloatingActionButton(
                        onPressed: () async {
                          final newItem = await _navigateToNewItemScreen(context);
                          _addItem(newItem as KurumsalItem);
                        },
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.add),
                      );
                    }
                  }
                }
              } else {

              }
              return const SizedBox();
            }
          },
        )
            : null,
      ),
    );
  }


  Widget _buildTabBar() {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem("Liste Görünümü", 0),
          _buildTabItem("Takvim Görünümü", 1),
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


  Widget _buildPage(List<KurumsalItem> items) {
    items.sort((a, b) => a.date.compareTo(b.date));

    return RefreshIndicator(
      onRefresh: _pullRefresh,
      child: ListView(
        children: [
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _calculateDaysLeft(item.date),
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      if (_calculateDaysLeft(item.date) != 'Süresi Geçti')
                        Text(
                          'Görevli : ${item.username}',
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      // Add your additional subtext here
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KurumsalDetailsPage(
                          title: "Screen ${_currentPage + 1}",
                          item: item.name,
                          description: item.description ?? "",
                          itemDate: item.date,
                          username: item.username,
                          onRemove: () {
                            _removeItem(item);
                          },
                          documentName: widget.documentName, // Pass it here
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }





  Widget _buildCalendarPage() {
    BuildContext context = this.context;
    _fetchTasksForTheCurrentMonth();
    bool _isNavigating = false; // Add this boolean flag

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

    return SingleChildScrollView(
      child: Column(
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
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Text('${_formatDate(_selectedDay)} tarihi için görevler :'),
                for (final task in tasksMap[_selectedDay]!)
                  GestureDetector(
                    onTap: ()  async {
                      // Access Firestore
                      FirebaseFirestore firestore = FirebaseFirestore.instance;



                        QuerySnapshot querySnapshot = await firestore
                            .collection('kurumlar')
                            .where(FieldPath.documentId, isEqualTo: widget.documentName)
                            .get();







                      // Fetch the current authenticated user
                      User? user = FirebaseAuth.instance.currentUser;

                      // Print statement to check if user is null
                      print("Current user: $user");

                      if (user != null) {
                        String? taskKey = Globals.taskKeysByName[task.details];
                        DatabaseReference userTaskReference = firebaseRef
                            .child('users')
                            .child(user.uid)
                            .child('tasks')
                            .child(taskKey!);

                        _fetchAndUpdateState(userTaskReference);
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
                            style: const TextStyle(
                              color: Colors.white,
                            ),
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
      for (var items in Globals.kurumsalItemsList) {
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

    setState(() {});
  }


  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onChanged: (value) {
          _filterItems(value);
        },
        decoration:const  InputDecoration(
          hintText: 'Görev Ara',
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  void _filterItems(String searchTerm) {
    setState(() {
      filteredItems = Globals.kurumsalItemsList[0]
          .where((item) =>
          item.name.toLowerCase().contains(searchTerm.toLowerCase())).cast<KurumsalItem>()
          .toList();
    });
  }

  void _addItem(KurumsalItem? kurumsalItem){
    //BURADA FİRESTOREA EKLERKEN USERNAME İ YANLIŞ EKLİYOR.ZATEN BU EKRANDAN Bİ ADD ITEM OLUCAKSA
    //BİR TANE USERNAME OLUR O DA YÖNETİCİNİN . ORDAN DA GİDİLEBİLİR.
    if (kurumsalItem != null) {

      Globals.kurumsalItemsList[0].add(kurumsalItem);
      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
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
                    'username': actualUsername, // replace with actual username
                    'name': kurumsalItem.name,
                    'description': kurumsalItem.description,
                    "date": kurumsalItem.date.toUtc().toIso8601String(),
                  };


                    documentReference.set({
                      'tasks': FieldValue.arrayUnion([userData]),
                    }, SetOptions(merge: true));
                    print('Array field updated/created successfully!');

                    // Add the item to user's tasks
                    DatabaseReference userTaskReference =
                    firebaseRef.child('users').child(user.uid).child('tasks');
                    Map<String, dynamic> newTaskData = {
                      "name": kurumsalItem.name,
                      "description": kurumsalItem.description ?? "",
                      "date": kurumsalItem.date.toUtc().toIso8601String(),
                      "email": user.email
                    };
                    print("New task data: $newTaskData");
                    DatabaseReference newTaskReference =
                    userTaskReference.push();
                    newTaskReference.set(newTaskData);
                    Globals.taskKeysByName[kurumsalItem.name] = newTaskReference.key!;

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

    }

  }

  void _fetchAndUpdateState(DatabaseReference userTaskReference) async {
    // Fetch the details of the task
    final snapshot = await userTaskReference.get();

    // Check if the snapshot value is not null and is of the expected type
    if (snapshot.value is Map<dynamic, dynamic>?) {
      // Access the data from the snapshot
      Map<dynamic, dynamic>? taskData = snapshot.value as Map<dynamic, dynamic>?;

      if (taskData != null) {
        // Create a new Item instance using the fetched data
        KurumsalItem selectedItem = KurumsalItem(
          name: taskData['name'],
          description: taskData['description'],
          date: DateTime.parse(taskData['date']),
          username: username,
        );

        // Use the 'selectedItem' instance as needed

        // Navigate to the DetailsPage and pass the selected item
        _navigateToDetailsPage(selectedItem);
      }
    }
  }
  Future<void> checkUserFoundingMembership() async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final String yarrak = widget.documentName;

    FirebaseFirestore.instance
        .collection('kurumlar')
        .doc(yarrak)
        .get()
        .then((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        // Explicitly cast the data object to a Map<String, dynamic>
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

        if (data != null && data['members'] is List<dynamic>) {
          var members = data['members'] as List<dynamic>;

          if (members.isNotEmpty) {
            // Access the fields of the first item in the 'members' array
            var firstMember = members[0];
            if (firstMember is Map<String, dynamic>) {
              // Check if 'kurucuÜye' exists in the first member
              var kurucuUyeValue = firstMember['name'];
              if (kurucuUyeValue.toString() == uid ) {
                isFoundingMember = true;
              } else {
                // If 'kurucuÜye' doesn't exist, do something else
                print('No kurucuÜye value found');
              }
            } else {
              // Handle case when firstMember is not a Map<String, dynamic>
              print('Invalid format for first member');
            }
          } else {
            // 'members' array is empty
            print('No members found.');
          }
        }
      } else {
        // Document not found
        print('Document not found');
      }
    }).catchError((error) {
      // Handle errors
      print('Error fetching document: $error');
    });
  }

  Future<void> _fetchTasksForSelectedDay(DateTime selectedDay) async {
    // Clear tasksMap before populating it again
    tasksMap.clear();

    // Fetch tasks for the selected day from the database
    List<Task> tasksForSelectedDay = Globals.kurumsalItemsList.expand((items) => items).where((item) =>
        item.date.isSameDate(selectedDay)).map((item) => Task(details: item.name, date: item.date)).toList();

    // Filter out expired tasks
    tasksForSelectedDay = tasksForSelectedDay.where((task) => !task.date.isBefore(DateTime.now())).toList();

    // Populate tasksMap with non-expired tasks
    tasksMap[selectedDay] = tasksForSelectedDay;

    setState(() {});
  }


  Future<void> _pullRefresh() async {

    setState(() {
      corpoUtil.fetchKurumsalItemsFromDatabase();
    });
  }




  void _navigateToDetailsPage(KurumsalItem item) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => KurumsalDetailsPage(
          title: "Screen ${_currentPage + 1}",
          item: item.name,
          description: item.description ?? "",
          itemDate: item.date,
          onRemove: () {
            _removeItem(item);
          },
          username: item.username,
          documentName: widget.documentName, // Pass it here
        ),
      ),
    );
  }



  Future<KurumsalItem?> _navigateToNewItemScreen(BuildContext context) async {
    return await Navigator.push(
      context,
      MaterialPageRoute<KurumsalItem>(
        builder: (context) => NewItemScreen(showRow: false, changeBehavior: 2,),
      ),
    );
  }
  void _removeItem(KurumsalItem item) async {

    // Perform asynchronous operations first
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? documentName = widget.documentName; // Provide the document name here

      // Get the reference to the Firestore collection
      CollectionReference kurumlarCollection = FirebaseFirestore.instance.collection('kurumlar');

      // Get the document reference based on the document name
      DocumentReference documentRef = kurumlarCollection.doc(documentName);

      // Fetch the document snapshot
      DocumentSnapshot documentSnapshot = await documentRef.get();

      // Check if the document exists
      if (documentSnapshot.exists) {
        // Get the tasks array from the document
        List<dynamic>? tasks = (documentSnapshot.data() as Map<String, dynamic>?)?['tasks'];


        if (tasks != null) {
          // Create a copy of the tasks list to iterate over
          List<dynamic> tasksCopy = List.from(tasks);

          // Iterate through the items in the tasks array
          for (var task in tasksCopy) {
            // Check if the task matches the item to be removed
            if (task is Map<String, dynamic> && // Ensure task is a Map<String, dynamic>
                task['date'] == item.date &&
                task['description'] == item.description &&
                task['name'] == item.name &&
                task['username'] == user.displayName) {
              // Remove the matching task from the tasks array
              tasks.remove(task);
            }
          }

          // Update the document in Firestore with the modified tasks array
          await documentRef.update({'tasks': tasks});
        }
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
      return 'Bugün';
    }else if(daysLeft<1){
      return 'Süresi Geçti';
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

  void _showInvitationCode() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final firebaseRef = FirebaseDatabase(
        databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
      ).reference();

      // Update the reference to include the user's UID
      DatabaseReference kurumsalReference = firebaseRef.child("users").child(user.uid).child("kurum");

      // Read the invitation code from the database
      DataSnapshot dataSnapshot = await kurumsalReference.get();
      Map<dynamic, dynamic>? values = dataSnapshot.value as Map<dynamic, dynamic>?;

      if (values != null && values.containsKey("invitationCode")) {
        String invitationCode = values["invitationCode"] as String;


        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Kurum Invitation Code'),
              content: SelectableText('Invitation Code: $invitationCode'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

      }
    }
  }


    Future<void> _shareInvitationCode() async {

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final firebaseRef = FirebaseDatabase(
          databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
        ).reference();

        // Update the reference to include the user's UID
        DatabaseReference kurumsalReference = firebaseRef.child("users").child(user.uid).child("kurum");

        // Read the invitation code from the database
        DataSnapshot dataSnapshot = await kurumsalReference.get();
        Map<dynamic, dynamic>? values = dataSnapshot.value as Map<dynamic, dynamic>?;

        if (values != null && values.containsKey("invitationCode")) {
          String invitationCode = values["invitationCode"] as String;
          // Find the index of the '-' character
          int dashIndex = widget.documentName.indexOf('-');

      // Extract the text before the '-' character
          String textBeforeDash = widget.documentName.substring(0, dashIndex).trim();

          Share.share("$textBeforeDash kurumumuza bu davet koduyla katılabilirsin: $invitationCode");

        }
      }
    }



  Future<bool> checkIfKurucuMemberExists() async {
    try {
      // Reference to the 'kurumlar' collection
      CollectionReference kurumlarCollection = FirebaseFirestore.instance.collection('kurumlar');

      // Document ID of the specific document you want to check
      String documentId = 'your_document_id_here';

      // Query to check if any member has 'kurucuÜye' equal to 'evet'
      QuerySnapshot querySnapshot = await kurumlarCollection
          .doc(documentId)
          .collection('members')
          .where('kurucuÜye', isEqualTo: 'evet')
          .get();

      // Return true if at least one member is a kurucuÜye with the value "evet"
      return querySnapshot.docs.isNotEmpty;
    } catch (error) {
      print('Error: $error');
      // Return false in case of an error
      return false;
    }
  }

}
