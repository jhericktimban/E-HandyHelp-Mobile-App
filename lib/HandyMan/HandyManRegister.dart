// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, avoid_print, unnecessary_string_interpolations, prefer_const_literals_to_create_immutables
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'HandyManLogin.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for shared_preferences

class HandyManRegister extends StatefulWidget {
  const HandyManRegister({Key? key}) : super(key: key);

  @override
  State<HandyManRegister> createState() => _HandyManRegisterState();
}

class _HandyManRegisterState extends State<HandyManRegister> {
  final List<String> _selectedSpecializations = [];
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
  List<String> _specializations = [
    'Electrician',
    'Plumber',
    'Carpenter',
    'Painter',
    'Mason',
    'Welder',
    'Gardener',
    'Cleaner',
    'Other'
  ];

  bool _dataPrivacyConsent = false;

  bool _isPasswordLongEnough = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasDigit = false;
  bool _hasSpecialCharacter = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<File> _idImages = [];
  final List<File> _certificatesImages = [];

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
        !_hasDigit) {
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

  Future<void> _registerHandyMan() async {
    // Validate required fields
    if (_idImages.isEmpty) {
      _showSnackBar('Please upload a photo of your valid ID.');
      return;
    }

    if (!_dataPrivacyConsent) {
      _showSnackBar('You must agree to the Data Privacy Act.');
      return;
    }

    // Additional field validations
    if (_fname.isEmpty ||
        _lname.isEmpty ||
        _username.isEmpty ||
        _password.isEmpty ||
        _contact.isEmpty ||
        _address.isEmpty ||
        _dateOfBirth == null) {
      _showSnackBar('Please fill in all required fields.');
      return;
    }

    final url = Uri.parse(
        'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/register-handyman');

    try {
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
          'specialization': _selectedSpecializations,
          'images': _idImages.map((file) => file.path).toList(),
          'certificatesImages':
              _certificatesImages.map((file) => file.path).toList(),
          'dataPrivacyConsent': _dataPrivacyConsent,
        }),
      );

      if (response.statusCode == 201) {
        // Registration successful
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('fname', _fname);
        await prefs.setString('lname', _lname);
        await prefs.setString('username', _username);
        await prefs.setString('contact', _contact);
        await prefs.setString('address', _address);
        await prefs.setString('dateOfBirth',
            _dateOfBirth?.toLocal().toString().split(' ')[0] ?? '');
        // Do NOT store password in SharedPreferences for security reasons.

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Registration Successful'),
              content: const Text(
                  'Your account has been created successfully. Please wait for a while as we verify your account. Thank you!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HandyManLogin(),
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
        String errorMessage;
        if (response.statusCode == 400) {
          errorMessage = 'Invalid data. Please check your input.';
        } else if (response.statusCode == 409) {
          errorMessage =
              'Username already exists. Please choose a different username.';
        } else {
          errorMessage = 'Registration failed. Please try again.';
        }
        _showSnackBar(errorMessage);
      }
    } catch (error) {
      // Error occurred
      print('Error: $error');
      _showSnackBar('An error occurred. Please try again later.');
    }
  }

// Helper function to show SnackBars
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _getidImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);

    if (pickedImage != null) {
      setState(() {
        _idImages.add(File(pickedImage.path));
      });
    }
  }

  void _removeidImage(int index) {
    setState(() {
      _idImages.removeAt(index);
    });
  }

  Future<void> _getcertificatesImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);

    if (pickedImage != null) {
      setState(() {
        _certificatesImages.add(File(pickedImage.path));
      });
    }
  }

  void _removecertificatesImage(int index) {
    setState(() {
      _certificatesImages.removeAt(index);
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
                        hintText: 'First Name',
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
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        hintText: 'Enter your Password',
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
                      validator: _validatePassword,
                      onChanged: (value) => _validatePasswordFields(value),
                      onSaved: (value) {
                        _password = value!;
                      },
                    ),
                    const SizedBox(height: 10),
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Column(
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
                                  color:
                                      _hasUpperCase ? Colors.green : Colors.red,
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
                                  color:
                                      _hasLowerCase ? Colors.green : Colors.red,
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
                                  color: _hasDigit ? Colors.green : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        hintText: 'Re-enter your Password',
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
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _dateController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        hintText: 'Enter your Date of Birth',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            _dateOfBirth = pickedDate;
                            _dateController.text =
                                pickedDate.toLocal().toString().split(' ')[0];
                          });
                        }
                      },
                      validator: _validateDateOfBirth,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        hintText: 'Enter your Phone Number',
                      ),
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
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Specializations',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      value: null,
                      items: _specializations.map((String specialization) {
                        return DropdownMenuItem<String>(
                          value: specialization,
                          child: StatefulBuilder(
                            builder:
                                (BuildContext context, StateSetter setState) {
                              return Row(
                                children: <Widget>[
                                  Checkbox(
                                    value: _selectedSpecializations
                                        .contains(specialization),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value!) {
                                          _selectedSpecializations
                                              .add(specialization);
                                        } else {
                                          _selectedSpecializations
                                              .remove(specialization);
                                        }
                                      });
                                    },
                                  ),
                                  SizedBox(width: 10),
                                  Text(specialization),
                                ],
                              );
                            },
                          ),
                        );
                      }).toList(),
                      validator: (value) {
                        if (_selectedSpecializations.isEmpty) {
                          return 'Please select at least one specialization.';
                        }
                        return null;
                      },
                      onChanged: (String? value) {},
                    ),
                    SizedBox(height: 35),
                    Text(
                      'Upload a photo(s) of your Barangay ID or any Valid ID',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: List.generate(_idImages.length + 1, (index) {
                        if (index == _idImages.length) {
                          return GestureDetector(
                            onTap: () {
                              _getidImage(ImageSource.gallery);
                            },
                            child: Container(
                              width: 100.0,
                              height: 100.0,
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
                              width: 100.0,
                              height: 100.0,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Color.fromARGB(255, 7, 49, 112)),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Image.file(_idImages[index] as File),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: IconButton(
                                onPressed: () {
                                  _removeidImage(index);
                                },
                                icon: Icon(Icons.delete),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Upload a file of your CV (optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: List.generate(_certificatesImages.length + 1,
                          (index) {
                        if (index == _certificatesImages.length) {
                          return GestureDetector(
                            onTap: () {
                              _getcertificatesImage(ImageSource.gallery);
                            },
                            child: Container(
                              width: 100.0,
                              height: 100.0,
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
                              width: 100.0,
                              height: 100.0,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Color.fromARGB(255, 7, 49, 112)),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Image.file(
                                  _certificatesImages[index] as File),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: IconButton(
                                onPressed: () {
                                  _removecertificatesImage(index);
                                },
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
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
                          _registerHandyMan();
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
                            builder: (context) => const HandyManLogin()),
                      );
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

  void _showAddSpecializationDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String newSpecialization = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Specialization'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Specialization',
                hintText: 'Enter new specialization',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a specialization.';
                }
                return null;
              },
              onSaved: (value) {
                newSpecialization = value!;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  setState(() {
                    _specializations = newSpecialization as List<String>;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
