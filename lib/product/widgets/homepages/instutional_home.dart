import 'package:casetracker/core/util/time/date_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../Utility/globals.dart';
import '../../../core/util/corpoUtil.dart';
import '../../../screens/kurumsal/corpo_details.dart';

class InstutionalHome extends StatefulWidget {
  const InstutionalHome({super.key, required this.items, required this.documentName, required this.currentPage});
  final List<KurumsalItem> items;
  final String documentName;
  final int currentPage;
  @override
  State<InstutionalHome> createState() => _InstutionalHomeState();
}

class _InstutionalHomeState extends State<InstutionalHome> {
  final _dateHelper= DateUtilsHelper();
  final CorpoUtil corpoUtil = CorpoUtil();

  @override
  Widget build(BuildContext context) {
    List<KurumsalItem> _items = widget.items;
    _items.sort((a, b) => a.date.compareTo(b.date));

    return RefreshIndicator(
      onRefresh: _pullRefresh,
      child: ListView(
        children: [
          for (final item in _items)
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
                    '${item.name} - ${DateUtilsHelper.formatDate(item.date)}',
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateUtilsHelper.calculateDaysLeft(item.date),
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      if (DateUtilsHelper.calculateDaysLeft(item.date) != 'Süresi Geçti')
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
                          title: "Screen ${widget.currentPage + 1}",
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
  Future<void> _pullRefresh() async {

    setState(() {
      corpoUtil.fetchKurumsalItemsFromDatabase();
    });
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

}
