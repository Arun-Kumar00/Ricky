import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ricky/Views/main_screen.dart';
import 'package:ricky/Views/create_restaurant_profile_screen.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPScreen({
    Key? key,
    required this.verificationId,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    // Listen for changes in the text field to enable/disable the button
    _otpController.addListener(_validateOtp);
  }

  @override
  void dispose() {
    // Clean up the controller and listener when the widget is disposed
    _otpController.removeListener(_validateOtp);
    _otpController.dispose();
    super.dispose();
  }

  /// Checks if the OTP has 6 digits and updates the button state.
  void _validateOtp() {
    final isComplete = _otpController.text.length == 6;
    if (isComplete != _isButtonEnabled) {
      setState(() {
        _isButtonEnabled = isComplete;
      });
    }
  }

  void _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      // This is a safeguard; button state should prevent this call
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      setState(() => _isVerifying = false);

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final snapshot = await FirebaseDatabase.instance.ref('restaurants/$uid/profile/name').get();

        if (mounted) {
          if (snapshot.exists) {
            // Profile exists → Go to Home
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
                  (route) => false,
            );
          } else {
            // No profile → Go to Setup
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const CreateRestaurantProfileScreen()),
                  (route) => false,
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isVerifying = false);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP Verification Failed: ${e.message}")),
        );
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter the 6-digit OTP sent to ${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'OTP',
                counterText: "", // Hides the counter
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_isVerifying || !_isButtonEnabled) ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: _isButtonEnabled ? Colors.deepPurple : Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: _isVerifying
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Verify OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
