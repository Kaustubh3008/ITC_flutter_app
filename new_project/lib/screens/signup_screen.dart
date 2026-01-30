// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../widgets/custom_text_field.dart';
// import 'home_screen.dart';

// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passController = TextEditingController();
//   final TextEditingController _confirmController = TextEditingController();

//   void _handleSignup() {
//     // Navigate to Home after "signup"
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (context) => const HomeScreen()),
//       (route) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F7F6),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 10),
//               Text(
//                 "Create Account",
//                 style: GoogleFonts.poppins(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: const Color(0xFF191825),
//                 ),
//               ),
//               Text(
//                 "Join AgriSync to start monitoring.",
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 40),

//               // --- INPUT FIELDS ---
//               CustomTextField(
//                 controller: _nameController,
//                 hintText: "Full Name",
//                 icon: Icons.person_outline,
//               ),
//               const SizedBox(height: 20),
//               CustomTextField(
//                 controller: _emailController,
//                 hintText: "Email Address",
//                 icon: Icons.email_outlined,
//                 keyboardType: TextInputType.emailAddress,
//               ),
//               const SizedBox(height: 20),
//               CustomTextField(
//                 controller: _passController,
//                 hintText: "Password",
//                 icon: Icons.lock_outline,
//                 isPassword: true,
//               ),
//               const SizedBox(height: 20),
//               CustomTextField(
//                 controller: _confirmController,
//                 hintText: "Confirm Password",
//                 icon: Icons.lock_reset,
//                 isPassword: true,
//               ),

//               const SizedBox(height: 40),

//               // --- SIGNUP BUTTON ---
//               SizedBox(
//                 width: double.infinity,
//                 height: 55,
//                 child: ElevatedButton(
//                   onPressed: _handleSignup,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(
//                       0xFF2E7D32,
//                     ), // Dark Green for contrast
//                     foregroundColor: Colors.white,
//                     elevation: 5,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                   ),
//                   child: Text(
//                     "Sign Up",
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 30),

//               // --- FOOTER ---
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     "Already have an account? ",
//                     style: GoogleFonts.poppins(color: Colors.grey[600]),
//                   ),
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: Text(
//                       "Login",
//                       style: GoogleFonts.poppins(
//                         color: const Color(0xFF2E7D32),
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_text_field.dart';
import 'home_screen.dart';
import '../services/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  void _handleSignup() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passController.text.trim();
    String confirm = _confirmController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.signup(name, email, password);

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account Created! Please Login."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to Login Screen
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                "Create Account",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF191825),
                ),
              ),
              Text(
                "Join AgriSync to start monitoring.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),

              // --- INPUT FIELDS ---
              CustomTextField(
                controller: _nameController,
                hintText: "Full Name",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _emailController,
                hintText: "Email Address",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passController,
                hintText: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _confirmController,
                hintText: "Confirm Password",
                icon: Icons.lock_reset,
                isPassword: true,
              ),

              const SizedBox(height: 40),

              // --- SIGNUP BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF2E7D32,
                    ), // Dark Green for contrast
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Sign Up",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),

              // --- FOOTER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      "Login",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
