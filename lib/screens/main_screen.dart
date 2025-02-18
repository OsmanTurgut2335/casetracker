
import 'package:casetracker/core/data/firebase_repository/database_repository.dart';
import 'package:casetracker/core/data/firebase_repository/firestore_repository.dart';
import 'package:casetracker/product/widgets/popupmenu/custom_popup_menu.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';


import '../core/helpers/firebase_helper.dart';

import 'kurumsal/instutional_home_screen.dart' as Kurumsal;
import 'personal/personal_home_screen.dart';



class HomeScreen extends StatefulWidget {

  final FirestoreRepository firestoreRepository;

  const HomeScreen({Key? key, required this.firestoreRepository}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {


  final DatabaseReference _firebaseReference =  FirebaseHelper.firebaseRef;

  String _username = '';
  User? user = FirebaseAuth.instance.currentUser;

  late final FirestoreRepository _firestoreRepository;


  final DatabaseRepository _databaseRepository = DatabaseRepository();



  @override
  void initState() {
    super.initState();
    _checkAndUpdateUsername();
    _firestoreRepository = widget.firestoreRepository;

  }


  void _checkAndUpdateUsername() async {
    String? fetchedUsername = await _databaseRepository.fetchUsername();
    DatabaseReference _userReference = _firebaseReference.child('users').child(user!.uid);
    if (fetchedUsername != null) {
      setState(() {
        _username = fetchedUsername;
      });
    } else {
      await _showSetUsernameDialog(_userReference);
    }
  }


  Future<void> _showSetUsernameDialog(DatabaseReference userReference) async {
    TextEditingController _usernameController = TextEditingController();
    bool usernameExists = false;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {

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
                Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                onPressed: () async {
              String newUsername = _usernameController.text.trim();
              bool success = await _firestoreRepository.updateUsername(newUsername, context);

              if (success) {
                setState(() {
                  _username = newUsername;
                });
                Navigator.pop(context);
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



  @override
  Widget build(BuildContext context,)  {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Ana Ekran",textAlign: TextAlign.center,),
          actions: [
           CustomPopUpMenu(_firestoreRepository).customPopUp(context),
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
                    MaterialPageRoute(builder: (context) =>MyHomePage()),
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
                  String invitationCode = await _databaseRepository.getInvitationCodeFromDatabase(user!.uid);
                  String kurumName = await _databaseRepository.getKurumNameFromDatabase(user.uid);
                  String documentName = ' $kurumName - $invitationCode ';

                  bool isMember = await _databaseRepository.isUserKurumsalMember(user.uid);
                  if (isMember) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Kurumsal.MyHomePage(documentName: documentName,),
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








  }
