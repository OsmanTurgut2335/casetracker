
import 'package:casetracker/product/authentication/view/create_user_button.dart';
import 'package:casetracker/product/authentication/view/reset_password_button.dart';
import 'package:casetracker/product/constants/strings/login_strings.dart';
import 'package:casetracker/product/widgets/sizedbox/custom_sized_box.dart';
import 'package:flutter/material.dart';


import '../product/authentication/view/login_button.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(LoginStrings.loginScreenTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: LoginStrings.email),
                  autofillHints: const [AutofillHints.email],
                ),
                CustomSizedBox().customSizedBox(16),
                passwordTextField(),
                CustomSizedBox().customSizedBox(25),
             LoginButton(emailController: _emailController,passwordController: _passwordController,),

                CustomSizedBox().customSizedBox(8),
               CreateUserButton(email: _emailController.text,password: _passwordController.text,),

                const SizedBox(height: 8),
                ResetPasswordButton(email: _emailController.text),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextField passwordTextField() {
    return TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: LoginStrings.password,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
              );
  }
}


