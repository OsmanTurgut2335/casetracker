import 'package:casetracker/core/provider/providers.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../viewmodel/auth_viewmodel.dart';

class LoginButton extends ConsumerWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const LoginButton({
    Key? key,
    required this.emailController,
    required this.passwordController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final authViewModel = ref.watch(authViewModelProvider);

    return ElevatedButton(
      onPressed: authViewModel.isLoading
          ? null
          : () async {
        if (EmailValidator.validate(emailController.text)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Geçersiz email formatı")),
          );
          return;
        }
      //BURDA GEÇERSİZ E MAİL FORMATINDAN BAŞKA BİR CASE VAR MI O KONTROL EDİLMİYO GALİBA
        await authViewModel.login(emailController.text, passwordController.text, context);
      },
      child: authViewModel.isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Giriş Yap'),
    );
  }
}
