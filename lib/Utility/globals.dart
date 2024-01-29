import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';
import '../Bireysel/mainBireysel.dart';

class Item {
  late String name;
  late String? description; // Allow null for description
  late DateTime date;

  Item({required this.name, this.description, required this.date});
}
class KurumsalItem {
  late String name;
  late String? description; // Allow null for description
  late DateTime date;
  late String person ;
  KurumsalItem({required this.name, this.description, required this.date,required this.person});
}


class Globals {
  static List<List<Item>> itemsList = [
    [],
    [],
  ];
  static List<List<KurumsalItem>> kurumsalItemsList = [
    [],
    [],
  ];


  static Map<String, String> taskKeysByName = {};
  static Map<String, String> kurumsalTaskKeysByName = {};

  //Kurumların invitaton valuesini tutan map

  static Map<String, String> kurumInvitationMap = {};

  static Map<String, String> userIDandName = {};

  List<String> kurumNameList = [];

 static  List<String> kurumsMembersList= [];

  static Future<void> fetchDataFromDatabase() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final firebaseRef = FirebaseDatabase(
        databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
      ).reference();

      // Update the reference to include the user's UID
      DatabaseReference userTaskReference =
      firebaseRef.child('users').child(user.uid).child("tasks");

      final snapshot = await userTaskReference.get();

      if (snapshot.value is Map<dynamic, dynamic>) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        itemsList[0].clear(); // Change here
        taskKeysByName.clear();
        data.forEach((key, value) {
          final item = Item(
            name: value['name'],
            description: value['description'],
            date: DateTime.parse(value['date']),
          );
          taskKeysByName[item.name] = key;

          itemsList[0].add(item);
        });
      }
    }
  }

}
class NumberGenerator {
  Future<List<String>> slowNumbers() async {
    return Future.delayed(const Duration(milliseconds: 1000), () => numbers,);
  }

  List<String> get numbers => List.generate(5, (index) => number);


  String get number => Random().nextInt(99999).toString();
}