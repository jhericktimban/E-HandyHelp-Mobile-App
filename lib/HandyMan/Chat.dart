import 'package:flutter/material.dart';

class Chat extends StatefulWidget {
  final String clientName;

  const Chat({
    required this.clientName,
    super.key,
  });

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _messageController = TextEditingController();
  final List<MessageBubble> _messages = [];
  String? _selectedReason;

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add(MessageBubble(
          message: _messageController.text.trim(),
          isMe: true,
        ));
      });
      _messageController.clear();
      // Simulate receiving a response from the other user
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          _messages.add(MessageBubble(
            message: "This is a response from ${widget.clientName}",
            isMe: false,
          ));
        });
      });
    }
  }

  void _reportClient() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Report Client'),
          content: Text('Do you want to report ${widget.clientName}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
                _showReasonDialog(); // Show the reason selection dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Background color of the button
              ),
              child: Text(
                'Report',
                style: TextStyle(
                  color: Colors.white, // Text color of the button
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReasonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Reason for Reporting'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select a reason for reporting ${widget.clientName}:'),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                    ),
                    items: <String>[
                      'Inappropriate behavior',
                      'Scam',
                      'Harassment',
                      'Overcharged',
                      'Uncomplete work',
                      'Other'
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedReason = newValue;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedReason != null) {
                      Navigator.of(context).pop(); // Close the dialog
                      _performReport(); // Call the method to perform the report
                    } else {
                      // Show an error message if no reason is selected
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select a reason for reporting.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Background color of the button
                  ),
                  child: Text(
                    'Report',
                    style: TextStyle(
                      color: Colors.white, // Text color of the button
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _performReport() {
    // Here you can add the logic to report the client with the selected reason
    // For example, sending the report to a server or updating a database
    print('Reporting ${widget.clientName} for $_selectedReason.');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Your report has been sent.')),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 7, 49, 112),
        title: Text('${widget.clientName}', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.report, color: Colors.white,),
            onPressed: _reportClient,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (ctx, index) => _messages[_messages.length - 1 - index],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Send a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;

  const MessageBubble({required this.message, required this.isMe, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Material(
            borderRadius: BorderRadius.circular(10),
            elevation: 5,
            color: isMe ? Colors.blueAccent : Colors.grey[300],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                message,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
