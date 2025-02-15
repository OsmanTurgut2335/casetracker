

import 'package:casetracker/Bireysel/personal_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:tuple/tuple.dart';


import '../../../Utility/globals.dart';
import '../../helpers/firebase_helper.dart';

class TaskUtils{

  final firebaseRef=FirebaseHelper.firebaseRef;

  Future<void> fetchTasksForSelectedDay(DateTime selectedDay, Map<DateTime, List<Task>> tasksMap,bool isPersonal) async {

    //if its from personal screen its 1

    // Clear tasksMap before populating it again
      tasksMap.clear();

    if(isPersonal){

      // Fetch tasks for the selected day from the database
      List<Task> tasksForSelectedDay = Globals.itemsList.expand((items) => items).where((item) =>
          item.date.isSameDate(selectedDay)).map((item) => Task(details: item.name, date: item.date)).toList();

      // Filter out expired tasks
      tasksForSelectedDay = tasksForSelectedDay.where((task) => !task.date.isBefore(DateTime.now())).toList();

      // Populate tasksMap with non-expired tasks
      tasksMap[selectedDay] = tasksForSelectedDay;

    }


    // Fetch tasks for the selected day from the database
    List<Task> tasksForSelectedDay = Globals.kurumsalItemsList.expand((items) => items).where((item) =>
        item.date.isSameDate(selectedDay)).map((item) => Task(details: item.name, date: item.date)).toList();

    // Filter out expired tasks
    tasksForSelectedDay = tasksForSelectedDay.where((task) => !task.date.isBefore(DateTime.now())).toList();

    // Populate tasksMap with non-expired tasks
    tasksMap[selectedDay] = tasksForSelectedDay;


  }

  void onDaySelected(DateTime selectedDay,Map<DateTime, List<Task>> tasksMap,bool isPersonal) async {

// SELECTED DAY İ KULLANMIYORUZ.KULLANMAK İÇİN DÖNDÜREBİLİRİZ VOİDİ DEĞİŞTİRİP LAZIMSA.

   // _selectedDay = selectedDay;


    await fetchTasksForSelectedDay(selectedDay,tasksMap,isPersonal);



  }

  void removeItem(Item item,String username) async {
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


  }

  Future<void> fetchTasksForTheCurrentMonth(Map<DateTime, List<Task>> tasksMapForMonth,bool isPersonal) async {
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
      if(isPersonal){

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


  }

  Future<void> addItem(Tuple2<Item, bool> newItemWithShare,String username) async {


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

  }


}