
import 'package:flutter/cupertino.dart';

import 'globals.dart';
import '../data/firebase_repository/database_repository.dart';
import '../util/task/task_utils.dart';
import 'firebase_helper.dart';

class HomeScreenValueHelper{

  void initializeValues(){

    TaskUtils taskUtils = TaskUtils();
    final PageController _pageController = PageController();
    int _currentPage = 0;
    Map<DateTime, List<Task>> tasksMap = {};
    DateTime _selectedDay = DateTime.now();
    final firebaseRef=FirebaseHelper.firebaseRef;
    late String username;
    final databaseRepository = DatabaseRepository();
  }


}