import 'package:flutter/material.dart';

class SnackbarWithCondition{

  SnackBar showSnackbarWithBool(String successString,String failString,bool result){
   return
      SnackBar(
        content: Text(result
            ? successString
            : failString),
      );

  }
}