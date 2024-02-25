// kurumsaldetails.dart

import 'dart:core';
import 'dart:math';
import 'package:casetracker/Kurumsal/KurumsalMain.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../Utility/globals.dart';
import 'KurumsalEditItem.dart';



class KurumsalDetailsPage extends StatefulWidget {
  final String title;
  final String item;
  final String description;
  final DateTime itemDate;
  final VoidCallback onRemove;
  final String username;
  final String documentName; // Add this parameter

  KurumsalDetailsPage({
    required this.title,
    required this.item,
    required this.description,
    required this.itemDate,
    required this.onRemove,
    required this.username,
    required this.documentName, // Include it in the constructor
  });

  @override
  _KurumsalDetailsPageState createState() => _KurumsalDetailsPageState();
}

class _KurumsalDetailsPageState extends State<KurumsalDetailsPage> {
  KurumsalItem _item = KurumsalItem(name: "", description: "", date: DateTime.now(), username: "");
  final firebaseRef = FirebaseDatabase(
    databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
  ).reference();


  @override
  void initState() {
    super.initState();
    _item = KurumsalItem(name: widget.item, description: widget.description, date: widget.itemDate, username: widget.username);
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kurumsal Detay Sayfası'),
        backgroundColor: Colors.grey,
        elevation: 4,
        shape: const UnderlineInputBorder(),
      ),
      body: CustomPaint(
        painter: MyCustomPainter(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView( // Wrap your Column with SingleChildScrollView
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 150,),
                _buildItemNameField('', _item.name),
                const SizedBox(height: 30),
                _buildUsernameField('Görevli:', _item.username),
                const SizedBox(height: 30),
                _buildDescriptionField('', _item.description),
                const SizedBox(height: 30),
                Text(
                  'Tarih: ${_formatDate(_item.date)}',
                  style: const TextStyle(
                      fontSize: 20
                  ),
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: () {
                    _navigateToEditItemScreen(context);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    foregroundColor: Colors.limeAccent,
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('Düzenle'),
                ),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Kaldır'),
                          content: const Text('Bunu kaldırmak istediğinizden emin misiniz?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('İptal'),
                            ),
                            TextButton(
                              onPressed: () async {
                                _removeItem(_item);
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text('Kaldır'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    foregroundColor: Colors.limeAccent,
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('Kaldır'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemNameField(String label, String? value) {
    return SizedBox(
      height: 75, // Adjust the height for the item name field
      child: TextField(
        textAlign: TextAlign.center,
        readOnly: true,
        controller: TextEditingController(text: value),
        style:const  TextStyle(
          backgroundColor: Colors.transparent, // Set background color to be barely visible
          fontSize: 16.0,
        ),
        maxLines: 1,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.brown[100], // Set a slightly visible background color
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField(String label, String? value) {
    return SizedBox(
      child: TextField(
        readOnly: true,
        controller: TextEditingController(text: value),
        style: TextStyle(
          backgroundColor: Colors.grey[200],
          fontSize: 15.0, // Increase the font size if needed
        ),
        maxLines: 3, // Increase the maxLines property to make the text field taller
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[200],
          enabledBorder: OutlineInputBorder(
            borderSide:const  BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }
  Widget _buildUsernameField(String label, String? value) {
    return SizedBox(
      height: 50,
      child: TextField(
        textAlign: TextAlign.center,
        readOnly: true,
        controller: TextEditingController(text: 'Görevli : $value' ),
        style: TextStyle(
          backgroundColor: Colors.grey[200],
          fontSize: 15.0, // Increase the font size if needed
        ),
        maxLines: 1, // Increase the maxLines property to make the text field taller
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[200],
          enabledBorder: OutlineInputBorder(
            borderSide:const  BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(8.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  void _removeItem(KurumsalItem item) async {
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
                    if (task['username'] == item.username &&
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


  void _navigateToEditItemScreen(BuildContext context) async {
    final editedItem = await Navigator.push(
      context,
      MaterialPageRoute<KurumsalItem>(
        builder: (context) => EditKurumsalItemScreen(kurumsalItem: _item),
      ),
    );
    if (editedItem != null) {
      setState(() {
        _item.name = editedItem.name;
        _item.description = editedItem.description;
        _item.date = editedItem.date;
        _item.username = editedItem.username;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}

class MyCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.fill;

    final double radius = size.width / 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(0, 0), radius: radius),
      pi / 2,
      -pi / 2,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
