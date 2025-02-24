import 'dart:core';
import 'package:casetracker/core/data/firebase_repository/database_repository.dart';
import 'package:casetracker/core/helpers/firebase_helper.dart';
import 'package:casetracker/core/util/corpoUtil.dart';
import 'package:casetracker/core/widgets/search_bar.dart';
import 'package:casetracker/product/widgets/homepages/instutional_home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/helpers/globals.dart';
import '../login_screen.dart';
import '../../core/provider/providers.dart';
import '../../core/util/task/task_utils.dart';
import '../../product/widgets/calendar_page.dart';
import '../../product/widgets/tabbar/tab_bar_views.dart';

import '../personal/new_item_screen.dart';
import 'instutional_details_screen.dart';



extension DateTimeExtension on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
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
              return const LoginScreen();
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

class MyHomePage extends ConsumerStatefulWidget  {
  final User? user; // Change the type to User?
  final String documentName; // Add this line

  const MyHomePage({this.user, required this.documentName});

  @override
  _MyHomePageState createState() => _MyHomePageState();

}

class Event {
  final String title;

  const Event(this.title);

  @override
  String toString() => title;
}
class _MyHomePageState extends ConsumerState<MyHomePage> {


  final PageController _pageController = PageController();
  int _currentPage = 0;
  Map<DateTime, List<Task>> tasksMap = {};
  List<KurumsalItem> filteredItems = [];

  DateTime _selectedDay = DateTime.now();
  late String username;
  late String actualUsername;
  TaskUtils taskUtils = TaskUtils();
  final CorpoUtil corpoUtil = CorpoUtil();
  Map<DateTime, List<Task>> tasksMapForMonth = {};
  bool isFoundingMember = false;

  final firebaseRef = FirebaseHelper.firebaseRef;
  final databaseRepository = DatabaseRepository();

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

    String documentName = widget.documentName;

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
                  databaseRepository.showInvitationCode(context);
                } else if (value == 'shareInvitationCode') {
                 // _shareInvitationCode();
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
            TabBarViews().buildTabBar(_currentPage),
            _currentPage == 0 ? CustomSearchBar(initialItems: filteredItems) : const SizedBox(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    if (index == 1) {
                      _selectedDay = DateTime.now();
                      taskUtils.onDaySelected(_selectedDay,tasksMap,false);
                    }
                  });
                },
                children: [
                  Container(
                 //   child: _buildPage(filteredItems.isNotEmpty ? filteredItems : Globals.kurumsalItemsList[0]),
                   child:  InstutionalHome(items: filteredItems.isNotEmpty ? filteredItems : Globals.kurumsalItemsList[0],
                       documentName: documentName, currentPage: _currentPage,),
                  ),
                 // _buildCalendarPage(),
                 CalendarWidget(selectedDay: _selectedDay, tasksMap: tasksMap,
                      tasksMapForMonth: tasksMapForMonth, fetchAndUpdateState: _fetchAndUpdateState,isPersonal: false,),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _currentPage == 0
            ? StreamBuilder<DocumentSnapshot>(
          stream: documentName.isNotEmpty ? FirebaseFirestore.instance.collection('kurumlar').doc(documentName).snapshots() : null,
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
                          taskUtils.addItem( kurumsalItem:  newItem as KurumsalItem);
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
    final authViewModel = ref.read(authViewModelProvider);
   authViewModel.removeItem(item, widget.documentName);

    setState(() {
      Globals.itemsList[0].remove(item);
    });
  }



}
