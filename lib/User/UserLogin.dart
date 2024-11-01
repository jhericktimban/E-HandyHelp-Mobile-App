// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:E_HandyHelp/ForgotPassword.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'UserRegister.dart';
import 'UserHomePage.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for shared_preferences

class UserLogin extends StatefulWidget {
  const UserLogin({super.key});

  @override
  _UserLoginState createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUserData(Map<String, dynamic> responseData) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if the user data exists in the response
    if (responseData.containsKey('user')) {
      final user = responseData['user'];

      // Store the user data safely, with null checks for each field
      await prefs.setString(
          'token', responseData['token'] ?? ''); // Handle null token
      await prefs.setString('_id', user['_id'] ?? ''); // Handle null _id
      await prefs.setString(
          'username', user['username'] ?? ''); // Handle null username
      await prefs.setString('fname', user['fname'] ?? ''); // Handle null fname
      await prefs.setString('lname', user['lname'] ?? ''); // Handle null lname
      await prefs.setString(
          'contact', user['contact'] ?? ''); // Handle null contact
      await prefs.setString(
          'dateOfBirth', user['dateOfBirth'] ?? ''); // Handle null dateOfBirth
      await prefs.setString('accounts_status',
          user['accounts_status'] ?? ''); // Handle null status

      // Convert images list to a JSON string
      if (user['images'] is List) {
        await prefs.setString('images', jsonEncode(user['images']));
      } else {
        await prefs.setString(
            'images', '[]'); // Default to an empty list if not a list
      }
    } else {
      print('Error: No user data found in response');
    }
  }

// Helper function to show alert dialog
  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notice'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

// Updated login function
Future<void> _loginUser() async {
  final url = Uri.parse('https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/login-user');
  final String username = _usernameController.text.trim();
  final String password = _passwordController.text.trim();

  try {
    // Log the login request body
    print('Login request: username = $username, password = $password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    // Log the HTTP response status
    print('HTTP Response: ${response.statusCode}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Decode the JSON response
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final user = data['user'];

      // Log the response data
      print('Login successful, response data: $responseData');

      // Save user data in shared preferences
      await _saveUserData(responseData);

        // Check account status
      final String accountsStatus = user['accounts_status'];
      if (accountsStatus == 'pending') {

        _showAlertDialog('Your account is still pending for verification.');
        return; // Exit the function, preventing login
      } else if (accountsStatus == 'suspended') {

        _showAlertDialog('Your account is currently suspended.');
        return; // Exit the function, preventing login
      } else if (accountsStatus != 'verified') {

        _showAlertDialog('Your account status is not verified.');
        return; // Handle other unexpected statuses if needed
      }
      
      // Navigate to Home Page regardless of account status
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserHomePage()),
      );
    } else {
      // Log the error response from server
      print('Login failed, response body: ${response.body}');

      // Handle invalid credentials
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Invalid credentials. Please try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  } catch (error) {
    // Log the error details
    print('Error during login: $error');

    // Handle server errors
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text('An error occurred. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

  String? _validateUsernameOrContact(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your username';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Color.fromARGB(255, 245, 245, 245);
    final gradientColors = [
      Color.fromARGB(255, 245, 245, 245),
      Color.fromARGB(255, 245, 245, 245),
      Color.fromARGB(255, 245, 245, 245)
    ];

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
          child: Column(
            children: <Widget>[
              SizedBox(height: 80),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Image.asset(
                        'lib/Images/logo.png',
                        height: 200,
                        width: 200,
                      ),
                    ),
                    SizedBox(height: 20),
               
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 7, 49, 112),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                          Text(
                      "Resident login",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'roboto',
                          fontWeight: FontWeight.bold),
                    ),
                        SizedBox(height: 40),
                        TextFormField(
                          controller: _usernameController,
                          validator: _validateUsernameOrContact,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.person, color: Colors.grey),
                            hintText: "Username",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          validator: _validatePassword,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock, color: Colors.grey),
                            hintText: "Password",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ForgotPasswordPage()),
                              );
                            },
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(height: 40),
                        MaterialButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              _loginUser();
                            }
                          },
                          height: 50,
                          minWidth: double.infinity,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: Color.fromARGB(255, 7, 49, 112),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(color: Colors.white),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => UserRegister()),
                                );
                              },
                              child: Text(
                                "Sign up",
                                style: TextStyle(
                                  color: Color.fromARGB(255, 109, 192, 255),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
