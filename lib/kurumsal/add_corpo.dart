import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../Utility/globals.dart';

class KurumEkleScreen extends StatefulWidget {
  @override
  _KurumEkleScreenState createState() => _KurumEkleScreenState();
}

class _KurumEkleScreenState extends State<KurumEkleScreen> {
  bool isButtonEnabled = true; // Flag to control button state
  File? _image;
  TextEditingController _kurumNameController = TextEditingController();

  Future getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = pickedFile != null ? File(pickedFile.path) : null;
    });
  }



  void _onKurumEkleButtonPressed() async {
    // Disable the button
    setState(() {
      isButtonEnabled = false;
    });

    if (_image != null) {
      final BuildContext currentContext = context;

      // Create a reference to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('kurum_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload the image to Firebase Storage
      final UploadTask uploadTask = storageRef.putFile(_image!);

      final TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

      // Get the download URL of the uploaded image
      final String downloadURL = await taskSnapshot.ref.getDownloadURL();

      // Use kurumName as the field name
      String kurumName = _kurumNameController.text;



      // Now, store the download URL, kurumName, and invitationCode in Cloud Firestore
      final db = FirebaseFirestore.instance;

      // Initialize the members field as an empty array
      List<Map<String, dynamic>> members = [];



      User? user1 = FirebaseAuth.instance.currentUser;
      if (user1 != null) {
        // Suppose you have a string you want to add
        String newMemberName = user1.uid;

        Map<String, dynamic> newMember = {
          'name': newMemberName,
          'kurucuÜye' : 'evet',
          // Add more fields as needed
        };

        members.add(newMember);
      }

      try {
        // Generate a random invitation code
        String invitationCode = _generateRandomCode(8); // Change 8 to the desired length

        // Create a new document for each Kurum with its name
        await db.collection("kurumlar").doc(" $kurumName - $invitationCode ").set({
          'kurumName': kurumName,
          'imageUrl': downloadURL,
          'invitationCode': invitationCode,
          'members': members,
        });

        // Now, add the same information to the Realtime Database
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          final firebaseRef = FirebaseDatabase(
            databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
          ).reference();

          DatabaseReference userTaskReference = firebaseRef.child('users').child(user.uid).child('kurum');

          // Create a map for the new task
          Map<String, dynamic> newTaskData = {
            "name": kurumName,
            "imageUrl": downloadURL,
            "invitationCode": invitationCode,
            // Add more fields as needed
          };

          // Set the value directly under the "kurum" branch
          userTaskReference.set(newTaskData).then((_) {
            Globals.taskKeysByName[kurumName] = userTaskReference.key!;

            // Use the stored context here
            Navigator.pop(currentContext);
          }).catchError((error) {
            print("Error writing document: $error");
          });

          // Create a new root named 'kurums' and branch it with the invitation code value
          DatabaseReference kurumsReference = firebaseRef.child('kurums').child(invitationCode);
          kurumsReference.set({
            "name": kurumName,
            "imageUrl": downloadURL,
            // Add more fields as needed
          });
        }
      } catch (e) {
        print("Error writing document: $e");
      }

      // Enable the button after the execution is complete

    }

    setState(() {
      isButtonEnabled = true;
    });
  }





  String _generateRandomCode(int length) {
    final random = Random();
    const chars = '0123456789';
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kurum Ekle'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  getImage();
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration:const  BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: _image != null
                      ? ClipOval(
                    child: Image.file(
                      _image!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Icon(
                    Icons.add_a_photo,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _kurumNameController,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Kurum Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const  SizedBox(height: 20),
              ElevatedButton(
                onPressed: isButtonEnabled ? _onKurumEkleButtonPressed : null,
                child: const Text('Kurum Ekle'),
              ),
              const SizedBox(height: 20),
          
            ],
          ),
        ),
      ),
    );
  }
}
