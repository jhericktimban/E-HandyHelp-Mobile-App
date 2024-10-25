import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'new_password.dart';

class OTPPage extends StatefulWidget {
  final String phoneNumber;

  OTPPage({required this.phoneNumber});

  @override
  _OTPPageState createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  late Timer _timer;
  int _start = 60;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start == 0) {
        timer.cancel();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  Future<void> _submitOTP() async {
    String enteredOTP =
        _otpControllers.map((controller) => controller.text).join();

    if (enteredOTP.length != 4) {
      _showErrorDialog('Please enter a valid 4-digit OTP.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Call API to verify OTP and check phone number in collections
    try {
      final response = await http.post(
        Uri.parse(
            'https://6762a6b5-bcae-47d9-9b32-173db9699b2c-00-2yzwy4xs0f5zs.pike.replit.dev/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': widget.phoneNumber,
          'otp': enteredOTP,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Success - OTP is correct, proceed to password reset page with user ID
        String userId = data['userId'];
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NewPasswordPage(userId: userId),
          ),
        );
      } else {
        // Error - OTP mismatch or phone number not found
        _showErrorDialog(data['message'] ?? 'Invalid OTP or phone number.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred. Please try again.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://6762a6b5-bcae-47d9-9b32-173db9699b2c-00-2yzwy4xs0f5zs.pike.replit.dev/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': widget.phoneNumber}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _start = 60;
        });
        _startTimer();
        _showSuccessDialog('OTP has been resent successfully.');
      } else {
        final errorResponse = json.decode(response.body);
        _showErrorDialog(errorResponse['message'] ?? 'Failed to resend OTP.');
      }
    } catch (e) {
      _showErrorDialog('Failed to resend OTP. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter OTP', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 7, 49, 112),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    _buildImage(),
                    SizedBox(height: 20),
                    _buildOtpSentText(),
                    SizedBox(height: 10),
                    _buildOtpInstructions(),
                    SizedBox(height: 20),
                    _buildOtpInput(),
                    SizedBox(height: 20),
                    _buildCountdownText(),
                    SizedBox(height: 10),
                    _buildResendButton(),
                    SizedBox(height: 20),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/Images/otpimage.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildOtpSentText() {
    return Text(
      'OTP sent to ${widget.phoneNumber}',
      style: TextStyle(
        fontSize: 24,
        color: Colors.black,
        fontFamily: 'Outfit',
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildOtpInstructions() {
    return Text(
      'Please enter the OTP sent to your phone number.',
      style: TextStyle(
        fontSize: 14,
        color: Color(0xFF5B5858),
        fontFamily: 'Outfit',
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(4, (index) {
        return SizedBox(
          width: 50,
          child: TextField(
            controller: _otpControllers[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              counterText: '',
            ),
            maxLength: 1,
            onChanged: (value) {
              if (value.isNotEmpty && index < 3) {
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildCountdownText() {
    return Text(
      _start == 0 ? '' : '$_start seconds remaining',
      style: TextStyle(fontSize: 16, color: Colors.grey),
    );
  }

  Widget _buildResendButton() {
    return _start == 0
        ? TextButton(
            onPressed: _resendCode,
            child: Text(
              'Didn\'t receive the code? Resend',
              style: TextStyle(color: Color.fromARGB(255, 7, 49, 112)),
            ),
          )
        : Container();
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitOTP,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 49, 112),
      ),
      child:
          Text('Submit', style: TextStyle(fontSize: 16, color: Colors.white)),
    );
  }
}
