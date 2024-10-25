import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON encoding

class ContactAdminScreen extends StatefulWidget {
  final String userId;

  ContactAdminScreen({required this.userId});

  @override
  _ContactAdminScreenState createState() => _ContactAdminScreenState();
}

class _ContactAdminScreenState extends State<ContactAdminScreen> {
  final _subjectController = TextEditingController();
  final _detailsController = TextEditingController();

  Future<void> _submitForm() async {
    String subject = _subjectController.text;
    String details = _detailsController.text;
    String userId = widget.userId; // Access userId passed from ListTile

    if (subject.isEmpty || details.isEmpty) {
      // Show error if fields are empty
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Please fill in both the subject and details.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      // Make the POST request to the backend
      var response = await http.post(
        Uri.parse('http://localhost:5000/api/contact-admin'), // Change to your server address
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'subject': subject,
          'details': details,
          'userId': userId, // Send userId in the body of the request
        }),
      );

      if (response.statusCode == 200) {
        // Show success message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Message Sent'),
            content: Text('Your message has been sent to the admin.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
        _subjectController.clear();
        _detailsController.clear();
      } else {
        // Handle failure
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to send message. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Handle error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to send message. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Admin'),
        backgroundColor: const Color.fromARGB(255, 7, 49, 112),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _detailsController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Details',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: const Color.fromARGB(255, 7, 49, 112),
              ),
              child: Text('Send Message', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
