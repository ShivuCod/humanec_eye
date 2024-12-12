
class Validator {

  static String? validateName(String? value) {
    value!.trim();
    String pattern = r'(^[a-zA-Z ]*$)';
    RegExp regExp = RegExp(pattern);
    if (value.isEmpty || value[0] == ' ') {
      return 'Please enter valid name';
    } else if (!regExp.hasMatch(value)) {
      return 'Name must be a-z and A-Z';
    }
    return null;
  }

  static String? validateRequired(String? value) {
    if (value == null || value.isEmpty || value[0] == ' ') {
      return 'This field is Required';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value!.length < 8 || value[0] == ' ') {
      return 'Atleast 8 Characters are Required';
    }
    return null;
  }

  static String? validateMobile(String? value) {
    String pattern = r'^(?:[+0]9)?[0-9]{10}$';
    RegExp regExp = RegExp(pattern);
    if (value!.isEmpty || value[0] == ' ') {
      return 'Mobile is Required';
    } else if (!regExp.hasMatch(value)) {
      return 'Invalid Mobile Number';
    } else {
      return null;
    }
  }

  static String? validateEmail(String? value) {
    String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = RegExp(pattern);
    if (value!.isEmpty || value[0] == ' ') {
      return 'Email is Required';
    } else if (!regExp.hasMatch(value)) {
      return 'Invalid Email';
    } else {
      return null;
    }
  }

}