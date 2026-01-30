// // // // import 'dart:async';
// // // // import 'dart:convert';
// // // // import 'dart:io';
// // // // import 'dart:typed_data';

// // // // import 'package:connectivity_plus/connectivity_plus.dart';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:google_fonts/google_fonts.dart';
// // // // import 'package:network_info_plus/network_info_plus.dart';
// // // // import 'package:open_file/open_file.dart';
// // // // import 'package:path_provider/path_provider.dart';
// // // // import 'package:permission_handler/permission_handler.dart';
// // // // import 'package:animate_do/animate_do.dart';

// // // // // --- CONFIGURATION ---
// // // // const String SECRET_KEY = "securekey";
// // // // const int TCP_PORT = 5001;
// // // // const int DISCOVERY_PORT = 5000;

// // // // void main() {
// // // //   runApp(const MyApp());
// // // // }

// // // // class MyApp extends StatelessWidget {
// // // //   const MyApp({super.key});

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return MaterialApp(
// // // //       debugShowCheckedModeBanner: false,
// // // //       title: 'AgriSync',
// // // //       theme: ThemeData(
// // // //         useMaterial3: true,
// // // //         scaffoldBackgroundColor: const Color(0xFFF4F7F6), // Light Grey Bg
// // // //         primaryColor: const Color(0xFF2E7D32), // Agri Green
// // // //         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
// // // //         textTheme: GoogleFonts.poppinsTextTheme(),
// // // //       ),
// // // //       home: const HomeScreen(),
// // // //     );
// // // //   }
// // // // }

// // // // class HomeScreen extends StatefulWidget {
// // // //   const HomeScreen({super.key});

// // // //   @override
// // // //   State<HomeScreen> createState() => _HomeScreenState();
// // // // }

// // // // class _HomeScreenState extends State<HomeScreen> {
// // // //   // --- STATE VARIABLES ---
// // // //   String _statusMessage = "Please connect to 'FileShareHotspot'";
// // // //   bool _isConnectedToWifi = false;
// // // //   bool _isTransferring = false;
// // // //   double _progress = 0.0;
// // // //   List<String> _receivedFiles = [];

// // // //   // Services
// // // //   final Connectivity _connectivity = Connectivity();
// // // //   StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _requestPermissions();
// // // //     _checkInitialConnection();

// // // //     // Listen for WiFi changes
// // // //     _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
// // // //       results,
// // // //     ) {
// // // //       // connectivity_plus v6 returns a List
// // // //       _updateConnectionStatus(results.first);
// // // //     });
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _connectivitySubscription?.cancel();
// // // //     super.dispose();
// // // //   }

// // // //   // --- 1. PERMISSIONS & WIFI CHECKS ---
// // // //   Future<void> _requestPermissions() async {
// // // //     if (Platform.isAndroid) {
// // // //       // 1. Storage Permission (Android 11+ needs Manage External Storage)
// // // //       if (await Permission.manageExternalStorage.request().isGranted) {
// // // //         debugPrint("Manage External Storage Granted");
// // // //       }

// // // //       // 2. Local Network Permissions
// // // //       await [
// // // //         Permission.location, // Critical for getting WiFi SSID
// // // //         Permission.nearbyWifiDevices, // Critical for Android 13+
// // // //         Permission.storage,
// // // //       ].request();
// // // //     }
// // // //   }

// // // //   void _checkInitialConnection() async {
// // // //     var result = await _connectivity.checkConnectivity();
// // // //     _updateConnectionStatus(result.first);
// // // //   }

// // // //   void _updateConnectionStatus(ConnectivityResult result) async {
// // // //     bool hasWifi = result == ConnectivityResult.wifi;

// // // //     // Only show popup if state CHANGED to connected
// // // //     if (hasWifi && !_isConnectedToWifi) {
// // // //       _showBottomNotification("WiFi Connected! Ready to Sync.");
// // // //     }

// // // //     setState(() {
// // // //       _isConnectedToWifi = hasWifi;
// // // //       _statusMessage = hasWifi
// // // //           ? "Connected to WiFi. Ready to receive."
// // // //           : "Please connect to 'FileShareHotspot'";
// // // //     });
// // // //   }

// // // //   void _showBottomNotification(String message, {bool isError = false}) {
// // // //     ScaffoldMessenger.of(context).clearSnackBars(); // Remove old snacks
// // // //     ScaffoldMessenger.of(context).showSnackBar(
// // // //       SnackBar(
// // // //         content: Row(
// // // //           children: [
// // // //             Icon(
// // // //               isError ? Icons.error_outline : Icons.wifi,
// // // //               color: Colors.white,
// // // //             ),
// // // //             const SizedBox(width: 10),
// // // //             Expanded(
// // // //               child: Text(
// // // //                 message,
// // // //                 style: const TextStyle(fontWeight: FontWeight.w500),
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //         backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B5E20),
// // // //         behavior: SnackBarBehavior.floating,
// // // //         margin: const EdgeInsets.all(20),
// // // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // //         duration: const Duration(seconds: 4),
// // // //       ),
// // // //     );
// // // //   }

// // // //   // --- 2. CORE TRANSFER LOGIC (Gateway First) ---
// // // //   Future<void> startSyncProcess() async {
// // // //     if (!_isConnectedToWifi) {
// // // //       _showBottomNotification(
// // // //         "No WiFi Connection! Check Settings.",
// // // //         isError: true,
// // // //       );
// // // //       return;
// // // //     }

// // // //     setState(() {
// // // //       _isTransferring = true;
// // // //       _progress = 0.1;
// // // //       _statusMessage = "Locating Server...";
// // // //     });

// // // //     try {
// // // //       // STRATEGY: Try Gateway IP first (Best for Hotspots), fallback to UDP.
// // // //       final info = NetworkInfo();
// // // //       var wifiIP = await info.getWifiIP();
// // // //       var gatewayIp = await info.getWifiGatewayIP();

// // // //       // Logic: If gateway is valid, use it. Else default to 10.42.0.1 (Linux Hotspot Default)
// // // //       String targetIp = (gatewayIp != null && gatewayIp != "0.0.0.0")
// // // //           ? gatewayIp
// // // //           : "10.42.0.1";

// // // //       debugPrint("My IP: $wifiIP | Target Gateway: $targetIp");

// // // //       setState(() {
// // // //         _statusMessage = "Connecting to $targetIp...";
// // // //         _progress = 0.2;
// // // //       });

// // // //       // Start Transfer
// // // //       await _receiveFiles(targetIp, TCP_PORT, wifiIP);
// // // //     } catch (e) {
// // // //       setState(() {
// // // //         _statusMessage = "Connection Failed";
// // // //         _isTransferring = false;
// // // //         _progress = 0.0;
// // // //       });
// // // //       // Show clean error message
// // // //       String errorMsg = e.toString().contains("Connection timed out")
// // // //           ? "Connection Timed Out. Check Firewall on Pi."
// // // //           : e.toString().split(':')[1]; // Simple error text

// // // //       _showBottomNotification("Error: $errorMsg", isError: true);
// // // //       debugPrint("Sync Error: $e");
// // // //     }
// // // //   }

// // // //   Future<void> _receiveFiles(String ip, int port, String? sourceIP) async {
// // // //     Socket? socket;
// // // //     int retryCount = 0;

// // // //     // RETRY LOOP (Fixes "Could not connect TCP")
// // // //     while (socket == null && retryCount < 3) {
// // // //       try {
// // // //         debugPrint("Attempt ${retryCount + 1}: Connecting to $ip:$port...");

// // // //         // CRITICAL: We bind to sourceAddress to force Android to use the WiFi interface
// // // //         // even if it says "No Internet".
// // // //         socket = await Socket.connect(
// // // //           ip,
// // // //           port,
// // // //           sourceAddress: sourceIP,
// // // //           timeout: const Duration(seconds: 5),
// // // //         );
// // // //       } catch (e) {
// // // //         retryCount++;
// // // //         if (retryCount >= 3)
// // // //           throw Exception("Could not connect to $ip after 3 attempts.");
// // // //         await Future.delayed(const Duration(seconds: 1));
// // // //       }
// // // //     }

// // // //     try {
// // // //       // 1. Auth Handshake
// // // //       socket!.add(utf8.encode(SECRET_KEY));
// // // //       await socket.flush();

// // // //       StreamIterator<Uint8List> reader = StreamIterator(socket);

// // // //       // 2. Wait for OK
// // // //       if (!await _readUntil(reader, "OK"))
// // // //         throw Exception("Auth Failed: Server rejected key");

// // // //       // 3. Get Header (NUM_FILES|X)
// // // //       String header = await _readHeader(reader);
// // // //       socket.add(utf8.encode("OK")); // ACK Header
// // // //       await socket.flush();

// // // //       if (header.startsWith("NUM_FILES")) {
// // // //         int count = int.parse(header.split("|")[1]);
// // // //         for (int i = 0; i < count; i++) {
// // // //           setState(() {
// // // //             _statusMessage = "Downloading file ${i + 1}/$count...";
// // // //             _progress = (i + 1) / (count + 1);
// // // //           });
// // // //           await _downloadSingleFile(reader, socket);
// // // //           socket.add(utf8.encode("OK")); // ACK File
// // // //           await socket.flush();
// // // //         }
// // // //       }

// // // //       setState(() {
// // // //         _isTransferring = false;
// // // //         _statusMessage = "Transfer Complete!";
// // // //         _progress = 1.0;
// // // //       });
// // // //       _showBottomNotification("Files Received Successfully!");
// // // //     } catch (e) {
// // // //       rethrow;
// // // //     } finally {
// // // //       socket?.destroy();
// // // //     }
// // // //   }

// // // //   Future<void> _downloadSingleFile(
// // // //     StreamIterator<Uint8List> reader,
// // // //     Socket socket,
// // // //   ) async {
// // // //     // Read: filename|size
// // // //     String header = await _readHeader(reader);
// // // //     var parts = header.split("|");
// // // //     String filename = parts[0];
// // // //     int filesize = int.parse(parts[1]);

// // // //     debugPrint("Receiving $filename ($filesize bytes)");

// // // //     socket.add(utf8.encode("OK")); // Ready for data
// // // //     await socket.flush();

// // // //     // Prepare File Path
// // // //     Directory? dir;
// // // //     if (Platform.isAndroid) {
// // // //       dir = await getExternalStorageDirectory(); // Android/data/com.app/files
// // // //     } else {
// // // //       dir = await getApplicationDocumentsDirectory();
// // // //     }

// // // //     String savePath = "${dir!.path}/$filename";
// // // //     File file = File(savePath);
// // // //     IOSink sink = file.openWrite();

// // // //     int received = 0;
// // // //     while (received < filesize) {
// // // //       if (await reader.moveNext()) {
// // // //         Uint8List chunk = reader.current;
// // // //         int remaining = filesize - received;

// // // //         if (chunk.length > remaining) {
// // // //           sink.add(chunk.sublist(0, remaining));
// // // //           received += remaining;
// // // //         } else {
// // // //           sink.add(chunk);
// // // //           received += chunk.length;
// // // //         }
// // // //       }
// // // //     }
// // // //     await sink.close();
// // // //     debugPrint("File Saved: $savePath");

// // // //     setState(() {
// // // //       _receivedFiles.insert(0, savePath); // Add to top of list
// // // //     });
// // // //   }

// // // //   // --- STREAM HELPERS ---
// // // //   Future<bool> _readUntil(
// // // //     StreamIterator<Uint8List> reader,
// // // //     String target,
// // // //   ) async {
// // // //     if (await reader.moveNext()) {
// // // //       return utf8.decode(reader.current).contains(target);
// // // //     }
// // // //     return false;
// // // //   }

// // // //   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
// // // //     if (await reader.moveNext()) {
// // // //       return utf8.decode(reader.current);
// // // //     }
// // // //     throw Exception("Connection closed unexpected");
// // // //   }

// // // //   // --- 3. UI COMPONENTS ---

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     // Define Colors based on screenshots
// // // //     final Color cardBgColor = const Color(
// // // //       0xFF1A1F30,
// // // //     ); // Dark Blue/Black from screenshot
// // // //     final Color btnColor = const Color(
// // // //       0xFFC8F000,
// // // //     ); // Neon Lime Green from screenshot

// // // //     return Scaffold(
// // // //       // --- APP BAR ---
// // // //       appBar: AppBar(
// // // //         backgroundColor: const Color(0xFFF4F7F6),
// // // //         elevation: 0,
// // // //         leading: Builder(
// // // //           builder: (context) {
// // // //             return IconButton(
// // // //               icon: const Icon(
// // // //                 Icons.menu_rounded,
// // // //                 color: Colors.black,
// // // //                 size: 32,
// // // //               ),
// // // //               onPressed: () => Scaffold.of(context).openDrawer(),
// // // //             );
// // // //           },
// // // //         ),
// // // //         actions: [
// // // //           Container(
// // // //             margin: const EdgeInsets.only(right: 20),
// // // //             padding: const EdgeInsets.all(2),
// // // //             decoration: BoxDecoration(
// // // //               shape: BoxShape.circle,
// // // //               border: Border.all(color: const Color(0xFF2E7D32), width: 2),
// // // //             ),
// // // //             child: const CircleAvatar(
// // // //               radius: 16,
// // // //               backgroundColor: Colors.white,
// // // //               child: Icon(Icons.person, size: 24, color: Color(0xFF2E7D32)),
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),

// // // //       // --- DRAWER MENU ---
// // // //       drawer: _buildDrawer(),

// // // //       // --- BODY ---
// // // //       body: Padding(
// // // //         padding: const EdgeInsets.all(24.0),
// // // //         child: Column(
// // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // //           children: [
// // // //             // Welcome Text
// // // //             FadeInDown(
// // // //               child: Text(
// // // //                 "Welcome Back,",
// // // //                 style: GoogleFonts.poppins(
// // // //                   fontSize: 16,
// // // //                   color: Colors.grey[600],
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //             FadeInDown(
// // // //               delay: const Duration(milliseconds: 100),
// // // //               child: Text(
// // // //                 "Agri-Manager",
// // // //                 style: GoogleFonts.poppins(
// // // //                   fontSize: 32,
// // // //                   fontWeight: FontWeight.bold,
// // // //                   color: const Color(0xFF191825),
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //             const SizedBox(height: 30),

// // // //             // --- STATUS CARD (Matches Screenshot) ---
// // // //             FadeInUp(
// // // //               delay: const Duration(milliseconds: 200),
// // // //               child: Container(
// // // //                 width: double.infinity,
// // // //                 padding: const EdgeInsets.all(25),
// // // //                 decoration: BoxDecoration(
// // // //                   color: cardBgColor, // Dark card
// // // //                   borderRadius: BorderRadius.circular(24),
// // // //                   boxShadow: [
// // // //                     BoxShadow(
// // // //                       color: Colors.black.withOpacity(0.2),
// // // //                       blurRadius: 15,
// // // //                       offset: const Offset(0, 8),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //                 child: Column(
// // // //                   children: [
// // // //                     // Header Row
// // // //                     Row(
// // // //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                       children: [
// // // //                         Text(
// // // //                           "System Status",
// // // //                           style: GoogleFonts.poppins(
// // // //                             color: Colors.grey[400],
// // // //                             fontSize: 14,
// // // //                           ),
// // // //                         ),
// // // //                         Icon(
// // // //                           _isConnectedToWifi ? Icons.wifi : Icons.wifi_off,
// // // //                           color: _isConnectedToWifi
// // // //                               ? Colors.greenAccent
// // // //                               : Colors.redAccent,
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                     const SizedBox(height: 20),

// // // //                     // Status Text
// // // //                     Text(
// // // //                       _statusMessage,
// // // //                       style: GoogleFonts.poppins(
// // // //                         color: Colors.white,
// // // //                         fontSize: 16,
// // // //                         fontWeight: FontWeight.w500,
// // // //                       ),
// // // //                       textAlign: TextAlign.center,
// // // //                     ),
// // // //                     const SizedBox(height: 25),

// // // //                     // Action Button or Loader
// // // //                     if (_isTransferring)
// // // //                       Column(
// // // //                         children: [
// // // //                           LinearProgressIndicator(
// // // //                             value: _progress,
// // // //                             backgroundColor: Colors.white10,
// // // //                             color: btnColor,
// // // //                           ),
// // // //                           const SizedBox(height: 10),
// // // //                           Text(
// // // //                             "${(_progress * 100).toInt()}%",
// // // //                             style: const TextStyle(color: Colors.white70),
// // // //                           ),
// // // //                         ],
// // // //                       )
// // // //                     else
// // // //                       SizedBox(
// // // //                         width: double.infinity,
// // // //                         height: 50,
// // // //                         child: ElevatedButton.icon(
// // // //                           onPressed: startSyncProcess,
// // // //                           icon: const Icon(
// // // //                             Icons.sync_outlined,
// // // //                             color: Colors.black,
// // // //                           ),
// // // //                           label: Text(
// // // //                             "Receive Data",
// // // //                             style: GoogleFonts.poppins(
// // // //                               fontWeight: FontWeight.w600,
// // // //                               fontSize: 16,
// // // //                             ),
// // // //                           ),
// // // //                           style: ElevatedButton.styleFrom(
// // // //                             backgroundColor: btnColor,
// // // //                             foregroundColor: Colors.black,
// // // //                             shape: RoundedRectangleBorder(
// // // //                               borderRadius: BorderRadius.circular(12),
// // // //                             ),
// // // //                             elevation: 0,
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //             ),

// // // //             const SizedBox(height: 40),
// // // //             Text(
// // // //               "Recent Received Files",
// // // //               style: GoogleFonts.poppins(
// // // //                 fontSize: 18,
// // // //                 fontWeight: FontWeight.bold,
// // // //               ),
// // // //             ),
// // // //             const SizedBox(height: 15),

// // // //             // --- FILE LIST ---
// // // //             Expanded(
// // // //               child: _receivedFiles.isEmpty
// // // //                   ? Center(
// // // //                       child: Column(
// // // //                         mainAxisAlignment: MainAxisAlignment.center,
// // // //                         children: [
// // // //                           Icon(
// // // //                             Icons.folder_outlined,
// // // //                             size: 60,
// // // //                             color: Colors.grey[300],
// // // //                           ),
// // // //                           const SizedBox(height: 15),
// // // //                           Text(
// // // //                             "No files received yet",
// // // //                             style: TextStyle(color: Colors.grey[400]),
// // // //                           ),
// // // //                         ],
// // // //                       ),
// // // //                     )
// // // //                   : ListView.builder(
// // // //                       itemCount: _receivedFiles.length,
// // // //                       itemBuilder: (context, index) {
// // // //                         String path = _receivedFiles[index];
// // // //                         String name = path.split('/').last;
// // // //                         return FadeInUp(
// // // //                           duration: const Duration(milliseconds: 300),
// // // //                           child: Card(
// // // //                             elevation: 0,
// // // //                             color: Colors.white,
// // // //                             margin: const EdgeInsets.only(bottom: 12),
// // // //                             shape: RoundedRectangleBorder(
// // // //                               borderRadius: BorderRadius.circular(16),
// // // //                             ),
// // // //                             child: ListTile(
// // // //                               contentPadding: const EdgeInsets.symmetric(
// // // //                                 horizontal: 20,
// // // //                                 vertical: 8,
// // // //                               ),
// // // //                               leading: Container(
// // // //                                 padding: const EdgeInsets.all(10),
// // // //                                 decoration: BoxDecoration(
// // // //                                   color: const Color(
// // // //                                     0xFFF0FDF4,
// // // //                                   ), // Light Green bg
// // // //                                   borderRadius: BorderRadius.circular(10),
// // // //                                 ),
// // // //                                 child: const Icon(
// // // //                                   Icons.folder_zip,
// // // //                                   color: Color(0xFF2E7D32),
// // // //                                 ),
// // // //                               ),
// // // //                               title: Text(
// // // //                                 name,
// // // //                                 style: const TextStyle(
// // // //                                   fontWeight: FontWeight.w600,
// // // //                                 ),
// // // //                               ),
// // // //                               subtitle: Text(
// // // //                                 "Tap to open",
// // // //                                 style: TextStyle(
// // // //                                   fontSize: 12,
// // // //                                   color: Colors.grey[500],
// // // //                                 ),
// // // //                               ),
// // // //                               onTap: () => OpenFile.open(path),
// // // //                               trailing: const Icon(
// // // //                                 Icons.chevron_right,
// // // //                                 color: Colors.grey,
// // // //                               ),
// // // //                             ),
// // // //                           ),
// // // //                         );
// // // //                       },
// // // //                     ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   // --- DRAWER (Matches Screenshot) ---
// // // //   Widget _buildDrawer() {
// // // //     return Drawer(
// // // //       backgroundColor: Colors.white,
// // // //       child: Column(
// // // //         children: [
// // // //           UserAccountsDrawerHeader(
// // // //             decoration: const BoxDecoration(
// // // //               color: Color(0xFF191825),
// // // //             ), // Dark Header
// // // //             accountName: Text(
// // // //               "Admin User",
// // // //               style: GoogleFonts.poppins(
// // // //                 fontWeight: FontWeight.bold,
// // // //                 fontSize: 16,
// // // //               ),
// // // //             ),
// // // //             accountEmail: Text(
// // // //               "admin@itc.project",
// // // //               style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
// // // //             ),
// // // //             currentAccountPicture: const CircleAvatar(
// // // //               backgroundColor: Colors.white,
// // // //               child: Icon(Icons.person, size: 40, color: Color(0xFF191825)),
// // // //             ),
// // // //           ),
// // // //           const SizedBox(height: 10),
// // // //           _drawerItem(Icons.folder_outlined, "My Files", () {}),
// // // //           _drawerItem(Icons.settings_outlined, "Settings", () {}),
// // // //           _drawerItem(Icons.info_outline, "About", () {}),
// // // //           const Spacer(),
// // // //           const Divider(),
// // // //           _drawerItem(Icons.logout, "Logout", () {}, isDestructive: true),
// // // //           const SizedBox(height: 20),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _drawerItem(
// // // //     IconData icon,
// // // //     String title,
// // // //     VoidCallback onTap, {
// // // //     bool isDestructive = false,
// // // //   }) {
// // // //     return ListTile(
// // // //       leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey[800]),
// // // //       title: Text(
// // // //         title,
// // // //         style: GoogleFonts.poppins(
// // // //           color: isDestructive ? Colors.red : Colors.black87,
// // // //           fontWeight: FontWeight.w500,
// // // //         ),
// // // //       ),
// // // //       onTap: () {
// // // //         Navigator.pop(context);
// // // //         onTap();
// // // //       },
// // // //     );
// // // //   }
// // // // }

// // // import 'dart:async';
// // // import 'dart:convert';
// // // import 'dart:io';
// // // import 'dart:typed_data';

// // // import 'package:connectivity_plus/connectivity_plus.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:google_fonts/google_fonts.dart';
// // // import 'package:network_info_plus/network_info_plus.dart';
// // // import 'package:open_file/open_file.dart';
// // // import 'package:path_provider/path_provider.dart';
// // // import 'package:permission_handler/permission_handler.dart';
// // // import 'package:animate_do/animate_do.dart';

// // // // --- CONFIGURATION ---
// // // const String SECRET_KEY = "securekey";
// // // const int TCP_PORT = 5001;
// // // const int DISCOVERY_PORT = 5000;

// // // void main() {
// // //   runApp(const MyApp());
// // // }

// // // class MyApp extends StatelessWidget {
// // //   const MyApp({super.key});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return MaterialApp(
// // //       debugShowCheckedModeBanner: false,
// // //       title: 'AgriSync',
// // //       theme: ThemeData(
// // //         useMaterial3: true,
// // //         scaffoldBackgroundColor: const Color(0xFFF4F7F6), // Light Grey Bg
// // //         primaryColor: const Color(0xFF2E7D32), // Agri Green
// // //         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
// // //         textTheme: GoogleFonts.poppinsTextTheme(),
// // //       ),
// // //       home: const HomeScreen(),
// // //     );
// // //   }
// // // }

// // // class HomeScreen extends StatefulWidget {
// // //   const HomeScreen({super.key});

// // //   @override
// // //   State<HomeScreen> createState() => _HomeScreenState();
// // // }

// // // class _HomeScreenState extends State<HomeScreen> {
// // //   // --- STATE VARIABLES ---
// // //   String _statusMessage = "Please connect to 'FileShareHotspot'";
// // //   bool _isConnectedToWifi = false;
// // //   bool _isTransferring = false;
// // //   double _progress = 0.0;
// // //   List<String> _receivedFiles = [];

// // //   // Services
// // //   final Connectivity _connectivity = Connectivity();
// // //   // FIXED: Changed type to match older package version
// // //   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _requestPermissions();
// // //     _checkInitialConnection();

// // //     // FIXED: Removed List handling for compatibility
// // //     _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
// // //       result,
// // //     ) {
// // //       _updateConnectionStatus(result);
// // //     });
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _connectivitySubscription?.cancel();
// // //     super.dispose();
// // //   }

// // //   // --- 1. PERMISSIONS & WIFI CHECKS ---
// // //   Future<void> _requestPermissions() async {
// // //     if (Platform.isAndroid) {
// // //       if (await Permission.manageExternalStorage.request().isGranted) {
// // //         debugPrint("Manage External Storage Granted");
// // //       }

// // //       await [
// // //         Permission.location,
// // //         Permission.nearbyWifiDevices,
// // //         Permission.storage,
// // //       ].request();
// // //     }
// // //   }

// // //   void _checkInitialConnection() async {
// // //     // FIXED: Removed .first accessor
// // //     var result = await _connectivity.checkConnectivity();
// // //     _updateConnectionStatus(result);
// // //   }

// // //   void _updateConnectionStatus(ConnectivityResult result) async {
// // //     bool hasWifi = result == ConnectivityResult.wifi;

// // //     if (hasWifi && !_isConnectedToWifi) {
// // //       _showBottomNotification("WiFi Connected! Ready to Sync.");
// // //     }

// // //     setState(() {
// // //       _isConnectedToWifi = hasWifi;
// // //       _statusMessage = hasWifi
// // //           ? "Connected to WiFi. Ready to receive."
// // //           : "Please connect to 'FileShareHotspot'";
// // //     });
// // //   }

