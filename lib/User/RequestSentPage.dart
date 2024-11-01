import 'dart:convert'; // Import for base64 decoding
import 'package:E_HandyHelp/User/UserHomePage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConfirmationPage extends StatelessWidget {
  final String service;
  final String clientName;
  final String handyman;
  final String reservationDateTime;
  final DateTime date;
  final List<String> handymanType; // Updated to List<String>
  final bool urgentRequest;
  final List<String>? base64Images; // Updated to List<String>

  const ConfirmationPage({
    super.key,
    required this.service,
    required this.clientName,
    required this.handyman,
    required this.reservationDateTime,
    required this.date,
    required this.handymanType,
    required this.urgentRequest,
    this.base64Images, // Updated to List<String>
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Sent', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 7, 49, 112),
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView( // Wrap with SingleChildScrollView
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStepIcon(Icons.location_on, false),
                _buildStepIcon(Icons.credit_card, true),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Your service request has been sent to the HandyMan',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Status for Confirmation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoColumn('Handyman:', handyman),
                      SizedBox(width: 16),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoColumn(
                        'Handyman Type:',
                        handymanType.join(', '),
                      ),
                      SizedBox(width: 16),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoColumn(
                        'Urgent Request:',
                        urgentRequest ? 'Yes' : 'No',
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoColumn(
                        'Reservation Date and Time:',
                        DateFormat('MM/dd/yyyy - hh:mm a').format(date),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            if (base64Images != null && base64Images!.isNotEmpty) ...[
              Text(
                'Attached Images:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Column(
                children: base64Images!.map((base64Image) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Image.memory(
                      base64Decode(base64Image), // Decode and display the image
                      fit: BoxFit.cover,
                      height: 200, // Adjust height as needed
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserHomePage(),
                  ),
                );
              },
              child: Text(
                'Proceed',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 7, 49, 112),
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIcon(IconData icon, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor:
              isActive ? const Color.fromARGB(255, 7, 49, 112) : Colors.grey,
          child: Icon(icon, color: Colors.white),
        ),
        if (isActive) ...[
          SizedBox(height: 4),
          Container(
            width: 40,
            height: 2,
            color: const Color.fromARGB(255, 7, 49, 112),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoColumn(String title, String content) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(content, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
