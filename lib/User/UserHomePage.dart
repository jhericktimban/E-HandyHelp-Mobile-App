import 'dart:io';
import 'package:E_HandyHelp/User/BookPage.dart';
import 'package:E_HandyHelp/User/UserNotification.dart';
import 'package:flutter/material.dart';
import 'package:E_HandyHelp/FirstPage.dart';
import 'package:E_HandyHelp/User/Messages.dart';
import 'package:E_HandyHelp/User/Settings.dart';
import 'package:E_HandyHelp/User/UserAccountInformation.dart';
import 'package:E_HandyHelp/User/ServiceRequest.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:E_HandyHelp/User/HandymanDetails.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-HandyHelp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String _fname = '';
  String _lname = '';
  String _username = '';
  String _password = '';
  String _contact = '';
  String _address = '';
  String _dateOfBirth = '';
  String _id = '';
  File? _profileImage;

  TextEditingController _passwordController = TextEditingController();
  TextEditingController _searchController =
      TextEditingController(); // Add search controller

  bool _isLoading = true; // Added loading state
  List<Map<String, dynamic>> profiles = []; // Profiles list
  List<Map<String, dynamic>> filteredProfiles = []; // Filtered profiles list

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data
    fetchProfiles(); // Fetch profiles from API
    _searchController
        .addListener(_filterProfiles); // Add listener to the search controller
  }

  @override
  void dispose() {
    _searchController
        .dispose(); // Dispose controller when the widget is destroyed
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    // Clear SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Navigate back to the login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              FirstPage()), // Replace with your login screen widget
    );
  }

  // Fetch profiles from the API
  Future<void> fetchProfiles() async {
    try {
      final response = await http.get(Uri.parse(
          'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/profiles'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          profiles = data.map((profile) {
            return {
              '_id': profile['_id'],
              'name': '${profile['fname']} ${profile['lname']}',
              'address': profile['address'],
              'handymanType': profile['specialization'], // Array of strings
              'imageUrl': profile['idImages'].isNotEmpty
                  ? profile['idImages'][0]
                  : null,
            };
          }).toList();
          filteredProfiles =
              profiles; // Initially, filtered profiles = all profiles
          _isLoading = false; // Set loading to false after fetching
        });
      } else {
        throw Exception('Failed to load profiles');
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Set loading to false on error
      });
      print('Error fetching profiles: $e');
    }
  }

  // Filter profiles based on the search term
  void _filterProfiles() {
    String searchQuery = _searchController.text.toLowerCase();
    setState(() {
      filteredProfiles = profiles.where((profile) {
        List<dynamic> handymanTypes = profile['handymanType'];
        return handymanTypes
            .any((type) => type.toLowerCase().contains(searchQuery));
      }).toList();
    });
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _id = prefs.getString('_id') ?? '';
      _fname = prefs.getString('fname') ?? '';
      _lname = prefs.getString('lname') ?? '';
      _username = prefs.getString('username') ?? '';
      _contact = prefs.getString('contact') ?? '';
      _password = prefs.getString('password') ?? '';
      String? imagePath = prefs.getString('images');
      if (imagePath != null && imagePath.isNotEmpty) {
        _profileImage = File(imagePath);
      }
    });
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      // Save image path or update profile image in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImage', image.path);
    }
  }

  Future<Map<String, String>> _getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String fname = prefs.getString('fname') ?? 'First Name';
    String lname = prefs.getString('lname') ?? 'Last Name';
    String username = prefs.getString('username') ?? 'Username';
    return {'fname': fname, 'lname': lname, 'username': username};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "E-HandyHelp",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF081A6E),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: FutureBuilder<Map<String, String>>(
          future: _getUserData(),
          builder: (BuildContext context,
              AsyncSnapshot<Map<String, String>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error loading user data'));
            } else {
              final userData = snapshot.data!;
              return ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 7, 49, 112),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _pickProfileImage,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 30,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                    as ImageProvider<Object>
                                : AssetImage('lib/Images/profile.webp')
                                    as ImageProvider<Object>,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '${userData['fname']} ${userData['lname']}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          '$_username',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.account_circle,
                      color: const Color.fromARGB(255, 7, 49, 112),
                    ),
                    title: Text('Account Information'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AccountInformation()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.circle_notifications_rounded,
                      color: const Color.fromARGB(255, 7, 49, 112),
                    ),
                    title: Text('Notification'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NotificationPage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.message_rounded,
                      color: const Color.fromARGB(255, 7, 49, 112),
                    ),
                    title: Text('Messages'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MessagesScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.pending,
                      color: const Color.fromARGB(255, 7, 49, 112),
                    ),
                    title: Text('Pending Bookings'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingListScreen(
                              status: 'accepted', userId: _id),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.check_circle,
                      color: const Color.fromARGB(255, 7, 49, 112),
                    ),
                    title: Text('Completed Bookings'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingListScreen(
                              status: 'completed', userId: _id),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.contact_support_rounded,
                      color: const Color.fromARGB(255, 7, 49, 112),
                    ),
                    title: Text('Contact Admin'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContactAdminScreen(userId: _id),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.settings,
                      color: const Color.fromARGB(255, 7, 49, 112),
                    ),
                    title: Text('Settings'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.logout_rounded,
                      color: const Color.fromARGB(255, 7, 49, 112),
                    ),
                    title: Text('Logout'),
                    onTap: () async {
                      await _logout(context);
                    },
                  ),
                ],
              );
            }
          },
        ),
      ),
      body: _isLoading // Check loading state before rendering profiles
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: TextField(
                          controller:
                              _searchController, // Use the search controller
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Search Handyman',
                            suffixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Available Handymen',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 10),
                      ListView.builder(
                        itemCount: filteredProfiles.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return Card(
                            margin: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16.0),
                              leading: CircleAvatar(
                                backgroundImage: filteredProfiles[index]
                                            ['imageUrl'] !=
                                        null
                                    ? NetworkImage(
                                        filteredProfiles[index]['imageUrl'])
                                    : AssetImage(
                                            'https://via.placeholder.com/400x200?text=Profile')
                                        as ImageProvider<Object>,
                              ),
                              title: Text(filteredProfiles[index]['name']),
                              subtitle: Text(
                                  '${filteredProfiles[index]['address']}\n${filteredProfiles[index]['handymanType'].join(', ')}'),
                              isThreeLine: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HandymanDetailsPage(
                                      userId: _id ?? '',
                                      handymanId: filteredProfiles[index]
                                          ['_id'],
                                      handymanName: filteredProfiles[index]
                                          ['name'],
                                      handymanType: filteredProfiles[index]
                                              ['handymanType']
                                          .join(', '),
                                      contact: filteredProfiles[index]
                                          ['contact'],
                                      address: filteredProfiles[index]
                                          ['address'],
                                      imageUrl: filteredProfiles[index]
                                          ['imageUrl'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class Booking {
  final String id;
  final String serviceDetails;
  final String status;
  final String dateOfService; // New field
  final List<String> images; // New field for array of base64 strings
  final String userId; // New field for user ID
  final String bookerFirstName; // New field for Booker's First Name
  final String bookerLastName; // New field for Booker's Last Name

  Booking({
    required this.id,
    required this.serviceDetails,
    required this.status,
    required this.dateOfService,
    required this.images,
    required this.userId,
    required this.bookerFirstName,
    required this.bookerLastName,
  });

  // Factory method to create a Booking object from JSON
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? "no id",
      serviceDetails: json['serviceDetails'] ?? "No details",
      status: json['status'] ?? "no status",
      dateOfService: json['dateOfService'] ?? "No date provided",
      images:
          List<String>.from(json['images'] ?? []), // Parse the array of images
      userId: json['userId'] ?? "no user ID",
      bookerFirstName: json['bookerFirstName'] ?? "Unknown",
      bookerLastName: json['bookerLastName'] ?? "Unknown",
    );
  }
}

class BookingListScreen extends StatefulWidget {
  final String status;
  final String userId;

  BookingListScreen({required this.status, required this.userId});

  @override
  _BookingListScreenState createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  late Future<List<Booking>> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = _fetchBookings();
  }

  Future<List<Booking>> _fetchBookings() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/bookings-user?userId=${widget.userId}&status=${widget.status}'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> bookingsJson = json.decode(response.body);
        return bookingsJson.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load bookings: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching bookings: $e');
      throw Exception('Error fetching bookings: $e');
    }
  }

  Future<void> _reportBooking(String bookingId, String reportReason) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/reports'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'bookingId': bookingId,
          'reason': reportReason,
          'reported_by': 'user'
        }),
      );
      if (response.statusCode == 201) {
        _showToast("Report submitted successfully!");
        _refreshBookings();
      } else {
        throw Exception('Failed to report booking: ${response.body}');
      }
    } catch (e) {
      print('Error reporting booking: $e');
      _showToast("Failed to submit report.");
    }
  }

  Future<void> _markAsCompleted(String bookingId) async {
    try {
      final response = await http.patch(
        Uri.parse(
            'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/bookings/$bookingId/complete'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        _showToast("Booking marked as completed!");
        _refreshBookings();
      } else {
        throw Exception(
            'Failed to mark booking as completed: ${response.body}');
      }
    } catch (e) {
      print('Error marking booking as completed: $e');
      _showToast("Failed to mark booking as completed.");
    }
  }

  Future<void> _submitFeedback(
      String bookingId, int rating, String feedback) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'bookingId': bookingId,
          'rating': rating,
          'feedbackText': feedback,
          'sentBy': 'user',
        }),
      );
      if (response.statusCode == 201) {
        _showToast("Feedback submitted successfully!");
        _refreshBookings();
      } else {
        throw Exception('Failed to submit feedback: ${response.body}');
      }
    } catch (e) {
      print('Error submitting feedback: $e');
      _showToast("Failed to submit feedback.");
    }
  }

  void _refreshBookings() {
    setState(() {
      _bookings = _fetchBookings();
    });
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

 void _showBookingDetails(BuildContext context, Booking booking) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Text('Service: ${booking.serviceDetails}'),
              Text('Date of Service: ${booking.dateOfService}'),
              Text('Booker Name: ${booking.bookerFirstName} ${booking.bookerLastName}'),
              ...booking.images
                  .map((image) => Image.memory(base64Decode(image))),
            ],
          ),
        ),
        actions: _getDialogActions(context, booking),
      );
    },
  );
}

