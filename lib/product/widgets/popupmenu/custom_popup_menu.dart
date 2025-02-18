import 'package:app_settings/app_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


import '../../../screens/login_screen.dart';
import '../../../core/data/firebase_repository/database_repository.dart';
import '../../../core/data/firebase_repository/firestore_repository.dart';
import '../../../screens/kurumsal/add_item.dart';

class CustomPopUpMenu  {

  final DatabaseRepository _databaseRepository = DatabaseRepository();
  final FirestoreRepository _firestoreRepository ;

  // Inject dependencies via constructor
  CustomPopUpMenu( this._firestoreRepository);


  PopupMenuButton customPopUp(BuildContext context){
 return    PopupMenuButton<String>(
      onSelected: (value) async {
        User? user = FirebaseAuth.instance.currentUser;

        if (value == 'addKurum') {
          bool isUserMember = await _databaseRepository.isUserKurumsalMember(user!.uid);

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
          bool isUserMember = await _databaseRepository.isUserKurumsalMember(user!.uid);

          if (isUserMember) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Zaten bir kurum üyesi olduğunuz için başka bir kuruma katılamazsınız"),
                  duration: Duration(seconds: 2)

              ),
            );
          } else {
            await _firestoreRepository.showJoinKurumDialog(context);
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
    );
  }
}