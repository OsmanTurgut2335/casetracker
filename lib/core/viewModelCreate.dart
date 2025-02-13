
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../product/authentication/viewmodel/auth_viewmodel.dart';

class ViewModelCreate{

  AuthViewModel provideModel(BuildContext context){
      return Provider.of<AuthViewModel>(context);
  }

}