// // //   void _showBottomNotification(String message, {bool isError = false}) {
// // //     ScaffoldMessenger.of(context).clearSnackBars();
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Row(
// // //           children: [
// // //             Icon(
// // //               isError ? Icons.error_outline : Icons.wifi,
// // //               color: Colors.white,
// // //             ),
// // //             const SizedBox(width: 10),
// // //             Expanded(
// // //               child: Text(
// // //                 message,
// // //                 style: const TextStyle(fontWeight: FontWeight.w500),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //         backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B5E20),
// // //         behavior: SnackBarBehavior.floating,
// // //         margin: const EdgeInsets.all(20),
// // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // //         duration: const Duration(seconds: 4),
// // //       ),
// // //     );
// // //   }

// // //   // --- 2. CORE TRANSFER LOGIC ---
// // //   Future<void> startSyncProcess() async {
// // //     if (!_isConnectedToWifi) {
// // //       _showBottomNotification(
// // //         "No WiFi Connection! Check Settings.",
// // //         isError: true,
// // //       );
// // //       return;
// // //     }

// // //     setState(() {
// // //       _isTransferring = true;
// // //       _progress = 0.1;
// // //       _statusMessage = "Locating Server...";
// // //     });

// // //     try {
// // //       final info = NetworkInfo();
// // //       var wifiIP = await info.getWifiIP();
// // //       var gatewayIp = await info.getWifiGatewayIP();

// // //       String targetIp = (gatewayIp != null && gatewayIp != "0.0.0.0")
// // //           ? gatewayIp
// // //           : "10.42.0.1";

// // //       debugPrint("My IP: $wifiIP | Target Gateway: $targetIp");

// // //       setState(() {
// // //         _statusMessage = "Connecting to $targetIp...";
// // //         _progress = 0.2;
// // //       });

// // //       await _receiveFiles(targetIp, TCP_PORT, wifiIP);
// // //     } catch (e) {
// // //       setState(() {
// // //         _statusMessage = "Connection Failed";
// // //         _isTransferring = false;
// // //         _progress = 0.0;
// // //       });
// // //       String errorMsg = e.toString().contains("Connection timed out")
// // //           ? "Connection Timed Out. Check Firewall on Pi."
// // //           : e.toString().split(':')[1];

// // //       _showBottomNotification("Error: $errorMsg", isError: true);
// // //       debugPrint("Sync Error: $e");
// // //     }
// // //   }

// // //   Future<void> _receiveFiles(String ip, int port, String? sourceIP) async {
// // //     Socket? socket;
// // //     int retryCount = 0;

// // //     // RETRY LOOP
// // //     while (socket == null && retryCount < 3) {
// // //       try {
// // //         debugPrint("Attempt ${retryCount + 1}: Connecting to $ip:$port...");
// // //         socket = await Socket.connect(
// // //           ip,
// // //           port,
// // //           sourceAddress: sourceIP,
// // //           timeout: const Duration(seconds: 5),
// // //         );
// // //       } catch (e) {
// // //         retryCount++;
// // //         if (retryCount >= 3)
// // //           throw Exception("Could not connect to $ip after 3 attempts.");
// // //         await Future.delayed(const Duration(seconds: 1));
// // //       }
// // //     }

// // //     try {
// // //       // 1. Auth Handshake
// // //       debugPrint("Connected. Sending Key...");
// // //       socket!.add(utf8.encode(SECRET_KEY));
// // //       await socket.flush();

// // //       StreamIterator<Uint8List> reader = StreamIterator(socket);

// // //       // 2. Wait for OK (Auth Success)
// // //       if (!await _readUntil(reader, "OK"))
// // //         throw Exception("Auth Failed: Server rejected key");
// // //       debugPrint("Auth Validated.");

// // //       // 3. Get Header (NUM_FILES|1)
// // //       String header = await _readHeader(reader);
// // //       debugPrint("Header Received: $header");

// // //       // ACK Header
// // //       socket.add(utf8.encode("OK"));
// // //       await socket.flush();

// // //       if (header.startsWith("NUM_FILES")) {
// // //         int count = int.parse(header.split("|")[1]);
// // //         for (int i = 0; i < count; i++) {
// // //           setState(() {
// // //             _statusMessage = "Downloading file ${i + 1}/$count...";
// // //             _progress = (i + 1) / (count + 1);
// // //           });
// // //           await _downloadSingleFile(reader, socket);
// // //         }
// // //       }

// // //       setState(() {
// // //         _isTransferring = false;
// // //         _statusMessage = "Transfer Complete!";
// // //         _progress = 1.0;
// // //       });
// // //       _showBottomNotification("Files Received Successfully!");
// // //     } catch (e) {
// // //       debugPrint("Protocol Error: $e");
// // //       rethrow;
// // //     } finally {
// // //       socket?.destroy();
// // //     }
// // //   }

// // //   Future<void> _downloadSingleFile(
// // //     StreamIterator<Uint8List> reader,
// // //     Socket socket,
// // //   ) async {
// // //     // 1. Read File Info: filename.zip|12345
// // //     String header = await _readHeader(reader);
// // //     var parts = header.split("|");
// // //     String filename = parts[0];
// // //     int filesize = int.parse(parts[1]);

// // //     debugPrint("Receiving $filename ($filesize bytes)");

// // //     // 2. Send OK to start the stream
// // //     socket.add(utf8.encode("OK"));
// // //     await socket.flush();

// // //     // 3. Prepare File Path
// // //     Directory? dir;
// // //     if (Platform.isAndroid) {
// // //       dir = await getExternalStorageDirectory();
// // //     } else {
// // //       dir = await getApplicationDocumentsDirectory();
// // //     }

// // //     String savePath = "${dir!.path}/$filename";
// // //     File file = File(savePath);
// // //     IOSink sink = file.openWrite();

// // //     // 4. Stream Data
// // //     int received = 0;
// // //     while (received < filesize) {
// // //       if (await reader.moveNext()) {
// // //         Uint8List chunk = reader.current;
// // //         int remaining = filesize - received;

// // //         if (chunk.length > remaining) {
// // //           sink.add(chunk.sublist(0, remaining));
// // //           received += remaining;
// // //         } else {
// // //           sink.add(chunk);
// // //           received += chunk.length;
// // //         }
// // //       } else {
// // //         break; // Stream ended prematurely
// // //       }
// // //     }
// // //     await sink.close();
// // //     debugPrint("File Saved: $savePath");

// // //     setState(() {
// // //       _receivedFiles.insert(0, savePath);
// // //     });
// // //   }

// // //   // --- STREAM HELPERS ---
// // //   Future<bool> _readUntil(
// // //     StreamIterator<Uint8List> reader,
// // //     String target,
// // //   ) async {
// // //     if (await reader.moveNext()) {
// // //       return utf8.decode(reader.current).contains(target);
// // //     }
// // //     return false;
// // //   }

// // //   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
// // //     if (await reader.moveNext()) {
// // //       return utf8.decode(reader.current);
// // //     }
// // //     throw Exception("Connection closed unexpected");
// // //   }

// // //   // --- 3. UI COMPONENTS ---

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final Color cardBgColor = const Color(0xFF1A1F30);
// // //     final Color btnColor = const Color(0xFFC8F000);

// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         backgroundColor: const Color(0xFFF4F7F6),
// // //         elevation: 0,
// // //         leading: Builder(
// // //           builder: (context) {
// // //             return IconButton(
// // //               icon: const Icon(
// // //                 Icons.menu_rounded,
// // //                 color: Colors.black,
// // //                 size: 32,
// // //               ),
// // //               onPressed: () => Scaffold.of(context).openDrawer(),
// // //             );
// // //           },
// // //         ),
// // //         actions: [
// // //           Container(
// // //             margin: const EdgeInsets.only(right: 20),
// // //             padding: const EdgeInsets.all(2),
// // //             decoration: BoxDecoration(
// // //               shape: BoxShape.circle,
// // //               border: Border.all(color: const Color(0xFF2E7D32), width: 2),
// // //             ),
// // //             child: const CircleAvatar(
// // //               radius: 16,
// // //               backgroundColor: Colors.white,
// // //               child: Icon(Icons.person, size: 24, color: Color(0xFF2E7D32)),
// // //             ),
// // //           ),
// // //         ],
// // //       ),

// // //       drawer: _buildDrawer(),

// // //       body: Padding(
// // //         padding: const EdgeInsets.all(24.0),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             FadeInDown(
// // //               child: Text(
// // //                 "Welcome Back,",
// // //                 style: GoogleFonts.poppins(
// // //                   fontSize: 16,
// // //                   color: Colors.grey[600],
// // //                 ),
// // //               ),
// // //             ),
// // //             FadeInDown(
// // //               delay: const Duration(milliseconds: 100),
// // //               child: Text(
// // //                 "Agri-Manager",
// // //                 style: GoogleFonts.poppins(
// // //                   fontSize: 32,
// // //                   fontWeight: FontWeight.bold,
// // //                   color: const Color(0xFF191825),
// // //                 ),
// // //               ),
// // //             ),
// // //             const SizedBox(height: 30),

// // //             FadeInUp(
// // //               delay: const Duration(milliseconds: 200),
// // //               child: Container(
// // //                 width: double.infinity,
// // //                 padding: const EdgeInsets.all(25),
// // //                 decoration: BoxDecoration(
// // //                   color: cardBgColor,
// // //                   borderRadius: BorderRadius.circular(24),
// // //                   boxShadow: [
// // //                     BoxShadow(
// // //                       color: Colors.black.withOpacity(0.2),
// // //                       blurRadius: 15,
// // //                       offset: const Offset(0, 8),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 child: Column(
// // //                   children: [
// // //                     Row(
// // //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                       children: [
// // //                         Text(
// // //                           "System Status",
// // //                           style: GoogleFonts.poppins(
// // //                             color: Colors.grey[400],
// // //                             fontSize: 14,
// // //                           ),
// // //                         ),
// // //                         Icon(
// // //                           _isConnectedToWifi ? Icons.wifi : Icons.wifi_off,
// // //                           color: _isConnectedToWifi
// // //                               ? Colors.greenAccent
// // //                               : Colors.redAccent,
// // //                         ),
// // //                       ],
// // //                     ),
// // //                     const SizedBox(height: 20),

// // //                     Text(
// // //                       _statusMessage,
// // //                       style: GoogleFonts.poppins(
// // //                         color: Colors.white,
// // //                         fontSize: 16,
// // //                         fontWeight: FontWeight.w500,
// // //                       ),
// // //                       textAlign: TextAlign.center,
// // //                     ),
// // //                     const SizedBox(height: 25),

// // //                     if (_isTransferring)
// // //                       Column(
// // //                         children: [
// // //                           LinearProgressIndicator(
// // //                             value: _progress,
// // //                             backgroundColor: Colors.white10,
// // //                             color: btnColor,
// // //                           ),
// // //                           const SizedBox(height: 10),
// // //                           Text(
// // //                             "${(_progress * 100).toInt()}%",
// // //                             style: const TextStyle(color: Colors.white70),
// // //                           ),
// // //                         ],
// // //                       )
// // //                     else
// // //                       SizedBox(
// // //                         width: double.infinity,
// // //                         height: 50,
// // //                         child: ElevatedButton.icon(
// // //                           onPressed: startSyncProcess,
// // //                           icon: const Icon(
// // //                             Icons.sync_outlined,
// // //                             color: Colors.black,
// // //                           ),
// // //                           label: Text(
// // //                             "Receive Data",
// // //                             style: GoogleFonts.poppins(
// // //                               fontWeight: FontWeight.w600,
// // //                               fontSize: 16,
// // //                             ),
// // //                           ),
// // //                           style: ElevatedButton.styleFrom(
// // //                             backgroundColor: btnColor,
// // //                             foregroundColor: Colors.black,
// // //                             shape: RoundedRectangleBorder(
// // //                               borderRadius: BorderRadius.circular(12),
// // //                             ),
// // //                             elevation: 0,
// // //                           ),
// // //                         ),
// // //                       ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),

// // //             const SizedBox(height: 40),
// // //             Text(
// // //               "Recent Received Files",
// // //               style: GoogleFonts.poppins(
// // //                 fontSize: 18,
// // //                 fontWeight: FontWeight.bold,
// // //               ),
// // //             ),
// // //             const SizedBox(height: 15),

// // //             Expanded(
// // //               child: _receivedFiles.isEmpty
// // //                   ? Center(
// // //                       child: Column(
// // //                         mainAxisAlignment: MainAxisAlignment.center,
// // //                         children: [
// // //                           Icon(
// // //                             Icons.folder_outlined,
// // //                             size: 60,
// // //                             color: Colors.grey[300],
// // //                           ),
// // //                           const SizedBox(height: 15),
// // //                           Text(
// // //                             "No files received yet",
// // //                             style: TextStyle(color: Colors.grey[400]),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                     )
// // //                   : ListView.builder(
// // //                       itemCount: _receivedFiles.length,
// // //                       itemBuilder: (context, index) {
// // //                         String path = _receivedFiles[index];
// // //                         String name = path.split('/').last;
// // //                         return FadeInUp(
// // //                           duration: const Duration(milliseconds: 300),
// // //                           child: Card(
// // //                             elevation: 0,
// // //                             color: Colors.white,
// // //                             margin: const EdgeInsets.only(bottom: 12),
// // //                             shape: RoundedRectangleBorder(
// // //                               borderRadius: BorderRadius.circular(16),
// // //                             ),
// // //                             child: ListTile(
// // //                               contentPadding: const EdgeInsets.symmetric(
// // //                                 horizontal: 20,
// // //                                 vertical: 8,
// // //                               ),
// // //                               leading: Container(
// // //                                 padding: const EdgeInsets.all(10),
// // //                                 decoration: BoxDecoration(
// // //                                   color: const Color(0xFFF0FDF4),
// // //                                   borderRadius: BorderRadius.circular(10),
// // //                                 ),
// // //                                 child: const Icon(
// // //                                   Icons.folder_zip,
// // //                                   color: Color(0xFF2E7D32),
// // //                                 ),
// // //                               ),
// // //                               title: Text(
// // //                                 name,
// // //                                 style: const TextStyle(
// // //                                   fontWeight: FontWeight.w600,
// // //                                 ),
// // //                               ),
// // //                               subtitle: Text(
// // //                                 "Tap to open",
// // //                                 style: TextStyle(
// // //                                   fontSize: 12,
// // //                                   color: Colors.grey[500],
// // //                                 ),
// // //                               ),
// // //                               onTap: () => OpenFile.open(path),
// // //                               trailing: const Icon(
// // //                                 Icons.chevron_right,
// // //                                 color: Colors.grey,
// // //                               ),
// // //                             ),
// // //                           ),
// // //                         );
// // //                       },
// // //                     ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildDrawer() {
// // //     return Drawer(
// // //       backgroundColor: Colors.white,
// // //       child: Column(
// // //         children: [
// // //           UserAccountsDrawerHeader(
// // //             decoration: const BoxDecoration(color: Color(0xFF191825)),
// // //             accountName: Text(
// // //               "Admin User",
// // //               style: GoogleFonts.poppins(
// // //                 fontWeight: FontWeight.bold,
// // //                 fontSize: 16,
// // //               ),
// // //             ),
// // //             accountEmail: Text(
// // //               "admin@itc.project",
// // //               style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
// // //             ),
// // //             currentAccountPicture: const CircleAvatar(
// // //               backgroundColor: Colors.white,
// // //               child: Icon(Icons.person, size: 40, color: Color(0xFF191825)),
// // //             ),
// // //           ),
// // //           const SizedBox(height: 10),
// // //           _drawerItem(Icons.folder_outlined, "My Files", () {}),
// // //           _drawerItem(Icons.settings_outlined, "Settings", () {}),
// // //           _drawerItem(Icons.info_outline, "About", () {}),
// // //           const Spacer(),
// // //           const Divider(),
// // //           _drawerItem(Icons.logout, "Logout", () {}, isDestructive: true),
// // //           const SizedBox(height: 20),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _drawerItem(
// // //     IconData icon,
// // //     String title,
// // //     VoidCallback onTap, {
// // //     bool isDestructive = false,
// // //   }) {
// // //     return ListTile(
// // //       leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey[800]),
// // //       title: Text(
// // //         title,
// // //         style: GoogleFonts.poppins(
// // //           color: isDestructive ? Colors.red : Colors.black87,
// // //           fontWeight: FontWeight.w500,
// // //         ),
// // //       ),
// // //       onTap: () {
// // //         Navigator.pop(context);
// // //         onTap();
// // //       },
// // //     );
// // //   }
// // // }

// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:io';
// // import 'dart:typed_data';
// // import 'package:connectivity_plus/connectivity_plus.dart';
// // import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:network_info_plus/network_info_plus.dart';
// // import 'package:open_file/open_file.dart';
// // import 'package:path_provider/path_provider.dart';
// // import 'package:permission_handler/permission_handler.dart';
// // import 'package:animate_do/animate_do.dart';

// // // --- CONFIGURATION ---
// // const String SECRET_KEY = "securekey";
// // const int TCP_PORT = 5001;
// // const int DISCOVERY_PORT = 5000;

// // void main() {
// //   runApp(const MyApp());
// // }

// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       title: 'AgriSync',
// //       theme: ThemeData(
// //         useMaterial3: true,
// //         scaffoldBackgroundColor: const Color(0xFFF4F7F6), // Light Grey Bg
// //         primaryColor: const Color(0xFF2E7D32), // Agri Green
// //         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
// //         textTheme: GoogleFonts.poppinsTextTheme(),
// //       ),
// //       home: const HomeScreen(),
// //     );
// //   }
// // }

// // class HomeScreen extends StatefulWidget {
// //   const HomeScreen({super.key});

// //   @override
// //   State<HomeScreen> createState() => _HomeScreenState();
// // }

// // class _HomeScreenState extends State<HomeScreen> {
// //   // --- STATE VARIABLES ---
// //   String _statusMessage = "Please connect to 'FileShareHotspot'";
// //   bool _isConnectedToWifi = false;
// //   bool _isTransferring = false;
// //   double _progress = 0.0;
// //   List<String> _receivedFiles = [];

// //   // Services
// //   final Connectivity _connectivity = Connectivity();

// //   // FIXED: Removed <List<...>> to match your installed version
// //   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _requestPermissions();
// //     _checkInitialConnection();

// //     // FIXED: Removed .listen((results) ... results.first)
// //     // Now simply listens for a single result
// //     _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
// //       result,
// //     ) {
// //       _updateConnectionStatus(result);
// //     });
// //   }

// //   @override
// //   void dispose() {
// //     _connectivitySubscription?.cancel();
// //     super.dispose();
// //   }

// //   // --- 1. PERMISSIONS & WIFI CHECKS ---
// //   Future<void> _requestPermissions() async {
// //     if (Platform.isAndroid) {
// //       if (await Permission.manageExternalStorage.request().isGranted) {
// //         debugPrint("Manage External Storage Granted");
// //       }

// //       await [
// //         Permission.location,
// //         Permission.nearbyWifiDevices,
// //         Permission.storage,
// //       ].request();
// //     }
// //   }

// //   void _checkInitialConnection() async {
// //     var result = await _connectivity.checkConnectivity();
// //     // FIXED: Removed .first accessor
// //     _updateConnectionStatus(result);
// //   }

// //   void _updateConnectionStatus(ConnectivityResult result) async {
// //     bool hasWifi = result == ConnectivityResult.wifi;

// //     if (hasWifi && !_isConnectedToWifi) {
// //       _showBottomNotification("WiFi Connected! Ready to Sync.");
// //     }

// //     setState(() {
// //       _isConnectedToWifi = hasWifi;
// //       _statusMessage = hasWifi
// //           ? "Connected to WiFi. Ready to receive."
// //           : "Please connect to 'FileShareHotspot'";
// //     });
// //   }

// //   void _showBottomNotification(String message, {bool isError = false}) {
// //     ScaffoldMessenger.of(context).clearSnackBars();
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Row(
// //           children: [
// //             Icon(
// //               isError ? Icons.error_outline : Icons.wifi,
// //               color: Colors.white,
// //             ),
// //             const SizedBox(width: 10),
// //             Expanded(
// //               child: Text(
// //                 message,
// //                 style: const TextStyle(fontWeight: FontWeight.w500),
// //               ),
// //             ),
// //           ],
// //         ),
// //         backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B5E20),
// //         behavior: SnackBarBehavior.floating,
// //         margin: const EdgeInsets.all(20),
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //         duration: const Duration(seconds: 4),
// //       ),
// //     );
// //   }

// //   // --- 2. CORE TRANSFER LOGIC ---
// //   Future<void> startSyncProcess() async {
// //     if (!_isConnectedToWifi) {
// //       _showBottomNotification(
// //         "No WiFi Connection! Check Settings.",
// //         isError: true,
// //       );
// //       return;
// //     }

// //     setState(() {
// //       _isTransferring = true;
// //       _progress = 0.1;
// //       _statusMessage = "Locating Server...";
// //     });

// //     try {
// //       final info = NetworkInfo();
// //       var wifiIP = await info.getWifiIP();
// //       var gatewayIp = await info.getWifiGatewayIP();

// //       String targetIp = (gatewayIp != null && gatewayIp != "0.0.0.0")
// //           ? gatewayIp
// //           : "10.42.0.1";

// //       debugPrint("My IP: $wifiIP | Target Gateway: $targetIp");

// //       setState(() {
// //         _statusMessage = "Connecting to $targetIp...";
// //         _progress = 0.2;
// //       });

// //       await _receiveFiles(targetIp, TCP_PORT, wifiIP);
// //     } catch (e) {
// //       setState(() {
// //         _statusMessage = "Connection Failed";
// //         _isTransferring = false;
// //         _progress = 0.0;
// //       });
// //       String errorMsg = e.toString().contains("Connection timed out")
// //           ? "Connection Timed Out. Check Firewall on Pi."
// //           : e.toString().split(':')[1];

// //       _showBottomNotification("Error: $errorMsg", isError: true);
// //       debugPrint("Sync Error: $e");
// //     }
// //   }

// //   Future<void> _receiveFiles(String ip, int port, String? sourceIP) async {
// //     Socket? socket;
// //     int retryCount = 0;

// //     // RETRY LOOP
// //     while (socket == null && retryCount < 3) {
// //       try {
// //         debugPrint("Attempt ${retryCount + 1}: Connecting to $ip:$port...");
// //         socket = await Socket.connect(
// //           ip,
// //           port,
// //           sourceAddress: sourceIP,
// //           timeout: const Duration(seconds: 5),
// //         );
// //       } catch (e) {
// //         retryCount++;
// //         if (retryCount >= 3)
// //           throw Exception("Could not connect to $ip after 3 attempts.");
// //         await Future.delayed(const Duration(seconds: 1));
// //       }
// //     }

// //     try {
// //       // 1. Auth Handshake
// //       debugPrint("Connected. Sending Key...");
// //       socket!.add(utf8.encode(SECRET_KEY));
// //       await socket.flush();

// //       StreamIterator<Uint8List> reader = StreamIterator(socket);

// //       // 2. Wait for OK (Auth Success)
// //       if (!await _readUntil(reader, "OK"))
// //         throw Exception("Auth Failed: Server rejected key");
// //       debugPrint("Auth Validated.");

// //       // 3. Get Header (NUM_FILES|1)
// //       String header = await _readHeader(reader);
// //       debugPrint("Header Received: $header");

// //       // ACK Header
// //       socket.add(utf8.encode("OK"));
// //       await socket.flush();

// //       if (header.startsWith("NUM_FILES")) {
// //         int count = int.parse(header.split("|")[1]);
// //         for (int i = 0; i < count; i++) {
// //           setState(() {
// //             _statusMessage = "Downloading file ${i + 1}/$count...";
// //             _progress = (i + 1) / (count + 1);
// //           });
// //           await _downloadSingleFile(reader, socket);
// //         }
// //       }

// //       setState(() {
// //         _isTransferring = false;
// //         _statusMessage = "Transfer Complete!";
// //         _progress = 1.0;
// //       });
// //       _showBottomNotification("Files Received Successfully!");
// //     } catch (e) {
// //       debugPrint("Protocol Error: $e");
// //       rethrow;
// //     } finally {
// //       socket?.destroy();
// //     }
// //   }

// //   Future<void> _downloadSingleFile(
// //     StreamIterator<Uint8List> reader,
// //     Socket socket,
// //   ) async {
// //     // 1. Read File Info: filename.zip|12345
// //     String header = await _readHeader(reader);
// //     var parts = header.split("|");
// //     String filename = parts[0];
// //     int filesize = int.parse(parts[1]);

// //     debugPrint("Receiving $filename ($filesize bytes)");

// //     // 2. Send OK to start the stream
// //     socket.add(utf8.encode("OK"));
// //     await socket.flush();

// //     // 3. Prepare File Path
// //     Directory? dir;
// //     if (Platform.isAndroid) {
// //       dir = await getExternalStorageDirectory();
// //     } else {
// //       dir = await getApplicationDocumentsDirectory();
// //     }

// //     String savePath = "${dir!.path}/$filename";
// //     File file = File(savePath);
// //     IOSink sink = file.openWrite();

// //     // 4. Stream Data
// //     int received = 0;
// //     while (received < filesize) {
// //       if (await reader.moveNext()) {
// //         Uint8List chunk = reader.current;
// //         int remaining = filesize - received;

// //         if (chunk.length > remaining) {
// //           sink.add(chunk.sublist(0, remaining));
// //           received += remaining;
// //         } else {
// //           sink.add(chunk);
// //           received += chunk.length;
// //         }
// //       } else {
// //         break; // Stream ended prematurely
// //       }
// //     }
// //     await sink.close();
// //     debugPrint("File Saved: $savePath");

// //     setState(() {
// //       _receivedFiles.insert(0, savePath);
// //     });
// //   }

// //   // --- STREAM HELPERS ---
// //   Future<bool> _readUntil(
// //     StreamIterator<Uint8List> reader,
// //     String target,
// //   ) async {
// //     if (await reader.moveNext()) {
// //       return utf8.decode(reader.current).contains(target);
// //     }
// //     return false;
// //   }

// //   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
// //     if (await reader.moveNext()) {
// //       return utf8.decode(reader.current);
// //     }
// //     throw Exception("Connection closed unexpected");
// //   }

// //   // --- 3. UI COMPONENTS ---

// //   @override
// //   Widget build(BuildContext context) {
// //     final Color cardBgColor = const Color(0xFF1A1F30);
// //     final Color btnColor = const Color(0xFFC8F000);

// //     return Scaffold(
// //       appBar: AppBar(
// //         backgroundColor: const Color(0xFFF4F7F6),
// //         elevation: 0,
// //         leading: Builder(
// //           builder: (context) {
// //             return IconButton(
// //               icon: const Icon(
// //                 Icons.menu_rounded,
// //                 color: Colors.black,
// //                 size: 32,
// //               ),
// //               onPressed: () => Scaffold.of(context).openDrawer(),
// //             );
// //           },
// //         ),
// //         actions: [
// //           Container(
// //             margin: const EdgeInsets.only(right: 20),
// //             padding: const EdgeInsets.all(2),
// //             decoration: BoxDecoration(
// //               shape: BoxShape.circle,
// //               border: Border.all(color: const Color(0xFF2E7D32), width: 2),
// //             ),
// //             child: const CircleAvatar(
// //               radius: 16,
// //               backgroundColor: Colors.white,
// //               child: Icon(Icons.person, size: 24, color: Color(0xFF2E7D32)),
// //             ),
// //           ),
// //         ],
// //       ),

// //       drawer: _buildDrawer(),

// //       body: Padding(
// //         padding: const EdgeInsets.all(24.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             FadeInDown(
// //               child: Text(
// //                 "Welcome Back,",
// //                 style: GoogleFonts.poppins(
// //                   fontSize: 16,
// //                   color: Colors.grey[600],
// //                 ),
// //               ),
// //             ),
// //             FadeInDown(
// //               delay: const Duration(milliseconds: 100),
// //               child: Text(
// //                 "Agri-Manager",
// //                 style: GoogleFonts.poppins(
// //                   fontSize: 32,
// //                   fontWeight: FontWeight.bold,
// //                   color: const Color(0xFF191825),
// //                 ),
// //               ),
// //             ),
// //             const SizedBox(height: 30),

// //             FadeInUp(
// //               delay: const Duration(milliseconds: 200),
// //               child: Container(
// //                 width: double.infinity,
// //                 padding: const EdgeInsets.all(25),
// //                 decoration: BoxDecoration(
// //                   color: cardBgColor,
// //                   borderRadius: BorderRadius.circular(24),
// //                   boxShadow: [
// //                     BoxShadow(
// //                       color: Colors.black.withOpacity(0.2),
// //                       blurRadius: 15,
// //                       offset: const Offset(0, 8),
// //                     ),
// //                   ],
// //                 ),
// //                 child: Column(
// //                   children: [
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                       children: [
// //                         Text(
// //                           "System Status",
// //                           style: GoogleFonts.poppins(
// //                             color: Colors.grey[400],
// //                             fontSize: 14,
// //                           ),
// //                         ),
// //                         Icon(
// //                           _isConnectedToWifi ? Icons.wifi : Icons.wifi_off,
// //                           color: _isConnectedToWifi
// //                               ? Colors.greenAccent
// //                               : Colors.redAccent,
// //                         ),
// //                       ],
// //                     ),
// //                     const SizedBox(height: 20),

// //                     Text(
// //                       _statusMessage,
// //                       style: GoogleFonts.poppins(
// //                         color: Colors.white,
// //                         fontSize: 16,
// //                         fontWeight: FontWeight.w500,
// //                       ),
// //                       textAlign: TextAlign.center,
// //                     ),
// //                     const SizedBox(height: 25),

// //                     if (_isTransferring)
// //                       Column(
// //                         children: [
// //                           LinearProgressIndicator(
// //                             value: _progress,
// //                             backgroundColor: Colors.white10,
// //                             color: btnColor,
// //                           ),
// //                           const SizedBox(height: 10),
// //                           Text(
// //                             "${(_progress * 100).toInt()}%",
// //                             style: const TextStyle(color: Colors.white70),
// //                           ),
// //                         ],
// //                       )
// //                     else
// //                       SizedBox(
// //                         width: double.infinity,
// //                         height: 50,
// //                         child: ElevatedButton.icon(
// //                           onPressed: startSyncProcess,
// //                           icon: const Icon(
// //                             Icons.sync_outlined,
// //                             color: Colors.black,
// //                           ),
// //                           label: Text(
// //                             "Receive Data",
// //                             style: GoogleFonts.poppins(
// //                               fontWeight: FontWeight.w600,
// //                               fontSize: 16,
// //                             ),
// //                           ),
// //                           style: ElevatedButton.styleFrom(
// //                             backgroundColor: btnColor,
// //                             foregroundColor: Colors.black,
// //                             shape: RoundedRectangleBorder(
// //                               borderRadius: BorderRadius.circular(12),
// //                             ),
// //                             elevation: 0,
// //                           ),
// //                         ),
// //                       ),
// //                   ],
// //                 ),
// //               ),
// //             ),

// //             const SizedBox(height: 40),
// //             Text(
// //               "Recent Received Files",
// //               style: GoogleFonts.poppins(
// //                 fontSize: 18,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             const SizedBox(height: 15),

// //             Expanded(
// //               child: _receivedFiles.isEmpty
// //                   ? Center(
// //                       child: Column(
// //                         mainAxisAlignment: MainAxisAlignment.center,
// //                         children: [
// //                           Icon(
// //                             Icons.folder_outlined,
// //                             size: 60,
// //                             color: Colors.grey[300],
// //                           ),
// //                           const SizedBox(height: 15),
// //                           Text(
// //                             "No files received yet",
// //                             style: TextStyle(color: Colors.grey[400]),
// //                           ),
// //                         ],
// //                       ),
// //                     )
// //                   : ListView.builder(
// //                       itemCount: _receivedFiles.length,
// //                       itemBuilder: (context, index) {
// //                         String path = _receivedFiles[index];
// //                         String name = path.split('/').last;
// //                         return FadeInUp(
// //                           duration: const Duration(milliseconds: 300),
// //                           child: Card(
// //                             elevation: 0,
// //                             color: Colors.white,
// //                             margin: const EdgeInsets.only(bottom: 12),
// //                             shape: RoundedRectangleBorder(
// //                               borderRadius: BorderRadius.circular(16),
// //                             ),
// //                             child: ListTile(
// //                               contentPadding: const EdgeInsets.symmetric(
// //                                 horizontal: 20,
// //                                 vertical: 8,
// //                               ),
// //                               leading: Container(
// //                                 padding: const EdgeInsets.all(10),
// //                                 decoration: BoxDecoration(
// //                                   color: const Color(0xFFF0FDF4),
// //                                   borderRadius: BorderRadius.circular(10),
// //                                 ),
// //                                 child: const Icon(
// //                                   Icons.folder_zip,
// //                                   color: Color(0xFF2E7D32),
// //                                 ),
// //                               ),
// //                               title: Text(
// //                                 name,
// //                                 style: const TextStyle(
// //                                   fontWeight: FontWeight.w600,
// //                                 ),
// //                               ),
// //                               subtitle: Text(
// //                                 "Tap to open",
// //                                 style: TextStyle(
// //                                   fontSize: 12,
// //                                   color: Colors.grey[500],
// //                                 ),
// //                               ),
// //                               onTap: () => OpenFile.open(path),
// //                               trailing: const Icon(
// //                                 Icons.chevron_right,
// //                                 color: Colors.grey,
// //                               ),
// //                             ),
// //                           ),
// //                         );
// //                       },
// //                     ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildDrawer() {
// //     return Drawer(
// //       backgroundColor: Colors.white,
// //       child: Column(
// //         children: [
// //           UserAccountsDrawerHeader(
// //             decoration: const BoxDecoration(color: Color(0xFF191825)),
// //             accountName: Text(
// //               "Admin User",
// //               style: GoogleFonts.poppins(
// //                 fontWeight: FontWeight.bold,
// //                 fontSize: 16,
// //               ),
// //             ),
// //             accountEmail: Text(
// //               "admin@itc.project",
// //               style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
// //             ),
// //             currentAccountPicture: const CircleAvatar(
// //               backgroundColor: Colors.white,
// //               child: Icon(Icons.person, size: 40, color: Color(0xFF191825)),
// //             ),
// //           ),
// //           const SizedBox(height: 10),
// //           _drawerItem(Icons.folder_outlined, "My Files", () {}),
// //           _drawerItem(Icons.settings_outlined, "Settings", () {}),
// //           _drawerItem(Icons.info_outline, "About", () {}),
// //           const Spacer(),
// //           const Divider(),
// //           _drawerItem(Icons.logout, "Logout", () {}, isDestructive: true),
// //           const SizedBox(height: 20),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _drawerItem(
// //     IconData icon,
// //     String title,
// //     VoidCallback onTap, {
// //     bool isDestructive = false,
// //   }) {
// //     return ListTile(
// //       leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey[800]),
// //       title: Text(
// //         title,
// //         style: GoogleFonts.poppins(
// //           color: isDestructive ? Colors.red : Colors.black87,
// //           fontWeight: FontWeight.w500,
// //         ),
// //       ),
// //       onTap: () {
// //         Navigator.pop(context);
// //         onTap();
// //       },
// //     );
// //   }
// // }

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:animate_do/animate_do.dart';

// // --- CONFIGURATION ---
// const String SECRET_KEY = "securekey";
// const int TCP_PORT = 5001;
// const int DISCOVERY_PORT = 5000;

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'AgriSync',
//       theme: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: const Color(0xFFF4F7F6), // Light Grey Bg
//         primaryColor: const Color(0xFF2E7D32), // Agri Green
//         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
//         textTheme: GoogleFonts.poppinsTextTheme(),
//       ),
//       home: const HomeScreen(),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // --- STATE VARIABLES ---
//   String _statusMessage = "Please connect to 'FileShareHotspot'";
//   bool _isConnectedToWifi = false;
//   bool _isTransferring = false;
//   double _progress = 0.0;
//   List<String> _receivedFiles = [];

//   // Services
//   final Connectivity _connectivity = Connectivity();
//   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _checkInitialConnection();

//     _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
//       result,
//     ) {
//       _updateConnectionStatus(result);
//     });
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     super.dispose();
//   }

//   // --- 1. PERMISSIONS & WIFI CHECKS ---
//   Future<void> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       if (await Permission.manageExternalStorage.request().isGranted) {
//         debugPrint("Manage External Storage Granted");
//       }

//       await [
//         Permission.location,
//         Permission.nearbyWifiDevices,
//         Permission.storage,
//       ].request();
//     }
//   }

//   void _checkInitialConnection() async {
//     var result = await _connectivity.checkConnectivity();
//     _updateConnectionStatus(result);
//   }

//   void _updateConnectionStatus(ConnectivityResult result) async {
//     bool hasWifi = result == ConnectivityResult.wifi;

//     if (hasWifi && !_isConnectedToWifi) {
//       _showBottomNotification("WiFi Connected! Ready to Sync.");
//     }

//     setState(() {
//       _isConnectedToWifi = hasWifi;
//       _statusMessage = hasWifi
//           ? "Connected to WiFi. Ready to receive."
//           : "Please connect to 'FileShareHotspot'";
//     });
//   }

//   void _showBottomNotification(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(
//               isError ? Icons.error_outline : Icons.wifi,
//               color: Colors.white,
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 message,
//                 style: const TextStyle(fontWeight: FontWeight.w500),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B5E20),
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.all(20),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         duration: const Duration(seconds: 4),
//       ),
//     );
//   }

//   // --- 2. CORE TRANSFER LOGIC ---
//   Future<void> startSyncProcess() async {
//     if (!_isConnectedToWifi) {
//       _showBottomNotification(
//         "No WiFi Connection! Check Settings.",
//         isError: true,
//       );
//       return;
//     }

//     setState(() {
//       _isTransferring = true;
//       _progress = 0.1;
//       _statusMessage = "Locating Server...";
//     });

//     try {
//       final info = NetworkInfo();
//       var wifiIP = await info.getWifiIP();
//       var gatewayIp = await info.getWifiGatewayIP();

//       String targetIp = (gatewayIp != null && gatewayIp != "0.0.0.0")
//           ? gatewayIp
//           : "10.42.0.1";

//       debugPrint("My IP: $wifiIP | Target Gateway: $targetIp");

//       setState(() {
//         _statusMessage = "Connecting to $targetIp...";
//         _progress = 0.2;
//       });

//       await _receiveFiles(targetIp, TCP_PORT, wifiIP);
//     } catch (e) {
//       setState(() {
//         _statusMessage = "Connection Failed";
//         _isTransferring = false;
//         _progress = 0.0;
//       });
//       String errorMsg = e.toString().contains("Connection timed out")
//           ? "Connection Timed Out. Check Firewall on Pi."
//           : e.toString().split(':')[1];

//       _showBottomNotification("Error: $errorMsg", isError: true);
//       debugPrint("Sync Error: $e");
//     }
//   }

//   Future<void> _receiveFiles(String ip, int port, String? sourceIP) async {
//     Socket? socket;
//     int retryCount = 0;

//     // RETRY LOOP
//     while (socket == null && retryCount < 3) {
//       try {
//         debugPrint("Attempt ${retryCount + 1}: Connecting to $ip:$port...");
//         socket = await Socket.connect(
//           ip,
//           port,
//           sourceAddress: sourceIP,
//           timeout: const Duration(seconds: 5),
//         );
//       } catch (e) {
//         retryCount++;
//         if (retryCount >= 3)
//           throw Exception("Could not connect to $ip after 3 attempts.");
//         await Future.delayed(const Duration(seconds: 1));
//       }
//     }

//     try {
//       // 1. Auth Handshake
//       debugPrint("Connected. Sending Key...");
//       socket!.add(utf8.encode(SECRET_KEY));
//       await socket.flush();

//       StreamIterator<Uint8List> reader = StreamIterator(socket);

//       // 2. Wait for OK (Auth Success)
//       if (!await _readUntil(reader, "OK"))
//         throw Exception("Auth Failed: Server rejected key");
//       debugPrint("Auth Validated.");

//       // 3. Get Header (NUM_FILES|1)
//       String header = await _readHeader(reader);
//       debugPrint("Header Received: $header");

//       // ACK Header
//       socket.add(utf8.encode("OK"));
//       await socket.flush();

//       if (header.startsWith("NUM_FILES")) {
//         int count = int.parse(header.split("|")[1]);
//         for (int i = 0; i < count; i++) {
//           setState(() {
//             _statusMessage = "Downloading file ${i + 1}/$count...";
//             _progress = (i + 1) / (count + 1);
//           });
//           await _downloadSingleFile(reader, socket);
//         }
//       }

//       setState(() {
//         _isTransferring = false;
//         _statusMessage = "Transfer Complete!";
//         _progress = 1.0;
//       });
//       _showBottomNotification("Files Received Successfully!");
//     } catch (e) {
//       debugPrint("Protocol Error: $e");
//       rethrow;
//     } finally {
//       socket?.destroy();
//     }
//   }

//   Future<void> _downloadSingleFile(
//     StreamIterator<Uint8List> reader,
//     Socket socket,
//   ) async {
//     // 1. Read File Info: filename.zip|12345
//     String header = await _readHeader(reader);
//     var parts = header.split("|");
//     String filename = parts[0];
//     int filesize = int.parse(parts[1]);

//     // --- FIX: Force .zip extension if missing or generic ---
//     if (!filename.toLowerCase().endsWith('.zip')) {
//       filename = "$filename.zip";
//     }
//     // -------------------------------------------------------

//     debugPrint("Receiving $filename ($filesize bytes)");

//     // 2. Send OK to start the stream
//     socket.add(utf8.encode("OK"));
//     await socket.flush();

//     // 3. Prepare File Path
//     Directory? dir;
//     if (Platform.isAndroid) {
//       dir = await getExternalStorageDirectory();
//     } else {
//       dir = await getApplicationDocumentsDirectory();
//     }

//     String savePath = "${dir!.path}/$filename";
//     File file = File(savePath);
//     IOSink sink = file.openWrite();

//     // 4. Stream Data
//     int received = 0;
//     while (received < filesize) {
//       if (await reader.moveNext()) {
//         Uint8List chunk = reader.current;
//         int remaining = filesize - received;

//         if (chunk.length > remaining) {
//           sink.add(chunk.sublist(0, remaining));
//           received += remaining;
//         } else {
//           sink.add(chunk);
//           received += chunk.length;
//         }
//       } else {
//         break; // Stream ended prematurely
//       }
//     }
//     await sink.close();
//     debugPrint("File Saved: $savePath");

//     setState(() {
//       _receivedFiles.insert(0, savePath);
//     });
//   }

//   // --- STREAM HELPERS ---
//   Future<bool> _readUntil(
//     StreamIterator<Uint8List> reader,
//     String target,
//   ) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current).contains(target);
//     }
//     return false;
//   }

//   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current);
//     }
//     throw Exception("Connection closed unexpected");
//   }

//   // --- 3. UI COMPONENTS ---

//   @override
//   Widget build(BuildContext context) {
//     final Color cardBgColor = const Color(0xFF1A1F30);
//     final Color btnColor = const Color(0xFFC8F000);

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF4F7F6),
//         elevation: 0,
//         leading: Builder(
//           builder: (context) {
//             return IconButton(
//               icon: const Icon(
//                 Icons.menu_rounded,
//                 color: Colors.black,
//                 size: 32,
//               ),
//               onPressed: () => Scaffold.of(context).openDrawer(),
//             );
//           },
//         ),
//         actions: [
//           Container(
//             margin: const EdgeInsets.only(right: 20),
//             padding: const EdgeInsets.all(2),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: const Color(0xFF2E7D32), width: 2),
//             ),
//             child: const CircleAvatar(
//               radius: 16,
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, size: 24, color: Color(0xFF2E7D32)),
//             ),
//           ),
//         ],
//       ),

//       drawer: _buildDrawer(),

//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             FadeInDown(
//               child: Text(
//                 "Welcome Back,",
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ),
//             FadeInDown(
//               delay: const Duration(milliseconds: 100),
//               child: Text(
//                 "Agri-Manager",
//                 style: GoogleFonts.poppins(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: const Color(0xFF191825),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 30),

