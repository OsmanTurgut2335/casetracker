
import 'package:casetracker/core/helpers/email_validate_helper.dart';
import 'package:casetracker/product/constants/strings/login_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helpers/view_model_create.dart';
import '../../../core/provider/providers.dart';

class CreateUserButton extends ConsumerWidget {
  const CreateUserButton({super.key, required this.email, required this.password});
final  String email;
 final String password;
  @override
  Widget build(BuildContext context,WidgetRef ref) {

    final authViewModel = ref.watch(authViewModelProvider);

    return  ElevatedButton(onPressed: authViewModel.isLoading
        ? null
        :  () async{
        if (!(EmailValidateHelper().validateEmail(email))) return;

        //if the email is okey proceed
        String? result = await authViewModel.createUser(email, password);

      ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(
          content: Text(
            result == null ? LoginStrings.userCreated : " ${LoginStrings.loginFailed} : $result", // Show real error message
          ),
      duration: const Duration(seconds: 2)
      ),



      );

    }, child: authViewModel.isLoading ? const CircularProgressIndicator(color: Colors.white):
    const Text(LoginStrings.createUser) );
  }
}
