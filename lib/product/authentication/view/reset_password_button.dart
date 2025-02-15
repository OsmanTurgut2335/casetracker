import 'package:casetracker/core/helpers/view_model_create.dart';
import 'package:casetracker/product/constants/strings/login_strings.dart';
import 'package:flutter/material.dart';



class ResetPasswordButton extends StatelessWidget {
  const ResetPasswordButton({super.key, required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    final authViewModel = ViewModelCreate().provideModel(context);


    return ElevatedButton(
      onPressed: authViewModel.isLoading
          ? null
          : () async {
        bool success = await authViewModel.resetPassword(email);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? LoginStrings.passwordResetSuccess
                : LoginStrings.passwordResetFail),
          ),
        );
      },
      child: authViewModel.isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(LoginStrings.forgotPassword),
    );
  }
}
