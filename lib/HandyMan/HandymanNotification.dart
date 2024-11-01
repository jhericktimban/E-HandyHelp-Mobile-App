import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationPage extends StatefulWidget {
  NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String _id = '';
  List<NotificationItem> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadHandyManData(); // Load user data
  }

  Future<void> _loadHandyManData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _id = prefs.getString('_id') ?? '';
    });
    await _fetchNotifications(); // Fetch notifications after loading user data
  }

  Future<void> _fetchNotifications() async {
    final response = await http.get(Uri.parse(
        'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/api/handynotifications/$_id'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        notifications = data
            .map((item) => NotificationItem(
                  title: item['title'],
                  description: item['description'],
                  date: DateTime.parse(item[
                      'date']), // Assuming date is in a parseable string format
                ))
            .toList();
      });
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 49, 112),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                'No latest notifications',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(notification.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.description),
                        SizedBox(height: 4),
                        Text(
                          DateFormat('MM/dd/yyyy - hh:mm a')
                              .format(notification.date),
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing:
                        Icon(Icons.notification_important, color: Colors.red),
                  ),
                );
              },
            ),
    );
  }
}

class NotificationItem {
  final String title;
  final String description;
  final DateTime date;

  NotificationItem({
    required this.title,
    required this.description,
    required this.date,
  });
}
