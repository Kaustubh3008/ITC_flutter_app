// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// import '../config.dart';
// import '../widgets/app_drawer.dart';
// import 'folder_detail_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   String _statusMessage = "Please connect to 'FileShareHotspot'";
//   bool _isConnectedToWifi = false;
//   bool _isTransferring = false;
//   double _progress = 0.0;
//   List<FileSystemEntity> _batchFolders = [];
//   final Connectivity _connectivity = Connectivity();
//   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _checkInitialConnection();
//     _loadSavedBatches();
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

//   Future<Directory> _getPublicDir() async {
//     Directory dir = Directory('/storage/emulated/0/Download/AgriSync_Files');
//     if (!await dir.exists()) {
//       try {
//         await dir.create(recursive: true);
//       } catch (e) {
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

//   Future<String?> _discoverServer(String? myIp) async {
//     if (myIp == null) return null;
//     RawDatagramSocket? socket;
//     try {
//       socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
//       socket.broadcastEnabled = true;
//       socket.send(
//         utf8.encode(SECRET_KEY),
//         InternetAddress('255.255.255.255'),
//         UDP_PORT,
//       );
//       var event = await socket
//           .firstWhere((event) => event == RawSocketEvent.read)
//           .timeout(const Duration(seconds: 2));
//       if (event == RawSocketEvent.read) {
//         Datagram? dg = socket.receive();
//         if (dg != null) {
//           String message = utf8.decode(dg.data).trim();
//           var parts = message.split('|');
//           if (parts.isNotEmpty) return parts[0];
//         }
//       }
//     } catch (e) {
//       debugPrint("UDP Discovery Failed: $e");
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
//       String? discoveredIp = await _discoverServer(wifiIP);
//       String targetIp =
//           discoveredIp ?? (await info.getWifiGatewayIP() ?? "10.42.0.1");

//       setState(() {
//         _statusMessage = "Connecting to $targetIp...";
//         _progress = 0.2;
//       });

//       String timestamp = DateTime.now()
//           .toString()
//           .replaceAll(RegExp(r'[^0-9]'), '')
//           .substring(0, 12);
//       String batchName = "Batch_$timestamp";
//       Directory rootDir = await _getPublicDir();
//       Directory sessionDir = Directory("${rootDir.path}/$batchName");
//       if (!await sessionDir.exists()) await sessionDir.create(recursive: true);

//       await _receiveFiles(targetIp, TCP_PORT, wifiIP, sessionDir);
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
//     if (await reader.moveNext())
//       return utf8.decode(reader.current).contains(target);
//     return false;
//   }

//   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
//     if (await reader.moveNext()) return utf8.decode(reader.current);
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
//         actions: const [
//           Padding(
//             padding: EdgeInsets.only(right: 20),
//             child: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF2E7D32)),
//             ),
//           ),
//         ],
//       ),
//       drawer: const AppDrawer(),
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
//             Container(
//               padding: const EdgeInsets.all(25),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A1F30),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: const [
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
//             Expanded(
//               child: _batchFolders.isEmpty
//                   ? const Center(
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
//                             subtitle: const Text("Tap to view files"),
//                             trailing: const Icon(
//                               Icons.chevron_right,
//                               color: Colors.grey,
//                             ),
//                             onTap: () async {
//                               await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       FolderDetailScreen(directory: dir),
//                                 ),
//                               );
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
// }

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// import '../config.dart';
// import '../widgets/app_drawer.dart';
// import 'folder_detail_screen.dart'; // <--- THIS IMPORT IS CRITICAL

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   String _statusMessage = "Please connect to 'FileShareHotspot'";
//   bool _isConnectedToWifi = false;
//   bool _isTransferring = false;
//   double _progress = 0.0;
//   List<FileSystemEntity> _batchFolders = [];
//   final Connectivity _connectivity = Connectivity();
//   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _checkInitialConnection();
//     _loadSavedBatches();
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

//   Future<Directory> _getPublicDir() async {
//     Directory dir = Directory('/storage/emulated/0/Download/AgriSync_Files');
//     if (!await dir.exists()) {
//       try {
//         await dir.create(recursive: true);
//       } catch (e) {
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

//   Future<String?> _discoverServer(String? myIp) async {
//     if (myIp == null) return null;
//     RawDatagramSocket? socket;
//     try {
//       socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
//       socket.broadcastEnabled = true;
//       socket.send(
//         utf8.encode(SECRET_KEY),
//         InternetAddress('255.255.255.255'),
//         UDP_PORT,
//       );
//       var event = await socket
//           .firstWhere((event) => event == RawSocketEvent.read)
//           .timeout(const Duration(seconds: 2));
//       if (event == RawSocketEvent.read) {
//         Datagram? dg = socket.receive();
//         if (dg != null) {
//           String message = utf8.decode(dg.data).trim();
//           var parts = message.split('|');
//           if (parts.isNotEmpty) return parts[0];
//         }
//       }
//     } catch (e) {
//       debugPrint("UDP Discovery Failed: $e");
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
//       String? discoveredIp = await _discoverServer(wifiIP);
//       String targetIp =
//           discoveredIp ?? (await info.getWifiGatewayIP() ?? "10.42.0.1");