//             FadeInUp(
//               delay: const Duration(milliseconds: 200),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(25),
//                 decoration: BoxDecoration(
//                   color: cardBgColor,
//                   borderRadius: BorderRadius.circular(24),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.2),
//                       blurRadius: 15,
//                       offset: const Offset(0, 8),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           "System Status",
//                           style: GoogleFonts.poppins(
//                             color: Colors.grey[400],
//                             fontSize: 14,
//                           ),
//                         ),
//                         Icon(
//                           _isConnectedToWifi ? Icons.wifi : Icons.wifi_off,
//                           color: _isConnectedToWifi
//                               ? Colors.greenAccent
//                               : Colors.redAccent,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 20),

//                     Text(
//                       _statusMessage,
//                       style: GoogleFonts.poppins(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 25),

//                     if (_isTransferring)
//                       Column(
//                         children: [
//                           LinearProgressIndicator(
//                             value: _progress,
//                             backgroundColor: Colors.white10,
//                             color: btnColor,
//                           ),
//                           const SizedBox(height: 10),
//                           Text(
//                             "${(_progress * 100).toInt()}%",
//                             style: const TextStyle(color: Colors.white70),
//                           ),
//                         ],
//                       )
//                     else
//                       SizedBox(
//                         width: double.infinity,
//                         height: 50,
//                         child: ElevatedButton.icon(
//                           onPressed: startSyncProcess,
//                           icon: const Icon(
//                             Icons.sync_outlined,
//                             color: Colors.black,
//                           ),
//                           label: Text(
//                             "Receive Data",
//                             style: GoogleFonts.poppins(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 16,
//                             ),
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: btnColor,
//                             foregroundColor: Colors.black,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 0,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 40),
//             Text(
//               "Recent Received Files",
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 15),

//             Expanded(
//               child: _receivedFiles.isEmpty
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.folder_outlined,
//                             size: 60,
//                             color: Colors.grey[300],
//                           ),
//                           const SizedBox(height: 15),
//                           Text(
//                             "No files received yet",
//                             style: TextStyle(color: Colors.grey[400]),
//                           ),
//                         ],
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: _receivedFiles.length,
//                       itemBuilder: (context, index) {
//                         String path = _receivedFiles[index];
//                         String name = path.split('/').last;
//                         return FadeInUp(
//                           duration: const Duration(milliseconds: 300),
//                           child: Card(
//                             elevation: 0,
//                             color: Colors.white,
//                             margin: const EdgeInsets.only(bottom: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: ListTile(
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 20,
//                                 vertical: 8,
//                               ),
//                               leading: Container(
//                                 padding: const EdgeInsets.all(10),
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFFF0FDF4),
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 child: const Icon(
//                                   Icons.folder_zip, // Changed to Zip Icon
//                                   color: Color(0xFF2E7D32),
//                                 ),
//                               ),
//                               title: Text(
//                                 name,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               subtitle: Text(
//                                 "Tap to open",
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[500],
//                                 ),
//                               ),
//                               onTap: () => OpenFile.open(path),
//                               trailing: const Icon(
//                                 Icons.chevron_right,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       backgroundColor: Colors.white,
//       child: Column(
//         children: [
//           UserAccountsDrawerHeader(
//             decoration: const BoxDecoration(color: Color(0xFF191825)),
//             accountName: Text(
//               "Admin User",
//               style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             accountEmail: Text(
//               "admin@itc.project",
//               style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
//             ),
//             currentAccountPicture: const CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, size: 40, color: Color(0xFF191825)),
//             ),
//           ),
//           const SizedBox(height: 10),
//           _drawerItem(Icons.folder_outlined, "My Files", () {}),
//           _drawerItem(Icons.settings_outlined, "Settings", () {}),
//           _drawerItem(Icons.info_outline, "About", () {}),
//           const Spacer(),
//           const Divider(),
//           _drawerItem(Icons.logout, "Logout", () {}, isDestructive: true),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _drawerItem(
//     IconData icon,
//     String title,
//     VoidCallback onTap, {
//     bool isDestructive = false,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey[800]),
//       title: Text(
//         title,
//         style: GoogleFonts.poppins(
//           color: isDestructive ? Colors.red : Colors.black87,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       onTap: () {
//         Navigator.pop(context);
//         onTap();
//       },
//     );
//   }
// }
// //

// TILL 12/01/26

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:animate_do/animate_do.dart';

// // --- CONFIGURATION ---
// const String SECRET_KEY = "securekey";
// const int TCP_PORT = 5001;
// const int DISCOVERY_PORT = 5000;

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'AgriSync',
//       theme: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: const Color(0xFFF4F7F6), // Light Grey Bg
//         primaryColor: const Color(0xFF2E7D32), // Agri Green
//         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
//         textTheme: GoogleFonts.poppinsTextTheme(),
//       ),
//       home: const HomeScreen(),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // --- STATE VARIABLES ---
//   String _statusMessage = "Please connect to 'FileShareHotspot'";
//   bool _isConnectedToWifi = false;
//   bool _isTransferring = false;
//   double _progress = 0.0;
//   List<String> _receivedFiles = [];

//   // Services
//   final Connectivity _connectivity = Connectivity();

//   // FIXED: Removed <List<...>> to match your installed version
//   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _checkInitialConnection();

//     // FIXED: Removed .listen((results) ... results.first)
//     // Now simply listens for a single result
//     _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
//       result,
//     ) {
//       _updateConnectionStatus(result);
//     });
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     super.dispose();
//   }

//   // --- 1. PERMISSIONS & WIFI CHECKS ---
//   Future<void> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       if (await Permission.manageExternalStorage.request().isGranted) {
//         debugPrint("Manage External Storage Granted");
//       }

//       await [
//         Permission.location,
//         Permission.nearbyWifiDevices,
//         Permission.storage,
//       ].request();
//     }
//   }

//   void _checkInitialConnection() async {
//     var result = await _connectivity.checkConnectivity();
//     // FIXED: Removed .first accessor
//     _updateConnectionStatus(result);
//   }

//   void _updateConnectionStatus(ConnectivityResult result) async {
//     bool hasWifi = result == ConnectivityResult.wifi;

//     if (hasWifi && !_isConnectedToWifi) {
//       _showBottomNotification("WiFi Connected! Ready to Sync.");
//     }

//     setState(() {
//       _isConnectedToWifi = hasWifi;
//       _statusMessage = hasWifi
//           ? "Connected to WiFi. Ready to receive."
//           : "Please connect to 'FileShareHotspot'";
//     });
//   }

//   void _showBottomNotification(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(
//               isError ? Icons.error_outline : Icons.wifi,
//               color: Colors.white,
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 message,
//                 style: const TextStyle(fontWeight: FontWeight.w500),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B5E20),
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.all(20),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         duration: const Duration(seconds: 4),
//       ),
//     );
//   }

//   // --- 2. CORE TRANSFER LOGIC ---
//   Future<void> startSyncProcess() async {
//     if (!_isConnectedToWifi) {
//       _showBottomNotification(
//         "No WiFi Connection! Check Settings.",
//         isError: true,
//       );
//       return;
//     }

//     setState(() {
//       _isTransferring = true;
//       _progress = 0.1;
//       _statusMessage = "Locating Server...";
//     });

//     try {
//       final info = NetworkInfo();
//       var wifiIP = await info.getWifiIP();
//       var gatewayIp = await info.getWifiGatewayIP();

//       String targetIp = (gatewayIp != null && gatewayIp != "0.0.0.0")
//           ? gatewayIp
//           : "10.42.0.1";

//       debugPrint("My IP: $wifiIP | Target Gateway: $targetIp");

//       setState(() {
//         _statusMessage = "Connecting to $targetIp...";
//         _progress = 0.2;
//       });

//       await _receiveFiles(targetIp, TCP_PORT, wifiIP);
//     } catch (e) {
//       setState(() {
//         _statusMessage = "Connection Failed";
//         _isTransferring = false;
//         _progress = 0.0;
//       });
//       String errorMsg = e.toString().contains("Connection timed out")
//           ? "Connection Timed Out. Check Firewall on Pi."
//           : e.toString().split(':')[1];

//       _showBottomNotification("Error: $errorMsg", isError: true);
//       debugPrint("Sync Error: $e");
//     }
//   }

//   Future<void> _receiveFiles(String ip, int port, String? sourceIP) async {
//     Socket? socket;
//     int retryCount = 0;

//     // RETRY LOOP
//     while (socket == null && retryCount < 3) {
//       try {
//         debugPrint("Attempt ${retryCount + 1}: Connecting to $ip:$port...");
//         socket = await Socket.connect(
//           ip,
//           port,
//           sourceAddress: sourceIP,
//           timeout: const Duration(seconds: 5),
//         );
//       } catch (e) {
//         retryCount++;
//         if (retryCount >= 3)
//           throw Exception("Could not connect to $ip after 3 attempts.");
//         await Future.delayed(const Duration(seconds: 1));
//       }
//     }

//     try {
//       // 1. Auth Handshake
//       debugPrint("Connected. Sending Key...");
//       socket!.add(utf8.encode(SECRET_KEY));
//       await socket.flush();

//       StreamIterator<Uint8List> reader = StreamIterator(socket);

//       // 2. Wait for OK (Auth Success)
//       if (!await _readUntil(reader, "OK"))
//         throw Exception("Auth Failed: Server rejected key");
//       debugPrint("Auth Validated.");

//       // 3. Get Header (NUM_FILES|1)
//       String header = await _readHeader(reader);
//       debugPrint("Header Received: $header");

//       // ACK Header
//       socket.add(utf8.encode("OK"));
//       await socket.flush();

//       if (header.startsWith("NUM_FILES")) {
//         int count = int.parse(header.split("|")[1]);
//         for (int i = 0; i < count; i++) {
//           setState(() {
//             _statusMessage = "Downloading file ${i + 1}/$count...";
//             _progress = (i + 1) / (count + 1);
//           });
//           await _downloadSingleFile(reader, socket);
//         }
//       }

//       setState(() {
//         _isTransferring = false;
//         _statusMessage = "Transfer Complete!";
//         _progress = 1.0;
//       });
//       _showBottomNotification("Files Received Successfully!");
//     } catch (e) {
//       debugPrint("Protocol Error: $e");
//       rethrow;
//     } finally {
//       socket?.destroy();
//     }
//   }

//   Future<void> _downloadSingleFile(
//     StreamIterator<Uint8List> reader,
//     Socket socket,
//   ) async {
//     // 1. Read File Info: filename.zip|12345
//     String header = await _readHeader(reader);
//     var parts = header.split("|");
//     String filename = parts[0];
//     int filesize = int.parse(parts[1]);

//     debugPrint("Receiving $filename ($filesize bytes)");

//     // 2. Send OK to start the stream
//     socket.add(utf8.encode("OK"));
//     await socket.flush();

//     // 3. Prepare File Path
//     Directory? dir;
//     if (Platform.isAndroid) {
//       dir = await getExternalStorageDirectory();
//     } else {
//       dir = await getApplicationDocumentsDirectory();
//     }

//     String savePath = "${dir!.path}/$filename";
//     File file = File(savePath);
//     IOSink sink = file.openWrite();

//     // 4. Stream Data
//     int received = 0;
//     while (received < filesize) {
//       if (await reader.moveNext()) {
//         Uint8List chunk = reader.current;
//         int remaining = filesize - received;

//         if (chunk.length > remaining) {
//           sink.add(chunk.sublist(0, remaining));
//           received += remaining;
//         } else {
//           sink.add(chunk);
//           received += chunk.length;
//         }
//       } else {
//         break; // Stream ended prematurely
//       }
//     }
//     await sink.close();
//     debugPrint("File Saved: $savePath");

//     setState(() {
//       _receivedFiles.insert(0, savePath);
//     });
//   }

//   // --- STREAM HELPERS ---
//   Future<bool> _readUntil(
//     StreamIterator<Uint8List> reader,
//     String target,
//   ) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current).contains(target);
//     }
//     return false;
//   }

//   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current);
//     }
//     throw Exception("Connection closed unexpected");
//   }

//   // --- 3. UI COMPONENTS ---

//   @override
//   Widget build(BuildContext context) {
//     final Color cardBgColor = const Color(0xFF1A1F30);
//     final Color btnColor = const Color(0xFFC8F000);

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF4F7F6),
//         elevation: 0,
//         leading: Builder(
//           builder: (context) {
//             return IconButton(
//               icon: const Icon(
//                 Icons.menu_rounded,
//                 color: Colors.black,
//                 size: 32,
//               ),
//               onPressed: () => Scaffold.of(context).openDrawer(),
//             );
//           },
//         ),
//         actions: [
//           Container(
//             margin: const EdgeInsets.only(right: 20),
//             padding: const EdgeInsets.all(2),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: const Color(0xFF2E7D32), width: 2),
//             ),
//             child: const CircleAvatar(
//               radius: 16,
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, size: 24, color: Color(0xFF2E7D32)),
//             ),
//           ),
//         ],
//       ),

//       drawer: _buildDrawer(),

//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             FadeInDown(
//               child: Text(
//                 "Welcome Back,",
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ),
//             FadeInDown(
//               delay: const Duration(milliseconds: 100),
//               child: Text(
//                 "Agri-Manager",
//                 style: GoogleFonts.poppins(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: const Color(0xFF191825),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 30),

//             FadeInUp(
//               delay: const Duration(milliseconds: 200),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(25),
//                 decoration: BoxDecoration(
//                   color: cardBgColor,
//                   borderRadius: BorderRadius.circular(24),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.2),
//                       blurRadius: 15,
//                       offset: const Offset(0, 8),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           "System Status",
//                           style: GoogleFonts.poppins(
//                             color: Colors.grey[400],
//                             fontSize: 14,
//                           ),
//                         ),
//                         Icon(
//                           _isConnectedToWifi ? Icons.wifi : Icons.wifi_off,
//                           color: _isConnectedToWifi
//                               ? Colors.greenAccent
//                               : Colors.redAccent,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 20),

//                     Text(
//                       _statusMessage,
//                       style: GoogleFonts.poppins(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 25),

//                     if (_isTransferring)
//                       Column(
//                         children: [
//                           LinearProgressIndicator(
//                             value: _progress,
//                             backgroundColor: Colors.white10,
//                             color: btnColor,
//                           ),
//                           const SizedBox(height: 10),
//                           Text(
//                             "${(_progress * 100).toInt()}%",
//                             style: const TextStyle(color: Colors.white70),
//                           ),
//                         ],
//                       )
//                     else
//                       SizedBox(
//                         width: double.infinity,
//                         height: 50,
//                         child: ElevatedButton.icon(
//                           onPressed: startSyncProcess,
//                           icon: const Icon(
//                             Icons.sync_outlined,
//                             color: Colors.black,
//                           ),
//                           label: Text(
//                             "Receive Data",
//                             style: GoogleFonts.poppins(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 16,
//                             ),
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: btnColor,
//                             foregroundColor: Colors.black,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 0,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 40),
//             Text(
//               "Recent Received Files",
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 15),

