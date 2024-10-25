import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:E_HandyHelp/User/RequestSentPage.dart';

class BookingForm extends StatefulWidget {
  final String handymanName;
  final List<String> handymanType;
  final String handymanId;
  final String userId;

  BookingForm({
    required this.userId,
    required this.handymanId,
    required this.handymanName,
    required List<dynamic> handymanType,
  }) : handymanType = List<String>.from(handymanType);

  @override
  _BookingFormState createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();

  final _serviceDetailsController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _urgentRequest = false;
  List<String> _imagesBase64 = [];

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      setState(() {
        _imagesBase64.add(base64Image);
      });
    }
  }

  Future<void> _sendBookingRequest() async {
    if (_formKey.currentState!.validate()) {
      // Check if the booking time is at least 3 hours from now
      final DateTime now = DateTime.now();
      if (_selectedDate.isBefore(now.add(Duration(hours: 3)))) {
        _showErrorDialog('Booking must be at least 3 hours in advance.');
        return;
      }

      final url =
          'https://6762a6b5-bcae-47d9-9b32-173db9699b2c-00-2yzwy4xs0f5zs.pike.replit.dev/api/bookings';
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'userId': widget.userId,
          'handymanId': widget.handymanId,
          'handymanName': widget.handymanName,
          'handymanType': widget.handymanType,
          'serviceDetails': _serviceDetailsController.text,
          'dateOfService': _selectedDate.toIso8601String(),
          'urgentRequest': _urgentRequest,
          'images': _imagesBase64,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessDialog('Booking request sent successfully!');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationPage(
              date: _selectedDate,
              handyman: widget.handymanName,
              service: '',
              clientName: '',
              reservationDateTime: '',
              handymanType: widget.handymanType,
              urgentRequest: _urgentRequest,
              base64Images: _imagesBase64,
            ),
          ),
        );
      } else {
        print('Failed to send booking request');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(
            context); // This will take you to the previous panel instead of the first page
        return false; // Prevent default back navigation behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Booking Information',
              style: TextStyle(color: Colors.white)),
          backgroundColor: const Color.fromARGB(255, 7, 49, 112),
          iconTheme: IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _serviceDetailsController,
                    decoration: InputDecoration(
                      labelText: 'Service Details',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                    ),
                    maxLines: 5,
                    validator: (value) => value!.isEmpty
                        ? 'Please describe the service needed'
                        : null,
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      'Date of Service: ${DateFormat('MM/dd/yyyy - hh:mm a').format(_selectedDate)}',
                    ),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () => _selectDateTime(context),
                  ),
                  CheckboxListTile(
                    title: Text('Urgent Request'),
                    value: _urgentRequest,
                    onChanged: (value) {
                      setState(() {
                        _urgentRequest = value ?? false;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text('Add Image'),
                  ),
                  Wrap(
                    children: _imagesBase64
                        .map((image) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.memory(
                                base64Decode(image),
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ))
                        .toList(),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _sendBookingRequest,
                    child: Text('Send Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 7, 49, 112),
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
