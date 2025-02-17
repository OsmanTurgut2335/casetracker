import 'dart:core';
import 'package:casetracker/core/data/firebase_repository/database_repository.dart';
import 'package:casetracker/core/helpers/firebase_helper.dart';
import 'package:casetracker/core/helpers/home_screen_value_helper.dart';

import 'package:casetracker/product/widgets/calendar_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:tuple/tuple.dart';


import '../../Utility/firebase_options.dart';
import '../../Utility/globals.dart';
import '../../Utility/login_screen.dart';
import '../../core/util/task/task_utils.dart';
import '../../product/widgets/homepages/personal_home.dart';
import '../../product/widgets/tabbar/tab_bar_views.dart';
import 'details_screen.dart';
import 'new_item_screen.dart';


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
  final helper=HomeScreenValueHelper();


  final PageController _pageController = PageController();
  int _currentPage = 0;
  Map<DateTime, List<Task>> tasksMap = {};
  Map<DateTime, List<Task>> tasksMapForMonth = {};
  List<Item> filteredItems = [];

  DateTime _selectedDay = DateTime.now();
  late List<DateTime> daysWithTasks ;
  TabBarViews tabBarViews = TabBarViews();
  TaskUtils taskUtils = TaskUtils();

  final databaseRepository=DatabaseRepository();
  final firebaseRef=FirebaseHelper.firebaseRef;

  late String username;

  @override
  void initState() {
    super.initState();
    helper.initializeValues();
    databaseRepository.fetchDataFromDatabase();

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
        await databaseRepository.fetchDataFromDatabase();
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
                    child: Text('Çıkış'),
                  ),
                ];
              },
            ),
          ],
          backgroundColor: Colors.grey, // Set app bar background color
          elevation: 4, // Set the elevation for a shadow effect
          shape: const UnderlineInputBorder(),
          // ... other properties
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              tabBarViews.buildTabBar(_currentPage),
              _currentPage == 0 ? _buildSearchBar() : const SizedBox(),
              SizedBox(
                height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - kBottomNavigationBarHeight,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                      if (index == 1) {
                        _selectedDay = DateTime.now();
                        taskUtils.onDaySelected(_selectedDay,tasksMap,true);
                      }
                    });
                  },
                  children: [
                    Container(
                   //   child: _buildPage(filteredItems.isNotEmpty ? filteredItems : Globals.itemsList[0]),
                      child: TaskListPage(
                        items: filteredItems.isNotEmpty ? filteredItems : Globals.itemsList[0],
                        onRefresh: _pullRefresh, // Make sure this function is defined
                        removeItem: removeItem,  // Ensure removeItem function exists
                        currentPage: _currentPage, // Ensure _currentPage is accessible
                      ),
                    ),
                   Container(
                    child: CalendarWidget(selectedDay: _selectedDay, tasksMap: tasksMap,
                        tasksMapForMonth: tasksMapForMonth, fetchAndUpdateState: _fetchAndUpdateState,isPersonal: true,),
                 ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _currentPage == 0 ? _buildFloatingButton(context) : null,
      ),
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
          hintText: 'Görev Ara...',
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



  Future<void> _pullRefresh() async {

    setState(() {
      databaseRepository.fetchDataFromDatabase();
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
            removeItem(item);
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
          taskUtils.addItem(newItemWithShare: Tuple2(newItem as Item, true), username: username);
          //taskUtils.addItem(newItem, username);
         setState(() {

         });

        //  _addItem(newItem);
        }
      },
      backgroundColor: Colors.green,
      child: const Icon(Icons.add),
    );
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

        // Navigate to the DetailsPage and pass the selected item
        _navigateToDetailsPage(selectedItem);
      }
    }
  }

  void removeItem(Item item){
      taskUtils.removeItem(item, username);

    setState(() {
      Globals.itemsList[0].remove(item);
    });

  }


}

