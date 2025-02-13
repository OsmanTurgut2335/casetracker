import 'package:email_validator/email_validator.dart';

class EmailValidateHelper{

    bool validateEmail(String email){
      return  EmailValidator.validate(email) ;
    }

}