//             Expanded(
//               child: _receivedFiles.isEmpty
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.folder_outlined,
//                             size: 60,
//                             color: Colors.grey[300],
//                           ),
//                           const SizedBox(height: 15),
//                           Text(
//                             "No files received yet",
//                             style: TextStyle(color: Colors.grey[400]),
//                           ),
//                         ],
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: _receivedFiles.length,
//                       itemBuilder: (context, index) {
//                         String path = _receivedFiles[index];
//                         String name = path.split('/').last;
//                         return FadeInUp(
//                           duration: const Duration(milliseconds: 300),
//                           child: Card(
//                             elevation: 0,
//                             color: Colors.white,
//                             margin: const EdgeInsets.only(bottom: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: ListTile(
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 20,
//                                 vertical: 8,
//                               ),
//                               leading: Container(
//                                 padding: const EdgeInsets.all(10),
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFFF0FDF4),
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 child: const Icon(
//                                   Icons.folder_zip,
//                                   color: Color(0xFF2E7D32),
//                                 ),
//                               ),
//                               title: Text(
//                                 name,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               subtitle: Text(
//                                 "Tap to open",
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[500],
//                                 ),
//                               ),
//                               onTap: () => OpenFile.open(path),
//                               trailing: const Icon(
//                                 Icons.chevron_right,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       backgroundColor: Colors.white,
//       child: Column(
//         children: [
//           UserAccountsDrawerHeader(
//             decoration: const BoxDecoration(color: Color(0xFF191825)),
//             accountName: Text(
//               "Admin User",
//               style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             accountEmail: Text(
//               "admin@itc.project",
//               style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
//             ),
//             currentAccountPicture: const CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, size: 40, color: Color(0xFF191825)),
//             ),
//           ),
//           const SizedBox(height: 10),
//           _drawerItem(Icons.folder_outlined, "My Files", () {}),
//           _drawerItem(Icons.settings_outlined, "Settings", () {}),
//           _drawerItem(Icons.info_outline, "About", () {}),
//           const Spacer(),
//           const Divider(),
//           _drawerItem(Icons.logout, "Logout", () {}, isDestructive: true),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _drawerItem(
//     IconData icon,
//     String title,
//     VoidCallback onTap, {
//     bool isDestructive = false,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey[800]),
//       title: Text(
//         title,
//         style: GoogleFonts.poppins(
//           color: isDestructive ? Colors.red : Colors.black87,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       onTap: () {
//         Navigator.pop(context);
//         onTap();
//       },
//     );
//   }
// }

// FILE TRANSFER AND OPENED IN MOBILE PHONE SUCCESSFULLY

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:animate_do/animate_do.dart';

// // --- CONFIGURATION ---
// const String SECRET_KEY = "securekey";
// const int TCP_PORT = 5001;
// const int DISCOVERY_PORT = 5000;

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'AgriSync',
//       theme: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: const Color(0xFFF4F7F6), // Light Grey Bg
//         primaryColor: const Color(0xFF2E7D32), // Agri Green
//         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
//         textTheme: GoogleFonts.poppinsTextTheme(),
//       ),
//       home: const HomeScreen(),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // --- STATE VARIABLES ---
//   String _statusMessage = "Please connect to 'FileShareHotspot'";
//   bool _isConnectedToWifi = false;
//   bool _isTransferring = false;
//   double _progress = 0.0;
//   List<String> _receivedFiles = [];

//   // Services
//   final Connectivity _connectivity = Connectivity();
//   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _checkInitialConnection();

//     _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
//       result,
//     ) {
//       _updateConnectionStatus(result);
//     });
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     super.dispose();
//   }

//   // --- 1. PERMISSIONS & WIFI CHECKS ---
//   Future<void> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       // Request Manage External Storage for Android 11+
//       if (await Permission.manageExternalStorage.request().isGranted) {
//         debugPrint("Manage External Storage Granted");
//       }

//       await [
//         Permission.location,
//         Permission.nearbyWifiDevices,
//         Permission.storage, // Critical for older Android versions
//       ].request();
//     }
//   }

//   void _checkInitialConnection() async {
//     var result = await _connectivity.checkConnectivity();
//     _updateConnectionStatus(result);
//   }

//   void _updateConnectionStatus(ConnectivityResult result) async {
//     bool hasWifi = result == ConnectivityResult.wifi;

//     if (hasWifi && !_isConnectedToWifi) {
//       _showBottomNotification("WiFi Connected! Ready to Sync.");
//     }

//     setState(() {
//       _isConnectedToWifi = hasWifi;
//       _statusMessage = hasWifi
//           ? "Connected to WiFi. Ready to receive."
//           : "Please connect to 'FileShareHotspot'";
//     });
//   }

//   void _showBottomNotification(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(
//               isError ? Icons.error_outline : Icons.wifi,
//               color: Colors.white,
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 message,
//                 style: const TextStyle(fontWeight: FontWeight.w500),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B5E20),
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.all(20),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         duration: const Duration(seconds: 4),
//       ),
//     );
//   }

//   // --- 2. CORE TRANSFER LOGIC ---
//   Future<void> startSyncProcess() async {
//     if (!_isConnectedToWifi) {
//       _showBottomNotification(
//         "No WiFi Connection! Check Settings.",
//         isError: true,
//       );
//       return;
//     }

//     setState(() {
//       _isTransferring = true;
//       _progress = 0.1;
//       _statusMessage = "Locating Server...";
//     });

//     try {
//       final info = NetworkInfo();
//       var wifiIP = await info.getWifiIP();
//       var gatewayIp = await info.getWifiGatewayIP();

//       // Fallback IP if gateway is missing (Hotspot default)
//       String targetIp = (gatewayIp != null && gatewayIp != "0.0.0.0")
//           ? gatewayIp
//           : "10.42.0.1";

//       debugPrint("My IP: $wifiIP | Target Gateway: $targetIp");

//       setState(() {
//         _statusMessage = "Connecting to $targetIp...";
//         _progress = 0.2;
//       });

//       await _receiveFiles(targetIp, TCP_PORT, wifiIP);
//     } catch (e) {
//       setState(() {
//         _statusMessage = "Connection Failed";
//         _isTransferring = false;
//         _progress = 0.0;
//       });
//       String errorMsg = e.toString().contains("Connection timed out")
//           ? "Connection Timed Out. Check Firewall on Pi."
//           : e.toString().split(':')[1];

//       _showBottomNotification("Error: $errorMsg", isError: true);
//       debugPrint("Sync Error: $e");
//     }
//   }

//   Future<void> _receiveFiles(String ip, int port, String? sourceIP) async {
//     Socket? socket;
//     int retryCount = 0;

//     // RETRY LOOP
//     while (socket == null && retryCount < 3) {
//       try {
//         debugPrint("Attempt ${retryCount + 1}: Connecting to $ip:$port...");
//         socket = await Socket.connect(
//           ip,
//           port,
//           sourceAddress: sourceIP,
//           timeout: const Duration(seconds: 5),
//         );
//       } catch (e) {
//         retryCount++;
//         if (retryCount >= 3)
//           throw Exception("Could not connect to $ip after 3 attempts.");
//         await Future.delayed(const Duration(seconds: 1));
//       }
//     }

//     try {
//       // 1. Auth Handshake
//       debugPrint("Connected. Sending Key...");
//       socket!.add(utf8.encode(SECRET_KEY));
//       await socket.flush();

//       StreamIterator<Uint8List> reader = StreamIterator(socket);

//       // 2. Wait for OK (Auth Success)
//       if (!await _readUntil(reader, "OK"))
//         throw Exception("Auth Failed: Server rejected key");
//       debugPrint("Auth Validated.");

//       // 3. Get Header (NUM_FILES|1)
//       String header = await _readHeader(reader);
//       debugPrint("Header Received: $header");

//       // ACK Header
//       socket.add(utf8.encode("OK"));
//       await socket.flush();

//       if (header.startsWith("NUM_FILES")) {
//         int count = int.parse(header.split("|")[1]);
//         for (int i = 0; i < count; i++) {
//           setState(() {
//             _statusMessage = "Downloading file ${i + 1}/$count...";
//             _progress = (i + 1) / (count + 1);
//           });
//           await _downloadSingleFile(reader, socket);
//         }
//       }

//       setState(() {
//         _isTransferring = false;
//         _statusMessage = "Transfer Complete!";
//         _progress = 1.0;
//       });
//       _showBottomNotification("Files Received Successfully!");
//     } catch (e) {
//       debugPrint("Protocol Error: $e");
//       rethrow;
//     } finally {
//       socket?.destroy();
//     }
//   }

//   // --- UPDATED DOWNLOAD LOGIC (SAVES TO PUBLIC DOWNLOADS) ---
//   Future<void> _downloadSingleFile(
//     StreamIterator<Uint8List> reader,
//     Socket socket,
//   ) async {
//     // 1. Read File Info
//     String header = await _readHeader(reader);
//     var parts = header.split("|");
//     String filename =
//         parts[0]; // Trust the filename from Python (e.g. image.jpg)
//     int filesize = int.parse(parts[1]);

//     debugPrint("Receiving $filename ($filesize bytes)");

//     // 2. Send OK to start stream
//     socket.add(utf8.encode("OK"));
//     await socket.flush();

//     // 3. Prepare PUBLIC File Path
//     String savePath;
//     if (Platform.isAndroid) {
//       // Hardcoded path to public Downloads folder for visibility
//       Directory publicDir = Directory(
//         '/storage/emulated/0/Download/AgriSync_Files',
//       );
//       if (!await publicDir.exists()) {
//         await publicDir.create(recursive: true);
//       }
//       savePath = "${publicDir.path}/$filename";
//     } else {
//       // iOS / Desktop Fallback
//       Directory? dir = await getApplicationDocumentsDirectory();
//       savePath = "${dir!.path}/$filename";
//     }

//     File file = File(savePath);
//     IOSink sink = file.openWrite();

//     // 4. Stream Data
//     int received = 0;
//     while (received < filesize) {
//       if (await reader.moveNext()) {
//         Uint8List chunk = reader.current;
//         int remaining = filesize - received;

//         if (chunk.length > remaining) {
//           sink.add(chunk.sublist(0, remaining));
//           received += remaining;
//         } else {
//           sink.add(chunk);
//           received += chunk.length;
//         }
//       } else {
//         break; // Stream ended
//       }
//     }
//     await sink.flush();
//     await sink.close();

//     debugPrint("File Saved Publicly: $savePath");

//     setState(() {
//       _receivedFiles.insert(0, savePath);
//     });
//   }

//   // --- STREAM HELPERS ---
//   Future<bool> _readUntil(
//     StreamIterator<Uint8List> reader,
//     String target,
//   ) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current).contains(target);
//     }
//     return false;
//   }

//   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current);
//     }
//     throw Exception("Connection closed unexpected");
//   }

//   // --- 3. UI COMPONENTS ---

//   @override
//   Widget build(BuildContext context) {
//     final Color cardBgColor = const Color(0xFF1A1F30);
//     final Color btnColor = const Color(0xFFC8F000);

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF4F7F6),
//         elevation: 0,
//         leading: Builder(
//           builder: (context) {
//             return IconButton(
//               icon: const Icon(
//                 Icons.menu_rounded,
//                 color: Colors.black,
//                 size: 32,
//               ),
//               onPressed: () => Scaffold.of(context).openDrawer(),
//             );
//           },
//         ),
//         actions: [
//           Container(
//             margin: const EdgeInsets.only(right: 20),
//             padding: const EdgeInsets.all(2),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: const Color(0xFF2E7D32), width: 2),
//             ),
//             child: const CircleAvatar(
//               radius: 16,
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, size: 24, color: Color(0xFF2E7D32)),
//             ),
//           ),
//         ],
//       ),

//       drawer: _buildDrawer(),

//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             FadeInDown(
//               child: Text(
//                 "Welcome Back,",
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ),
//             FadeInDown(
//               delay: const Duration(milliseconds: 100),
//               child: Text(
//                 "Agri-Manager",
//                 style: GoogleFonts.poppins(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: const Color(0xFF191825),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 30),

//             FadeInUp(
//               delay: const Duration(milliseconds: 200),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(25),
//                 decoration: BoxDecoration(
//                   color: cardBgColor,
//                   borderRadius: BorderRadius.circular(24),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.2),
//                       blurRadius: 15,
//                       offset: const Offset(0, 8),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           "System Status",
//                           style: GoogleFonts.poppins(
//                             color: Colors.grey[400],
//                             fontSize: 14,
//                           ),
//                         ),
//                         Icon(
//                           _isConnectedToWifi ? Icons.wifi : Icons.wifi_off,
//                           color: _isConnectedToWifi
//                               ? Colors.greenAccent
//                               : Colors.redAccent,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 20),

//                     Text(
//                       _statusMessage,
//                       style: GoogleFonts.poppins(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 25),

//                     if (_isTransferring)
//                       Column(
//                         children: [
//                           LinearProgressIndicator(
//                             value: _progress,
//                             backgroundColor: Colors.white10,
//                             color: btnColor,
//                           ),
//                           const SizedBox(height: 10),
//                           Text(
//                             "${(_progress * 100).toInt()}%",
//                             style: const TextStyle(color: Colors.white70),
//                           ),
//                         ],
//                       )
//                     else
//                       SizedBox(
//                         width: double.infinity,
//                         height: 50,
//                         child: ElevatedButton.icon(
//                           onPressed: startSyncProcess,
//                           icon: const Icon(
//                             Icons.sync_outlined,
//                             color: Colors.black,
//                           ),
//                           label: Text(
//                             "Receive Data",
//                             style: GoogleFonts.poppins(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 16,
//                             ),
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: btnColor,
//                             foregroundColor: Colors.black,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 0,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 40),
//             Text(
//               "Recent Received Files",
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 15),

//             Expanded(
//               child: _receivedFiles.isEmpty
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.folder_outlined,
//                             size: 60,
//                             color: Colors.grey[300],
//                           ),
//                           const SizedBox(height: 15),
//                           Text(
//                             "No files received yet",
//                             style: TextStyle(color: Colors.grey[400]),
//                           ),
//                         ],
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: _receivedFiles.length,
//                       itemBuilder: (context, index) {
//                         String path = _receivedFiles[index];
//                         String name = path.split('/').last;

//                         // Dynamic Icon Logic
//                         IconData fileIcon = Icons.insert_drive_file;
//                         Color iconColor = Colors.grey;
//                         if (name.toLowerCase().endsWith('.jpg') ||
//                             name.toLowerCase().endsWith('.png')) {
//                           fileIcon = Icons.image;
//                           iconColor = Colors.purple;
//                         } else if (name.toLowerCase().endsWith('.csv')) {
//                           fileIcon = Icons.table_chart;
//                           iconColor = Colors.green;
//                         } else if (name.toLowerCase().endsWith('.zip')) {
//                           fileIcon = Icons.folder_zip;
//                           iconColor = Colors.orange;
//                         }

//                         return FadeInUp(
//                           duration: const Duration(milliseconds: 300),
//                           child: Card(
//                             elevation: 0,
//                             color: Colors.white,
//                             margin: const EdgeInsets.only(bottom: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: ListTile(
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 20,
//                                 vertical: 8,
//                               ),
//                               leading: Container(
//                                 padding: const EdgeInsets.all(10),
//                                 decoration: BoxDecoration(
//                                   color: iconColor.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 child: Icon(fileIcon, color: iconColor),
//                               ),
//                               title: Text(
//                                 name,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               subtitle: Text(
//                                 "Tap to open",
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[500],
//                                 ),
//                               ),
//                               onTap: () => OpenFile.open(path),
//                               trailing: const Icon(
//                                 Icons.chevron_right,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       backgroundColor: Colors.white,
//       child: Column(
//         children: [
//           UserAccountsDrawerHeader(
//             decoration: const BoxDecoration(color: Color(0xFF191825)),
//             accountName: Text(
//               "Admin User",
//               style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             accountEmail: Text(
//               "admin@itc.project",
//               style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
//             ),
//             currentAccountPicture: const CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, size: 40, color: Color(0xFF191825)),
//             ),
//           ),
//           const SizedBox(height: 10),
//           _drawerItem(Icons.folder_outlined, "My Files", () {}),
//           _drawerItem(Icons.settings_outlined, "Settings", () {}),
//           _drawerItem(Icons.info_outline, "About", () {}),
//           const Spacer(),
//           const Divider(),
//           _drawerItem(Icons.logout, "Logout", () {}, isDestructive: true),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _drawerItem(
//     IconData icon,
//     String title,
//     VoidCallback onTap, {
//     bool isDestructive = false,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey[800]),
//       title: Text(
//         title,
//         style: GoogleFonts.poppins(
//           color: isDestructive ? Colors.red : Colors.black87,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       onTap: () {
//         Navigator.pop(context);
//         onTap();
//       },
//     );
//   }
// }

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:animate_do/animate_do.dart';

// // --- CONFIGURATION ---
// const String SECRET_KEY = "securekey";
// const int TCP_PORT = 5001;
// const int DISCOVERY_PORT = 5000;

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'AgriSync',
//       theme: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: const Color(0xFFF4F7F6),
//         primaryColor: const Color(0xFF2E7D32),
//         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
//         textTheme: GoogleFonts.poppinsTextTheme(),
//       ),
//       home: const HomeScreen(),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // --- STATE VARIABLES ---
//   String _statusMessage = "Please connect to 'FileShareHotspot'";
//   bool _isConnectedToWifi = false;
//   bool _isTransferring = false;
//   double _progress = 0.0;

//   // List of Saved Batches (Folders)
//   List<FileSystemEntity> _batchFolders = [];

//   final Connectivity _connectivity = Connectivity();
//   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _checkInitialConnection();
//     _loadSavedBatches(); // Load history on startup

//     _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
//       result,
//     ) {
//       _updateConnectionStatus(result);
//     });
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     super.dispose();
//   }

//   // --- 1. FILE SYSTEM & PERSISTENCE ---
//   Future<Directory> _getPublicDir() async {
//     // Saves to: Internal Storage > Download > AgriSync_Files
//     // This is the standard public Downloads folder
//     Directory dir = Directory('/storage/emulated/0/Download/AgriSync_Files');
//     if (!await dir.exists()) {
//       try {
//         await dir.create(recursive: true);
//       } catch (e) {
//         debugPrint("Error creating directory: $e");
//         // Fallback for older Androids or emulators
//         dir =
//             await getExternalStorageDirectory() ??
//             await getApplicationDocumentsDirectory();
//       }
//     }
//     return dir;
//   }

//   Future<void> _loadSavedBatches() async {
//     try {
//       final dir = await _getPublicDir();
//       if (await dir.exists()) {
//         final entities = dir.listSync();
//         setState(() {
//           // Get folders only and sort by newest first
//           _batchFolders = entities.whereType<Directory>().toList()
//             ..sort(
//               (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
//             );
//         });
//       }
//     } catch (e) {
//       debugPrint("Error loading batches: $e");
//     }
//   }

//   // --- 2. PERMISSIONS & WIFI ---
//   Future<void> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       // 1. Request standard storage permissions
//       var status = await Permission.storage.request();

//       // 2. Request "Manage All Files" for Android 11+
//       if (await Permission.manageExternalStorage.status.isDenied) {
//         await Permission.manageExternalStorage.request();
//       }

//       await [Permission.location, Permission.nearbyWifiDevices].request();
//     }
//   }

//   void _checkInitialConnection() async {
//     var result = await _connectivity.checkConnectivity();
//     _updateConnectionStatus(result);
//   }

//   void _updateConnectionStatus(ConnectivityResult result) async {
//     bool hasWifi = result == ConnectivityResult.wifi;
//     if (hasWifi && !_isConnectedToWifi) {
//       _showBottomNotification("WiFi Connected! Ready to Sync.");
//     }
//     setState(() {
//       _isConnectedToWifi = hasWifi;
//       _statusMessage = hasWifi
//           ? "Connected to WiFi. Ready to receive."
//           : "Please connect to 'FileShareHotspot'";
//     });
//   }

//   // --- 3. TRANSFER LOGIC (Session-Based) ---
//   Future<void> startSyncProcess() async {
//     if (!_isConnectedToWifi) {
//       _showBottomNotification(
//         "No WiFi Connection! Check Settings.",
//         isError: true,
//       );
//       return;
//     }

//     // Check Permission Again before starting
//     if (Platform.isAndroid &&
//         !(await Permission.manageExternalStorage.isGranted)) {
//       await Permission.manageExternalStorage.request();
//       // If still denied, try standard storage
//       if (!(await Permission.storage.isGranted)) {
//         _showBottomNotification("Storage Permission Required!", isError: true);
//         return;
//       }
//     }

//     setState(() {
//       _isTransferring = true;
//       _progress = 0.1;
//       _statusMessage = "Locating Server...";
//     });

//     try {
//       final info = NetworkInfo();
//       var wifiIP = await info.getWifiIP();
//       var gatewayIp = await info.getWifiGatewayIP();
//       String targetIp = (gatewayIp != null && gatewayIp != "0.0.0.0")
//           ? gatewayIp
//           : "10.42.0.1";

//       setState(() {
//         _statusMessage = "Connecting to $targetIp...";
//         _progress = 0.2;
//       });

//       // 1. Create a Unique Folder for this Session
//       String timestamp = DateTime.now()
//           .toString()
//           .replaceAll(RegExp(r'[^0-9]'), '')
//           .substring(0, 12);
//       String batchName = "Batch_$timestamp"; // e.g., Batch_202601121830

//       Directory rootDir = await _getPublicDir();
//       Directory sessionDir = Directory("${rootDir.path}/$batchName");

//       if (!await sessionDir.exists()) {
//         await sessionDir.create(recursive: true);
//       }

//       // 2. Receive Files into that Folder
//       await _receiveFiles(targetIp, TCP_PORT, wifiIP, sessionDir);

//       // 3. Refresh List
//       await _loadSavedBatches();
//     } catch (e) {
//       setState(() {
//         _statusMessage = "Connection Failed";
//         _isTransferring = false;
//         _progress = 0.0;
//       });
//       _showBottomNotification("Error: ${e.toString()}", isError: true);
//     }
//   }

//   Future<void> _receiveFiles(
//     String ip,
//     int port,
//     String? sourceIP,
//     Directory sessionDir,
//   ) async {
//     Socket? socket;
//     int retryCount = 0;

//     while (socket == null && retryCount < 3) {
//       try {
//         socket = await Socket.connect(
//           ip,
//           port,
//           sourceAddress: sourceIP,
//           timeout: const Duration(seconds: 5),
//         );
//       } catch (e) {
//         retryCount++;
//         await Future.delayed(const Duration(seconds: 1));
//       }
//     }

//     if (socket == null) throw Exception("Could not connect to Server.");

//     try {
//       socket.add(utf8.encode(SECRET_KEY));
//       await socket.flush();

//       StreamIterator<Uint8List> reader = StreamIterator(socket);
//       if (!await _readUntil(reader, "OK")) throw Exception("Auth Failed");

//       String header = await _readHeader(reader);
//       socket.add(utf8.encode("OK"));
//       await socket.flush();

//       if (header.startsWith("NUM_FILES")) {
//         int count = int.parse(header.split("|")[1]);
//         for (int i = 0; i < count; i++) {
//           setState(() {
//             _statusMessage = "Downloading file ${i + 1}/$count...";
//             _progress = (i + 1) / (count + 1);
//           });
//           await _downloadSingleFile(reader, socket, sessionDir);
//         }
//       }

//       setState(() {
//         _isTransferring = false;
//         _statusMessage = "Transfer Complete!";
//         _progress = 1.0;
//       });
//       _showBottomNotification("Saved to: ${sessionDir.path.split('/').last}");
//     } finally {
//       socket.destroy();
//     }
//   }

//   Future<void> _downloadSingleFile(
//     StreamIterator<Uint8List> reader,
//     Socket socket,
//     Directory dir,
//   ) async {
//     String header = await _readHeader(reader);
//     var parts = header.split("|");
//     // Ensure filename is safe (remove paths like 'folder/image.jpg')
//     String filename = parts[0].split('/').last.split('\\').last;
//     int filesize = int.parse(parts[1]);

//     socket.add(utf8.encode("OK"));
//     await socket.flush();

//     File file = File("${dir.path}/$filename");
//     IOSink sink = file.openWrite();

//     int received = 0;
//     while (received < filesize) {
//       if (await reader.moveNext()) {
//         Uint8List chunk = reader.current;
//         int remaining = filesize - received;
//         if (chunk.length > remaining) {
//           sink.add(chunk.sublist(0, remaining));
//           received += remaining;
//         } else {
//           sink.add(chunk);
//           received += chunk.length;
//         }
//       } else {
//         break;
//       }
//     }
//     await sink.flush();
//     await sink.close();

//     // Verify file size
//     if (await file.length() == 0) {
//       debugPrint("Warning: File $filename is empty!");
//     } else {
//       debugPrint("File Saved: ${file.path}");
//     }
//   }

//   Future<bool> _readUntil(
//     StreamIterator<Uint8List> reader,
//     String target,
//   ) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current).contains(target);
//     }
//     return false;
//   }

//   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current);
//     }
//     throw Exception("Connection closed");
//   }

//   void _showBottomNotification(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B5E20),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // --- 4. UI BUILDING ---
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF4F7F6),
//         elevation: 0,
//         leading: Builder(
//           builder: (c) => IconButton(
//             icon: const Icon(Icons.menu_rounded, size: 32),
//             onPressed: () => Scaffold.of(c).openDrawer(),
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 20),
//             child: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF2E7D32)),
//             ),
//           ),
//         ],
//       ),
//       drawer: _buildDrawer(),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Welcome Back,",
//               style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
//             ),
//             Text(
//               "Agri-Manager",
//               style: GoogleFonts.poppins(
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF191825),
//               ),
//             ),
//             const SizedBox(height: 30),

//             // Status Card
//             Container(
//               padding: const EdgeInsets.all(25),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A1F30),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 10,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "System Status",
//                         style: GoogleFonts.poppins(color: Colors.grey[400]),
//                       ),
//                       Icon(
//                         _isConnectedToWifi ? Icons.wifi : Icons.wifi_off,
//                         color: _isConnectedToWifi
//                             ? Colors.greenAccent
//                             : Colors.redAccent,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     _statusMessage,
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.poppins(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 25),
//                   if (_isTransferring)
//                     LinearProgressIndicator(
//                       value: _progress,
//                       backgroundColor: Colors.white10,
//                       color: const Color(0xFFC8F000),
//                     )
//                   else
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton.icon(
//                         onPressed: startSyncProcess,
//                         icon: const Icon(
//                           Icons.sync_outlined,
//                           color: Colors.black,
//                         ),
//                         label: Text(
//                           "Receive Data",
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFC8F000),
//                           foregroundColor: Colors.black,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),
//             Text(
//               "Received Batches",
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),

//             // Batch List (Persistent History)
//             Expanded(
//               child: _batchFolders.isEmpty
//                   ? Center(
//                       child: Text(
//                         "No batches received yet",
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: _batchFolders.length,
//                       itemBuilder: (context, index) {
//                         Directory dir = _batchFolders[index] as Directory;
//                         String name = dir.path.split('/').last;
//                         // Format: Batch_202601121830 -> 2026-01-12 18:30
//                         String dateStr = name.replaceAll("Batch_", "");
//                         return Card(
//                           elevation: 0,
//                           color: Colors.white,
//                           margin: const EdgeInsets.only(bottom: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: ListTile(
//                             leading: Container(
//                               padding: const EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFE3F2FD),
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: const Icon(
//                                 Icons.folder_open,
//                                 color: Color(0xFF1565C0),
//                               ),
//                             ),
//                             title: Text(
//                               name,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             subtitle: Text("Tap to view files"),
//                             trailing: const Icon(
//                               Icons.chevron_right,
//                               color: Colors.grey,
//                             ),
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       FolderDetailScreen(directory: dir),
//                                 ),
//                               );
//                             },
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       backgroundColor: Colors.white,
//       child: Column(
//         children: [
//           const UserAccountsDrawerHeader(
//             decoration: BoxDecoration(color: Color(0xFF191825)),
//             accountName: Text(
//               "Admin User",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             accountEmail: Text("admin@itc.project"),
//             currentAccountPicture: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF191825)),
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.folder_copy),
//             title: const Text("My Files"),
//             onTap: () {
//               Navigator.pop(context);
//               // Just closes drawer as current screen IS the file viewer
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// // --- UPDATED SCREEN: FOLDER DETAIL VIEW (Now Stateful) ---
// class FolderDetailScreen extends StatefulWidget {
//   final Directory directory;

//   const FolderDetailScreen({super.key, required this.directory});

//   @override
//   State<FolderDetailScreen> createState() => _FolderDetailScreenState();
// }

// class _FolderDetailScreenState extends State<FolderDetailScreen> {
//   List<FileSystemEntity> _files = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadFiles();
//   }

//   // Load files when screen opens
//   void _loadFiles() {
//     try {
//       if (widget.directory.existsSync()) {
//         final files = widget.directory.listSync().whereType<File>().toList()
//           ..sort((a, b) => a.path.compareTo(b.path));
//         setState(() {
//           _files = files;
//         });

