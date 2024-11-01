import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:E_HandyHelp/User/BookPage.dart';
import 'package:E_HandyHelp/User/UserNotification.dart';
import 'package:E_HandyHelp/User/UserHomePage.dart'; // Import UserHomepage
import 'package:E_HandyHelp/User/Messages.dart';
import 'package:E_HandyHelp/User/Settings.dart';
import 'package:E_HandyHelp/User/UserAccountInformation.dart';
import 'package:E_HandyHelp/User/ServiceRequest.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class HandymanDetailsPage extends StatefulWidget {
  final String userId;
  final String handymanId;
  final String? handymanName;
  final String? handymanType;
  final String? contact;
  final String? address;
  final String? imageUrl;

  HandymanDetailsPage({
    required this.userId,
    required this.handymanId,
    this.handymanName,
    this.handymanType,
    this.contact,
    this.address,
    this.imageUrl,
  });

  @override
  _HandymanDetailsPageState createState() => _HandymanDetailsPageState();
}

class _HandymanDetailsPageState extends State<HandymanDetailsPage> {
  int feedbackCount = 0;
  double averageRating = 0.0;
  List<dynamic> feedbacks = []; // List to store feedbacks

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
  }

  Future<void> _fetchFeedbacks() async {
    final url =
        'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/feedbacks?handymanId=${widget.handymanId}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        feedbackCount = decodedResponse['feedbackCount'] ?? 0;
        averageRating =
            double.tryParse(decodedResponse['averageRating']) ?? 0.0;
        feedbacks = decodedResponse['feedbacks'] ?? []; // Store feedbacks
        setState(() {});
      } catch (e) {
        print('Error decoding feedbacks: $e');
        _resetFeedbacks();
      }
    } else {
      print(
          'Failed to fetch feedbacks: ${response.statusCode} - ${response.body}');
    }
  }

  void _resetFeedbacks() {
    setState(() {
      feedbackCount = 0;
      averageRating = 0.0;
      feedbacks = [];
    });
  }

  void _showFeedbacksDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Feedbacks'),
          content: SizedBox(
            height: 300, // Set a height for the dialog
            width: 300, // Set a width for the dialog
            child: ListView.builder(
              itemCount: feedbacks.length,
              itemBuilder: (context, index) {
                var feedback = feedbacks[index];
                return ListTile(
                  title: Text('Feedback by: ' + feedback['userName']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(feedback['feedbackText']),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.yellow[700]),
                          SizedBox(width: 4),
                          Text(feedback['rating'].toString(),
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    print("Back button pressed"); // Debugging output
    return true; // Allow the back action
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Handle back button press
      child: Scaffold(
        appBar: AppBar(
          title: Text('Handyman Details'),
          backgroundColor: Color.fromARGB(255, 7, 49, 112),
          iconTheme: IconThemeData(color: Colors.white),
           foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildProfileImage(),
              SizedBox(height: 16),
              _buildHandymanInfo(),
              SizedBox(height: 16),
              _buildRatingInfo(),
              SizedBox(height: 24),
              _buildFeedbackButton(),
              SizedBox(height: 16),
              _buildBookButton(),
              SizedBox(height: 16),
              _buildCancelButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: CircleAvatar(
        radius: 50,
        backgroundImage: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
            ? NetworkImage(widget.imageUrl!)
            : AssetImage('https://via.placeholder.com/400x200?text=Profile')
                as ImageProvider<Object>,
      ),
    );
  }

  Widget _buildHandymanInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.handymanName ?? 'Unknown Handyman',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('Handyman Type: ${widget.handymanType ?? 'N/A'}',
            style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        Text('Contact: ${widget.contact ?? 'N/A'}',
            style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        Text('Address: ${widget.address ?? 'N/A'}',
            style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildRatingInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star, color: Colors.yellow[700]),
        SizedBox(width: 4),
        Text(averageRating.toStringAsFixed(1), style: TextStyle(fontSize: 18)),
        SizedBox(width: 8),
        Text('($feedbackCount Feedbacks)'),
      ],
    );
  }

  Widget _buildFeedbackButton() {
    return ElevatedButton(
      onPressed: _showFeedbacksDialog, // Show feedbacks dialog
      child: Text('View Feedbacks' ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 7, 49, 112),
        minimumSize: Size(double.infinity, 50), 
        foregroundColor: Colors.white,
        
      ),
    );
  }

  Widget _buildBookButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingForm(
              userId: widget.userId,
              handymanId: widget.handymanId,
              handymanName: widget.handymanName ?? 'Unknown Handyman',
              handymanType: [widget.handymanType ?? 'Unknown'],
            ),
          ),
        );
      },
      child: Text('Book'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 7, 49, 112),
        minimumSize: Size(double.infinity, 50),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCancelButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: Text('Cancel'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        minimumSize: Size(double.infinity, 50),
        foregroundColor: Colors.white,
      ),
    );
  }
}
