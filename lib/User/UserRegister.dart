// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:E_HandyHelp/User/UserAccountInformation.dart';
import 'package:E_HandyHelp/User/UserLogin.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:image_picker/image_picker.dart';

class UserRegister extends StatefulWidget {
  const UserRegister({Key? key}) : super(key: key);

  @override
  State<UserRegister> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<UserRegister> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _fname = '';
  String _lname = '';
  String _username = '';
  String _password = '';
  DateTime? _dateOfBirth;
  String _contact = '';
  String _address = '';
  List<File> _images = [];
  bool _dataPrivacyConsent = false;

  bool _isPasswordLongEnough = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasDigit = false;
  bool _hasSpecialCharacter = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  get imagePaths => null;

  @override
  void dispose() {
    _dateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    final regex = RegExp(r'^(?=.*[0-9])(?=.*[!@#\$&*~_]).{1,}$');
    if (!regex.hasMatch(value)) {
      return 'Username must contain at least one digit and one special character';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value!.isEmpty) {
      return 'Please enter your password.';
    }
    if (!_isPasswordLongEnough ||
        !_hasUpperCase ||
        !_hasLowerCase ||
        !_hasDigit ) {
      return 'Password does not meet the requirements.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value!.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String? _validateDateOfBirth(String? value) {
    if (_dateOfBirth == null) {
      return 'Please enter your date of birth.';
    }
    final DateTime today = DateTime.now();
    final DateTime age18 = DateTime(today.year - 18, today.month, today.day);
    if (_dateOfBirth!.isAfter(age18)) {
      return 'You must be at least 18 years old.';
    }
    return null;
  }

  void _validatePasswordFields(String value) {
    setState(() {
      _isPasswordLongEnough = value.length >= 8;
      _hasUpperCase = RegExp(r'(?=.*[A-Z])').hasMatch(value);
      _hasLowerCase = RegExp(r'(?=.*[a-z])').hasMatch(value);
      _hasDigit = RegExp(r'(?=.*\d)').hasMatch(value);
     
    });
  }

  String? _validatePhoneNumber(String? value) {
    if (value!.isEmpty) {
      return 'Please enter your phone number.';
    }

    // Check if value contains only digits
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Please enter a valid phone number.';
    }

    // Check if the length of the phone number is valid
    if (value.length != 11) {
      return 'Please enter a 11-digit phone number.';
    }

    return null;
  }