//         if (files.isEmpty) {
//           debugPrint("Folder exists but is empty: ${widget.directory.path}");
//         }
//       } else {
//         debugPrint("Folder does not exist: ${widget.directory.path}");
//       }
//     } catch (e) {
//       debugPrint("Error listing files: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.directory.path.split('/').last,
//           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       backgroundColor: const Color(0xFFF4F7F6),
//       body: _files.isEmpty
//           ? const Center(child: Text("Empty Folder (No files found)"))
//           : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _files.length,
//               itemBuilder: (context, index) {
//                 File file = _files[index] as File;
//                 String name = file.path.split('/').last;
//                 String ext = name.split('.').last.toLowerCase();

//                 // Dynamic Icon & Color
//                 IconData icon = Icons.insert_drive_file;
//                 Color color = Colors.grey;

//                 // Case-insensitive check
//                 if (['jpg', 'jpeg', 'png', 'bmp'].contains(ext)) {
//                   icon = Icons.image;
//                   color = Colors.purple;
//                 } else if (['csv', 'txt', 'pdf'].contains(ext)) {
//                   icon = Icons.table_chart;
//                   color = Colors.green;
//                 }

//                 return Card(
//                   elevation: 0,
//                   color: Colors.white,
//                   margin: const EdgeInsets.only(bottom: 10),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: ListTile(
//                     leading: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: color.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(icon, color: color),
//                     ),
//                     title: Text(
//                       name,
//                       style: const TextStyle(fontWeight: FontWeight.w500),
//                     ),
//                     subtitle: Text(
//                       "${(file.lengthSync() / 1024).toStringAsFixed(1)} KB",
//                     ), // Show size
//                     trailing: const Icon(
//                       Icons.open_in_new,
//                       size: 20,
//                       color: Colors.grey,
//                     ),
//                     onTap: () => _openFile(context, file.path),
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   void _openFile(BuildContext context, String path) async {
//     try {
//       final result = await OpenFile.open(path);
//       if (result.type != ResultType.done) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "Error: ${result.message} (Try installing a viewer app)",
//             ),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Cannot open: $e"), backgroundColor: Colors.red),
//       );
//     }
//   }
// }

// 13/01/26  1 15/01/2026

// 16/01/26 FIRST
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:archive/archive_io.dart'; // Import for Unzipping

// // --- CONFIGURATION ---
// const String SECRET_KEY = "securekey";
// const int TCP_PORT = 5001;

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'AgriSync',
//       theme: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: const Color(0xFFF4F7F6),
//         primaryColor: const Color(0xFF2E7D32),
//         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
//         textTheme: GoogleFonts.poppinsTextTheme(),
//       ),
//       home: const HomeScreen(),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // --- STATE VARIABLES ---
//   String _statusMessage = "Please connect to 'FileShareHotspot'";
//   bool _isConnectedToWifi = false;
//   bool _isTransferring = false;
//   double _progress = 0.0;

//   // List of Saved Batches (Folders)
//   List<FileSystemEntity> _batchFolders = [];

//   final Connectivity _connectivity = Connectivity();
//   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _checkInitialConnection();
//     _loadSavedBatches(); // Load history on startup

//     _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
//       result,
//     ) {
//       _updateConnectionStatus(result);
//     });
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     super.dispose();
//   }

//   // --- 1. FILE SYSTEM & PERSISTENCE ---
//   Future<Directory> _getPublicDir() async {
//     // Saves to: Internal Storage > Download > AgriSync_Files
//     Directory dir = Directory('/storage/emulated/0/Download/AgriSync_Files');
//     if (!await dir.exists()) {
//       try {
//         await dir.create(recursive: true);
//       } catch (e) {
//         debugPrint("Error creating directory: $e");
//         dir =
//             await getExternalStorageDirectory() ??
//             await getApplicationDocumentsDirectory();
//       }
//     }
//     return dir;
//   }

//   Future<void> _loadSavedBatches() async {
//     try {
//       final dir = await _getPublicDir();
//       if (await dir.exists()) {
//         final entities = dir.listSync();
//         setState(() {
//           // Get folders only and sort by newest first
//           _batchFolders = entities.whereType<Directory>().toList()
//             ..sort(
//               (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
//             );
//         });
//       }
//     } catch (e) {
//       debugPrint("Error loading batches: $e");
//     }
//   }

//   // --- 2. PERMISSIONS & WIFI ---
//   Future<void> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       await Permission.storage.request();
//       if (await Permission.manageExternalStorage.status.isDenied) {
//         await Permission.manageExternalStorage.request();
//       }
//       await [Permission.location, Permission.nearbyWifiDevices].request();
//     }
//   }

//   void _checkInitialConnection() async {
//     var result = await _connectivity.checkConnectivity();
//     _updateConnectionStatus(result);
//   }

//   void _updateConnectionStatus(ConnectivityResult result) async {
//     bool hasWifi = result == ConnectivityResult.wifi;
//     if (hasWifi && !_isConnectedToWifi) {
//       _showBottomNotification("WiFi Connected! Ready to Sync.");
//     }
//     setState(() {
//       _isConnectedToWifi = hasWifi;
//       _statusMessage = hasWifi
//           ? "Connected to WiFi. Ready to receive."
//           : "Please connect to 'FileShareHotspot'";
//     });
//   }

//   // --- 3. TRANSFER LOGIC ---
//   Future<void> startSyncProcess() async {
//     if (!_isConnectedToWifi) {
//       _showBottomNotification(
//         "No WiFi Connection! Check Settings.",
//         isError: true,
//       );
//       return;
//     }

//     if (Platform.isAndroid &&
//         !(await Permission.manageExternalStorage.isGranted)) {
//       await Permission.manageExternalStorage.request();
//       if (!(await Permission.storage.isGranted)) return;
//     }

//     setState(() {
//       _isTransferring = true;
//       _progress = 0.1;
//       _statusMessage = "Locating Server...";
//     });

//     try {
//       final info = NetworkInfo();
//       var wifiIP = await info.getWifiIP();
//       var gatewayIp = await info.getWifiGatewayIP();
//       String targetIp = (gatewayIp != null && gatewayIp != "0.0.0.0")
//           ? gatewayIp
//           : "10.42.0.1";

//       setState(() {
//         _statusMessage = "Connecting to $targetIp...";
//         _progress = 0.2;
//       });

//       // 1. Create a Unique Folder for this Session
//       String timestamp = DateTime.now()
//           .toString()
//           .replaceAll(RegExp(r'[^0-9]'), '')
//           .substring(0, 12);
//       String batchName = "Batch_$timestamp";

//       Directory rootDir = await _getPublicDir();
//       Directory sessionDir = Directory("${rootDir.path}/$batchName");

//       if (!await sessionDir.exists()) {
//         await sessionDir.create(recursive: true);
//       }

//       // 2. Receive Files into that Folder
//       await _receiveFiles(targetIp, TCP_PORT, wifiIP, sessionDir);

//       // 3. Refresh List
//       await _loadSavedBatches();
//     } catch (e) {
//       setState(() {
//         _statusMessage = "Connection Failed";
//         _isTransferring = false;
//         _progress = 0.0;
//       });
//       _showBottomNotification("Error: ${e.toString()}", isError: true);
//     }
//   }

//   Future<void> _receiveFiles(
//     String ip,
//     int port,
//     String? sourceIP,
//     Directory sessionDir,
//   ) async {
//     Socket? socket;
//     int retryCount = 0;

//     while (socket == null && retryCount < 3) {
//       try {
//         socket = await Socket.connect(
//           ip,
//           port,
//           sourceAddress: sourceIP,
//           timeout: const Duration(seconds: 5),
//         );
//       } catch (e) {
//         retryCount++;
//         await Future.delayed(const Duration(seconds: 1));
//       }
//     }

//     if (socket == null) throw Exception("Could not connect to Server.");

//     try {
//       socket.add(utf8.encode(SECRET_KEY));
//       await socket.flush();

//       StreamIterator<Uint8List> reader = StreamIterator(socket);
//       if (!await _readUntil(reader, "OK")) throw Exception("Auth Failed");

//       String header = await _readHeader(reader);
//       socket.add(utf8.encode("OK"));
//       await socket.flush();

//       if (header.startsWith("NUM_FILES")) {
//         int count = int.parse(header.split("|")[1]);
//         for (int i = 0; i < count; i++) {
//           setState(() {
//             _statusMessage = "Downloading file ${i + 1}/$count...";
//             _progress = (i + 1) / (count + 1);
//           });
//           await _downloadSingleFile(reader, socket, sessionDir);
//         }
//       }

//       setState(() {
//         _isTransferring = false;
//         _statusMessage = "Transfer Complete!";
//         _progress = 1.0;
//       });
//       _showBottomNotification("Saved to: ${sessionDir.path.split('/').last}");
//     } finally {
//       socket.destroy();
//     }
//   }

//   Future<void> _downloadSingleFile(
//     StreamIterator<Uint8List> reader,
//     Socket socket,
//     Directory dir,
//   ) async {
//     String header = await _readHeader(reader);
//     var parts = header.split("|");
//     String filename = parts[0].split('/').last.split('\\').last;
//     int filesize = int.parse(parts[1]);

//     socket.add(utf8.encode("OK"));
//     await socket.flush();

//     File file = File("${dir.path}/$filename");
//     IOSink sink = file.openWrite();

//     int received = 0;
//     while (received < filesize) {
//       if (await reader.moveNext()) {
//         Uint8List chunk = reader.current;
//         int remaining = filesize - received;
//         if (chunk.length > remaining) {
//           sink.add(chunk.sublist(0, remaining));
//           received += remaining;
//         } else {
//           sink.add(chunk);
//           received += chunk.length;
//         }
//       } else {
//         break;
//       }
//     }
//     await sink.flush();
//     await sink.close();
//   }

//   Future<bool> _readUntil(
//     StreamIterator<Uint8List> reader,
//     String target,
//   ) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current).contains(target);
//     }
//     return false;
//   }

//   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current);
//     }
//     throw Exception("Connection closed");
//   }

//   void _showBottomNotification(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B5E20),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // --- 4. UI BUILDING ---
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF4F7F6),
//         elevation: 0,
//         leading: Builder(
//           builder: (c) => IconButton(
//             icon: const Icon(Icons.menu_rounded, size: 32),
//             onPressed: () => Scaffold.of(c).openDrawer(),
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 20),
//             child: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF2E7D32)),
//             ),
//           ),
//         ],
//       ),
//       drawer: _buildDrawer(),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Welcome Back,",
//               style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
//             ),
//             Text(
//               "Agri-Manager",
//               style: GoogleFonts.poppins(
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF191825),
//               ),
//             ),
//             const SizedBox(height: 30),

//             // Status Card
//             Container(
//               padding: const EdgeInsets.all(25),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A1F30),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 10,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "System Status",
//                         style: GoogleFonts.poppins(color: Colors.grey[400]),
//                       ),
//                       Icon(
//                         _isConnectedToWifi ? Icons.wifi : Icons.wifi_off,
//                         color: _isConnectedToWifi
//                             ? Colors.greenAccent
//                             : Colors.redAccent,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     _statusMessage,
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.poppins(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 25),
//                   if (_isTransferring)
//                     LinearProgressIndicator(
//                       value: _progress,
//                       backgroundColor: Colors.white10,
//                       color: const Color(0xFFC8F000),
//                     )
//                   else
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton.icon(
//                         onPressed: startSyncProcess,
//                         icon: const Icon(
//                           Icons.sync_outlined,
//                           color: Colors.black,
//                         ),
//                         label: Text(
//                           "Receive Data",
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFC8F000),
//                           foregroundColor: Colors.black,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),
//             Text(
//               "My Files",
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),

//             // Batch List
//             Expanded(
//               child: _batchFolders.isEmpty
//                   ? Center(
//                       child: Text(
//                         "No batches received yet",
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: _batchFolders.length,
//                       itemBuilder: (context, index) {
//                         Directory dir = _batchFolders[index] as Directory;
//                         String name = dir.path.split('/').last;
//                         return Card(
//                           elevation: 0,
//                           color: Colors.white,
//                           margin: const EdgeInsets.only(bottom: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: ListTile(
//                             leading: Container(
//                               padding: const EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFE3F2FD),
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: const Icon(
//                                 Icons.folder_open,
//                                 color: Color(0xFF1565C0),
//                               ),
//                             ),
//                             title: Text(
//                               name,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             subtitle: Text("Tap to view files"),
//                             trailing: const Icon(
//                               Icons.chevron_right,
//                               color: Colors.grey,
//                             ),
//                             onTap: () async {
//                               // Navigate and wait for result (in case zip extracted)
//                               await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       FolderDetailScreen(directory: dir),
//                                 ),
//                               );
//                               // Refresh list when coming back
//                               _loadSavedBatches();
//                             },
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       backgroundColor: Colors.white,
//       child: Column(
//         children: [
//           const UserAccountsDrawerHeader(
//             decoration: BoxDecoration(color: Color(0xFF191825)),
//             accountName: Text(
//               "Admin User",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             accountEmail: Text("admin@itc.project"),
//             currentAccountPicture: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF191825)),
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.folder_copy),
//             title: const Text("My Files"),
//             onTap: () {
//               // Since 'Home' IS the file viewer, just close drawer
//               Navigator.pop(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// // --- UPDATED SCREEN: FOLDER DETAIL VIEW ---
// class FolderDetailScreen extends StatefulWidget {
//   final Directory directory;

//   const FolderDetailScreen({super.key, required this.directory});

//   @override
//   State<FolderDetailScreen> createState() => _FolderDetailScreenState();
// }

// class _FolderDetailScreenState extends State<FolderDetailScreen> {
//   List<FileSystemEntity> _files = [];
//   bool _isProcessing = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadFiles();
//   }

//   void _loadFiles() {
//     try {
//       if (widget.directory.existsSync()) {
//         final files = widget.directory.listSync().whereType<File>().toList()
//           ..sort((a, b) => a.path.compareTo(b.path));
//         setState(() {
//           _files = files;
//         });
//       }
//     } catch (e) {
//       debugPrint("Error listing files: $e");
//     }
//   }

//   // --- LOGIC: UNZIP FILES INTERNALLY ---
//   Future<void> _handleZipFile(File zipFile) async {
//     setState(() => _isProcessing = true);

//     try {
//       final bytes = zipFile.readAsBytesSync();
//       final archive = ZipDecoder().decodeBytes(bytes);

//       // Extract to the same directory
//       for (final file in archive) {
//         final filename = file.name;
//         if (file.isFile) {
//           final data = file.content as List<int>;
//           File('${widget.directory.path}/$filename')
//             ..createSync(recursive: true)
//             ..writeAsBytesSync(data);
//         } else {
//           Directory(
//             '${widget.directory.path}/$filename',
//           ).create(recursive: true);
//         }
//       }

//       // Optional: Delete the zip after extraction to clean up
//       // zipFile.deleteSync();

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Unzip Successful!")));

//       _loadFiles(); // Refresh list to show extracted files
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Unzip Failed: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isProcessing = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.directory.path.split('/').last,
//           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       backgroundColor: const Color(0xFFF4F7F6),
//       body: _isProcessing
//           ? const Center(child: CircularProgressIndicator())
//           : _files.isEmpty
//           ? const Center(child: Text("Empty Folder"))
//           : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _files.length,
//               itemBuilder: (context, index) {
//                 File file = _files[index] as File;
//                 String name = file.path.split('/').last;
//                 String ext = name.split('.').last.toLowerCase();

//                 IconData icon = Icons.insert_drive_file;
//                 Color color = Colors.grey;
//                 bool isZip = false;

//                 if (['jpg', 'jpeg', 'png'].contains(ext)) {
//                   icon = Icons.image;
//                   color = Colors.purple;
//                 } else if (ext == 'pdf') {
//                   icon = Icons.picture_as_pdf;
//                   color = Colors.red;
//                 } else if (ext == 'zip') {
//                   icon = Icons.folder_zip;
//                   color = Colors.orange;
//                   isZip = true;
//                 }

//                 return Card(
//                   elevation: 0,
//                   color: Colors.white,
//                   margin: const EdgeInsets.only(bottom: 10),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: ListTile(
//                     leading: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: color.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(icon, color: color),
//                     ),
//                     title: Text(
//                       name,
//                       style: const TextStyle(fontWeight: FontWeight.w500),
//                     ),
//                     subtitle: Text(
//                       isZip
//                           ? "Tap to Unzip"
//                           : "${(file.lengthSync() / 1024).toStringAsFixed(1)} KB",
//                     ),
//                     trailing: Icon(
//                       isZip ? Icons.system_update_alt : Icons.open_in_new,
//                       size: 20,
//                       color: Colors.grey,
//                     ),
//                     onTap: () {
//                       if (isZip) {
//                         _handleZipFile(file);
//                       } else {
//                         _openFile(context, file.path);
//                       }
//                     },
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   void _openFile(BuildContext context, String path) async {
//     try {
//       final result = await OpenFile.open(path);
//       if (result.type != ResultType.done) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Could not open file: ${result.message}"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
//       );
//     }
//   }
// }

// // 16/01/26 SECOND 18/01/2026
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:archive/archive_io.dart'; // Import for Unzipping

// // --- CONFIGURATION ---
// const String SECRET_KEY = "securekey";
// const int TCP_PORT = 5001;
// const int UDP_PORT = 5000; // Added for Discovery

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'AgriSync',
//       theme: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: const Color(0xFFF4F7F6),
//         primaryColor: const Color(0xFF2E7D32),
//         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
//         textTheme: GoogleFonts.poppinsTextTheme(),
//       ),
//       home: const HomeScreen(),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // --- STATE VARIABLES ---
//   String _statusMessage = "Please connect to 'FileShareHotspot'";
//   bool _isConnectedToWifi = false;
//   bool _isTransferring = false;
//   double _progress = 0.0;

//   // List of Saved Batches (Folders)
//   List<FileSystemEntity> _batchFolders = [];

//   final Connectivity _connectivity = Connectivity();
//   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _checkInitialConnection();
//     _loadSavedBatches(); // Load history on startup

//     _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
//       result,
//     ) {
//       _updateConnectionStatus(result);
//     });
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     super.dispose();
//   }

//   // --- 1. FILE SYSTEM & PERSISTENCE ---
//   Future<Directory> _getPublicDir() async {
//     // Saves to: Internal Storage > Download > AgriSync_Files
//     Directory dir = Directory('/storage/emulated/0/Download/AgriSync_Files');
//     if (!await dir.exists()) {
//       try {
//         await dir.create(recursive: true);
//       } catch (e) {
//         debugPrint("Error creating directory: $e");
//         dir =
//             await getExternalStorageDirectory() ??
//             await getApplicationDocumentsDirectory();
//       }
//     }
//     return dir;
//   }

//   Future<void> _loadSavedBatches() async {
//     try {
//       final dir = await _getPublicDir();
//       if (await dir.exists()) {
//         final entities = dir.listSync();
//         setState(() {
//           // Get folders only and sort by newest first
//           _batchFolders = entities.whereType<Directory>().toList()
//             ..sort(
//               (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
//             );
//         });
//       }
//     } catch (e) {
//       debugPrint("Error loading batches: $e");
//     }
//   }

//   // --- 2. PERMISSIONS & WIFI ---
//   Future<void> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       await Permission.storage.request();
//       if (await Permission.manageExternalStorage.status.isDenied) {
//         await Permission.manageExternalStorage.request();
//       }
//       await [Permission.location, Permission.nearbyWifiDevices].request();
//     }
//   }

//   void _checkInitialConnection() async {
//     var result = await _connectivity.checkConnectivity();
//     _updateConnectionStatus(result);
//   }

//   void _updateConnectionStatus(ConnectivityResult result) async {
//     bool hasWifi = result == ConnectivityResult.wifi;
//     if (hasWifi && !_isConnectedToWifi) {
//       _showBottomNotification("WiFi Connected! Ready to Sync.");
//     }
//     setState(() {
//       _isConnectedToWifi = hasWifi;
//       _statusMessage = hasWifi
//           ? "Connected to WiFi. Ready to receive."
//           : "Please connect to 'FileShareHotspot'";
//     });
//   }

//   // --- 3. TRANSFER LOGIC ---

//   // NEW: UDP Discovery Helper
//   Future<String?> _discoverServer(String? myIp) async {
//     if (myIp == null) return null;

//     RawDatagramSocket? socket;
//     try {
//       socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
//       socket.broadcastEnabled = true;

//       // Send Broadcast to Port 5000
//       socket.send(
//         utf8.encode(SECRET_KEY),
//         InternetAddress('255.255.255.255'),
//         UDP_PORT,
//       );
//       debugPrint("Sent UDP Broadcast...");

//       // Wait for response (Timeout 2 seconds)
//       var event = await socket
//           .firstWhere((event) => event == RawSocketEvent.read)
//           .timeout(const Duration(seconds: 2));

//       if (event == RawSocketEvent.read) {
//         Datagram? dg = socket.receive();
//         if (dg != null) {
//           String message = utf8.decode(dg.data).trim();
//           // Python sends: "IP|PORT"
//           var parts = message.split('|');
//           if (parts.isNotEmpty) {
//             return parts[0]; // Return the IP address
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("UDP Discovery Failed (Timeout or Error): $e");
//     } finally {
//       socket?.close();
//     }
//     return null;
//   }

//   Future<void> startSyncProcess() async {
//     if (!_isConnectedToWifi) {
//       _showBottomNotification(
//         "No WiFi Connection! Check Settings.",
//         isError: true,
//       );
//       return;
//     }

//     if (Platform.isAndroid &&
//         !(await Permission.manageExternalStorage.isGranted)) {
//       await Permission.manageExternalStorage.request();
//       if (!(await Permission.storage.isGranted)) return;
//     }

//     setState(() {
//       _isTransferring = true;
//       _progress = 0.1;
//       _statusMessage = "Locating Server (UDP)...";
//     });

//     try {
//       final info = NetworkInfo();
//       var wifiIP = await info.getWifiIP();

//       // --- CHANGED: Try UDP Discovery First ---
//       String? discoveredIp = await _discoverServer(wifiIP);

//       String targetIp;
//       if (discoveredIp != null) {
//         targetIp = discoveredIp;
//         debugPrint("UDP Discovery Successful: Found Server at $targetIp");
//       } else {
//         // Fallback to Gateway if UDP fails
//         var gatewayIp = await info.getWifiGatewayIP();
//         targetIp = (gatewayIp != null && gatewayIp != "0.0.0.0")
//             ? gatewayIp
//             : "10.42.0.1";
//         debugPrint("UDP Failed. Falling back to Gateway IP: $targetIp");
//       }

//       setState(() {
//         _statusMessage = "Connecting to $targetIp...";
//         _progress = 0.2;
//       });

//       // 1. Create a Unique Folder for this Session
//       String timestamp = DateTime.now()
//           .toString()
//           .replaceAll(RegExp(r'[^0-9]'), '')
//           .substring(0, 12);
//       String batchName = "Batch_$timestamp";

//       Directory rootDir = await _getPublicDir();
//       Directory sessionDir = Directory("${rootDir.path}/$batchName");

//       if (!await sessionDir.exists()) {
//         await sessionDir.create(recursive: true);
//       }

//       // 2. Receive Files into that Folder
//       await _receiveFiles(targetIp, TCP_PORT, wifiIP, sessionDir);

//       // 3. Refresh List
//       await _loadSavedBatches();
//     } catch (e) {
//       setState(() {
//         _statusMessage = "Connection Failed";
//         _isTransferring = false;
//         _progress = 0.0;
//       });
//       _showBottomNotification("Error: ${e.toString()}", isError: true);
//     }
//   }

//   Future<void> _receiveFiles(
//     String ip,
//     int port,
//     String? sourceIP,
//     Directory sessionDir,
//   ) async {
//     Socket? socket;
//     int retryCount = 0;

//     while (socket == null && retryCount < 3) {
//       try {
//         socket = await Socket.connect(
//           ip,
//           port,
//           sourceAddress: sourceIP,
//           timeout: const Duration(seconds: 5),
//         );
//       } catch (e) {
//         retryCount++;
//         await Future.delayed(const Duration(seconds: 1));
//       }
//     }

//     if (socket == null) throw Exception("Could not connect to Server.");

//     try {
//       socket.add(utf8.encode(SECRET_KEY));
//       await socket.flush();

//       StreamIterator<Uint8List> reader = StreamIterator(socket);
//       if (!await _readUntil(reader, "OK")) throw Exception("Auth Failed");

//       String header = await _readHeader(reader);
//       socket.add(utf8.encode("OK"));
//       await socket.flush();

//       if (header.startsWith("NUM_FILES")) {
//         int count = int.parse(header.split("|")[1]);
//         for (int i = 0; i < count; i++) {
//           setState(() {
//             _statusMessage = "Downloading file ${i + 1}/$count...";
//             _progress = (i + 1) / (count + 1);
//           });
//           await _downloadSingleFile(reader, socket, sessionDir);
//         }
//       }

//       setState(() {
//         _isTransferring = false;
//         _statusMessage = "Transfer Complete!";
//         _progress = 1.0;
//       });
//       _showBottomNotification("Saved to: ${sessionDir.path.split('/').last}");
//     } finally {
//       socket.destroy();
//     }
//   }

//   Future<void> _downloadSingleFile(
//     StreamIterator<Uint8List> reader,
//     Socket socket,
//     Directory dir,
//   ) async {
//     String header = await _readHeader(reader);
//     var parts = header.split("|");
//     String filename = parts[0].split('/').last.split('\\').last;
//     int filesize = int.parse(parts[1]);

//     socket.add(utf8.encode("OK"));
//     await socket.flush();

//     File file = File("${dir.path}/$filename");
//     IOSink sink = file.openWrite();

//     int received = 0;
//     while (received < filesize) {
//       if (await reader.moveNext()) {
//         Uint8List chunk = reader.current;
//         int remaining = filesize - received;
//         if (chunk.length > remaining) {
//           sink.add(chunk.sublist(0, remaining));
//           received += remaining;
//         } else {
//           sink.add(chunk);
//           received += chunk.length;
//         }
//       } else {
//         break;
//       }
//     }
//     await sink.flush();
//     await sink.close();
//   }

//   Future<bool> _readUntil(
//     StreamIterator<Uint8List> reader,
//     String target,
//   ) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current).contains(target);
//     }
//     return false;
//   }

//   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current);
//     }
//     throw Exception("Connection closed");
//   }

//   void _showBottomNotification(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B5E20),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // --- 4. UI BUILDING ---
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF4F7F6),
//         elevation: 0,
//         leading: Builder(
//           builder: (c) => IconButton(
//             icon: const Icon(Icons.menu_rounded, size: 32),
//             onPressed: () => Scaffold.of(c).openDrawer(),
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 20),
//             child: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF2E7D32)),
//             ),
//           ),
//         ],
//       ),
//       drawer: _buildDrawer(),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Welcome Back,",
//               style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
//             ),
//             Text(
//               "Agri-Manager",
//               style: GoogleFonts.poppins(
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF191825),
//               ),
//             ),
//             const SizedBox(height: 30),

//             // Status Card
//             Container(
//               padding: const EdgeInsets.all(25),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A1F30),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 10,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "System Status",
//                         style: GoogleFonts.poppins(color: Colors.grey[400]),
//                       ),
//                       Icon(
//                         _isConnectedToWifi ? Icons.wifi : Icons.wifi_off,
//                         color: _isConnectedToWifi
//                             ? Colors.greenAccent
//                             : Colors.redAccent,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     _statusMessage,
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.poppins(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 25),
//                   if (_isTransferring)
//                     LinearProgressIndicator(
//                       value: _progress,
//                       backgroundColor: Colors.white10,
//                       color: const Color(0xFFC8F000),
//                     )
//                   else
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton.icon(
//                         onPressed: startSyncProcess,
//                         icon: const Icon(
//                           Icons.sync_outlined,
//                           color: Colors.black,
//                         ),
//                         label: Text(
//                           "Receive Data",
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFC8F000),
//                           foregroundColor: Colors.black,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),
//             Text(
//               "My Files",
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),

//             // Batch List
//             Expanded(
//               child: _batchFolders.isEmpty
//                   ? Center(
//                       child: Text(
//                         "No batches received yet",
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: _batchFolders.length,
//                       itemBuilder: (context, index) {
//                         Directory dir = _batchFolders[index] as Directory;
//                         String name = dir.path.split('/').last;
//                         return Card(
//                           elevation: 0,
//                           color: Colors.white,
//                           margin: const EdgeInsets.only(bottom: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: ListTile(
//                             leading: Container(
//                               padding: const EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFE3F2FD),
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: const Icon(
//                                 Icons.folder_open,
//                                 color: Color(0xFF1565C0),
//                               ),
//                             ),
//                             title: Text(
//                               name,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             subtitle: Text("Tap to view files"),
//                             trailing: const Icon(
//                               Icons.chevron_right,
//                               color: Colors.grey,
//                             ),
//                             onTap: () async {
//                               // Navigate and wait for result (in case zip extracted)
//                               await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       FolderDetailScreen(directory: dir),
//                                 ),
//                               );
//                               // Refresh list when coming back
//                               _loadSavedBatches();
//                             },
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       backgroundColor: Colors.white,
//       child: Column(
//         children: [
//           const UserAccountsDrawerHeader(
//             decoration: BoxDecoration(color: Color(0xFF191825)),
//             accountName: Text(
//               "Admin User",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             accountEmail: Text("admin@itc.project"),
//             currentAccountPicture: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF191825)),
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.folder_copy),
//             title: const Text("My Files"),
//             onTap: () {
//               // Since 'Home' IS the file viewer, just close drawer
//               Navigator.pop(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// // --- UPDATED SCREEN: FOLDER DETAIL VIEW ---
// class FolderDetailScreen extends StatefulWidget {
//   final Directory directory;

