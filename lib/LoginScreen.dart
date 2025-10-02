// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'OTPScreen.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({Key? key}) : super(key: key);
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _phoneController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   bool _isLoading = false;
//
//   void _sendOTP() async {
//     final phone = _phoneController.text.trim();
//     if (phone.isEmpty || phone.length < 10) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enter a valid phone number")),
//       );
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     await _auth.verifyPhoneNumber(
//       phoneNumber: '+91$phone',
//       verificationCompleted: (PhoneAuthCredential credential) {},
//       verificationFailed: (FirebaseAuthException e) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("OTP Failed: ${e.message}")),
//         );
//       },
//       codeSent: (String verificationId, int? resendToken) {
//         setState(() => _isLoading = false);
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => OTPScreen(
//               verificationId: verificationId,
//               phoneNumber: '+91$phone',
//             ),
//           ),
//         );
//       },
//       codeAutoRetrievalTimeout: (String verificationId) {},
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Ricky Login'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Image.asset(
//             'lib/assests/icons/icon.png', // Make sure this path matches your file
//             height: 150, // You can adjust the size
//             ),
//             const SizedBox(height: 40),
//             const SizedBox(height: 30),
//             TextField(
//               controller: _phoneController,
//               keyboardType: TextInputType.phone,
//               maxLength: 10,
//               decoration: const InputDecoration(
//                 border: OutlineInputBorder(),
//                 labelText: 'Phone Number',
//                 prefixText: '+91 ',
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _isLoading ? null : _sendOTP,
//               child: _isLoading
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text("Send OTP"),
//               style: ElevatedButton.styleFrom(
//                 minimumSize: const Size(double.infinity, 50),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'OTPScreen.dart'; // Make sure this path is correct

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    // Listen for changes in the text field to enable/disable the button
    _phoneController.addListener(_validatePhoneNumber);
  }

  @override
  void dispose() {
    // Clean up the controller and listener when the widget is disposed
    _phoneController.removeListener(_validatePhoneNumber);
    _phoneController.dispose();
    super.dispose();
  }

  /// Checks if the phone number has 10 digits and updates the button state.
  void _validatePhoneNumber() {
    final isComplete = _phoneController.text.length == 10;
    // Only call setState if the enabled state actually changes
    if (isComplete != _isButtonEnabled) {
      setState(() {
        _isButtonEnabled = isComplete;
      });
    }
  }

  void _sendOTP() async {
    final phone = _phoneController.text.trim();
    // This check is a safeguard, but the button state should prevent this.
    if (phone.length != 10) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      verificationCompleted: (PhoneAuthCredential credential) {
        // Handle auto-verification if it occurs
        setState(() => _isLoading = false);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP Failed: ${e.message}")),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OTPScreen(
                verificationId: verificationId,
                phoneNumber: '+91$phone',
              ),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ricky Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ensure you have an image at this path in your project assets
            Image.asset(
              'lib/assests/icons/icon.png',
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                // Shows a placeholder if the image is not found
                return const Icon(Icons.local_taxi, size: 150);
              },
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Phone Number',
                prefixText: '+91 ',
                counterText: "", // Hides the counter below the field
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              // Button is disabled if loading or if the number is not 10 digits
              onPressed: (_isLoading || !_isButtonEnabled) ? null : _sendOTP,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                // Change color based on whether the button is enabled
                backgroundColor: _isButtonEnabled
                    ? Colors.deepPurple
                    : Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Send OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