List<Widget> _getDialogActions(BuildContext context, Booking booking) {
  if (widget.status == 'accepted') {
    return [
      TextButton(
        onPressed: () => _showReportDialog(context, booking.id),
        child: Text('Report Booking'),
      ),
      TextButton(
        onPressed: () => _confirmMarkAsCompleted(context, booking.id),
        child: Text('Mark as Completed'),
      ),
    ];
  } else {
    return [
      TextButton(
        onPressed: () => _showFeedbackDialog(context, booking.id),
        child: Text('Leave Feedback'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Close'),
      ),
    ];
  }
}

void _showReportDialog(BuildContext context, String bookingId) {
  String reportReason = '';
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Report Booking'),
        content: TextField(
          onChanged: (value) => reportReason = value,
          decoration: InputDecoration(hintText: 'Enter report reason'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              bool confirmed = await _showConfirmationDialog(context, 'Report Submission', 'Are you sure you want to submit this report?');
              if (confirmed) {
                _reportBooking(bookingId, reportReason);
                Navigator.pop(context);
              }
            },
            child: Text('Submit Report'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      );
    },
  );
}

void _confirmMarkAsCompleted(BuildContext context, String bookingId) async {
  bool confirmed = await _showConfirmationDialog(context, 'Mark as Completed', 'Are you sure you want to mark this booking as completed?');
  if (confirmed) {
    _markAsCompleted(bookingId);
    Navigator.pop(context); // Close the booking details dialog
  }
}