//   const FolderDetailScreen({super.key, required this.directory});

//   @override
//   State<FolderDetailScreen> createState() => _FolderDetailScreenState();
// }

// class _FolderDetailScreenState extends State<FolderDetailScreen> {
//   List<FileSystemEntity> _files = [];
//   bool _isProcessing = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadFiles();
//   }

//   void _loadFiles() {
//     try {
//       if (widget.directory.existsSync()) {
//         final files = widget.directory.listSync().whereType<File>().toList()
//           ..sort((a, b) => a.path.compareTo(b.path));
//         setState(() {
//           _files = files;
//         });
//       }
//     } catch (e) {
//       debugPrint("Error listing files: $e");
//     }
//   }

//   // --- LOGIC: UNZIP FILES INTERNALLY ---
//   Future<void> _handleZipFile(File zipFile) async {
//     setState(() => _isProcessing = true);

//     try {
//       final bytes = zipFile.readAsBytesSync();
//       final archive = ZipDecoder().decodeBytes(bytes);

//       // Extract to the same directory
//       for (final file in archive) {
//         final filename = file.name;
//         if (file.isFile) {
//           final data = file.content as List<int>;
//           File('${widget.directory.path}/$filename')
//             ..createSync(recursive: true)
//             ..writeAsBytesSync(data);
//         } else {
//           Directory(
//             '${widget.directory.path}/$filename',
//           ).create(recursive: true);
//         }
//       }

//       // Optional: Delete the zip after extraction to clean up
//       // zipFile.deleteSync();

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Unzip Successful!")));

//       _loadFiles(); // Refresh list to show extracted files
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Unzip Failed: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isProcessing = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.directory.path.split('/').last,
//           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       backgroundColor: const Color(0xFFF4F7F6),
//       body: _isProcessing
//           ? const Center(child: CircularProgressIndicator())
//           : _files.isEmpty
//           ? const Center(child: Text("Empty Folder"))
//           : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _files.length,
//               itemBuilder: (context, index) {
//                 File file = _files[index] as File;
//                 String name = file.path.split('/').last;
//                 String ext = name.split('.').last.toLowerCase();

//                 IconData icon = Icons.insert_drive_file;
//                 Color color = Colors.grey;
//                 bool isZip = false;

//                 if (['jpg', 'jpeg', 'png'].contains(ext)) {
//                   icon = Icons.image;
//                   color = Colors.purple;
//                 } else if (ext == 'pdf') {
//                   icon = Icons.picture_as_pdf;
//                   color = Colors.red;
//                 } else if (ext == 'zip') {
//                   icon = Icons.folder_zip;
//                   color = Colors.orange;
//                   isZip = true;
//                 }

//                 return Card(
//                   elevation: 0,
//                   color: Colors.white,
//                   margin: const EdgeInsets.only(bottom: 10),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: ListTile(
//                     leading: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: color.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(icon, color: color),
//                     ),
//                     title: Text(
//                       name,
//                       style: const TextStyle(fontWeight: FontWeight.w500),
//                     ),
//                     subtitle: Text(
//                       isZip
//                           ? "Tap to Unzip"
//                           : "${(file.lengthSync() / 1024).toStringAsFixed(1)} KB",
//                     ),
//                     trailing: Icon(
//                       isZip ? Icons.system_update_alt : Icons.open_in_new,
//                       size: 20,
//                       color: Colors.grey,
//                     ),
//                     onTap: () {
//                       if (isZip) {
//                         _handleZipFile(file);
//                       } else {
//                         _openFile(context, file.path);
//                       }
//                     },
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   void _openFile(BuildContext context, String path) async {
//     try {
//       final result = await OpenFile.open(path);
//       if (result.type != ResultType.done) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Could not open file: ${result.message}"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
//       );
//     }
//   }
// }

// 18/01/26 FIRST CHANGE
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:archive/archive_io.dart'; // Import for Unzipping

// // --- CONFIGURATION ---
// const String SECRET_KEY = "securekey";
// const int TCP_PORT = 5001;
// const int UDP_PORT = 5000; // Added for Discovery & Messaging

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'AgriSync',
//       theme: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: const Color(0xFFF4F7F6),
//         primaryColor: const Color(0xFF2E7D32),
//         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
//         textTheme: GoogleFonts.poppinsTextTheme(),
//       ),
//       home: const HomeScreen(),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // --- STATE VARIABLES ---
//   String _statusMessage = "Please connect to 'FileShareHotspot'";
//   bool _isConnectedToWifi = false;
//   bool _isTransferring = false;
//   double _progress = 0.0;

//   // List of Saved Batches (Folders)
//   List<FileSystemEntity> _batchFolders = [];

//   final Connectivity _connectivity = Connectivity();
//   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _checkInitialConnection();
//     _loadSavedBatches(); // Load history on startup

//     _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
//       result,
//     ) {
//       _updateConnectionStatus(result);
//     });
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     super.dispose();
//   }

//   // --- 1. FILE SYSTEM & PERSISTENCE ---
//   Future<Directory> _getPublicDir() async {
//     // Saves to: Internal Storage > Download > AgriSync_Files
//     Directory dir = Directory('/storage/emulated/0/Download/AgriSync_Files');
//     if (!await dir.exists()) {
//       try {
//         await dir.create(recursive: true);
//       } catch (e) {
//         debugPrint("Error creating directory: $e");
//         dir =
//             await getExternalStorageDirectory() ??
//             await getApplicationDocumentsDirectory();
//       }
//     }
//     return dir;
//   }

//   Future<void> _loadSavedBatches() async {
//     try {
//       final dir = await _getPublicDir();
//       if (await dir.exists()) {
//         final entities = dir.listSync();
//         setState(() {
//           // Get folders only and sort by newest first
//           _batchFolders = entities.whereType<Directory>().toList()
//             ..sort(
//               (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
//             );
//         });
//       }
//     } catch (e) {
//       debugPrint("Error loading batches: $e");
//     }
//   }

//   // --- 2. PERMISSIONS & WIFI ---
//   Future<void> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       await Permission.storage.request();
//       if (await Permission.manageExternalStorage.status.isDenied) {
//         await Permission.manageExternalStorage.request();
//       }
//       await [Permission.location, Permission.nearbyWifiDevices].request();
//     }
//   }

//   void _checkInitialConnection() async {
//     var result = await _connectivity.checkConnectivity();
//     _updateConnectionStatus(result);
//   }

//   void _updateConnectionStatus(ConnectivityResult result) async {
//     bool hasWifi = result == ConnectivityResult.wifi;
//     if (hasWifi && !_isConnectedToWifi) {
//       _showBottomNotification("WiFi Connected! Ready to Sync.");
//     }
//     setState(() {
//       _isConnectedToWifi = hasWifi;
//       _statusMessage = hasWifi
//           ? "Connected to WiFi. Ready to receive."
//           : "Please connect to 'FileShareHotspot'";
//     });
//   }

//   // --- 3. TRANSFER LOGIC ---

//   // NEW: UDP Discovery Helper
//   Future<String?> _discoverServer(String? myIp) async {
//     if (myIp == null) return null;

//     RawDatagramSocket? socket;
//     try {
//       socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
//       socket.broadcastEnabled = true;

//       // Send Broadcast to Port 5000
//       socket.send(
//         utf8.encode(SECRET_KEY),
//         InternetAddress('255.255.255.255'),
//         UDP_PORT,
//       );
//       debugPrint("Sent UDP Broadcast...");

//       // Wait for response (Timeout 2 seconds)
//       var event = await socket
//           .firstWhere((event) => event == RawSocketEvent.read)
//           .timeout(const Duration(seconds: 2));

//       if (event == RawSocketEvent.read) {
//         Datagram? dg = socket.receive();
//         if (dg != null) {
//           String message = utf8.decode(dg.data).trim();
//           // Python sends: "IP|PORT"
//           var parts = message.split('|');
//           if (parts.isNotEmpty) {
//             return parts[0]; // Return the IP address
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("UDP Discovery Failed (Timeout or Error): $e");
//     } finally {
//       socket?.close();
//     }
//     return null;
//   }

//   Future<void> startSyncProcess() async {
//     if (!_isConnectedToWifi) {
//       _showBottomNotification(
//         "No WiFi Connection! Check Settings.",
//         isError: true,
//       );
//       return;
//     }

//     if (Platform.isAndroid &&
//         !(await Permission.manageExternalStorage.isGranted)) {
//       await Permission.manageExternalStorage.request();
//       if (!(await Permission.storage.isGranted)) return;
//     }

//     setState(() {
//       _isTransferring = true;
//       _progress = 0.1;
//       _statusMessage = "Locating Server (UDP)...";
//     });

//     try {
//       final info = NetworkInfo();
//       var wifiIP = await info.getWifiIP();

//       // --- CHANGED: Try UDP Discovery First ---
//       String? discoveredIp = await _discoverServer(wifiIP);

//       String targetIp;
//       if (discoveredIp != null) {
//         targetIp = discoveredIp;
//         debugPrint("UDP Discovery Successful: Found Server at $targetIp");
//       } else {
//         // Fallback to Gateway if UDP fails
//         var gatewayIp = await info.getWifiGatewayIP();
//         targetIp = (gatewayIp != null && gatewayIp != "0.0.0.0")
//             ? gatewayIp
//             : "10.42.0.1";
//         debugPrint("UDP Failed. Falling back to Gateway IP: $targetIp");
//       }

//       setState(() {
//         _statusMessage = "Connecting to $targetIp...";
//         _progress = 0.2;
//       });

//       // 1. Create a Unique Folder for this Session
//       String timestamp = DateTime.now()
//           .toString()
//           .replaceAll(RegExp(r'[^0-9]'), '')
//           .substring(0, 12);
//       String batchName = "Batch_$timestamp";

//       Directory rootDir = await _getPublicDir();
//       Directory sessionDir = Directory("${rootDir.path}/$batchName");

//       if (!await sessionDir.exists()) {
//         await sessionDir.create(recursive: true);
//       }

//       // 2. Receive Files into that Folder
//       await _receiveFiles(targetIp, TCP_PORT, wifiIP, sessionDir);

//       // 3. Refresh List
//       await _loadSavedBatches();
//     } catch (e) {
//       setState(() {
//         _statusMessage = "Connection Failed";
//         _isTransferring = false;
//         _progress = 0.0;
//       });
//       _showBottomNotification("Error: ${e.toString()}", isError: true);
//     }
//   }

//   Future<void> _receiveFiles(
//     String ip,
//     int port,
//     String? sourceIP,
//     Directory sessionDir,
//   ) async {
//     Socket? socket;
//     int retryCount = 0;

//     while (socket == null && retryCount < 3) {
//       try {
//         socket = await Socket.connect(
//           ip,
//           port,
//           sourceAddress: sourceIP,
//           timeout: const Duration(seconds: 5),
//         );
//       } catch (e) {
//         retryCount++;
//         await Future.delayed(const Duration(seconds: 1));
//       }
//     }

//     if (socket == null) throw Exception("Could not connect to Server.");

//     try {
//       socket.add(utf8.encode(SECRET_KEY));
//       await socket.flush();

//       StreamIterator<Uint8List> reader = StreamIterator(socket);
//       if (!await _readUntil(reader, "OK")) throw Exception("Auth Failed");

//       String header = await _readHeader(reader);
//       socket.add(utf8.encode("OK"));
//       await socket.flush();

//       if (header.startsWith("NUM_FILES")) {
//         int count = int.parse(header.split("|")[1]);
//         for (int i = 0; i < count; i++) {
//           setState(() {
//             _statusMessage = "Downloading file ${i + 1}/$count...";
//             _progress = (i + 1) / (count + 1);
//           });
//           await _downloadSingleFile(reader, socket, sessionDir);
//         }
//       }

//       setState(() {
//         _isTransferring = false;
//         _statusMessage = "Transfer Complete!";
//         _progress = 1.0;
//       });
//       _showBottomNotification("Saved to: ${sessionDir.path.split('/').last}");
//     } finally {
//       socket.destroy();
//     }
//   }

//   Future<void> _downloadSingleFile(
//     StreamIterator<Uint8List> reader,
//     Socket socket,
//     Directory dir,
//   ) async {
//     String header = await _readHeader(reader);
//     var parts = header.split("|");
//     String filename = parts[0].split('/').last.split('\\').last;
//     int filesize = int.parse(parts[1]);

//     socket.add(utf8.encode("OK"));
//     await socket.flush();

//     File file = File("${dir.path}/$filename");
//     IOSink sink = file.openWrite();

//     int received = 0;
//     while (received < filesize) {
//       if (await reader.moveNext()) {
//         Uint8List chunk = reader.current;
//         int remaining = filesize - received;
//         if (chunk.length > remaining) {
//           sink.add(chunk.sublist(0, remaining));
//           received += remaining;
//         } else {
//           sink.add(chunk);
//           received += chunk.length;
//         }
//       } else {
//         break;
//       }
//     }
//     await sink.flush();
//     await sink.close();
//   }

//   Future<bool> _readUntil(
//     StreamIterator<Uint8List> reader,
//     String target,
//   ) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current).contains(target);
//     }
//     return false;
//   }

//   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current);
//     }
//     throw Exception("Connection closed");
//   }

//   void _showBottomNotification(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B5E20),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // --- 4. UI BUILDING ---
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF4F7F6),
//         elevation: 0,
//         leading: Builder(
//           builder: (c) => IconButton(
//             icon: const Icon(Icons.menu_rounded, size: 32),
//             onPressed: () => Scaffold.of(c).openDrawer(),
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 20),
//             child: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF2E7D32)),
//             ),
//           ),
//         ],
//       ),
//       drawer: _buildDrawer(),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Welcome Back,",
//               style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
//             ),
//             Text(
//               "Agri-Manager",
//               style: GoogleFonts.poppins(
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF191825),
//               ),
//             ),
//             const SizedBox(height: 30),

//             // Status Card
//             Container(
//               padding: const EdgeInsets.all(25),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A1F30),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 10,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "System Status",
//                         style: GoogleFonts.poppins(color: Colors.grey[400]),
//                       ),
//                       Icon(
//                         _isConnectedToWifi ? Icons.wifi : Icons.wifi_off,
//                         color: _isConnectedToWifi
//                             ? Colors.greenAccent
//                             : Colors.redAccent,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     _statusMessage,
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.poppins(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 25),
//                   if (_isTransferring)
//                     LinearProgressIndicator(
//                       value: _progress,
//                       backgroundColor: Colors.white10,
//                       color: const Color(0xFFC8F000),
//                     )
//                   else
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton.icon(
//                         onPressed: startSyncProcess,
//                         icon: const Icon(
//                           Icons.sync_outlined,
//                           color: Colors.black,
//                         ),
//                         label: Text(
//                           "Receive Data",
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFC8F000),
//                           foregroundColor: Colors.black,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),
//             Text(
//               "My Files",
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),

//             // Batch List
//             Expanded(
//               child: _batchFolders.isEmpty
//                   ? Center(
//                       child: Text(
//                         "No batches received yet",
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: _batchFolders.length,
//                       itemBuilder: (context, index) {
//                         Directory dir = _batchFolders[index] as Directory;
//                         String name = dir.path.split('/').last;
//                         return Card(
//                           elevation: 0,
//                           color: Colors.white,
//                           margin: const EdgeInsets.only(bottom: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: ListTile(
//                             leading: Container(
//                               padding: const EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFE3F2FD),
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: const Icon(
//                                 Icons.folder_open,
//                                 color: Color(0xFF1565C0),
//                               ),
//                             ),
//                             title: Text(
//                               name,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             subtitle: Text("Tap to view files"),
//                             trailing: const Icon(
//                               Icons.chevron_right,
//                               color: Colors.grey,
//                             ),
//                             onTap: () async {
//                               // Navigate and wait for result (in case zip extracted)
//                               await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       FolderDetailScreen(directory: dir),
//                                 ),
//                               );
//                               // Refresh list when coming back
//                               _loadSavedBatches();
//                             },
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       backgroundColor: Colors.white,
//       child: Column(
//         children: [
//           const UserAccountsDrawerHeader(
//             decoration: BoxDecoration(color: Color(0xFF191825)),
//             accountName: Text(
//               "Admin User",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             accountEmail: Text("admin@itc.project"),
//             currentAccountPicture: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF191825)),
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.folder_copy),
//             title: const Text("My Files"),
//             onTap: () {
//               // Since 'Home' IS the file viewer, just close drawer
//               Navigator.pop(context);
//             },
//           ),
//           // --- NEW: MESSAGE BOX PAGE ---
//           ListTile(
//             leading: const Icon(Icons.message_outlined),
//             title: const Text("Message Box"),
//             onTap: () {
//               Navigator.pop(context); // Close Drawer
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const MessageBoxScreen(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// // --- UPDATED SCREEN: FOLDER DETAIL VIEW ---
// class FolderDetailScreen extends StatefulWidget {
//   final Directory directory;

//   const FolderDetailScreen({super.key, required this.directory});

//   @override
//   State<FolderDetailScreen> createState() => _FolderDetailScreenState();
// }

// class _FolderDetailScreenState extends State<FolderDetailScreen> {
//   List<FileSystemEntity> _files = [];
//   bool _isProcessing = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadFiles();
//   }

//   void _loadFiles() {
//     try {
//       if (widget.directory.existsSync()) {
//         final files = widget.directory.listSync().whereType<File>().toList()
//           ..sort((a, b) => a.path.compareTo(b.path));
//         setState(() {
//           _files = files;
//         });
//       }
//     } catch (e) {
//       debugPrint("Error listing files: $e");
//     }
//   }

//   // --- LOGIC: UNZIP FILES INTERNALLY ---
//   Future<void> _handleZipFile(File zipFile) async {
//     setState(() => _isProcessing = true);

//     try {
//       final bytes = zipFile.readAsBytesSync();
//       final archive = ZipDecoder().decodeBytes(bytes);

//       // Extract to the same directory
//       for (final file in archive) {
//         final filename = file.name;
//         if (file.isFile) {
//           final data = file.content as List<int>;
//           File('${widget.directory.path}/$filename')
//             ..createSync(recursive: true)
//             ..writeAsBytesSync(data);
//         } else {
//           Directory(
//             '${widget.directory.path}/$filename',
//           ).create(recursive: true);
//         }
//       }

//       // Optional: Delete the zip after extraction to clean up
//       // zipFile.deleteSync();

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Unzip Successful!")));

//       _loadFiles(); // Refresh list to show extracted files
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Unzip Failed: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isProcessing = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.directory.path.split('/').last,
//           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       backgroundColor: const Color(0xFFF4F7F6),
//       body: _isProcessing
//           ? const Center(child: CircularProgressIndicator())
//           : _files.isEmpty
//           ? const Center(child: Text("Empty Folder"))
//           : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _files.length,
//               itemBuilder: (context, index) {
//                 File file = _files[index] as File;
//                 String name = file.path.split('/').last;
//                 String ext = name.split('.').last.toLowerCase();

//                 IconData icon = Icons.insert_drive_file;
//                 Color color = Colors.grey;
//                 bool isZip = false;

//                 if (['jpg', 'jpeg', 'png'].contains(ext)) {
//                   icon = Icons.image;
//                   color = Colors.purple;
//                 } else if (ext == 'pdf') {
//                   icon = Icons.picture_as_pdf;
//                   color = Colors.red;
//                 } else if (ext == 'zip') {
//                   icon = Icons.folder_zip;
//                   color = Colors.orange;
//                   isZip = true;
//                 }

//                 return Card(
//                   elevation: 0,
//                   color: Colors.white,
//                   margin: const EdgeInsets.only(bottom: 10),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: ListTile(
//                     leading: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: color.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(icon, color: color),
//                     ),
//                     title: Text(
//                       name,
//                       style: const TextStyle(fontWeight: FontWeight.w500),
//                     ),
//                     subtitle: Text(
//                       isZip
//                           ? "Tap to Unzip"
//                           : "${(file.lengthSync() / 1024).toStringAsFixed(1)} KB",
//                     ),
//                     trailing: Icon(
//                       isZip ? Icons.system_update_alt : Icons.open_in_new,
//                       size: 20,
//                       color: Colors.grey,
//                     ),
//                     onTap: () {
//                       if (isZip) {
//                         _handleZipFile(file);
//                       } else {
//                         _openFile(context, file.path);
//                       }
//                     },
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   void _openFile(BuildContext context, String path) async {
//     try {
//       final result = await OpenFile.open(path);
//       if (result.type != ResultType.done) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Could not open file: ${result.message}"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
//       );
//     }
//   }
// }

// // --- NEW PAGE: MESSAGE BOX ---
// class MessageBoxScreen extends StatefulWidget {
//   const MessageBoxScreen({super.key});

//   @override
//   State<MessageBoxScreen> createState() => _MessageBoxScreenState();
// }

// class _MessageBoxScreenState extends State<MessageBoxScreen> {
//   final TextEditingController _controller = TextEditingController();
//   bool _isSending = false;

//   Future<void> _sendMessage() async {
//     String text = _controller.text.trim();
//     if (text.isEmpty) return;

//     setState(() => _isSending = true);

//     RawDatagramSocket? socket;
//     try {
//       socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
//       socket.broadcastEnabled = true;

//       // Protocol: "MSG:Hello World"
//       // Sending to Broadcast 255.255.255.255 on Port 5000
//       String payload = "MSG:$text";
//       socket.send(
//         utf8.encode(payload),
//         InternetAddress('255.255.255.255'),
//         UDP_PORT,
//       );

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Message Broadcasted!"),
//           backgroundColor: Color(0xFF2E7D32),
//         ),
//       );
//       _controller.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error Sending: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       socket?.close();
//       setState(() => _isSending = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Message Box",
//           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       backgroundColor: const Color(0xFFF4F7F6),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Send Message to Device",
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF191825),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Text Area
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 10,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: TextField(
//                 controller: _controller,
//                 maxLines: 6,
//                 decoration: InputDecoration(
//                   hintText: "Type your message here...",
//                   hintStyle: GoogleFonts.poppins(color: Colors.grey),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(16),
//                     borderSide: BorderSide.none,
//                   ),
//                   contentPadding: const EdgeInsets.all(20),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 30),

//             // Send Button
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton.icon(
//                 onPressed: _isSending ? null : _sendMessage,
//                 icon: _isSending
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.black,
//                         ),
//                       )
//                     : const Icon(Icons.send, color: Colors.black),
//                 label: Text(
//                   _isSending ? "Sending..." : "Send Message",
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFC8F000),
//                   foregroundColor: Colors.black,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// SECOND CHANGE 18
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:archive/archive_io.dart'; // Import for Unzipping

// // --- CONFIGURATION ---
// const String SECRET_KEY = "securekey";
// const int TCP_PORT = 5001;
// const int UDP_PORT = 5000; // Added for Discovery & Messaging

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'AgriSync',
//       theme: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: const Color(0xFFF4F7F6),
//         primaryColor: const Color(0xFF2E7D32),
//         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
//         textTheme: GoogleFonts.poppinsTextTheme(),
//       ),
//       home: const HomeScreen(),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // --- STATE VARIABLES ---
//   String _statusMessage = "Please connect to 'FileShareHotspot'";
//   bool _isConnectedToWifi = false;
//   bool _isTransferring = false;
//   double _progress = 0.0;

//   // List of Saved Batches (Folders)
//   List<FileSystemEntity> _batchFolders = [];

//   final Connectivity _connectivity = Connectivity();
//   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _checkInitialConnection();
//     _loadSavedBatches(); // Load history on startup

//     _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
//       result,
//     ) {
//       _updateConnectionStatus(result);
//     });
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     super.dispose();
//   }

//   // --- 1. FILE SYSTEM & PERSISTENCE ---
//   Future<Directory> _getPublicDir() async {
//     // Saves to: Internal Storage > Download > AgriSync_Files
//     Directory dir = Directory('/storage/emulated/0/Download/AgriSync_Files');
//     if (!await dir.exists()) {
//       try {
//         await dir.create(recursive: true);
//       } catch (e) {
//         debugPrint("Error creating directory: $e");
//         dir =
//             await getExternalStorageDirectory() ??
//             await getApplicationDocumentsDirectory();
//       }
//     }
//     return dir;
//   }

//   Future<void> _loadSavedBatches() async {
//     try {
//       final dir = await _getPublicDir();
//       if (await dir.exists()) {
//         final entities = dir.listSync();
//         setState(() {
//           // Get folders only and sort by newest first
//           _batchFolders = entities.whereType<Directory>().toList()
//             ..sort(
//               (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
//             );
//         });
//       }
//     } catch (e) {
//       debugPrint("Error loading batches: $e");
//     }
//   }

//   // --- 2. PERMISSIONS & WIFI ---
//   Future<void> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       await Permission.storage.request();
//       if (await Permission.manageExternalStorage.status.isDenied) {
//         await Permission.manageExternalStorage.request();
//       }
//       await [Permission.location, Permission.nearbyWifiDevices].request();
//     }
//   }

//   void _checkInitialConnection() async {
//     var result = await _connectivity.checkConnectivity();
//     _updateConnectionStatus(result);
//   }

//   void _updateConnectionStatus(ConnectivityResult result) async {
//     bool hasWifi = result == ConnectivityResult.wifi;
//     if (hasWifi && !_isConnectedToWifi) {
//       _showBottomNotification("WiFi Connected! Ready to Sync.");
//     }
//     setState(() {
//       _isConnectedToWifi = hasWifi;
//       _statusMessage = hasWifi
//           ? "Connected to WiFi. Ready to receive."
//           : "Please connect to 'FileShareHotspot'";
//     });
//   }

//   // --- 3. TRANSFER LOGIC ---

//   // NEW: UDP Discovery Helper
//   Future<String?> _discoverServer(String? myIp) async {
//     if (myIp == null) return null;

//     RawDatagramSocket? socket;
//     try {
//       socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
//       socket.broadcastEnabled = true;

//       // Send Broadcast to Port 5000
//       socket.send(
//         utf8.encode(SECRET_KEY),
//         InternetAddress('255.255.255.255'),
//         UDP_PORT,
//       );
//       debugPrint("Sent UDP Broadcast...");

//       // Wait for response (Timeout 2 seconds)
//       var event = await socket
//           .firstWhere((event) => event == RawSocketEvent.read)
//           .timeout(const Duration(seconds: 2));

//       if (event == RawSocketEvent.read) {
//         Datagram? dg = socket.receive();
//         if (dg != null) {
//           String message = utf8.decode(dg.data).trim();
//           // Python sends: "IP|PORT"
//           var parts = message.split('|');
//           if (parts.isNotEmpty) {
//             return parts[0]; // Return the IP address
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("UDP Discovery Failed (Timeout or Error): $e");
//     } finally {
//       socket?.close();
//     }
//     return null;
//   }

//   Future<void> startSyncProcess() async {
//     if (!_isConnectedToWifi) {
//       _showBottomNotification(
//         "No WiFi Connection! Check Settings.",
//         isError: true,
//       );
//       return;
//     }

//     if (Platform.isAndroid &&
//         !(await Permission.manageExternalStorage.isGranted)) {
//       await Permission.manageExternalStorage.request();
//       if (!(await Permission.storage.isGranted)) return;
//     }

//     setState(() {
//       _isTransferring = true;
//       _progress = 0.1;
//       _statusMessage = "Locating Server (UDP)...";
//     });

//     try {
//       final info = NetworkInfo();
//       var wifiIP = await info.getWifiIP();

//       // --- CHANGED: Try UDP Discovery First ---
//       String? discoveredIp = await _discoverServer(wifiIP);

//       String targetIp;
//       if (discoveredIp != null) {
//         targetIp = discoveredIp;
//         debugPrint("UDP Discovery Successful: Found Server at $targetIp");
//       } else {
//         // Fallback to Gateway if UDP fails
//         var gatewayIp = await info.getWifiGatewayIP();
//         targetIp = (gatewayIp != null && gatewayIp != "0.0.0.0")
//             ? gatewayIp
//             : "10.42.0.1";
//         debugPrint("UDP Failed. Falling back to Gateway IP: $targetIp");
//       }

//       setState(() {
//         _statusMessage = "Connecting to $targetIp...";
//         _progress = 0.2;
//       });

//       // 1. Create a Unique Folder for this Session
//       String timestamp = DateTime.now()
//           .toString()
//           .replaceAll(RegExp(r'[^0-9]'), '')
//           .substring(0, 12);
//       String batchName = "Batch_$timestamp";

//       Directory rootDir = await _getPublicDir();
//       Directory sessionDir = Directory("${rootDir.path}/$batchName");

//       if (!await sessionDir.exists()) {
//         await sessionDir.create(recursive: true);
//       }

//       // 2. Receive Files into that Folder
//       await _receiveFiles(targetIp, TCP_PORT, wifiIP, sessionDir);

//       // 3. Refresh List
//       await _loadSavedBatches();
//     } catch (e) {
//       setState(() {
//         _statusMessage = "Connection Failed";
//         _isTransferring = false;
//         _progress = 0.0;
//       });
//       _showBottomNotification("Error: ${e.toString()}", isError: true);
//     }
//   }

//   Future<void> _receiveFiles(
//     String ip,
//     int port,
//     String? sourceIP,
//     Directory sessionDir,
//   ) async {
//     Socket? socket;
//     int retryCount = 0;

//     while (socket == null && retryCount < 3) {
//       try {
//         socket = await Socket.connect(
//           ip,
//           port,
//           sourceAddress: sourceIP,
//           timeout: const Duration(seconds: 5),
//         );
//       } catch (e) {
//         retryCount++;
//         await Future.delayed(const Duration(seconds: 1));
//       }
//     }

//     if (socket == null) throw Exception("Could not connect to Server.");

//     try {
//       socket.add(utf8.encode(SECRET_KEY));
//       await socket.flush();

//       StreamIterator<Uint8List> reader = StreamIterator(socket);
//       if (!await _readUntil(reader, "OK")) throw Exception("Auth Failed");

//       String header = await _readHeader(reader);
//       socket.add(utf8.encode("OK"));
//       await socket.flush();

//       if (header.startsWith("NUM_FILES")) {
//         int count = int.parse(header.split("|")[1]);
//         for (int i = 0; i < count; i++) {
//           setState(() {
//             _statusMessage = "Downloading file ${i + 1}/$count...";
//             _progress = (i + 1) / (count + 1);
//           });
//           await _downloadSingleFile(reader, socket, sessionDir);
//         }
//       }

//       setState(() {
//         _isTransferring = false;
//         _statusMessage = "Transfer Complete!";
//         _progress = 1.0;
//       });
//       _showBottomNotification("Saved to: ${sessionDir.path.split('/').last}");
//     } finally {
//       socket.destroy();
//     }
//   }

//   Future<void> _downloadSingleFile(
//     StreamIterator<Uint8List> reader,
//     Socket socket,
//     Directory dir,
//   ) async {
//     String header = await _readHeader(reader);
//     var parts = header.split("|");
//     String filename = parts[0].split('/').last.split('\\').last;
//     int filesize = int.parse(parts[1]);

//     socket.add(utf8.encode("OK"));
//     await socket.flush();

//     File file = File("${dir.path}/$filename");
//     IOSink sink = file.openWrite();

//     int received = 0;
//     while (received < filesize) {
//       if (await reader.moveNext()) {
//         Uint8List chunk = reader.current;
//         int remaining = filesize - received;
//         if (chunk.length > remaining) {
//           sink.add(chunk.sublist(0, remaining));
//           received += remaining;
//         } else {
//           sink.add(chunk);
//           received += chunk.length;
//         }
//       } else {
//         break;
//       }
//     }
//     await sink.flush();
//     await sink.close();
//   }

//   Future<bool> _readUntil(
//     StreamIterator<Uint8List> reader,
//     String target,
//   ) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current).contains(target);
//     }
//     return false;
//   }

//   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current);
//     }
//     throw Exception("Connection closed");
//   }

//   void _showBottomNotification(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B5E20),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // --- 4. UI BUILDING ---
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF4F7F6),
//         elevation: 0,
//         leading: Builder(
//           builder: (c) => IconButton(
//             icon: const Icon(Icons.menu_rounded, size: 32),
//             onPressed: () => Scaffold.of(c).openDrawer(),
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 20),
//             child: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF2E7D32)),
//             ),
//           ),
//         ],
//       ),
//       drawer: _buildDrawer(),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Welcome Back,",
//               style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
//             ),
//             Text(
//               "Agri-Manager",
//               style: GoogleFonts.poppins(
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF191825),
//               ),
//             ),
//             const SizedBox(height: 30),

