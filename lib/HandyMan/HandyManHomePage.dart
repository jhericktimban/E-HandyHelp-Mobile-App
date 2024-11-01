// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:E_HandyHelp/FirstPage.dart';
import 'package:E_HandyHelp/HandyMan/HandyManMessage.dart';
import 'package:E_HandyHelp/HandyMan/HandyManAccInformation.dart';
import 'package:E_HandyHelp/HandyMan/HandymanNotification.dart';

import 'package:E_HandyHelp/User/Settings.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HandyManHomePage extends StatefulWidget {
  const HandyManHomePage({super.key});

  @override
  _HandyManHomePageState createState() => _HandyManHomePageState();
}

class _HandyManHomePageState extends State<HandyManHomePage> {
  String _id = '';
  String _fname = '';
  String _lname = '';
  String _username = '';
  String _password = '';
  String _contact = '';
  String _address = '';
  String _dateOfBirth = '';
  File? _handymanImage;

  TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHandymanData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchProfiles(); // Fetch profiles whenever dependencies change
  }

  List<Map<String, dynamic>> profiles = [];

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

  Future<void> _loadHandymanData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _id = prefs.getString('_id') ?? '';
      _fname = prefs.getString('fname') ?? '';
      _lname = prefs.getString('lname') ?? '';
      _username = prefs.getString('username') ?? '';
      _contact = prefs.getString('contact') ?? '';
      _password = prefs.getString('password') ?? '';
      String? imagePath = prefs.getString('handymanImage');
      if (imagePath != null && imagePath.isNotEmpty) {
        _handymanImage = File(imagePath);
      }
      print('Loaded handyman data: _id: $_id, fname: $_fname, lname: $_lname');
      fetchProfiles();
    });
  }

  Future<void> fetchProfiles() async {
    try {
      if (_id == null || _id.isEmpty) {
        throw Exception('Handyman ID is missing');
      }

      print('Fetching profiles for handymanId: $_id');

      final response = await http.get(
        Uri.parse(
            'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/requested-profiles?handymanId=$_id'),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);

        setState(() {
          profiles = jsonResponse.map((profile) {
            // Handle null or incorrect types for 'serviceImages'
            List<String> serviceImages = (profile['serviceImages'] is List)
                ? List<String>.from(profile['serviceImages'])
                : [];

            // Safely handle 'images' field, checking if it can be a List or String
            var imageUrl = profile['images'];
            if (imageUrl is List) {
              imageUrl = imageUrl.isNotEmpty
                  ? imageUrl[0]
                  : ''; // Get the first image if it's a list
            } else if (imageUrl is! String) {
              imageUrl = ''; // Default to an empty string if it's not a string
            }

            return {
              'bookingId': profile['bookingId'],
              'userId': profile['userId'],
              'handymanId': _id,
              'name': profile['name'] ?? 'Unknown',
              'address': profile['address'] ?? 'No address',
              'contact': profile['contact'] ?? 'No contact',
              'serviceDetails': profile['serviceDetails'] ?? 'No details',
              'dateOfService': profile['dateOfService'] ?? 'No date',
              'serviceImages': serviceImages,
              'imageUrl': imageUrl,
            };
          }).toList();
        });
      } else {
        throw Exception('Failed to load profiles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profiles: $e');
    }
  }

  Future<Map<String, String>> _getHandymanData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String fname = prefs.getString('fname') ?? 'First Name';
    String lname = prefs.getString('lname') ?? 'Last Name';
    String username = prefs.getString('username') ?? 'Username';
    return {'fname': fname, 'lname': lname, 'username': username};
  }

  Future<void> _pickHandymanImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _handymanImage = File(image.path);
      });
      // Save image path or update profile image in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('handymanImage', image.path);
    }
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
          future: _getHandymanData(),
          builder: (BuildContext context,
              AsyncSnapshot<Map<String, String>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error loading user data'));
            } else {
              final handymanData = snapshot.data!;
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
                          onTap: _pickHandymanImage,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 30,
                            backgroundImage: _handymanImage != null
                                ? FileImage(_handymanImage!)
                                    as ImageProvider<Object>
                                : AssetImage('lib/Images/profile.webp')
                                    as ImageProvider<Object>,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '${handymanData['fname']} ${handymanData['lname']}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          '@${handymanData['username']!}',
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
                            builder: (context) => HandymanMessagesScreen()),
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
                              status: 'accepted', handyManId: _id),
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
                              status: 'completed', handyManId: _id),
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
                        MaterialPageRoute(builder: (context) => SettingsPage()),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 40),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Service Requests',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 7, 49, 112),
                        ),
                      ),
                    ],
                  ),
                ),
                // Conditional rendering based on profiles length
                if (profiles.isEmpty) // Check if profiles is empty
                  Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                    child: Center(
                      child: Text(
                        'No service requests yet',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Color.fromARGB(255, 7, 49, 112),
                        ),
                      ),
                    ),
                  )
                else // Render ListView.builder if profiles is not empty
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount:
                        profiles.length, // Use profiles.length for dynamic data
                    itemBuilder: (context, index) {
                      // Logging the values to check for null
                      String name = profiles[index]['name'] ?? 'Unknown';
                      if (profiles[index]['name'] == null)
                        print('Null detected in "name" at index $index');

                      String address =
                          profiles[index]['address'] ?? 'No address';
                      if (profiles[index]['address'] == null)
                        print('Null detected in "address" at index $index');

                      String contact =
                          profiles[index]['contact'] ?? 'No contact';
                      if (profiles[index]['contact'] == null)
                        print('Null detected in "contact" at index $index');

                      String imageUrl = profiles[index]['imageUrl'] ??
                          'assets/default_image.png'; // Ensure a fallback image
                      if (profiles[index]['imageUrl'] == null)
                        print('Null detected in "imageUrl" at index $index');

                      String serviceDetails =
                          profiles[index]['serviceDetails'] ?? 'No details';
                      if (profiles[index]['serviceDetails'] == null)
                        print(
                            'Null detected in "serviceDetails" at index $index');

                      String dateOfService =
                          profiles[index]['dateOfService'] ?? 'No date';
                      if (profiles[index]['dateOfService'] == null)
                        print(
                            'Null detected in "dateOfService" at index $index');

                      List<String> serviceImages = profiles[index]
                                      ['serviceImages'] !=
                                  null &&
                              profiles[index]['serviceImages'] is List<String>
                          ? profiles[index]['serviceImages']
                          : [];
                      if (profiles[index]['serviceImages'] == null)
                        print(
                            'Null detected in "serviceImages" at index $index');

                      return Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileDetailPage(
                                    bookingId: profiles[index]['bookingId'],
                                    userId: profiles[index]['userId'],
                                    handymanId: _id,
                                    imageUrl: imageUrl,
                                    name: name,
                                    address: address,
                                    contact: contact,
                                    serviceDetails: serviceDetails,
                                    dateOfService: dateOfService,
                                    serviceImages:
                                        serviceImages, // Pass the list of images
                                  ),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  // Rerun fetchProfiles when returning to the previous screen
                                  fetchProfiles();
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: AssetImage(imageUrl),
                                ),
                                title: Text(name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Address: $address'),
                                    Text('Contact: $contact'),
                                    Text('Service: $serviceDetails'),
                                    Text('Date: $dateOfService'),
                                  ],
                                ),
                              ),
                            ),
                          ),
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

