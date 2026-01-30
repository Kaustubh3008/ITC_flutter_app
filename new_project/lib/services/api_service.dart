// // // import 'dart:convert';
// // // import 'package:http/http.dart' as http;
// // // import '../config.dart';

// // // class ApiService {
// // //   // --- LOGIN ---
// // //   static Future<Map<String, dynamic>> login(
// // //     String email,
// // //     String password,
// // //   ) async {
// // //     try {
// // //       final response = await http.post(
// // //         Uri.parse('$API_BASE_URL/login'),
// // //         headers: {"Content-Type": "application/json"},
// // //         body: jsonEncode({"email": email, "password": password}),
// // //       );

// // //       final data = jsonDecode(response.body);

// // //       if (response.statusCode == 200) {
// // //         return {"success": true, "data": data};
// // //       } else {
// // //         return {"success": false, "message": data['message'] ?? "Login failed"};
// // //       }
// // //     } catch (e) {
// // //       return {"success": false, "message": "Server Error: $e"};
// // //     }
// // //   }

// // //   // --- SIGNUP ---
// // //   static Future<Map<String, dynamic>> signup(
// // //     String name,
// // //     String email,
// // //     String password,
// // //   ) async {
// // //     try {
// // //       final response = await http.post(
// // //         Uri.parse('$API_BASE_URL/register'),
// // //         headers: {"Content-Type": "application/json"},
// // //         body: jsonEncode({"name": name, "email": email, "password": password}),
// // //       );

// // //       final data = jsonDecode(response.body);

// // //       if (response.statusCode == 201) {
// // //         return {"success": true, "message": "Account created!"};
// // //       } else {
// // //         return {
// // //           "success": false,
// // //           "message": data['message'] ?? "Signup failed",
// // //         };
// // //       }
// // //     } catch (e) {
// // //       return {"success": false, "message": "Server Error: $e"};
// // //     }
// // //   }
// // // }

// // import 'dart:convert';
// // import 'dart:io';
// // import 'package:http/http.dart' as http;
// // import '../config.dart';

// // class ApiService {
// //   // --- LOGIN ---
// //   static Future<Map<String, dynamic>> login(
// //     String email,
// //     String password,
// //   ) async {
// //     try {
// //       final response = await http.post(
// //         Uri.parse('$API_BASE_URL/login'),
// //         headers: {"Content-Type": "application/json"},
// //         body: jsonEncode({"email": email, "password": password}),
// //       );

// //       final data = jsonDecode(response.body);

// //       if (response.statusCode == 200) {
// //         return {"success": true, "data": data};
// //       } else {
// //         return {"success": false, "message": data['message'] ?? "Login failed"};
// //       }
// //     } catch (e) {
// //       return {"success": false, "message": "Server Error: $e"};
// //     }
// //   }

// //   // --- SIGNUP ---
// //   static Future<Map<String, dynamic>> signup(
// //     String name,
// //     String email,
// //     String password,
// //   ) async {
// //     try {
// //       final response = await http.post(
// //         Uri.parse('$API_BASE_URL/register'),
// //         headers: {"Content-Type": "application/json"},
// //         body: jsonEncode({"name": name, "email": email, "password": password}),
// //       );

// //       final data = jsonDecode(response.body);

// //       if (response.statusCode == 201) {
// //         return {"success": true, "message": "Account created!"};
// //       } else {
// //         return {
// //           "success": false,
// //           "message": data['message'] ?? "Signup failed",
// //         };
// //       }
// //     } catch (e) {
// //       return {"success": false, "message": "Server Error: $e"};
// //     }
// //   }

// //   // --- NEW: UPLOAD BATCH FOR ANALYSIS ---
// //   static Future<Map<String, dynamic>> uploadBatch(File zipFile) async {
// //     try {
// //       // Ensure PREDICT_API_URL is defined in your config.dart file
// //       var request = http.MultipartRequest('POST', Uri.parse(PREDICT_API_URL));

// //       // Add the file
// //       request.files.add(
// //         await http.MultipartFile.fromPath('file', zipFile.path),
// //       );

// //       // Send
// //       var streamedResponse = await request.send();
// //       var response = await http.Response.fromStream(streamedResponse);

// //       if (response.statusCode == 200) {
// //         return jsonDecode(response.body);
// //       } else {
// //         return {
// //           "status": "error",
// //           "message": "Server Error: ${response.statusCode} - ${response.body}",
// //         };
// //       }
// //     } catch (e) {
// //       return {"status": "error", "message": "Connection Error: $e"};
// //     }
// //   }
// // }

// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import '../config.dart';

// class ApiService {
//   // ==========================================
//   // 1. AUTHENTICATION (Login & Signup)
//   // ==========================================

//   // --- LOGIN ---
//   static Future<Map<String, dynamic>> login(
//     String email,
//     String password,
//   ) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$API_BASE_URL/login'),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"email": email, "password": password}),
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         return {"success": true, "data": data};
//       } else {
//         return {"success": false, "message": data['message'] ?? "Login failed"};
//       }
//     } catch (e) {
//       return {"success": false, "message": "Server Error: $e"};
//     }
//   }

//   // --- SIGNUP ---
//   static Future<Map<String, dynamic>> signup(
//     String name,
//     String email,
//     String password,
//   ) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$API_BASE_URL/register'),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"name": name, "email": email, "password": password}),
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 201) {
//         return {"success": true, "message": "Account created!"};
//       } else {
//         return {
//           "success": false,
//           "message": data['message'] ?? "Signup failed",
//         };
//       }
//     } catch (e) {
//       return {"success": false, "message": "Server Error: $e"};
//     }
//   }

//   // ==========================================
//   // 2. CLOUD PROCESSING (Upload to Senior Dev's API)
//   // ==========================================

//   static Future<Map<String, dynamic>> uploadBatch(File zipFile) async {
//     try {
//       var request = http.MultipartRequest('POST', Uri.parse(PREDICT_API_URL));

//       // Add the file
//       request.files.add(
//         await http.MultipartFile.fromPath('file', zipFile.path),
//       );

//       // Send
//       var streamedResponse = await request.send();
//       var response = await http.Response.fromStream(streamedResponse);

//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       } else {
//         return {
//           "status": "error",
//           "message": "Server Error: ${response.statusCode} - ${response.body}",
//         };
//       }
//     } catch (e) {
//       return {"status": "error", "message": "Connection Error: $e"};
//     }
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  // 1. AUTHENTICATION (Login & Signup)
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$API_BASE_URL/login'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(const Duration(seconds: 15)); // 15s timeout for login

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data['message'] ?? "Login failed"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection Error: $e"};
    }
  }

  static Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$API_BASE_URL/register'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": name,
              "email": email,
              "password": password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {"success": true, "message": "Account created!"};
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Signup failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Connection Error: $e"};
    }
  }

  // 2. CLOUD PROCESSING (Upload with Long Timeout)
  static Future<Map<String, dynamic>> uploadBatch(File zipFile) async {
    final client = http.Client();
    try {
      var request = http.MultipartRequest('POST', Uri.parse(PREDICT_API_URL));

      // Add the file
      request.files.add(
        await http.MultipartFile.fromPath('file', zipFile.path),
      );

      // SEND WITH 5 MINUTE TIMEOUT
      // This helps if the server is slow, but won't fix it if the Server cuts us off.
      var streamedResponse = await client
          .send(request)
          .timeout(const Duration(minutes: 5));

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "error",
          "message": "Server Error: ${response.statusCode} - ${response.body}",
        };
      }
    } catch (e) {
      return {"status": "error", "message": "Connection Error: $e"};
    } finally {
      client.close();
    }
  }
}