//             // Status Card
//             Container(
//               padding: const EdgeInsets.all(25),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A1F30),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 10,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "System Status",
//                         style: GoogleFonts.poppins(color: Colors.grey[400]),
//                       ),
//                       Icon(
//                         _isConnectedToWifi ? Icons.wifi : Icons.wifi_off,
//                         color: _isConnectedToWifi
//                             ? Colors.greenAccent
//                             : Colors.redAccent,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     _statusMessage,
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.poppins(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 25),
//                   if (_isTransferring)
//                     LinearProgressIndicator(
//                       value: _progress,
//                       backgroundColor: Colors.white10,
//                       color: const Color(0xFFC8F000),
//                     )
//                   else
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton.icon(
//                         onPressed: startSyncProcess,
//                         icon: const Icon(
//                           Icons.sync_outlined,
//                           color: Colors.black,
//                         ),
//                         label: Text(
//                           "Receive Data",
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFC8F000),
//                           foregroundColor: Colors.black,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),
//             Text(
//               "My Files",
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),

//             // Batch List
//             Expanded(
//               child: _batchFolders.isEmpty
//                   ? Center(
//                       child: Text(
//                         "No batches received yet",
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: _batchFolders.length,
//                       itemBuilder: (context, index) {
//                         Directory dir = _batchFolders[index] as Directory;
//                         String name = dir.path.split('/').last;
//                         return Card(
//                           elevation: 0,
//                           color: Colors.white,
//                           margin: const EdgeInsets.only(bottom: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: ListTile(
//                             leading: Container(
//                               padding: const EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFE3F2FD),
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: const Icon(
//                                 Icons.folder_open,
//                                 color: Color(0xFF1565C0),
//                               ),
//                             ),
//                             title: Text(
//                               name,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             subtitle: Text("Tap to view files"),
//                             trailing: const Icon(
//                               Icons.chevron_right,
//                               color: Colors.grey,
//                             ),
//                             onTap: () async {
//                               // Navigate and wait for result (in case zip extracted)
//                               await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       FolderDetailScreen(directory: dir),
//                                 ),
//                               );
//                               // Refresh list when coming back
//                               _loadSavedBatches();
//                             },
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       backgroundColor: Colors.white,
//       child: Column(
//         children: [
//           const UserAccountsDrawerHeader(
//             decoration: BoxDecoration(color: Color(0xFF191825)),
//             accountName: Text(
//               "Admin User",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             accountEmail: Text("admin@itc.project"),
//             currentAccountPicture: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF191825)),
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.folder_copy),
//             title: const Text("My Files"),
//             onTap: () {
//               // Since 'Home' IS the file viewer, just close drawer
//               Navigator.pop(context);
//             },
//           ),
//           // --- NEW: MESSAGE BOX PAGE ---
//           ListTile(
//             leading: const Icon(Icons.message_outlined),
//             title: const Text("Message Box"),
//             onTap: () {
//               Navigator.pop(context); // Close Drawer
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const MessageBoxScreen(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// // --- UPDATED SCREEN: FOLDER DETAIL VIEW ---
// class FolderDetailScreen extends StatefulWidget {
//   final Directory directory;

//   const FolderDetailScreen({super.key, required this.directory});

//   @override
//   State<FolderDetailScreen> createState() => _FolderDetailScreenState();
// }

// class _FolderDetailScreenState extends State<FolderDetailScreen> {
//   List<FileSystemEntity> _files = [];
//   bool _isProcessing = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadFiles();
//   }

//   void _loadFiles() {
//     try {
//       if (widget.directory.existsSync()) {
//         final files = widget.directory.listSync().whereType<File>().toList()
//           ..sort((a, b) => a.path.compareTo(b.path));
//         setState(() {
//           _files = files;
//         });
//       }
//     } catch (e) {
//       debugPrint("Error listing files: $e");
//     }
//   }

//   // --- LOGIC: UNZIP FILES INTERNALLY ---
//   Future<void> _handleZipFile(File zipFile) async {
//     setState(() => _isProcessing = true);

//     try {
//       final bytes = zipFile.readAsBytesSync();
//       final archive = ZipDecoder().decodeBytes(bytes);

//       // Extract to the same directory
//       for (final file in archive) {
//         final filename = file.name;
//         if (file.isFile) {
//           final data = file.content as List<int>;
//           File('${widget.directory.path}/$filename')
//             ..createSync(recursive: true)
//             ..writeAsBytesSync(data);
//         } else {
//           Directory(
//             '${widget.directory.path}/$filename',
//           ).create(recursive: true);
//         }
//       }

//       // Optional: Delete the zip after extraction to clean up
//       // zipFile.deleteSync();

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Unzip Successful!")));

//       _loadFiles(); // Refresh list to show extracted files
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Unzip Failed: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isProcessing = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.directory.path.split('/').last,
//           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       backgroundColor: const Color(0xFFF4F7F6),
//       body: _isProcessing
//           ? const Center(child: CircularProgressIndicator())
//           : _files.isEmpty
//           ? const Center(child: Text("Empty Folder"))
//           : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _files.length,
//               itemBuilder: (context, index) {
//                 File file = _files[index] as File;
//                 String name = file.path.split('/').last;
//                 String ext = name.split('.').last.toLowerCase();

//                 IconData icon = Icons.insert_drive_file;
//                 Color color = Colors.grey;
//                 bool isZip = false;

//                 if (['jpg', 'jpeg', 'png'].contains(ext)) {
//                   icon = Icons.image;
//                   color = Colors.purple;
//                 } else if (ext == 'pdf') {
//                   icon = Icons.picture_as_pdf;
//                   color = Colors.red;
//                 } else if (ext == 'zip') {
//                   icon = Icons.folder_zip;
//                   color = Colors.orange;
//                   isZip = true;
//                 }

//                 return Card(
//                   elevation: 0,
//                   color: Colors.white,
//                   margin: const EdgeInsets.only(bottom: 10),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: ListTile(
//                     leading: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: color.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(icon, color: color),
//                     ),
//                     title: Text(
//                       name,
//                       style: const TextStyle(fontWeight: FontWeight.w500),
//                     ),
//                     subtitle: Text(
//                       isZip
//                           ? "Tap to Unzip"
//                           : "${(file.lengthSync() / 1024).toStringAsFixed(1)} KB",
//                     ),
//                     trailing: Icon(
//                       isZip ? Icons.system_update_alt : Icons.open_in_new,
//                       size: 20,
//                       color: Colors.grey,
//                     ),
//                     onTap: () {
//                       if (isZip) {
//                         _handleZipFile(file);
//                       } else {
//                         _openFile(context, file.path);
//                       }
//                     },
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   void _openFile(BuildContext context, String path) async {
//     try {
//       final result = await OpenFile.open(path);
//       if (result.type != ResultType.done) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Could not open file: ${result.message}"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
//       );
//     }
//   }
// }

// // --- NEW PAGE: MESSAGE BOX ---
// class MessageBoxScreen extends StatefulWidget {
//   const MessageBoxScreen({super.key});

//   @override
//   State<MessageBoxScreen> createState() => _MessageBoxScreenState();
// }

// class _MessageBoxScreenState extends State<MessageBoxScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final List<String> _messages = []; // Stores chat history
//   RawDatagramSocket? _socket;
//   bool _isSending = false;

//   @override
//   void initState() {
//     super.initState();
//     _startListening();
//   }

//   @override
//   void dispose() {
//     _socket?.close(); // Stop listening when leaving page
//     _controller.dispose();
//     super.dispose();
//   }

//   // --- 1. LISTENER LOGIC ---
//   Future<void> _startListening() async {
//     try {
//       _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 5000);
//       _socket!.broadcastEnabled = true;

//       _socket!.listen((RawSocketEvent event) {
//         if (event == RawSocketEvent.read) {
//           Datagram? dg = _socket!.receive();
//           if (dg != null) {
//             String msg = utf8.decode(dg.data).trim();

//             // Check for Pi's prefix
//             if (msg.startsWith("MSG_FROM_PI:")) {
//               String content = msg.replaceAll("MSG_FROM_PI:", "");
//               setState(() {
//                 _messages.add("Pi: $content");
//               });
//             }
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint("Error binding socket: $e");
//     }
//   }

//   // --- 2. SENDER LOGIC ---
//   Future<void> _sendMessage() async {
//     String text = _controller.text.trim();
//     if (text.isEmpty) return;

//     setState(() => _isSending = true);

//     // If socket isn't open, open temporary one (though listener should handle it)
//     if (_socket == null) {
//       await _startListening();
//     }

//     try {
//       // Protocol: "MSG:Hello World"
//       // Sending to Broadcast 255.255.255.255 on Port 5000
//       String payload = "MSG:$text";
//       _socket?.send(
//         utf8.encode(payload),
//         InternetAddress('255.255.255.255'),
//         5000,
//       );

//       setState(() {
//         _messages.add("Me: $text"); // Show my own message
//       });
//       _controller.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
//       );
//     } finally {
//       setState(() => _isSending = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Message Box",
//           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       backgroundColor: const Color(0xFFF4F7F6),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Send Message to Device",
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF191825),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Input Area
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 10,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: TextField(
//                 controller: _controller,
//                 maxLines: 3,
//                 decoration: InputDecoration(
//                   hintText: "Type your message here...",
//                   hintStyle: GoogleFonts.poppins(color: Colors.grey),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(16),
//                     borderSide: BorderSide.none,
//                   ),
//                   contentPadding: const EdgeInsets.all(20),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Send Button
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton.icon(
//                 onPressed: _isSending ? null : _sendMessage,
//                 icon: _isSending
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.black,
//                         ),
//                       )
//                     : const Icon(Icons.send, color: Colors.black),
//                 label: Text(
//                   _isSending ? "Sending..." : "Send Message",
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFC8F000),
//                   foregroundColor: Colors.black,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 30),

//             // --- NEW: CHAT HISTORY DISPLAY ---
//             Text(
//               "Chat History",
//               style: GoogleFonts.poppins(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[700],
//               ),
//             ),
//             const SizedBox(height: 10),

//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: Colors.black12),
//                 ),
//                 child: _messages.isEmpty
//                     ? Center(
//                         child: Text(
//                           "No messages yet",
//                           style: TextStyle(color: Colors.grey),
//                         ),
//                       )
//                     : ListView.builder(
//                         itemCount: _messages.length,
//                         itemBuilder: (context, index) {
//                           String msg = _messages[index];
//                           bool isMe = msg.startsWith("Me:");
//                           return Container(
//                             margin: const EdgeInsets.only(bottom: 10),
//                             alignment: isMe
//                                 ? Alignment.centerRight
//                                 : Alignment.centerLeft,
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 10,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: isMe
//                                     ? const Color(0xFFE8F5E9)
//                                     : const Color(0xFFF5F5F5),
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: isMe
//                                       ? const Color(0xFFC8E6C9)
//                                       : const Color(0xFFEEEEEE),
//                                 ),
//                               ),
//                               child: Text(
//                                 msg,
//                                 style: GoogleFonts.poppins(
//                                   color: isMe
//                                       ? Colors.green[900]
//                                       : Colors.black87,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// THIRD CHANGE
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:archive/archive_io.dart'; // Import for Unzipping

// // --- CONFIGURATION ---
// const String SECRET_KEY = "securekey";
// const int TCP_PORT = 5001;
// const int UDP_PORT = 5000; // Added for Discovery & Messaging

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'AgriSync',
//       theme: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: const Color(0xFFF4F7F6),
//         primaryColor: const Color(0xFF2E7D32),
//         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
//         textTheme: GoogleFonts.poppinsTextTheme(),
//       ),
//       home: const HomeScreen(),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // --- STATE VARIABLES ---
//   String _statusMessage = "Please connect to 'FileShareHotspot'";
//   bool _isConnectedToWifi = false;
//   bool _isTransferring = false;
//   double _progress = 0.0;

//   // List of Saved Batches (Folders)
//   List<FileSystemEntity> _batchFolders = [];

//   final Connectivity _connectivity = Connectivity();
//   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _checkInitialConnection();
//     _loadSavedBatches(); // Load history on startup

//     _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
//       result,
//     ) {
//       _updateConnectionStatus(result);
//     });
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     super.dispose();
//   }

//   // --- 1. FILE SYSTEM & PERSISTENCE ---
//   Future<Directory> _getPublicDir() async {
//     // Saves to: Internal Storage > Download > AgriSync_Files
//     Directory dir = Directory('/storage/emulated/0/Download/AgriSync_Files');
//     if (!await dir.exists()) {
//       try {
//         await dir.create(recursive: true);
//       } catch (e) {
//         debugPrint("Error creating directory: $e");
//         dir =
//             await getExternalStorageDirectory() ??
//             await getApplicationDocumentsDirectory();
//       }
//     }
//     return dir;
//   }

//   Future<void> _loadSavedBatches() async {
//     try {
//       final dir = await _getPublicDir();
//       if (await dir.exists()) {
//         final entities = dir.listSync();
//         setState(() {
//           // Get folders only and sort by newest first
//           _batchFolders = entities.whereType<Directory>().toList()
//             ..sort(
//               (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
//             );
//         });
//       }
//     } catch (e) {
//       debugPrint("Error loading batches: $e");
//     }
//   }

//   // --- 2. PERMISSIONS & WIFI ---
//   Future<void> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       await Permission.storage.request();
//       if (await Permission.manageExternalStorage.status.isDenied) {
//         await Permission.manageExternalStorage.request();
//       }
//       await [Permission.location, Permission.nearbyWifiDevices].request();
//     }
//   }

//   void _checkInitialConnection() async {
//     var result = await _connectivity.checkConnectivity();
//     _updateConnectionStatus(result);
//   }

//   void _updateConnectionStatus(ConnectivityResult result) async {
//     bool hasWifi = result == ConnectivityResult.wifi;
//     if (hasWifi && !_isConnectedToWifi) {
//       _showBottomNotification("WiFi Connected! Ready to Sync.");
//     }
//     setState(() {
//       _isConnectedToWifi = hasWifi;
//       _statusMessage = hasWifi
//           ? "Connected to WiFi. Ready to receive."
//           : "Please connect to 'FileShareHotspot'";
//     });
//   }

//   // --- 3. TRANSFER LOGIC ---

//   // NEW: UDP Discovery Helper
//   Future<String?> _discoverServer(String? myIp) async {
//     if (myIp == null) return null;

//     RawDatagramSocket? socket;
//     try {
//       socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
//       socket.broadcastEnabled = true;

//       // Send Broadcast to Port 5000
//       socket.send(
//         utf8.encode(SECRET_KEY),
//         InternetAddress('255.255.255.255'),
//         UDP_PORT,
//       );
//       debugPrint("Sent UDP Broadcast...");

//       // Wait for response (Timeout 2 seconds)
//       var event = await socket
//           .firstWhere((event) => event == RawSocketEvent.read)
//           .timeout(const Duration(seconds: 2));

//       if (event == RawSocketEvent.read) {
//         Datagram? dg = socket.receive();
//         if (dg != null) {
//           String message = utf8.decode(dg.data).trim();
//           // Python sends: "IP|PORT"
//           var parts = message.split('|');
//           if (parts.isNotEmpty) {
//             return parts[0]; // Return the IP address
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("UDP Discovery Failed (Timeout or Error): $e");
//     } finally {
//       socket?.close();
//     }
//     return null;
//   }

//   Future<void> startSyncProcess() async {
//     if (!_isConnectedToWifi) {
//       _showBottomNotification(
//         "No WiFi Connection! Check Settings.",
//         isError: true,
//       );
//       return;
//     }

//     if (Platform.isAndroid &&
//         !(await Permission.manageExternalStorage.isGranted)) {
//       await Permission.manageExternalStorage.request();
//       if (!(await Permission.storage.isGranted)) return;
//     }

//     setState(() {
//       _isTransferring = true;
//       _progress = 0.1;
//       _statusMessage = "Locating Server (UDP)...";
//     });

//     try {
//       final info = NetworkInfo();
//       var wifiIP = await info.getWifiIP();

//       // --- CHANGED: Try UDP Discovery First ---
//       String? discoveredIp = await _discoverServer(wifiIP);

//       String targetIp;
//       if (discoveredIp != null) {
//         targetIp = discoveredIp;
//         debugPrint("UDP Discovery Successful: Found Server at $targetIp");
//       } else {
//         // Fallback to Gateway if UDP fails
//         var gatewayIp = await info.getWifiGatewayIP();
//         targetIp = (gatewayIp != null && gatewayIp != "0.0.0.0")
//             ? gatewayIp
//             : "10.42.0.1";
//         debugPrint("UDP Failed. Falling back to Gateway IP: $targetIp");
//       }

//       setState(() {
//         _statusMessage = "Connecting to $targetIp...";
//         _progress = 0.2;
//       });

//       // 1. Create a Unique Folder for this Session
//       String timestamp = DateTime.now()
//           .toString()
//           .replaceAll(RegExp(r'[^0-9]'), '')
//           .substring(0, 12);
//       String batchName = "Batch_$timestamp";

//       Directory rootDir = await _getPublicDir();
//       Directory sessionDir = Directory("${rootDir.path}/$batchName");

//       if (!await sessionDir.exists()) {
//         await sessionDir.create(recursive: true);
//       }

//       // 2. Receive Files into that Folder
//       await _receiveFiles(targetIp, TCP_PORT, wifiIP, sessionDir);

//       // 3. Refresh List
//       await _loadSavedBatches();
//     } catch (e) {
//       setState(() {
//         _statusMessage = "Connection Failed";
//         _isTransferring = false;
//         _progress = 0.0;
//       });
//       _showBottomNotification("Error: ${e.toString()}", isError: true);
//     }
//   }

//   Future<void> _receiveFiles(
//     String ip,
//     int port,
//     String? sourceIP,
//     Directory sessionDir,
//   ) async {
//     Socket? socket;
//     int retryCount = 0;

//     while (socket == null && retryCount < 3) {
//       try {
//         socket = await Socket.connect(
//           ip,
//           port,
//           sourceAddress: sourceIP,
//           timeout: const Duration(seconds: 5),
//         );
//       } catch (e) {
//         retryCount++;
//         await Future.delayed(const Duration(seconds: 1));
//       }
//     }

//     if (socket == null) throw Exception("Could not connect to Server.");

//     try {
//       socket.add(utf8.encode(SECRET_KEY));
//       await socket.flush();

//       StreamIterator<Uint8List> reader = StreamIterator(socket);
//       if (!await _readUntil(reader, "OK")) throw Exception("Auth Failed");

//       String header = await _readHeader(reader);
//       socket.add(utf8.encode("OK"));
//       await socket.flush();

//       if (header.startsWith("NUM_FILES")) {
//         int count = int.parse(header.split("|")[1]);
//         for (int i = 0; i < count; i++) {
//           setState(() {
//             _statusMessage = "Downloading file ${i + 1}/$count...";
//             _progress = (i + 1) / (count + 1);
//           });
//           await _downloadSingleFile(reader, socket, sessionDir);
//         }
//       }

//       setState(() {
//         _isTransferring = false;
//         _statusMessage = "Transfer Complete!";
//         _progress = 1.0;
//       });
//       _showBottomNotification("Saved to: ${sessionDir.path.split('/').last}");
//     } finally {
//       socket.destroy();
//     }
//   }

//   Future<void> _downloadSingleFile(
//     StreamIterator<Uint8List> reader,
//     Socket socket,
//     Directory dir,
//   ) async {
//     String header = await _readHeader(reader);
//     var parts = header.split("|");
//     String filename = parts[0].split('/').last.split('\\').last;
//     int filesize = int.parse(parts[1]);

//     socket.add(utf8.encode("OK"));
//     await socket.flush();

//     File file = File("${dir.path}/$filename");
//     IOSink sink = file.openWrite();

//     int received = 0;
//     while (received < filesize) {
//       if (await reader.moveNext()) {
//         Uint8List chunk = reader.current;
//         int remaining = filesize - received;
//         if (chunk.length > remaining) {
//           sink.add(chunk.sublist(0, remaining));
//           received += remaining;
//         } else {
//           sink.add(chunk);
//           received += chunk.length;
//         }
//       } else {
//         break;
//       }
//     }
//     await sink.flush();
//     await sink.close();
//   }

//   Future<bool> _readUntil(
//     StreamIterator<Uint8List> reader,
//     String target,
//   ) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current).contains(target);
//     }
//     return false;
//   }

//   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current);
//     }
//     throw Exception("Connection closed");
//   }

//   void _showBottomNotification(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B5E20),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // --- 4. UI BUILDING ---
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF4F7F6),
//         elevation: 0,
//         leading: Builder(
//           builder: (c) => IconButton(
//             icon: const Icon(Icons.menu_rounded, size: 32),
//             onPressed: () => Scaffold.of(c).openDrawer(),
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 20),
//             child: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF2E7D32)),
//             ),
//           ),
//         ],
//       ),
//       drawer: _buildDrawer(),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Welcome Back,",
//               style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
//             ),
//             Text(
//               "Agri-Manager",
//               style: GoogleFonts.poppins(
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF191825),
//               ),
//             ),
//             const SizedBox(height: 30),

//             // Status Card
//             Container(
//               padding: const EdgeInsets.all(25),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A1F30),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 10,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "System Status",
//                         style: GoogleFonts.poppins(color: Colors.grey[400]),
//                       ),
//                       Icon(
//                         _isConnectedToWifi ? Icons.wifi : Icons.wifi_off,
//                         color: _isConnectedToWifi
//                             ? Colors.greenAccent
//                             : Colors.redAccent,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     _statusMessage,
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.poppins(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 25),
//                   if (_isTransferring)
//                     LinearProgressIndicator(
//                       value: _progress,
//                       backgroundColor: Colors.white10,
//                       color: const Color(0xFFC8F000),
//                     )
//                   else
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton.icon(
//                         onPressed: startSyncProcess,
//                         icon: const Icon(
//                           Icons.sync_outlined,
//                           color: Colors.black,
//                         ),
//                         label: Text(
//                           "Receive Data",
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFC8F000),
//                           foregroundColor: Colors.black,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),
//             Text(
//               "My Files",
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),