class ProfileDetailPage extends StatefulWidget {
  final String bookingId;
  final String userId;
  final String handymanId;
  final String name;
  final String address;
  final String serviceDetails;
  final String imageUrl; // User's profile image
  final List<String> serviceImages; // List of service images
  final String contact; // New parameter for contact information
  final String dateOfService; // New parameter for date of service

  const ProfileDetailPage({
    Key? key,
    required this.bookingId,
    required this.userId,
    required this.handymanId,
    required this.name,
    required this.address,
    required this.serviceDetails,
    required this.imageUrl,
    required this.serviceImages, // List of service images
    required this.contact, // Add contact parameter
    required this.dateOfService, // Add dateOfService parameter
  }) : super(key: key);

  @override
  _ProfileDetailPageState createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  bool _isLoading = false; // Loading state variable

  Future<void> acceptBooking(BuildContext context) async {
    setState(() {
      _isLoading = true; // Show loader
    });

    final response = await http.post(
      Uri.parse(
          'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/accept-booking'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'bookingId': widget.bookingId,
        'handymanId': widget.handymanId,
        'userId': widget.userId,
        'serviceDetails': widget.serviceDetails,
        'name': widget.name,
        'contact': widget.contact,
        'address': widget.address,
        'dateOfService': widget.dateOfService,
      }),
    );

