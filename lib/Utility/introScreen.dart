import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:casetracker/Bireysel/mainBireysel.dart' as Bireysel;
import 'package:casetracker/Kurumsal/KurumsalMain.dart' as Kurumsal;
import '../Kurumsal/KurumEkle.dart';
import 'login_screen.dart';
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.reference();
  String _username = '';

  @override
  void initState() {
    super.initState();
    _checkAndUpdateUsername();
  }
  Future<void> _checkAndUpdateUsername() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DatabaseReference userReference = _databaseReference.child('users').child(user.uid);

      DataSnapshot userSnapshot = await userReference.get();

      if (userSnapshot.value != null) {
        Map<dynamic, dynamic> userData = userSnapshot.value as Map<dynamic, dynamic>;

        if (userData.containsKey('username') && userData['username'] != null) {
          setState(() {
            _username = userData['username'];
          });
        } else {
          await _showSetUsernameDialog(userReference);
        }
      } else {
        await _showSetUsernameDialog(userReference);
      }
    }
  }

  Future<void> _showSetUsernameDialog(DatabaseReference userReference) async {
    TextEditingController _usernameController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set Username'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please set your username:',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String newUsername = _usernameController.text.trim();

                if (newUsername.isNotEmpty) {
                  await userReference.update({
                    'username': newUsername,
                  });

                  setState(() {
                    _username = newUsername;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Username set successfully.'),
                    ),
                  );

                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid username.'),
                    ),
                  );
                }
              },
              child: Text('Set Username'),
            ),
          ],
        );
      },
    );
  }



    Future<bool> isUserKurumsalMember(String userId) async {
      final firebaseRef = FirebaseDatabase(
        databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
      ).reference();

      DatabaseReference userTaskReference =
      firebaseRef.child('users').child(userId).child("kurum");

      DataSnapshot snapshot = await userTaskReference.get();

      return snapshot.value != null;
    }


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Home Screen"),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                User? user = FirebaseAuth.instance.currentUser;

                if (value == 'addKurum') {
                  bool isUserMember = await isUserKurumsalMember(user!.uid);

                  if (isUserMember) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("You are already a member of a kurum and cannot add a new one."),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => KurumEkleScreen()),
                    );
                  }
                } else if (value == 'joinKurum') {
                  bool isUserMember = await isUserKurumsalMember(user!.uid);

                  if (isUserMember) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("You are already a member of a kurum and cannot join another one."),
                      ),
                    );
                  } else {
                    await _showJoinKurumDialog(context);
                  }
                } else if (value == 'signOut') {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                }
              },
              itemBuilder: (BuildContext context) =>
              [
                const PopupMenuItem<String>(
                  value: 'addKurum',
                  child: Text('Add Kurum'),
                ),
                const PopupMenuItem<String>(
                  value: 'joinKurum',
                  child: Text('Join a Kurum'),
                ),
                const PopupMenuItem<String>(
                  value: 'signOut',
                  child: Text('Sign Out'),
                ),
              ],
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Bireysel.MyHomePage()),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Bireysel',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  User? user = FirebaseAuth.instance.currentUser;
                  bool isMember = await isUserKurumsalMember(user!.uid);

                  if (isMember) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Kurumsal.MyHomePage()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("You are not a Kurumsal member yet."),
                      ),
                    );
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Kurumsal',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

    Future<void> _showJoinKurumDialog(BuildContext context) async {
      TextEditingController _invitationCodeController = TextEditingController();

      return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Join Kurum'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You are not a member of any Kurum. Enter the invitation code to join:',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _invitationCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Invitation Code',
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  String invitationCode = _invitationCodeController.text;
                  _joinKurum(invitationCode, context);
                },
                child: Text('Join'),
              ),
            ],
          );
        },
      );
    }

    Future<void> _joinKurum(String invitationCode, BuildContext context) async {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final firebaseRef = FirebaseDatabase(
          databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
        ).reference();

        DatabaseReference kurumsReference = firebaseRef.child('kurums');
        DatabaseReference userTaskReference =
        firebaseRef.child('users').child(user.uid);

        DataSnapshot kurumsSnapshot = await kurumsReference.get();

        if (kurumsSnapshot.value != null) {
          Map<dynamic, dynamic> kurumsData =
          (kurumsSnapshot.value as Map<dynamic, dynamic>);

          for (var kurumKey in kurumsData.keys) {
            String kurumInvitationCode = kurumKey;

            if (kurumInvitationCode == invitationCode) {
              try {
                await userTaskReference.update({
                  'kurum': {
                    'name': kurumsData[kurumKey]['name'],
                    'imageUrl': kurumsData[kurumKey]['imageUrl'],
                    'invitationCode': invitationCode,
                  },
                });


                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        "Successfully joined Kurum: ${kurumsData[kurumKey]['name']}"),
                    duration: Duration(seconds: 3),
                  ),
                );

                await addMemberToFirestore(invitationCode);
                Navigator.pop(context);
                break;
              } catch (error) {
                print("Error updating user Kurum: $error");
              }
            }
          }
        }
      }
    }

    Future<void> addMemberToFirestore(String kurumName) async {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      User? user = FirebaseAuth.instance.currentUser;

      try {
        QuerySnapshot kurumlarSnapshot =
        await _firestore.collection('kurumlar').get();

        for (QueryDocumentSnapshot kurumDocument in kurumlarSnapshot.docs) {
          String kurumDocumentName = kurumDocument.id;
          String osman = kurumName;
          print("KANKA OSMAN:$osman");
          print("KANKA kurumName:$kurumName");
          if (kurumDocumentName.contains(osman)) {
            print("YARRRRRRRRAK");
            DocumentReference kurumReference = kurumDocument.reference;

            DocumentSnapshot kurumSnapshot = await kurumReference.get();
            List<Map<String, dynamic>> currentMembers = [];

            if (kurumSnapshot.exists) {
              Map<String, dynamic>? data =
              kurumSnapshot.data() as Map<String, dynamic>?;

              if (data != null && data.containsKey('members')) {
                List<dynamic>? membersData = data['members'];

                if (membersData != null) {
                  currentMembers = List<Map<String, dynamic>>.from(
                      membersData.map((member) =>
                      member as Map<String, dynamic>));
                }
              }
            }

            if (user != null) {
              Map<String, dynamic> currentUser = {
                'name': user.uid,
              };

              currentMembers.add(currentUser);

              await kurumReference.update({
                'members': currentMembers,
              });


              print(
                  'User added to the members list of $kurumDocumentName successfully');
            }

            break;
          }
        }
      } catch (e) {
        print('Error adding member to Firestore: $e');
      }
    }
  }
