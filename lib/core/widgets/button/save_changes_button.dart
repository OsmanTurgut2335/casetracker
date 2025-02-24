import 'package:casetracker/core/helpers/firebase_helper.dart';
import 'package:casetracker/core/provider/providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../product/authentication/viewmodel/auth_viewmodel.dart';
import '../../helpers/globals.dart';

class SaveChangesButton extends ConsumerWidget {
  const SaveChangesButton({super.key, required this.itemName, required this.itemNameController,
    required this.descriptionController, required this.selectedDueDate, this.personController});

  final String itemName;
  final TextEditingController itemNameController;
  final TextEditingController descriptionController;
  final DateTime selectedDueDate;
  final TextEditingController? personController;
  final  bool isKurumsal = false;

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final authViewModel = ref.watch(authViewModelProvider);
    return ElevatedButton(
        onPressed: (){
          updateTask(itemName: itemName,itemNameController: itemNameController,descriptionController:
          descriptionController,selectedDueDate: selectedDueDate,personController: personController,isKurumsal: isKurumsal,context: context,
             authViewModel:  authViewModel );
        } ,
        style: ElevatedButton.styleFrom(
          elevation: 5,
          foregroundColor: Colors.lightGreen[200],
          backgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child:const Text('Değişiklikleri Kaydet') ,

    );
  }

  Future<void> updateTask({
    required String itemName,
    required TextEditingController itemNameController,
    required TextEditingController descriptionController,
    required DateTime selectedDueDate,
    TextEditingController? personController, // Optional for KurumsalItem
    bool isKurumsal = false,
    required BuildContext context,
    required AuthViewModel authViewModel,
  }) async {
    final editedItem = isKurumsal
        ? KurumsalItem(
      name: itemNameController.text,
      description: descriptionController.text,
      date: selectedDueDate,
      username: personController?.text ?? "",
    )
        : Item(
      name: itemNameController.text,
      description: descriptionController.text,
      date: selectedDueDate,
    );

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final firebaseRef = FirebaseHelper.firebaseRef;

        DatabaseReference userTaskReference = firebaseRef
            .child('users')
            .child(user.uid)
            .child("tasks")
            .child(Globals.taskKeysByName[itemName]!);

        Map<String, dynamic> newTaskData = {
          "name": editedItem.name,
          "description": editedItem.description ?? "",
          "date": editedItem.date.toUtc().toIso8601String(),
        };

        await userTaskReference.set(newTaskData);

        // Update Cloud Firestore
        final firestore = FirebaseFirestore.instance;
        String invitationCode = await authViewModel.getInvitationCodeFromDatabase(user.uid);
        String kurumName = await authViewModel.getKurumNameFromDatabase(user.uid);
        String documentName = " $kurumName - $invitationCode ";

        QuerySnapshot querySnapshot = await firestore
            .collection('kurumlar')
            .where(FieldPath.documentId, isEqualTo: documentName)
            .get();

        for (QueryDocumentSnapshot document in querySnapshot.docs) {
          List tasksArray = document['tasks'];

          for (int i = 0; i < tasksArray.length; i++) {
            if (tasksArray[i]['name'] == itemName) {
              tasksArray[i]['name'] = editedItem.name;
              tasksArray[i]['description'] = editedItem.description ?? "";
              tasksArray[i]['date'] = editedItem.date.toUtc().toIso8601String();

              await firestore.collection('kurumlar').doc(document.id).update({
                'tasks': tasksArray,
              });

              break;
            }
          }
        }

        // Update local list
        for (var itemList in Globals.itemsList) {
          try {
            var item = itemList.firstWhere((item) => item.name == itemName);
            item.name = editedItem.name;

            if (isKurumsal) {
              await Globals().fetchKurumsalItemsFromDatabase();
            } else {
              await Globals.fetchDataFromDatabase();
            }

            break;
          } catch (e) {
            // Item not found, continue searching
          }
        }
      }
    } catch (e) {
      print("Error during database update: $e");
    }

    Navigator.pop(context);
  }
}