Future<bool> _showConfirmationDialog(BuildContext context, String title, String message) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
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

void _showFeedbackDialog(BuildContext context, String bookingId) {
  int rating = 3;
  String feedback = '';
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Leave Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rate your experience:'),
            DropdownButton<int>(
              value: rating,
              onChanged: (newRating) {
                setState(() {
                  rating = newRating!;
                });
              },
              items: List.generate(5, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1} Star${index == 0 ? '' : 's'}'),
                );
              }),
            ),
            TextField(
              onChanged: (value) => feedback = value,
              decoration: InputDecoration(hintText: 'Enter feedback'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _submitFeedback(bookingId, rating, feedback);
              Navigator.pop(context);
            },
            child: Text('Submit Feedback'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.status == 'accepted'
            ? 'Pending Bookings'
            : 'Completed Bookings'),
      ),
      body: FutureBuilder<List<Booking>>(
        future: _bookings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading bookings',
                    style: TextStyle(color: Colors.red, fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Details: ${snapshot.error}',
                    style: TextStyle(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No bookings found'));
          } else {
            final bookings = snapshot.data!;
            return ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return ListTile(
                  title: Text('Booking ID: ${booking.id}'),
                  subtitle: Text('Service: ${booking.serviceDetails}'),
                  trailing: Text(
                      widget.status == 'accepted' ? 'Pending' : 'Completed'),
                  onTap: () => _showBookingDetails(context, booking),
                );
              },
            );
          }
        },
      ),
    );
  }
}

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
        Uri.parse(
            'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/contact-admin'), // Change to your server address
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
              child: Text('Send Message',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