    setState(() {
      _isLoading = false; // Hide loader
    });

    if (response.statusCode == 200) {
      Navigator.pop(context, true);
      print('Booking accepted');
    } else {
      // Show error message
      print('Failed to accept booking');
    }
  }

  Future<void> declineBooking(BuildContext context) async {
    setState(() {
      _isLoading = true; // Show loader
    });

    final response = await http.post(
      Uri.parse(
          'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/decline-booking'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'bookingId': widget.bookingId,
        'handymanId': widget.handymanId,
        'userId': widget.userId,
      }),
    );

    setState(() {
      _isLoading = false; // Hide loader
    });

    if (response.statusCode == 200) {
      Navigator.pop(context, true);
      print('Booking declined');
    } else {
      // Show error message
      print('Failed to decline booking');
    }
  }

  // Method to show full-screen zoomable image
  void _showImageGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text("Service Images")),
          body: PhotoViewGallery.builder(
            itemCount: widget.serviceImages.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider:
                    MemoryImage(base64Decode(widget.serviceImages[index])),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.0,
              );
            },
            scrollPhysics: BouncingScrollPhysics(),
            backgroundDecoration: BoxDecoration(color: Colors.black),
            pageController: PageController(initialPage: initialIndex),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 7, 49, 112),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(widget.imageUrl),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Name:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(widget.name, style: TextStyle(fontSize: 20)),
                  SizedBox(height: 16),
                  Text('Address:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(widget.address, style: TextStyle(fontSize: 20)),
                  SizedBox(height: 16),
                  Text('Contact:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(widget.contact, style: TextStyle(fontSize: 20)),
                  SizedBox(height: 16),
                  Text('Date of Service:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(widget.dateOfService, style: TextStyle(fontSize: 20)),
                  SizedBox(height: 16),
                  Text('Service Details:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(widget.serviceDetails, style: TextStyle(fontSize: 20)),
                  SizedBox(height: 24),
                  Text('Service Images:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  // Display service images
                  widget.serviceImages.isNotEmpty
                      ? Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children:
                              widget.serviceImages.asMap().entries.map((entry) {
                            int index = entry.key;
                            String imageBase64 = entry.value;
                            return GestureDetector(
                              onTap: () {
                                _showImageGallery(context,
                                    index); // Show zoomable image on tap
                              },
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  image: DecorationImage(
                                    image:
                                        MemoryImage(base64Decode(imageBase64)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      : Text('No service images available.'),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                _showConfirmationDialog(
                                  context: context,
                                  title: 'Accept Booking',
                                  content:
                                      'Are you sure you want to accept this booking?',
                                  onConfirm: () {
                                    acceptBooking(
                                        context); // Call accept booking function
                                    _showSuccessMessage(context,
                                        'Booking accepted successfully');
                                  },
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 7, 49, 112),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2.0,
                              )
                            : Text('Accept',
                                style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                _showConfirmationDialog(
                                  context: context,
                                  title: 'Decline Booking',
                                  content:
                                      'Are you sure you want to decline this booking?',
                                  onConfirm: () {
                                    declineBooking(
                                        context); // Call decline booking function
                                  },
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2.0,
                              )
                            : Text('Decline',
                                style: TextStyle(color: Colors.white)),
                      ),
                    ],
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

class ViewHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service History'),
      ),
      body: Center(
        child: Text('Service History Page Content'),
      ),
    );
  }
}

void _showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close the dialog
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              onConfirm(); // Proceed with the action
            },
            child: Text('Confirm'),
          ),
        ],
      );
    },
  );
}

void _showSuccessMessage(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
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
  final String handyManId;

  BookingListScreen({required this.status, required this.handyManId});

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
            'https://82a31fb0-14d4-4fa5-99a4-d77055a37ac9-00-7tbd8qpmk7fk.sisko.replit.dev/bookings?handymanId=${widget.handyManId}&status=${widget.status}'),
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
          'reported_by': 'handyman'
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
          'sentBy': 'handyman'
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
