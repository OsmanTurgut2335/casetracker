import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:casetracker/Bireysel/mainBireysel.dart' as Bireysel;
import 'package:casetracker/Kurumsal/corpo_home.dart' as Kurumsal;
import '../Kurumsal/add_corpo.dart';
import 'package:app_settings/app_settings.dart';
import 'login_screen.dart';
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {


  final DatabaseReference _databaseReference =  FirebaseDatabase(
    databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
  ).reference();
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
    bool usernameExists = false;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final navigatorState = Navigator.of(context);
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: const Text('Kullanıcı Adı Belirle'),
              contentPadding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 15.0), // Adjust content padding
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Kullanıcı adınız diğer kullanıcılar tarafından görülebilecektir',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                      ),
                      onChanged: (value) {
                        setState(() {
                          usernameExists = false; // Reset the flag when username changes
                        });
                      },
                    ),
                    if (usernameExists)
                      const Text(
                        'Bu kullanıcı adı kullanılıyor.Lütfen farklı bir kullanıcı adı giriniz',
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
              /*  TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),*/
                Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                    onPressed: () async {
                      String newUsername = _usernameController.text.trim();

                      if (newUsername.isNotEmpty) {
                        // Fetch the user list
                        CollectionReference usernamesCollection =
                        FirebaseFirestore.instance.collection('usernames');
                        DocumentSnapshot usernamesDoc =
                        await usernamesCollection.doc('usernames').get();
                        List<dynamic> userList =
                        List.from(usernamesDoc['userList']);

                        // Check if the new username already exists in the user list
                        for (var userItem in userList) {
                          if (userItem['username'] == newUsername) {
                            setState(() {
                              usernameExists = true;
                            });
                            return; // Exit onPressed callback if username exists
                          }
                        }

                        // Proceed with updating the username
                        await userReference.update({
                          'username': newUsername,
                        });

                        User? user = FirebaseAuth.instance.currentUser;

                        // Update the username in the user list
                        for (int i = 0; i < userList.length; i++) {
                          if (userList[i]['userid'] == user?.uid) {
                            userList[i]['username'] = newUsername;
                            break;
                          }
                        }

                        // Update the user list in Firestore
                        await usernamesCollection
                            .doc('usernames')
                            .update({'userList': userList});

                        // Update the state using setState for synchronous updates
                        setState(() {
                          _username = newUsername;
                        });

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kullanıcı adı başarıyla oluşturuldu.'),
                              duration: Duration(seconds: 2)
                          ),
                        );
                      } else {
                        // Display a warning message if the username is empty
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lütfen geçerli bir kullanıcı adı girin.'),
                              duration: Duration(seconds: 1)
                          ),
                        );
                      }
                    },
                    child: const Text('Tamam'),
                  ),],
                ),
              ],
            );
          },
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
          centerTitle: true,
          title: const Text("Ana Ekran",textAlign: TextAlign.center,),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                User? user = FirebaseAuth.instance.currentUser;

                if (value == 'addKurum') {
                  bool isUserMember = await isUserKurumsalMember(user!.uid);

                  if (isUserMember) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Zaten bir kurum üyesi olduğunuz için yeni bir kurum oluşturamazsınız."),
                          duration: Duration(seconds: 2)
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
                        content: Text("Zaten bir kurum üyesi olduğunuz için başka bir kuruma katılamazsınız"),
                          duration: Duration(seconds: 2)

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
                else if (value == 'ayarlar') {
                  AppSettings.openAppSettings(type: AppSettingsType.settings);
                }
              },
              itemBuilder: (BuildContext context) =>
              [
                const PopupMenuItem<String>(
                  value: 'addKurum',
                  child: Text('Kurum Oluştur'),
                ),
                const PopupMenuItem<String>(
                  value: 'joinKurum',
                  child: Text('Bir Kuruma Katıl'),
                ),
                const PopupMenuItem<String>(
                  value: 'signOut',
                  child: Text('Çıkış'),
                ),
                const PopupMenuItem<String>(
                  value: 'ayarlar',
                  child: Text('Ayarlar'),
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
                  String invitationCode = await _getInvitationCodeFromDatabase(user!.uid);
                  String kurumName = await _getKurumNameFromDatabase(user.uid);
                  String documentName = ' $kurumName - $invitationCode ';

                  bool isMember = await isUserKurumsalMember(user.uid);
                  if (isMember) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Kurumsal.MyHomePage(documentName: documentName),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
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
            title: const Text('Join Kurum'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'You are not a member of any Kurum. Enter the invitation code to join:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
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
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  String invitationCode = _invitationCodeController.text;
                  _joinKurum(invitationCode, context);
                },
                child: const Text('Join'),
              ),
            ],
          );
        },
      );
    }

    Future<void> _joinKurum(String invitationCode, BuildContext context) async {
      User? user = FirebaseAuth.instance.currentUser;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
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


                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                        "Successfully joined Kurum: ${kurumsData[kurumKey]['name']}"),
                    duration: const Duration(seconds: 3),
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
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      User? user = FirebaseAuth.instance.currentUser;


      try {
        QuerySnapshot kurumlarSnapshot =
        await firestore.collection('kurumlar').get();

        for (QueryDocumentSnapshot kurumDocument in kurumlarSnapshot.docs) {
          String kurumDocumentName = kurumDocument.id;
          String osman = kurumName;

          if (kurumDocumentName.contains(osman)) {

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

// Helper method to get 'invitationCode' from Realtime Database
  Future<String> _getInvitationCodeFromDatabase(String userId) async {
    DatabaseReference firebaseRef = FirebaseDatabase(
      databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
    ).reference();

    // Reference to 'invitationCode' field in Realtime Database
    DatabaseReference userTaskReference = firebaseRef.child('users').child(userId).child('kurum').child('invitationCode');

    // Get the 'invitationCode' value
    DataSnapshot snapshot = await userTaskReference.get();

    return snapshot.value.toString();
  }

  // Helper method to get 'name' from Realtime Database
  Future<String> _getKurumNameFromDatabase(String userId) async {
    DatabaseReference firebaseRef = FirebaseDatabase(
      databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
    ).reference();

    // Reference to 'invitationCode' field in Realtime Database
    DatabaseReference userTaskReference = firebaseRef.child('users').child(userId).child('kurum').child('name');

    // Get the 'invitationCode' value
    DataSnapshot snapshot = await userTaskReference.get();

    return snapshot.value.toString();
  }



  }