//             // Batch List
//             Expanded(
//               child: _batchFolders.isEmpty
//                   ? Center(
//                       child: Text(
//                         "No batches received yet",
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: _batchFolders.length,
//                       itemBuilder: (context, index) {
//                         Directory dir = _batchFolders[index] as Directory;
//                         String name = dir.path.split('/').last;
//                         return Card(
//                           elevation: 0,
//                           color: Colors.white,
//                           margin: const EdgeInsets.only(bottom: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: ListTile(
//                             leading: Container(
//                               padding: const EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFE3F2FD),
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: const Icon(
//                                 Icons.folder_open,
//                                 color: Color(0xFF1565C0),
//                               ),
//                             ),
//                             title: Text(
//                               name,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             subtitle: Text("Tap to view files"),
//                             trailing: const Icon(
//                               Icons.chevron_right,
//                               color: Colors.grey,
//                             ),
//                             onTap: () async {
//                               // Navigate and wait for result (in case zip extracted)
//                               await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       FolderDetailScreen(directory: dir),
//                                 ),
//                               );
//                               // Refresh list when coming back
//                               _loadSavedBatches();
//                             },
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       backgroundColor: Colors.white,
//       child: Column(
//         children: [
//           const UserAccountsDrawerHeader(
//             decoration: BoxDecoration(color: Color(0xFF191825)),
//             accountName: Text(
//               "Admin User",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             accountEmail: Text("admin@itc.project"),
//             currentAccountPicture: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF191825)),
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.folder_copy),
//             title: const Text("My Files"),
//             onTap: () {
//               // Since 'Home' IS the file viewer, just close drawer
//               Navigator.pop(context);
//             },
//           ),
//           // --- NEW: MESSAGE BOX PAGE ---
//           ListTile(
//             leading: const Icon(Icons.message_outlined),
//             title: const Text("Message Box"),
//             onTap: () {
//               Navigator.pop(context); // Close Drawer
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const MessageBoxScreen(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// // --- UPDATED SCREEN: FOLDER DETAIL VIEW ---
// class FolderDetailScreen extends StatefulWidget {
//   final Directory directory;

//   const FolderDetailScreen({super.key, required this.directory});

//   @override
//   State<FolderDetailScreen> createState() => _FolderDetailScreenState();
// }

// class _FolderDetailScreenState extends State<FolderDetailScreen> {
//   List<FileSystemEntity> _files = [];
//   bool _isProcessing = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadFiles();
//   }

//   void _loadFiles() {
//     try {
//       if (widget.directory.existsSync()) {
//         final files = widget.directory.listSync().whereType<File>().toList()
//           ..sort((a, b) => a.path.compareTo(b.path));
//         setState(() {
//           _files = files;
//         });
//       }
//     } catch (e) {
//       debugPrint("Error listing files: $e");
//     }
//   }

//   // --- LOGIC: UNZIP FILES INTERNALLY ---
//   Future<void> _handleZipFile(File zipFile) async {
//     setState(() => _isProcessing = true);

//     try {
//       final bytes = zipFile.readAsBytesSync();
//       final archive = ZipDecoder().decodeBytes(bytes);

//       // Extract to the same directory
//       for (final file in archive) {
//         final filename = file.name;
//         if (file.isFile) {
//           final data = file.content as List<int>;
//           File('${widget.directory.path}/$filename')
//             ..createSync(recursive: true)
//             ..writeAsBytesSync(data);
//         } else {
//           Directory(
//             '${widget.directory.path}/$filename',
//           ).create(recursive: true);
//         }
//       }

//       // Optional: Delete the zip after extraction to clean up
//       // zipFile.deleteSync();

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Unzip Successful!")));

//       _loadFiles(); // Refresh list to show extracted files
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Unzip Failed: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isProcessing = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.directory.path.split('/').last,
//           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       backgroundColor: const Color(0xFFF4F7F6),
//       body: _isProcessing
//           ? const Center(child: CircularProgressIndicator())
//           : _files.isEmpty
//           ? const Center(child: Text("Empty Folder"))
//           : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _files.length,
//               itemBuilder: (context, index) {
//                 File file = _files[index] as File;
//                 String name = file.path.split('/').last;
//                 String ext = name.split('.').last.toLowerCase();

//                 IconData icon = Icons.insert_drive_file;
//                 Color color = Colors.grey;
//                 bool isZip = false;

//                 if (['jpg', 'jpeg', 'png'].contains(ext)) {
//                   icon = Icons.image;
//                   color = Colors.purple;
//                 } else if (ext == 'pdf') {
//                   icon = Icons.picture_as_pdf;
//                   color = Colors.red;
//                 } else if (ext == 'zip') {
//                   icon = Icons.folder_zip;
//                   color = Colors.orange;
//                   isZip = true;
//                 }

//                 return Card(
//                   elevation: 0,
//                   color: Colors.white,
//                   margin: const EdgeInsets.only(bottom: 10),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: ListTile(
//                     leading: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: color.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(icon, color: color),
//                     ),
//                     title: Text(
//                       name,
//                       style: const TextStyle(fontWeight: FontWeight.w500),
//                     ),
//                     subtitle: Text(
//                       isZip
//                           ? "Tap to Unzip"
//                           : "${(file.lengthSync() / 1024).toStringAsFixed(1)} KB",
//                     ),
//                     trailing: Icon(
//                       isZip ? Icons.system_update_alt : Icons.open_in_new,
//                       size: 20,
//                       color: Colors.grey,
//                     ),
//                     onTap: () {
//                       if (isZip) {
//                         _handleZipFile(file);
//                       } else {
//                         _openFile(context, file.path);
//                       }
//                     },
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   void _openFile(BuildContext context, String path) async {
//     try {
//       final result = await OpenFile.open(path);
//       if (result.type != ResultType.done) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Could not open file: ${result.message}"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
//       );
//     }
//   }
// }

// // --- NEW PAGE: MESSAGE BOX ---
// class MessageBoxScreen extends StatefulWidget {
//   const MessageBoxScreen({super.key});

//   @override
//   State<MessageBoxScreen> createState() => _MessageBoxScreenState();
// }

// class _MessageBoxScreenState extends State<MessageBoxScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final List<String> _messages = []; // Stores chat history
//   RawDatagramSocket? _socket;
//   bool _isSending = false;

//   @override
//   void initState() {
//     super.initState();
//     _startListening();
//   }

//   @override
//   void dispose() {
//     _socket?.close(); // Stop listening when leaving page
//     _controller.dispose();
//     super.dispose();
//   }

//   // --- 1. LISTENER LOGIC ---
//   Future<void> _startListening() async {
//     try {
//       _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 5000);
//       _socket!.broadcastEnabled = true;

//       _socket!.listen((RawSocketEvent event) {
//         if (event == RawSocketEvent.read) {
//           Datagram? dg = _socket!.receive();
//           if (dg != null) {
//             String msg = utf8.decode(dg.data).trim();

//             // Check for Pi's prefix
//             if (msg.startsWith("MSG_FROM_PI:")) {
//               String content = msg.replaceAll("MSG_FROM_PI:", "");
//               setState(() {
//                 // This is the ONLY place where messages are added to history
//                 _messages.add("Pi: $content");
//               });
//             }
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint("Error binding socket: $e");
//     }
//   }

//   // --- 2. SENDER LOGIC ---
//   Future<void> _sendMessage() async {
//     String text = _controller.text.trim();
//     if (text.isEmpty) return;

//     setState(() => _isSending = true);

//     // If socket isn't open, open temporary one (though listener should handle it)
//     if (_socket == null) {
//       await _startListening();
//     }

//     try {
//       // Protocol: "MSG:Hello World"
//       // Sending to Broadcast 255.255.255.255 on Port 5000
//       String payload = "MSG:$text";
//       _socket?.send(
//         utf8.encode(payload),
//         InternetAddress('255.255.255.255'),
//         5000,
//       );

//       // NOTE: Logic to add "Me: $text" to history has been REMOVED.

//       _controller.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
//       );
//     } finally {
//       setState(() => _isSending = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Message Box",
//           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       backgroundColor: const Color(0xFFF4F7F6),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Send Message to Device",
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF191825),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Input Area
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 10,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: TextField(
//                 controller: _controller,
//                 maxLines: 3,
//                 decoration: InputDecoration(
//                   hintText: "Type your message here...",
//                   hintStyle: GoogleFonts.poppins(color: Colors.grey),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(16),
//                     borderSide: BorderSide.none,
//                   ),
//                   contentPadding: const EdgeInsets.all(20),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Send Button
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton.icon(
//                 onPressed: _isSending ? null : _sendMessage,
//                 icon: _isSending
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.black,
//                         ),
//                       )
//                     : const Icon(Icons.send, color: Colors.black),
//                 label: Text(
//                   _isSending ? "Sending..." : "Send Message",
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFC8F000),
//                   foregroundColor: Colors.black,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 30),

//             // --- CHAT HISTORY DISPLAY ---
//             Text(
//               "Incoming Messages",
//               style: GoogleFonts.poppins(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[700],
//               ),
//             ),
//             const SizedBox(height: 10),

//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: Colors.black12),
//                 ),
//                 child: _messages.isEmpty
//                     ? Center(
//                         child: Text(
//                           "No incoming messages",
//                           style: TextStyle(color: Colors.grey),
//                         ),
//                       )
//                     : ListView.builder(
//                         itemCount: _messages.length,
//                         itemBuilder: (context, index) {
//                           return Container(
//                             margin: const EdgeInsets.only(bottom: 10),
//                             // Always align left since these are incoming messages
//                             alignment: Alignment.centerLeft,
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 10,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFE8F5E9),
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: const Color(0xFFC8E6C9),
//                                 ),
//                               ),
//                               child: Text(
//                                 _messages[index], // Will be "Pi: [Message Content]"
//                                 style: GoogleFonts.poppins(
//                                   color: Colors.green[900],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// 19 FIRST CHANGE
// 28 FIRST CHANGE
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:archive/archive_io.dart'; // Import for Unzipping

// // --- CONFIGURATION ---
// const String SECRET_KEY = "securekey";
// const int TCP_PORT = 5001;
// const int UDP_PORT = 5000; // Added for Discovery & Messaging

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'AgriSync',
//       theme: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: const Color(0xFFF4F7F6),
//         primaryColor: const Color(0xFF2E7D32),
//         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
//         textTheme: GoogleFonts.poppinsTextTheme(),
//       ),
//       home: const HomeScreen(),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // --- STATE VARIABLES ---
//   String _statusMessage = "Please connect to 'FileShareHotspot'";
//   bool _isConnectedToWifi = false;
//   bool _isTransferring = false;
//   double _progress = 0.0;

//   // List of Saved Batches (Folders)
//   List<FileSystemEntity> _batchFolders = [];

//   final Connectivity _connectivity = Connectivity();
//   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _checkInitialConnection();
//     _loadSavedBatches(); // Load history on startup

//     _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
//       result,
//     ) {
//       _updateConnectionStatus(result);
//     });
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     super.dispose();
//   }

//   // --- 1. FILE SYSTEM & PERSISTENCE ---
//   Future<Directory> _getPublicDir() async {
//     // Saves to: Internal Storage > Download > AgriSync_Files
//     Directory dir = Directory('/storage/emulated/0/Download/AgriSync_Files');
//     if (!await dir.exists()) {
//       try {
//         await dir.create(recursive: true);
//       } catch (e) {
//         debugPrint("Error creating directory: $e");
//         dir =
//             await getExternalStorageDirectory() ??
//             await getApplicationDocumentsDirectory();
//       }
//     }
//     return dir;
//   }

//   Future<void> _loadSavedBatches() async {
//     try {
//       final dir = await _getPublicDir();
//       if (await dir.exists()) {
//         final entities = dir.listSync();
//         setState(() {
//           // Get folders only and sort by newest first
//           _batchFolders = entities.whereType<Directory>().toList()
//             ..sort(
//               (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
//             );
//         });
//       }
//     } catch (e) {
//       debugPrint("Error loading batches: $e");
//     }
//   }

//   // --- 2. PERMISSIONS & WIFI ---
//   Future<void> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       await Permission.storage.request();
//       if (await Permission.manageExternalStorage.status.isDenied) {
//         await Permission.manageExternalStorage.request();
//       }
//       await [Permission.location, Permission.nearbyWifiDevices].request();
//     }
//   }

//   void _checkInitialConnection() async {
//     var result = await _connectivity.checkConnectivity();
//     _updateConnectionStatus(result);
//   }

//   void _updateConnectionStatus(ConnectivityResult result) async {
//     bool hasWifi = result == ConnectivityResult.wifi;
//     if (hasWifi && !_isConnectedToWifi) {
//       _showBottomNotification("WiFi Connected! Ready to Sync.");
//     }
//     setState(() {
//       _isConnectedToWifi = hasWifi;
//       _statusMessage = hasWifi
//           ? "Connected to WiFi. Ready to receive."
//           : "Please connect to 'FileShareHotspot'";
//     });
//   }

//   // --- 3. TRANSFER LOGIC ---

//   // NEW: UDP Discovery Helper
//   Future<String?> _discoverServer(String? myIp) async {
//     if (myIp == null) return null;

//     RawDatagramSocket? socket;
//     try {
//       socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
//       socket.broadcastEnabled = true;

//       // Send Broadcast to Port 5000
//       socket.send(
//         utf8.encode(SECRET_KEY),
//         InternetAddress('255.255.255.255'),
//         UDP_PORT,
//       );
//       debugPrint("Sent UDP Broadcast...");

//       // Wait for response (Timeout 2 seconds)
//       var event = await socket
//           .firstWhere((event) => event == RawSocketEvent.read)
//           .timeout(const Duration(seconds: 2));

//       if (event == RawSocketEvent.read) {
//         Datagram? dg = socket.receive();
//         if (dg != null) {
//           String message = utf8.decode(dg.data).trim();
//           // Python sends: "IP|PORT"
//           var parts = message.split('|');
//           if (parts.isNotEmpty) {
//             return parts[0]; // Return the IP address
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("UDP Discovery Failed (Timeout or Error): $e");
//     } finally {
//       socket?.close();
//     }
//     return null;
//   }

//   Future<void> startSyncProcess() async {
//     if (!_isConnectedToWifi) {
//       _showBottomNotification(
//         "No WiFi Connection! Check Settings.",
//         isError: true,
//       );
//       return;
//     }

//     if (Platform.isAndroid &&
//         !(await Permission.manageExternalStorage.isGranted)) {
//       await Permission.manageExternalStorage.request();
//       if (!(await Permission.storage.isGranted)) return;
//     }

//     setState(() {
//       _isTransferring = true;
//       _progress = 0.1;
//       _statusMessage = "Locating Server (UDP)...";
//     });

//     try {
//       final info = NetworkInfo();
//       var wifiIP = await info.getWifiIP();

//       // --- CHANGED: Try UDP Discovery First ---
//       String? discoveredIp = await _discoverServer(wifiIP);

//       String targetIp;
//       if (discoveredIp != null) {
//         targetIp = discoveredIp;
//         debugPrint("UDP Discovery Successful: Found Server at $targetIp");
//       } else {
//         // Fallback to Gateway if UDP fails
//         var gatewayIp = await info.getWifiGatewayIP();
//         targetIp = (gatewayIp != null && gatewayIp != "0.0.0.0")
//             ? gatewayIp
//             : "10.42.0.1";
//         debugPrint("UDP Failed. Falling back to Gateway IP: $targetIp");
//       }

//       setState(() {
//         _statusMessage = "Connecting to $targetIp...";
//         _progress = 0.2;
//       });

//       // 1. Create a Unique Folder for this Session
//       String timestamp = DateTime.now()
//           .toString()
//           .replaceAll(RegExp(r'[^0-9]'), '')
//           .substring(0, 12);
//       String batchName = "Batch_$timestamp";

//       Directory rootDir = await _getPublicDir();
//       Directory sessionDir = Directory("${rootDir.path}/$batchName");

//       if (!await sessionDir.exists()) {
//         await sessionDir.create(recursive: true);
//       }

//       // 2. Receive Files into that Folder
//       await _receiveFiles(targetIp, TCP_PORT, wifiIP, sessionDir);

//       // 3. Refresh List
//       await _loadSavedBatches();
//     } catch (e) {
//       setState(() {
//         _statusMessage = "Connection Failed";
//         _isTransferring = false;
//         _progress = 0.0;
//       });
//       _showBottomNotification("Error: ${e.toString()}", isError: true);
//     }
//   }

//   Future<void> _receiveFiles(
//     String ip,
//     int port,
//     String? sourceIP,
//     Directory sessionDir,
//   ) async {
//     Socket? socket;
//     int retryCount = 0;

//     while (socket == null && retryCount < 3) {
//       try {
//         socket = await Socket.connect(
//           ip,
//           port,
//           sourceAddress: sourceIP,
//           timeout: const Duration(seconds: 5),
//         );
//       } catch (e) {
//         retryCount++;
//         await Future.delayed(const Duration(seconds: 1));
//       }
//     }

//     if (socket == null) throw Exception("Could not connect to Server.");

//     try {
//       socket.add(utf8.encode(SECRET_KEY));
//       await socket.flush();

//       StreamIterator<Uint8List> reader = StreamIterator(socket);
//       if (!await _readUntil(reader, "OK")) throw Exception("Auth Failed");

//       String header = await _readHeader(reader);
//       socket.add(utf8.encode("OK"));
//       await socket.flush();

//       if (header.startsWith("NUM_FILES")) {
//         int count = int.parse(header.split("|")[1]);
//         for (int i = 0; i < count; i++) {
//           setState(() {
//             _statusMessage = "Downloading file ${i + 1}/$count...";
//             _progress = (i + 1) / (count + 1);
//           });
//           await _downloadSingleFile(reader, socket, sessionDir);
//         }
//       }

//       setState(() {
//         _isTransferring = false;
//         _statusMessage = "Transfer Complete!";
//         _progress = 1.0;
//       });
//       _showBottomNotification("Saved to: ${sessionDir.path.split('/').last}");
//     } finally {
//       socket.destroy();
//     }
//   }

//   Future<void> _downloadSingleFile(
//     StreamIterator<Uint8List> reader,
//     Socket socket,
//     Directory dir,
//   ) async {
//     String header = await _readHeader(reader);
//     var parts = header.split("|");
//     String filename = parts[0].split('/').last.split('\\').last;
//     int filesize = int.parse(parts[1]);

//     socket.add(utf8.encode("OK"));
//     await socket.flush();

//     File file = File("${dir.path}/$filename");
//     IOSink sink = file.openWrite();

//     int received = 0;
//     while (received < filesize) {
//       if (await reader.moveNext()) {
//         Uint8List chunk = reader.current;
//         int remaining = filesize - received;
//         if (chunk.length > remaining) {
//           sink.add(chunk.sublist(0, remaining));
//           received += remaining;
//         } else {
//           sink.add(chunk);
//           received += chunk.length;
//         }
//       } else {
//         break;
//       }
//     }
//     await sink.flush();
//     await sink.close();
//   }

//   Future<bool> _readUntil(
//     StreamIterator<Uint8List> reader,
//     String target,
//   ) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current).contains(target);
//     }
//     return false;
//   }

//   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
//     if (await reader.moveNext()) {
//       return utf8.decode(reader.current);
//     }
//     throw Exception("Connection closed");
//   }

//   void _showBottomNotification(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B5E20),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // --- 4. UI BUILDING ---
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF4F7F6),
//         elevation: 0,
//         leading: Builder(
//           builder: (c) => IconButton(
//             icon: const Icon(Icons.menu_rounded, size: 32),
//             onPressed: () => Scaffold.of(c).openDrawer(),
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 20),
//             child: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF2E7D32)),
//             ),
//           ),
//         ],
//       ),
//       drawer: _buildDrawer(),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Welcome Back,",
//               style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
//             ),
//             Text(
//               "Agri-Manager",
//               style: GoogleFonts.poppins(
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF191825),
//               ),
//             ),
//             const SizedBox(height: 30),

//             // Status Card
//             Container(
//               padding: const EdgeInsets.all(25),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A1F30),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 10,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "System Status",
//                         style: GoogleFonts.poppins(color: Colors.grey[400]),
//                       ),
//                       Icon(
//                         _isConnectedToWifi ? Icons.wifi : Icons.wifi_off,
//                         color: _isConnectedToWifi
//                             ? Colors.greenAccent
//                             : Colors.redAccent,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     _statusMessage,
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.poppins(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 25),
//                   if (_isTransferring)
//                     LinearProgressIndicator(
//                       value: _progress,
//                       backgroundColor: Colors.white10,
//                       color: const Color(0xFFC8F000),
//                     )
//                   else
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton.icon(
//                         onPressed: startSyncProcess,
//                         icon: const Icon(
//                           Icons.sync_outlined,
//                           color: Colors.black,
//                         ),
//                         label: Text(
//                           "Receive Data",
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFC8F000),
//                           foregroundColor: Colors.black,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),
//             Text(
//               "My Files",
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),

//             // Batch List
//             Expanded(
//               child: _batchFolders.isEmpty
//                   ? Center(
//                       child: Text(
//                         "No batches received yet",
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: _batchFolders.length,
//                       itemBuilder: (context, index) {
//                         Directory dir = _batchFolders[index] as Directory;
//                         String name = dir.path.split('/').last;
//                         return Card(
//                           elevation: 0,
//                           color: Colors.white,
//                           margin: const EdgeInsets.only(bottom: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: ListTile(
//                             leading: Container(
//                               padding: const EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFE3F2FD),
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: const Icon(
//                                 Icons.folder_open,
//                                 color: Color(0xFF1565C0),
//                               ),
//                             ),
//                             title: Text(
//                               name,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             subtitle: Text("Tap to view files"),
//                             trailing: const Icon(
//                               Icons.chevron_right,
//                               color: Colors.grey,
//                             ),
//                             onTap: () async {
//                               // Navigate and wait for result (in case zip extracted)
//                               await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       FolderDetailScreen(directory: dir),
//                                 ),
//                               );
//                               // Refresh list when coming back
//                               _loadSavedBatches();
//                             },
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       backgroundColor: Colors.white,
//       child: Column(
//         children: [
//           const UserAccountsDrawerHeader(
//             decoration: BoxDecoration(color: Color(0xFF191825)),
//             accountName: Text(
//               "Admin User",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             accountEmail: Text("admin@itc.project"),
//             currentAccountPicture: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF191825)),
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.folder_copy),
//             title: const Text("My Files"),
//             onTap: () {
//               // Since 'Home' IS the file viewer, just close drawer
//               Navigator.pop(context);
//             },
//           ),
//           // --- NEW: MESSAGE BOX PAGE ---
//           ListTile(
//             leading: const Icon(Icons.message_outlined),
//             title: const Text("Message Box"),
//             onTap: () {
//               Navigator.pop(context); // Close Drawer
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const MessageBoxScreen(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// // --- UPDATED SCREEN: FOLDER DETAIL VIEW ---
// class FolderDetailScreen extends StatefulWidget {
//   final Directory directory;

//   const FolderDetailScreen({super.key, required this.directory});

//   @override
//   State<FolderDetailScreen> createState() => _FolderDetailScreenState();
// }

// class _FolderDetailScreenState extends State<FolderDetailScreen> {
//   List<FileSystemEntity> _files = [];
//   bool _isProcessing = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadFiles();
//   }

//   void _loadFiles() {
//     try {
//       if (widget.directory.existsSync()) {
//         final files = widget.directory.listSync().whereType<File>().toList()
//           ..sort((a, b) => a.path.compareTo(b.path));
//         setState(() {
//           _files = files;
//         });
//       }
//     } catch (e) {
//       debugPrint("Error listing files: $e");
//     }
//   }

//   // --- LOGIC: UNZIP FILES INTERNALLY ---
//   Future<void> _handleZipFile(File zipFile) async {
//     setState(() => _isProcessing = true);

//     try {
//       final bytes = zipFile.readAsBytesSync();
//       final archive = ZipDecoder().decodeBytes(bytes);

//       // Extract to the same directory
//       for (final file in archive) {
//         final filename = file.name;
//         if (file.isFile) {
//           final data = file.content as List<int>;
//           File('${widget.directory.path}/$filename')
//             ..createSync(recursive: true)
//             ..writeAsBytesSync(data);
//         } else {
//           Directory(
//             '${widget.directory.path}/$filename',
//           ).create(recursive: true);
//         }
//       }

//       // Optional: Delete the zip after extraction to clean up
//       // zipFile.deleteSync();

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Unzip Successful!")));

//       _loadFiles(); // Refresh list to show extracted files
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Unzip Failed: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isProcessing = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.directory.path.split('/').last,
//           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       backgroundColor: const Color(0xFFF4F7F6),
//       body: _isProcessing
//           ? const Center(child: CircularProgressIndicator())
//           : _files.isEmpty
//           ? const Center(child: Text("Empty Folder"))
//           : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _files.length,
//               itemBuilder: (context, index) {
//                 File file = _files[index] as File;
//                 String name = file.path.split('/').last;
//                 String ext = name.split('.').last.toLowerCase();

//                 IconData icon = Icons.insert_drive_file;
//                 Color color = Colors.grey;
//                 bool isZip = false;

//                 if (['jpg', 'jpeg', 'png'].contains(ext)) {
//                   icon = Icons.image;
//                   color = Colors.purple;
//                 } else if (ext == 'pdf') {
//                   icon = Icons.picture_as_pdf;
//                   color = Colors.red;
//                 } else if (ext == 'zip') {
//                   icon = Icons.folder_zip;
//                   color = Colors.orange;
//                   isZip = true;
//                 }

//                 return Card(
//                   elevation: 0,
//                   color: Colors.white,
//                   margin: const EdgeInsets.only(bottom: 10),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: ListTile(
//                     leading: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: color.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(icon, color: color),
//                     ),
//                     title: Text(
//                       name,
//                       style: const TextStyle(fontWeight: FontWeight.w500),
//                     ),
//                     subtitle: Text(
//                       isZip
//                           ? "Tap to Unzip"
//                           : "${(file.lengthSync() / 1024).toStringAsFixed(1)} KB",
//                     ),
//                     trailing: Icon(
//                       isZip ? Icons.system_update_alt : Icons.open_in_new,
//                       size: 20,
//                       color: Colors.grey,
//                     ),
//                     onTap: () {
//                       if (isZip) {
//                         _handleZipFile(file);
//                       } else {
//                         _openFile(context, file.path);
//                       }
//                     },
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   void _openFile(BuildContext context, String path) async {
//     try {
//       final result = await OpenFile.open(path);
//       if (result.type != ResultType.done) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Could not open file: ${result.message}"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
//       );
//     }
//   }
// }

// // --- NEW PAGE: MESSAGE BOX ---
// class MessageBoxScreen extends StatefulWidget {
//   const MessageBoxScreen({super.key});

//   @override
//   State<MessageBoxScreen> createState() => _MessageBoxScreenState();
// }

// class _MessageBoxScreenState extends State<MessageBoxScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final List<String> _messages = []; // Stores chat history
//   RawDatagramSocket? _socket;
//   bool _isSending = false;

//   @override
//   void initState() {
//     super.initState();
//     _startListening();
//   }

//   @override
//   void dispose() {
//     _socket?.close(); // Stop listening when leaving page
//     _controller.dispose();
//     super.dispose();
//   }

//   // --- 1. LISTENER LOGIC ---
//   Future<void> _startListening() async {
//     try {
//       _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 5000);
//       _socket!.broadcastEnabled = true;

//       _socket!.listen((RawSocketEvent event) {
//         if (event == RawSocketEvent.read) {
//           Datagram? dg = _socket!.receive();
//           if (dg != null) {
//             String msg = utf8.decode(dg.data).trim();

//             // Check for Pi's prefix
//             if (msg.startsWith("MSG_FROM_PI:")) {
//               String content = msg.replaceAll("MSG_FROM_PI:", "");
//               setState(() {
//                 // This is the ONLY place where messages are added to history
//                 _messages.add("Pi: $content");
//               });
//             }
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint("Error binding socket: $e");
//     }
//   }

//   // --- 2. SENDER LOGIC ---
//   Future<void> _sendMessage() async {
//     String text = _controller.text.trim();
//     if (text.isEmpty) return;

//     setState(() => _isSending = true);

//     // If socket isn't open, open temporary one (though listener should handle it)
//     if (_socket == null) {
//       await _startListening();
//     }

//     try {
//       // Protocol: "MSG:Hello World"
//       // Sending to Broadcast 255.255.255.255 on Port 5000
//       String payload = "MSG:$text";
//       _socket?.send(
//         utf8.encode(payload),
//         InternetAddress('255.255.255.255'),
//         5000,
//       );

//       // NOTE: Logic to add "Me: $text" to history has been REMOVED.

//       _controller.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
//       );
//     } finally {
//       setState(() => _isSending = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Message Box",
//           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       backgroundColor: const Color(0xFFF4F7F6),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Send Message to Device",
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF191825),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Input Area
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 10,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: TextField(
//                 controller: _controller,
//                 maxLines: 3,
//                 decoration: InputDecoration(
//                   hintText: "Type your message here...",
//                   hintStyle: GoogleFonts.poppins(color: Colors.grey),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(16),
//                     borderSide: BorderSide.none,
//                   ),
//                   contentPadding: const EdgeInsets.all(20),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Send Button
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton.icon(
//                 onPressed: _isSending ? null : _sendMessage,
//                 icon: _isSending
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.black,
//                         ),
//                       )
//                     : const Icon(Icons.send, color: Colors.black),
//                 label: Text(
//                   _isSending ? "Sending..." : "Send Message",
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFC8F000),
//                   foregroundColor: Colors.black,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 30),

//             // --- CHAT HISTORY DISPLAY ---
//             Text(
//               "Incoming Messages",
//               style: GoogleFonts.poppins(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[700],
//               ),
//             ),
//             const SizedBox(height: 10),

//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: Colors.black12),
//                 ),
//                 child: _messages.isEmpty
//                     ? Center(
//                         child: Text(
//                           "No incoming messages",
//                           style: TextStyle(color: Colors.grey),
//                         ),
//                       )
//                     : ListView.builder(
//                         itemCount: _messages.length,
//                         itemBuilder: (context, index) {
//                           return Container(
//                             margin: const EdgeInsets.only(bottom: 10),
//                             // Always align left since these are incoming messages
//                             alignment: Alignment.centerLeft,
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 10,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFE8F5E9),
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: const Color(0xFFC8E6C9),
//                                 ),
//                               ),
//                               child: Text(
//                                 _messages[index], // Will be "Pi: [Message Content]"
//                                 style: GoogleFonts.poppins(
//                                   color: Colors.green[900],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// 28 STRUCTURED CODE
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart'; // Import Login Screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriSync',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      // CHANGE: Start with LoginScreen instead of HomeScreen
      home: const LoginScreen(),
    );
  }
}