  Future<void> _registerUser() async {
    // Validate image uploads
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload a photo of your Barangay ID.')),
      );
      print('User registration failed: Images are empty'); // Log message
      return;
    }

    if (!_dataPrivacyConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must agree to the Data Privacy Act.')),
      );
      print(
          'User registration failed: Data privacy consent not agreed'); // Log message
      return;
    }

    final url = Uri.parse(
        'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/register');
    print('Preparing to send registration request to: $url'); // Log URL

    try {
      // Log user data being sent (excluding sensitive info)
      print('Sending registration request with data: {'
          'fname: $_fname, '
          'lname: $_lname, '
          'username: $_username, '
          'dateOfBirth: ${_dateOfBirth?.toIso8601String()}, '
          'contact: $_contact, '
          'address: $_address, '
          'dataPrivacyConsent: $_dataPrivacyConsent}'); // Log message

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fname': _fname,
          'lname': _lname,
          'username': _username,
          'password': _password,
          'dateOfBirth': _dateOfBirth?.toIso8601String(),
          'contact': _contact,
          'address': _address,
          'images': _images.map((file) => file.path).toList(),
          'dataPrivacyConsent': _dataPrivacyConsent,
        }),
      );

      print(
          'Received response with status code: ${response.statusCode}'); // Log response status code

      if (response.statusCode == 201) {
        // Registration successful
        print(
            'Registration successful for username: $_username'); // Log success message

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('fname', _fname);
        await prefs.setString('lname', _lname);
        await prefs.setString('username', _username);
        await prefs.setString('contact', _contact);
        await prefs.setString('address', _address);
        await prefs.setString('dateOfBirth',
            _dateOfBirth?.toLocal().toString().split(' ')[0] ?? '');
        await prefs.setString('password', _password);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Registration Successful'),
              content: const Text(
                'Your account has been created successfully. Please wait for a while as we verify your account. Thank you!',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserLogin(),
                      ),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // Registration failed
        print(
            'Registration failed with status code: ${response.statusCode}'); // Log failure
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration failed. Please try again.')),
        );
      }
    } catch (error) {
      // Error occurred
      print('Error occurred during registration: $error'); // Log error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);

    if (pickedImage != null) {
      setState(() {
        _images.add(File(pickedImage.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 7, 49, 112),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'lib/Images/logo.png',
                    width: 100,
                    height: 70,
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      color: Color.fromARGB(255, 7, 49, 112),
                      fontFamily: 'roboto',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        hintText: 'Enter your First Name',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your First Name.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _fname = value!;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        hintText: 'Enter your Last Name',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your Last Name.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _lname = value!;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        hintText: 'Enter your Username',
                      ),
                      validator: _validateUsername,
                      onSaved: (value) {
                        _username = value!;
                      },
                    ),
                    const SizedBox(height: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            hintText: 'Enter your password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: _validatePassword,
                          onSaved: (value) {
                            _password = value!;
                          },
                          onChanged: (value) {
                            _validatePasswordFields(value);
                          },
                        ),
                        const SizedBox(height: 5),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isPasswordLongEnough
                                      ? Icons.check
                                      : Icons.clear,
                                  color: _isPasswordLongEnough
                                      ? Colors.green
                                      : Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'At least 8 characters long',
                                  style: TextStyle(
                                    color: _isPasswordLongEnough
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  _hasUpperCase ? Icons.check : Icons.clear,
                                  color:
                                      _hasUpperCase ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'At least one uppercase letter',
                                  style: TextStyle(
                                    color: _hasUpperCase
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  _hasLowerCase ? Icons.check : Icons.clear,
                                  color:
                                      _hasLowerCase ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'At least one lowercase letter',
                                  style: TextStyle(
                                    color: _hasLowerCase
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  _hasDigit ? Icons.check : Icons.clear,
                                  color: _hasDigit ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'At least one number',
                                  style: TextStyle(
                                    color:
                                        _hasDigit ? Colors.green : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                        
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        hintText: 'Confirm your password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        hintText: 'Enter your date of birth',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.datetime,
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        DateTime? date = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          _dateOfBirth = date;
                          _dateController.text =
                              date.toLocal().toString().split(' ')[0];
                        }
                      },
                      validator: _validateDateOfBirth,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Contact Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        hintText: 'Enter your contact number',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: _validatePhoneNumber,
                      onSaved: (value) {
                        _contact = value!;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        hintText: 'Enter your Address',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your Address.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _address = value!;
                      },
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Upload a photo(s) of your Barangay ID',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: List.generate(_images.length + 1, (index) {
                        if (index == _images.length) {
                          return GestureDetector(
                            onTap: () {
                              _getImage(ImageSource.gallery);
                            },
                            child: Container(
                              width: 150.0,
                              height: 150.0,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Color.fromARGB(255, 7, 49, 112)),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Center(child: Icon(Icons.add)),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            Container(
                              width: 150.0,
                              height: 150.0,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Color.fromARGB(255, 7, 49, 112)),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Image.file(_images[index] as File),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: IconButton(
                                onPressed: () {
                                  _removeImage(index);
                                },
                                icon: Icon(Icons.delete),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: <Widget>[
                        Checkbox(
                          value: _dataPrivacyConsent,
                          onChanged: (bool? value) {
                            setState(() {
                              _dataPrivacyConsent = value!;
                            });
                          },
                        ),
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                        'Republic Act 10173 - Data Privacy Act of 2012 (Philippines)'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Your privacy is important to us. By registering, you acknowledge and agree to the following:',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            '- We will collect and store your personal information, including your name, username, date of birth, and contact details, for account creation and authentication purposes.',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          Text(
                                            '- Your information will be kept confidential and will not be shared with third parties without your consent, except as required by law or legal process.',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          Text(
                                            '- We may use your information to communicate with you about our services, promotions, and updates.',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          Text(
                                            '- You have the right to access, correct, and delete your personal information. For inquiries or requests regarding your data, please contact us.',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Close'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'I have read and agree to the ',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  TextSpan(
                                    text: 'Data Privacy Act',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _registerUser();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 7, 49, 112),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const UserLogin()),
                      ); // Navigate back to the login screen
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
