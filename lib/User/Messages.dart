import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<dynamic> messages = [];
  String _id = '';
  @override
  void initState() {
    super.initState();
    _loadHandymanData();
  }

  Future<void> _loadHandymanData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _id = prefs.getString('_id') ?? '';

      fetchMessages();
    });
  }

  Future<void> fetchMessages() async {
    print('id:' + _id);
    final response = await http.get(Uri.parse(
        'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/api/user-messages?userId=$_id'));

    if (response.statusCode == 200) {
      setState(() {
        messages = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load messages');
    }
  }

  void navigateToChat(String bookingId, String handymanId, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          bookingId: bookingId,
          handymanId: handymanId,
          userId: userId,
        ),
      ),
    );
  }

 void reportMessage(String bookingId) {
  showDialog(
    context: context,
    builder: (context) {
      String reportReason = '';
      return AlertDialog(
        title: Text('Report Client'),
        content: TextField(
          onChanged: (value) {
            reportReason = value;
          },
          decoration: InputDecoration(hintText: 'Enter report reason'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (reportReason.isNotEmpty) {
                // Confirmation dialog before sending the report
                bool confirmed = await _showConfirmationDialog(context);

                if (confirmed) {
                  // Send report to the backend
                  final response = await http.post(
                    Uri.parse(
                        'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/reports'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'bookingId': bookingId,
                      'reason': reportReason,
                      'reported_by': 'handyman',
                    }),
                  );

                  if (response.statusCode == 201) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Report sent successfully!')),
                    );
                  } else {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to submit report.')),
                    );
                  }
                }
              }
            },
            child: Text('Submit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        ],
      );
    },
  );
}

// Function to show confirmation dialog
Future<bool> _showConfirmationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Confirm Submission'),
        content: Text('Are you sure you want to submit this report?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Return false if canceled
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Return true if confirmed
            },
            child: Text('Confirm'),
          ),
        ],
      );
    },
  ).then((value) => value ?? false); // Handle null case
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return MessageCard(
                    name:
                        '${message['userFirstName']} ${message['userLastName']}',
                    message: '${message['last_message']}...',
                    onTap: () {
                      navigateToChat(message['booking_id'],
                          message['handyman_id'], message['user_id']);
                    },
                    onReport: () => reportMessage(
                        message['booking_id']), // Pass message ID to report
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageCard extends StatelessWidget {
  final String name;
  final String message;
  final VoidCallback onTap;
  final VoidCallback onReport;

  MessageCard({
    required this.name,
    required this.message,
    required this.onTap,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(color: Colors.blue),
        ),
        child: ListTile(
          leading: Container(
            width: 50.0,
            height: 50.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(name)),
              IconButton(
                icon: Icon(Icons.report),
                onPressed: onReport, // Report button action
              ),
            ],
          ),
          subtitle: Text(message),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String handymanId;
  final String userId;

  ChatScreen(
      {required this.bookingId,
      required this.handymanId,
      required this.userId});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _messages = [];

  @override
  void initState() {
    super.initState();
    fetchConversation();
  }

  Future<void> fetchConversation() async {
    final response = await http.get(Uri.parse(
        'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/api/user-conversation/${widget.bookingId}'));
    if (response.statusCode == 200) {
      setState(() {
        _messages = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load conversation');
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      // Prepare the message data
      final newMessage = {
        'contents': _controller.text,
        'handyman_id': widget.handymanId, // Pass handyman_id dynamically
        'user_id': widget.userId, // Pass user_id dynamically
        'booking_id': widget.bookingId, // Pass booking_id dynamically
      };

      try {
        // Send the message to the backend API
        final response = await http.post(
          Uri.parse(
              'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/api/send-message-user'), // Your API endpoint
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(newMessage),
        );

        if (response.statusCode == 200) {
          fetchConversation();
        } else {
          throw Exception('Failed to send message');
        }
      } catch (error) {
        print('Error sending message: $error');
      }

      // Clear the input field
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                String sender = message['sender'] == 'user'
                    ? 'You'
                    : '${message['handyMan_details']['fname']} ${message['handyMan_details']['lname']}'; // Display user’s full name

                return MessageWidget(
                  text: message['contents'],
                  sender: sender,
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        InputDecoration(hintText: 'Enter your message...'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed:
                      _sendMessage, // Send the message when the button is pressed
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageWidget extends StatelessWidget {
  final String text;
  final String sender;

  MessageWidget({required this.text, required this.sender});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment:
            sender == 'You' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Material(
            borderRadius: BorderRadius.circular(10.0),
            elevation: 5.0,
            color: sender == 'You' ? Colors.lightBlueAccent : Colors.grey[300],
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
