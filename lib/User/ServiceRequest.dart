import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ServiceRequestPage extends StatefulWidget {
  const ServiceRequestPage({Key? key}) : super(key: key);

  @override
  _ServiceRequestPageState createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends State<ServiceRequestPage> {
  String _name = '';
  String _handymanType = '';
  String _location = '';
  String _serviceDescription = '';
  List<File> _images = [];
  bool _isUrgent = false;
  final _formKey = GlobalKey<FormState>();

  void _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Map<String, dynamic> requestData = {
      'name': _name,
      'handymanType': _handymanType,
      'location': _location,
      'serviceDescription': _serviceDescription,
      'images': _images.map((file) => file.path).toList(),
      'isUrgent': _isUrgent,
    };

    final response = await http.post(
      Uri.parse(
          'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/submit-request'),
      body: json.encode(requestData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Service request submitted successfully')),
      );
      _formKey.currentState!.reset();
      setState(() {
        _isUrgent = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting service request')),
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
        title: Text('Request a Service'),
        backgroundColor: Color.fromARGB(255, 7, 49, 112),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  style: TextStyle(fontSize: 16.0),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _name = value;
                    });
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  style: TextStyle(fontSize: 16.0),
                  decoration: InputDecoration(
                    labelText: 'Location',
                    hintText: 'Enter your location',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _location = value;
                    });
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your location';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  style: TextStyle(fontSize: 16.0),
                  decoration: InputDecoration(
                    labelText: 'Handyman Type',
                    hintText: 'Enter handyman type',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _handymanType = value;
                    });
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter handyman type';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  style: TextStyle(fontSize: 16.0),
                  decoration: InputDecoration(
                    labelText: 'Service Description',
                    hintText: 'Enter service description',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    isDense: true,
                  ),
                  maxLines: 5,
                  onChanged: (value) {
                    setState(() {
                      _serviceDescription = value;
                    });
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter service description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10.0),
                Text(
                  'Upload a photo(s) of your concern',
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
                          child: Image.file(_images[index]),
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
                SizedBox(height: 20),
                CheckboxListTile(
                  title: Text('Urgent Request'),
                  value: _isUrgent,
                  onChanged: (bool? value) {
                    setState(() {
                      _isUrgent = value ?? false;
                    });
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitRequest,
                  child: Text(
                    'Submit Request',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 7, 49, 112),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    textStyle: TextStyle(fontSize: 16.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
