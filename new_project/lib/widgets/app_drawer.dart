// // import 'package:flutter/material.dart';
// // import '../screens/home_screen.dart'; // Just in case you navigate back
// // import '../screens/message_box_screen.dart';

// // class AppDrawer extends StatelessWidget {
// //   const AppDrawer({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Drawer(
// //       backgroundColor: Colors.white,
// //       child: Column(
// //         children: [
// //           const UserAccountsDrawerHeader(
// //             decoration: BoxDecoration(color: Color(0xFF191825)),
// //             accountName: Text(
// //               "Admin User",
// //               style: TextStyle(fontWeight: FontWeight.bold),
// //             ),
// //             accountEmail: Text("admin@itc.project"),
// //             currentAccountPicture: CircleAvatar(
// //               backgroundColor: Colors.white,
// //               child: Icon(Icons.person, color: Color(0xFF191825)),
// //             ),
// //           ),
// //           ListTile(
// //             leading: const Icon(Icons.folder_copy),
// //             title: const Text("My Files"),
// //             onTap: () {
// //               Navigator.pop(context); // Close drawer
// //               // If already on Home, do nothing or navigate
// //             },
// //           ),
// //           ListTile(
// //             leading: const Icon(Icons.message_outlined),
// //             title: const Text("Message Box"),
// //             onTap: () {
// //               Navigator.pop(context); // Close Drawer
// //               Navigator.push(
// //                 context,
// //                 MaterialPageRoute(
// //                   builder: (context) => const MessageBoxScreen(),
// //                 ),
// //               );
// //             },
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// 29 FIRST
// import 'package:flutter/material.dart';
// import '../services/user_session.dart'; // Import the session manager
// import '../screens/login_screen.dart';
// import '../screens/home_screen.dart';
// import '../screens/message_box_screen.dart';

// class AppDrawer extends StatelessWidget {
//   const AppDrawer({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       backgroundColor: Colors.white,
//       child: Column(
//         children: [
//           UserAccountsDrawerHeader(
//             decoration: const BoxDecoration(color: Color(0xFF191825)),
//             // --- DYNAMIC DATA FROM SESSION ---
//             accountName: Text(
//               UserSession.name, // Reads "Kaustubh" (or whatever name)
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             accountEmail: Text(
//               UserSession.email, // Reads the email used to login
//             ),
//             // ---------------------------------
//             currentAccountPicture: const CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF191825)),
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.folder_copy),
//             title: const Text("My Files"),
//             onTap: () {
//               Navigator.pop(context); // Close drawer
//               // Logic to navigate home if not already there
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.message_outlined),
//             title: const Text("Message Box"),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const MessageBoxScreen(),
//                 ),
//               );
//             },
//           ),
//           const Spacer(), // Pushes Logout to the bottom
//           const Divider(),
//           ListTile(
//             leading: const Icon(Icons.logout, color: Colors.red),
//             title: const Text("Logout", style: TextStyle(color: Colors.red)),
//             onTap: () {
//               // --- LOGOUT LOGIC ---
//               UserSession.clear(); // Clear data
//               Navigator.pushAndRemoveUntil(
//                 context,
//                 MaterialPageRoute(builder: (context) => const LoginScreen()),
//                 (route) => false, // Remove all previous routes
//               );
//             },
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../services/user_session.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/message_box_screen.dart';
import '../screens/server_upload_screen.dart'; // Import the new screen

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF191825)),
            accountName: Text(
              UserSession.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(UserSession.email),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF191825)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.folder_copy),
            title: const Text("My Files"),
            onTap: () {
              Navigator.pop(context);
              // Navigate to Home if not already there
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.message_outlined),
            title: const Text("Message Box"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MessageBoxScreen(),
                ),
              );
            },
          ),
          // --- NEW OPTION ADDED HERE ---
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text("Upload to Server"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServerUploadScreen(),
                ),
              );
            },
          ),
          // -----------------------------
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () {
              UserSession.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
