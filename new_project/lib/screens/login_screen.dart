// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../widgets/custom_text_field.dart';
// import 'signup_screen.dart';
// import 'home_screen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   void _handleLogin() {
//     // For now, just navigate to Home
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => const HomeScreen()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F7F6),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 40),
//               // --- HEADER ---
//               Center(
//                 child: Container(
//                   height: 80,
//                   width: 80,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFE8F5E9),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.eco,
//                     size: 40,
//                     color: Color(0xFF2E7D32),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),
//               Text(
//                 "Welcome Back,",
//                 style: GoogleFonts.poppins(
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                   color: const Color(0xFF191825),
//                 ),
//               ),
//               Text(
//                 "Sign in to continue managing your data.",
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 40),

//               // --- INPUT FIELDS ---
//               CustomTextField(
//                 controller: _emailController,
//                 hintText: "Email Address",
//                 icon: Icons.email_outlined,
//                 keyboardType: TextInputType.emailAddress,
//               ),
//               const SizedBox(height: 20),
//               CustomTextField(
//                 controller: _passwordController,
//                 hintText: "Password",
//                 icon: Icons.lock_outline,
//                 isPassword: true,
//               ),

//               // --- FORGOT PASSWORD ---
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: TextButton(
//                   onPressed: () {},
//                   child: Text(
//                     "Forgot Password?",
//                     style: GoogleFonts.poppins(
//                       color: const Color(0xFF2E7D32),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),

//               // --- LOGIN BUTTON ---
//               SizedBox(
//                 width: double.infinity,
//                 height: 55,
//                 child: ElevatedButton(
//                   onPressed: _handleLogin,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFFC8F000), // Lime theme
//                     foregroundColor: Colors.black,
//                     elevation: 5,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                   ),
//                   child: Text(
//                     "Login",
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // --- FOOTER ---
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     "Don't have an account? ",
//                     style: GoogleFonts.poppins(color: Colors.grey[600]),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const SignupScreen(),
//                         ),
//                       );
//                     },
//                     child: Text(
//                       "Create Account",
//                       style: GoogleFonts.poppins(
//                         color: const Color(0xFF2E7D32),
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
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
import 'signup_screen.dart';
import 'home_screen.dart';
import '../services/api_service.dart';
import '../services/user_session.dart'; // Import this at the top

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Call API
    final result = await ApiService.login(email, password);

    setState(() => _isLoading = false);

    if (result['success']) {
      // --- SAVE DATA TO SESSION ---
      // The API returns 'name' in result['data']['name']
      // The API doesn't return 'email', but we have it from the text controller
      String name = result['data']['name'];
      UserSession.setUser(name, email);
      // ----------------------------

      if (mounted) {
        // Navigate to Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      if (mounted) {
        // Error
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // --- HEADER ---
              Center(
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco,
                    size: 40,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "Welcome Back,",
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF191825),
                ),
              ),
              Text(
                "Sign in to continue managing your data.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),

              // --- INPUT FIELDS ---
              CustomTextField(
                controller: _emailController,
                hintText: "Email Address",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                hintText: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),

              // --- FORGOT PASSWORD ---
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    "Forgot Password?",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- LOGIN BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8F000), // Lime theme
                    foregroundColor: Colors.black,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.black,
                        ) // Show loader
                      : Text(
                          "Login",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // --- FOOTER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Create Account",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