//       setState(() {
//         _statusMessage = "Connecting to $targetIp...";
//         _progress = 0.2;
//       });

//       String timestamp = DateTime.now()
//           .toString()
//           .replaceAll(RegExp(r'[^0-9]'), '')
//           .substring(0, 12);
//       String batchName = "Batch_$timestamp";
//       Directory rootDir = await _getPublicDir();
//       Directory sessionDir = Directory("${rootDir.path}/$batchName");
//       if (!await sessionDir.exists()) await sessionDir.create(recursive: true);

//       await _receiveFiles(targetIp, TCP_PORT, wifiIP, sessionDir);
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
//     if (await reader.moveNext())
//       return utf8.decode(reader.current).contains(target);
//     return false;
//   }

//   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
//     if (await reader.moveNext()) return utf8.decode(reader.current);
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
//         actions: const [
//           Padding(
//             padding: EdgeInsets.only(right: 20),
//             child: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF2E7D32)),
//             ),
//           ),
//         ],
//       ),
//       drawer: const AppDrawer(),
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
//             Container(
//               padding: const EdgeInsets.all(25),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A1F30),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: const [
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
//             Expanded(
//               child: _batchFolders.isEmpty
//                   ? const Center(
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
//                             subtitle: const Text("Tap to view files"),
//                             trailing: const Icon(
//                               Icons.chevron_right,
//                               color: Colors.grey,
//                             ),
//                             onTap: () async {
//                               await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       FolderDetailScreen(directory: dir),
//                                 ),
//                               );
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
// }





// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// import '../config.dart';
// import '../widgets/app_drawer.dart';
// import 'folder_detail_screen.dart'; // <--- THIS IMPORT IS CRITICAL

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   String _statusMessage = "Please connect to 'FileShareHotspot'";
//   bool _isConnectedToWifi = false;
//   bool _isTransferring = false;
//   double _progress = 0.0;
//   List<FileSystemEntity> _batchFolders = [];
//   final Connectivity _connectivity = Connectivity();
//   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _checkInitialConnection();
//     _loadSavedBatches();
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

//   Future<Directory> _getPublicDir() async {
//     Directory dir = Directory('/storage/emulated/0/Download/AgriSync_Files');
//     if (!await dir.exists()) {
//       try {
//         await dir.create(recursive: true);
//       } catch (e) {
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

//   Future<String?> _discoverServer(String? myIp) async {
//     if (myIp == null) return null;
//     RawDatagramSocket? socket;
//     try {
//       socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
//       socket.broadcastEnabled = true;
//       socket.send(
//         utf8.encode(SECRET_KEY),
//         InternetAddress('255.255.255.255'),
//         UDP_PORT,
//       );
//       var event = await socket
//           .firstWhere((event) => event == RawSocketEvent.read)
//           .timeout(const Duration(seconds: 2));
//       if (event == RawSocketEvent.read) {
//         Datagram? dg = socket.receive();
//         if (dg != null) {
//           String message = utf8.decode(dg.data).trim();
//           var parts = message.split('|');
//           if (parts.isNotEmpty) return parts[0];
//         }
//       }
//     } catch (e) {
//       debugPrint("UDP Discovery Failed: $e");
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
//       String? discoveredIp = await _discoverServer(wifiIP);
//       String targetIp =
//           discoveredIp ?? (await info.getWifiGatewayIP() ?? "10.42.0.1");

//       setState(() {
//         _statusMessage = "Connecting to $targetIp...";
//         _progress = 0.2;
//       });

//       String timestamp = DateTime.now()
//           .toString()
//           .replaceAll(RegExp(r'[^0-9]'), '')
//           .substring(0, 12);
//       String batchName = "Batch.$timestamp";
//       Directory rootDir = await _getPublicDir();
//       // Directory sessionDir = Directory("${rootDir.path}");
//       Directory sessionDir = Directory("${rootDir.path}/$batchName");
//       if (!await sessionDir.exists()) await sessionDir.create(recursive: true);

//       await _receiveFiles(targetIp, TCP_PORT, wifiIP, sessionDir);
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
//     if (await reader.moveNext())
//       return utf8.decode(reader.current).contains(target);
//     return false;
//   }

//   Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
//     if (await reader.moveNext()) return utf8.decode(reader.current);
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
//         actions: const [
//           Padding(
//             padding: EdgeInsets.only(right: 20),
//             child: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Color(0xFF2E7D32)),
//             ),
//           ),
//         ],
//       ),
//       drawer: const AppDrawer(),
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
//             Container(
//               padding: const EdgeInsets.all(25),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A1F30),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: const [
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
//             Expanded(
//               child: _batchFolders.isEmpty
//                   ? const Center(
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
//                             subtitle: const Text("Tap to view files"),
//                             trailing: const Icon(
//                               Icons.chevron_right,
//                               color: Colors.grey,
//                             ),
//                             onTap: () async {
//                               await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       FolderDetailScreen(directory: dir),
//                                 ),
//                               );
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
// }







import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config.dart';
import '../widgets/app_drawer.dart';
import 'folder_detail_screen.dart'; // <--- THIS IMPORT IS CRITICAL

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _statusMessage = "Please connect to 'FileShareHotspot'";
  bool _isConnectedToWifi = false;
  bool _isTransferring = false;
  double _progress = 0.0;
  List<FileSystemEntity> _batchFolders = [];
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _checkInitialConnection();
    _loadSavedBatches();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      _updateConnectionStatus(result);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<Directory> _getPublicDir() async {
    Directory dir = Directory('/storage/emulated/0/Download/AgriSync_Files');
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (e) {
        dir =
            await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      }
    }
    return dir;
  }

  Future<void> _loadSavedBatches() async {
    try {
      final dir = await _getPublicDir();
      if (await dir.exists()) {
        final entities = dir.listSync();
        setState(() {
          _batchFolders = entities.whereType<Directory>().toList()
            ..sort(
              (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
            );
        });
      }
    } catch (e) {
      debugPrint("Error loading batches: $e");
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      if (await Permission.manageExternalStorage.status.isDenied) {
        await Permission.manageExternalStorage.request();
      }
      await [Permission.location, Permission.nearbyWifiDevices].request();
    }
  }

  void _checkInitialConnection() async {
    var result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) async {
    bool hasWifi = result == ConnectivityResult.wifi;
    if (hasWifi && !_isConnectedToWifi) {
      _showBottomNotification("WiFi Connected! Ready to Sync.");
    }
    setState(() {
      _isConnectedToWifi = hasWifi;
      _statusMessage = hasWifi
          ? "Connected to WiFi. Ready to receive."
          : "Please connect to 'FileShareHotspot'";
    });
  }

  Future<String?> _discoverServer(String? myIp) async {
    if (myIp == null) return null;
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(
        utf8.encode(SECRET_KEY),
        InternetAddress('255.255.255.255'),
        UDP_PORT,
      );
      var event = await socket
          .firstWhere((event) => event == RawSocketEvent.read)
          .timeout(const Duration(seconds: 2));
      if (event == RawSocketEvent.read) {
        Datagram? dg = socket.receive();
        if (dg != null) {
          String message = utf8.decode(dg.data).trim();
          var parts = message.split('|');
          if (parts.isNotEmpty) return parts[0];
        }
      }
    } catch (e) {
      debugPrint("UDP Discovery Failed: $e");
    } finally {
      socket?.close();
    }
    return null;
  }

  Future<void> startSyncProcess() async {
    if (!_isConnectedToWifi) {
      _showBottomNotification(
        "No WiFi Connection! Check Settings.",
        isError: true,
      );
      return;
    }
    if (Platform.isAndroid &&
        !(await Permission.manageExternalStorage.isGranted)) {
      await Permission.manageExternalStorage.request();
      if (!(await Permission.storage.isGranted)) return;
    }

    setState(() {
      _isTransferring = true;
      _progress = 0.1;
      _statusMessage = "Locating Server (UDP)...";
    });

    try {
      final info = NetworkInfo();
      var wifiIP = await info.getWifiIP();
      String? discoveredIp = await _discoverServer(wifiIP);
      String targetIp =
          discoveredIp ?? (await info.getWifiGatewayIP() ?? "10.42.0.1");

      setState(() {
        _statusMessage = "Connecting to $targetIp...";
        _progress = 0.2;
      });

      String timestamp = DateTime.now()
          .toString()
          .replaceAll(RegExp(r'[^0-9]'), '')
          .substring(0, 12);
      String batchName = "Batch.$timestamp";
      Directory rootDir = await _getPublicDir();
      // Directory sessionDir = Directory("${rootDir.path}");
      Directory sessionDir = Directory("${rootDir.path}/$batchName");
      if (!await sessionDir.exists()) await sessionDir.create(recursive: true);

      await _receiveFiles(targetIp, TCP_PORT, wifiIP, sessionDir);
      try {
        // 1. List everything inside the new Batch folder
        List<FileSystemEntity> files = sessionDir.listSync();

        // 2. Find the .zip file
        var zipFile = files.firstWhere(
          (file) => file is File && file.path.endsWith('.zip'),
          orElse: () =>
              File(''), // Return empty file if not found to avoid crash
        );

        if (zipFile.path.isNotEmpty) {
          print(">>> SUCCESS: Found the file inside session directory!");
          print(">>> PATH: ${zipFile.path}");

          // Optional: Show it in a notification or dialog immediately
          _showBottomNotification("Received: ${zipFile.path.split('/').last}");
        } else {
          print(">>> WARNING: No zip file found in ${sessionDir.path}");
        }
      } catch (e) {
        print("Error finding file in session directory: $e");
      }
      await _loadSavedBatches();
    } catch (e) {
      setState(() {
        _statusMessage = "Connection Failed";
        _isTransferring = false;
        _progress = 0.0;
      });
      _showBottomNotification("Error: ${e.toString()}", isError: true);
    }
  }

  Future<void> _receiveFiles(
    String ip,
    int port,
    String? sourceIP,
    Directory sessionDir,
  ) async {
    Socket? socket;
    int retryCount = 0;
    while (socket == null && retryCount < 3) {
      try {
        socket = await Socket.connect(
          ip,
          port,
          sourceAddress: sourceIP,
          timeout: const Duration(seconds: 5),
        );
      } catch (e) {
        retryCount++;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    if (socket == null) throw Exception("Could not connect to Server.");

    try {
      socket.add(utf8.encode(SECRET_KEY));
      await socket.flush();
      StreamIterator<Uint8List> reader = StreamIterator(socket);
      if (!await _readUntil(reader, "OK")) throw Exception("Auth Failed");

      String header = await _readHeader(reader);
      socket.add(utf8.encode("OK"));
      await socket.flush();

      if (header.startsWith("NUM_FILES")) {
        int count = int.parse(header.split("|")[1]);
        for (int i = 0; i < count; i++) {
          setState(() {
            _statusMessage = "Downloading file ${i + 1}/$count...";
            _progress = (i + 1) / (count + 1);
          });
          await _downloadSingleFile(reader, socket, sessionDir);
        }
      }
      setState(() {
        _isTransferring = false;
        _statusMessage = "Transfer Complete!";
        _progress = 1.0;
      });
      _showBottomNotification("Saved to: ${sessionDir.path.split('/').last}");
    } finally {
      socket.destroy();
    }
  }

  Future<void> _downloadSingleFile(
    StreamIterator<Uint8List> reader,
    Socket socket,
    Directory dir,
  ) async {
    String header = await _readHeader(reader);
    var parts = header.split("|");
    String filename = parts[0].split('/').last.split('\\').last;
    int filesize = int.parse(parts[1]);
    socket.add(utf8.encode("OK"));
    await socket.flush();

    File file = File("${dir.path}/$filename");
    IOSink sink = file.openWrite();
    int received = 0;
    while (received < filesize) {
      if (await reader.moveNext()) {
        Uint8List chunk = reader.current;
        int remaining = filesize - received;
        if (chunk.length > remaining) {
          sink.add(chunk.sublist(0, remaining));
          received += remaining;
        } else {
          sink.add(chunk);
          received += chunk.length;
        }
      } else {
        break;
      }
    }
    await sink.flush();
    await sink.close();
  }

  Future<bool> _readUntil(
    StreamIterator<Uint8List> reader,
    String target,
  ) async {
    if (await reader.moveNext())
      return utf8.decode(reader.current).contains(target);
    return false;
  }

  Future<String> _readHeader(StreamIterator<Uint8List> reader) async {
    if (await reader.moveNext()) return utf8.decode(reader.current);
    throw Exception("Connection closed");
  }

  void _showBottomNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7F6),
        elevation: 0,
        leading: Builder(
          builder: (c) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 32),
            onPressed: () => Scaffold.of(c).openDrawer(),
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF2E7D32)),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome Back,",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            Text(
              "Agri-Manager",
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF191825),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F30),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "System Status",
                        style: GoogleFonts.poppins(color: Colors.grey[400]),
                      ),
                      Icon(
                        _isConnectedToWifi ? Icons.wifi : Icons.wifi_off,
                        color: _isConnectedToWifi
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (_isTransferring)
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white10,
                      color: const Color(0xFFC8F000),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: startSyncProcess,
                        icon: const Icon(
                          Icons.sync_outlined,
                          color: Colors.black,
                        ),
                        label: Text(
                          "Receive Data",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC8F000),
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "My Files",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _batchFolders.isEmpty
                  ? const Center(
                      child: Text(
                        "No batches received yet",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _batchFolders.length,
                      itemBuilder: (context, index) {
                        Directory dir = _batchFolders[index] as Directory;
                        String name = dir.path.split('/').last;
                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.folder_open,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text("Tap to view files"),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FolderDetailScreen(directory: dir),
                                ),
                              );
                              _loadSavedBatches();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

