// // // import 'dart:io';
// // // import 'package:flutter/material.dart';
// // // import 'package:google_fonts/google_fonts.dart';
// // // import 'package:open_file/open_file.dart';
// // // import 'package:archive/archive_io.dart';

// // // class FolderDetailScreen extends StatefulWidget {
// // //   final Directory directory;
// // //   const FolderDetailScreen({super.key, required this.directory});

// // //   @override
// // //   State<FolderDetailScreen> createState() => _FolderDetailScreenState();
// // // }

// // // class _FolderDetailScreenState extends State<FolderDetailScreen> {
// // //   List<FileSystemEntity> _files = [];
// // //   bool _isProcessing = false;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _loadFiles();
// // //   }

// // //   void _loadFiles() {
// // //     try {
// // //       if (widget.directory.existsSync()) {
// // //         final files = widget.directory.listSync().whereType<File>().toList()
// // //           ..sort((a, b) => a.path.compareTo(b.path));
// // //         setState(() {
// // //           _files = files;
// // //         });
// // //       }
// // //     } catch (e) {
// // //       debugPrint("Error listing files: $e");
// // //     }
// // //   }

// // //   Future<void> _handleZipFile(File zipFile) async {
// // //     setState(() => _isProcessing = true);
// // //     try {
// // //       final bytes = zipFile.readAsBytesSync();
// // //       final archive = ZipDecoder().decodeBytes(bytes);
// // //       for (final file in archive) {
// // //         final filename = file.name;
// // //         if (file.isFile) {
// // //           final data = file.content as List<int>;
// // //           File('${widget.directory.path}/$filename')
// // //             ..createSync(recursive: true)
// // //             ..writeAsBytesSync(data);
// // //         } else {
// // //           Directory(
// // //             '${widget.directory.path}/$filename',
// // //           ).create(recursive: true);
// // //         }
// // //       }
// // //       ScaffoldMessenger.of(
// // //         context,
// // //       ).showSnackBar(const SnackBar(content: Text("Unzip Successful!")));
// // //       _loadFiles();
// // //     } catch (e) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text("Unzip Failed: $e"),
// // //           backgroundColor: Colors.red,
// // //         ),
// // //       );
// // //     } finally {
// // //       setState(() => _isProcessing = false);
// // //     }
// // //   }

// // //   void _openFile(BuildContext context, String path) async {
// // //     try {
// // //       final result = await OpenFile.open(path);
// // //       if (result.type != ResultType.done) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Text("Could not open file: ${result.message}"),
// // //             backgroundColor: Colors.red,
// // //           ),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
// // //       );
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: Text(
// // //           widget.directory.path.split('/').last,
// // //           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
// // //         ),
// // //         backgroundColor: Colors.white,
// // //         elevation: 0,
// // //         foregroundColor: Colors.black,
// // //       ),
// // //       backgroundColor: const Color(0xFFF4F7F6),
// // //       body: _isProcessing
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : _files.isEmpty
// // //           ? const Center(child: Text("Empty Folder"))
// // //           : ListView.builder(
// // //               padding: const EdgeInsets.all(16),
// // //               itemCount: _files.length,
// // //               itemBuilder: (context, index) {
// // //                 File file = _files[index] as File;
// // //                 String name = file.path.split('/').last;
// // //                 String ext = name.split('.').last.toLowerCase();
// // //                 IconData icon = Icons.insert_drive_file;
// // //                 Color color = Colors.grey;
// // //                 bool isZip = false;

// // //                 if (['jpg', 'jpeg', 'png'].contains(ext)) {
// // //                   icon = Icons.image;
// // //                   color = Colors.purple;
// // //                 } else if (ext == 'pdf') {
// // //                   icon = Icons.picture_as_pdf;
// // //                   color = Colors.red;
// // //                 } else if (ext == 'zip') {
// // //                   icon = Icons.folder_zip;
// // //                   color = Colors.orange;
// // //                   isZip = true;
// // //                 }

// // //                 return Card(
// // //                   elevation: 0,
// // //                   color: Colors.white,
// // //                   margin: const EdgeInsets.only(bottom: 10),
// // //                   shape: RoundedRectangleBorder(
// // //                     borderRadius: BorderRadius.circular(12),
// // //                   ),
// // //                   child: ListTile(
// // //                     leading: Container(
// // //                       padding: const EdgeInsets.all(8),
// // //                       decoration: BoxDecoration(
// // //                         color: color.withOpacity(0.1),
// // //                         borderRadius: BorderRadius.circular(8),
// // //                       ),
// // //                       child: Icon(icon, color: color),
// // //                     ),
// // //                     title: Text(
// // //                       name,
// // //                       style: const TextStyle(fontWeight: FontWeight.w500),
// // //                     ),
// // //                     subtitle: Text(
// // //                       isZip
// // //                           ? "Tap to Unzip"
// // //                           : "${(file.lengthSync() / 1024).toStringAsFixed(1)} KB",
// // //                     ),
// // //                     trailing: Icon(
// // //                       isZip ? Icons.system_update_alt : Icons.open_in_new,
// // //                       size: 20,
// // //                       color: Colors.grey,
// // //                     ),
// // //                     onTap: () {
// // //                       if (isZip)
// // //                         _handleZipFile(file);
// // //                       else
// // //                         _openFile(context, file.path);
// // //                     },
// // //                   ),
// // //                 );
// // //               },
// // //             ),
// // //     );
// // //   }
// // // }

// // 29 FIRST
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:open_file/open_file.dart';
// // import 'package:archive/archive_io.dart';
// // import 'package:path_provider/path_provider.dart'; // Needed for temp zip creation
// // import '../services/api_service.dart'; // Import API Service

// // class FolderDetailScreen extends StatefulWidget {
// //   final Directory directory;
// //   const FolderDetailScreen({super.key, required this.directory});

// //   @override
// //   State<FolderDetailScreen> createState() => _FolderDetailScreenState();
// // }

// // class _FolderDetailScreenState extends State<FolderDetailScreen> {
// //   List<FileSystemEntity> _files = [];
// //   bool _isProcessing = false;
// //   bool _isUploading = false; // New state for upload

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadFiles();
// //   }

// //   void _loadFiles() {
// //     try {
// //       if (widget.directory.existsSync()) {
// //         final files = widget.directory.listSync().whereType<File>().toList()
// //           ..sort((a, b) => a.path.compareTo(b.path));
// //         setState(() {
// //           _files = files;
// //         });
// //       }
// //     } catch (e) {
// //       debugPrint("Error listing files: $e");
// //     }
// //   }

// //   // --- 1. LOCAL UNZIP LOGIC (Keep existing) ---
// //   Future<void> _handleZipFile(File zipFile) async {
// //     setState(() => _isProcessing = true);
// //     try {
// //       final bytes = zipFile.readAsBytesSync();
// //       final archive = ZipDecoder().decodeBytes(bytes);
// //       for (final file in archive) {
// //         final filename = file.name;
// //         if (file.isFile) {
// //           final data = file.content as List<int>;
// //           File('${widget.directory.path}/$filename')
// //             ..createSync(recursive: true)
// //             ..writeAsBytesSync(data);
// //         } else {
// //           Directory(
// //             '${widget.directory.path}/$filename',
// //           ).create(recursive: true);
// //         }
// //       }
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(const SnackBar(content: Text("Unzip Successful!")));
// //       _loadFiles();
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text("Unzip Failed: $e"),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //     } finally {
// //       setState(() => _isProcessing = false);
// //     }
// //   }

// //   void _openFile(BuildContext context, String path) async {
// //     try {
// //       final result = await OpenFile.open(path);
// //       if (result.type != ResultType.done) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text("Could not open file: ${result.message}"),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
// //       );
// //     }
// //   }

// //   // --- 2. NEW: CLOUD PROCESSING LOGIC ---
// //   Future<void> _processOnCloud() async {
// //     setState(() => _isUploading = true);

// //     try {
// //       // A. Create a temporary ZIP file
// //       final tempDir = await getTemporaryDirectory();
// //       final zipPath = '${tempDir.path}/upload_payload.zip';
// //       final encoder = ZipFileEncoder();
// //       encoder.create(zipPath);

// //       // B. Add images to ZIP with specific folder structure "ITC_test_folder/"
// //       // This is crucial because the API expects this specific folder name.
// //       int imageCount = 0;
// //       for (var entity in _files) {
// //         if (entity is File) {
// //           String ext = entity.path.split('.').last.toLowerCase();
// //           if (['jpg', 'jpeg', 'png'].contains(ext)) {
// //             String filename = entity.path.split('/').last;
// //             // Add file to zip inside the required folder
// //             encoder.addFile(entity, "ITC_test_folder/$filename");
// //             imageCount++;
// //           }
// //         }
// //       }
// //       encoder.close();

// //       if (imageCount == 0) {
// //         throw Exception("No images found in this batch to upload.");
// //       }

// //       // C. Send to API
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(const SnackBar(content: Text("Uploading to Cloud...")));

// //       final result = await ApiService.uploadBatch(File(zipPath));

// //       // D. Handle Response
// //       if (result['status'] == 'success') {
// //         // Show the success message (In next steps, we will download the result file)
// //         _showResultDialog(result);
// //       } else {
// //         throw Exception(result['message']);
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("Cloud Error: $e"), backgroundColor: Colors.red),
// //       );
// //     } finally {
// //       setState(() => _isUploading = false);
// //     }
// //   }

// //   void _showResultDialog(Map<String, dynamic> result) {
// //     showDialog(
// //       context: context,
// //       builder: (ctx) => AlertDialog(
// //         title: const Text("Analysis Complete"),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text("Job ID: ${result['job_id']}"),
// //             const SizedBox(height: 10),
// //             Text("Result: ${result['result_folders']}"),
// //             const SizedBox(height: 20),
// //             const Text(
// //               "The result file is ready.",
// //               style: TextStyle(fontWeight: FontWeight.bold),
// //             ),
// //           ],
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.of(ctx).pop(),
// //             child: const Text("Close"),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(
// //           widget.directory.path.split('/').last,
// //           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
// //         ),
// //         backgroundColor: Colors.white,
// //         elevation: 0,
// //         foregroundColor: Colors.black,
// //         actions: [
// //           // --- NEW CLOUD BUTTON ---
// //           IconButton(
// //             onPressed: (_isProcessing || _isUploading) ? null : _processOnCloud,
// //             icon: _isUploading
// //                 ? const SizedBox(
// //                     width: 20,
// //                     height: 20,
// //                     child: CircularProgressIndicator(
// //                       strokeWidth: 2,
// //                       color: Colors.black,
// //                     ),
// //                   )
// //                 : const Icon(
// //                     Icons.cloud_upload_outlined,
// //                     color: Color(0xFF2E7D32),
// //                   ),
// //             tooltip: "Process on Cloud",
// //           ),
// //         ],
// //       ),
// //       backgroundColor: const Color(0xFFF4F7F6),
// //       body: _isProcessing
// //           ? const Center(child: CircularProgressIndicator())
// //           : _files.isEmpty
// //           ? const Center(child: Text("Empty Folder"))
// //           : ListView.builder(
// //               padding: const EdgeInsets.all(16),
// //               itemCount: _files.length,
// //               itemBuilder: (context, index) {
// //                 File file = _files[index] as File;
// //                 String name = file.path.split('/').last;
// //                 String ext = name.split('.').last.toLowerCase();
// //                 IconData icon = Icons.insert_drive_file;
// //                 Color color = Colors.grey;
// //                 bool isZip = false;

// //                 if (['jpg', 'jpeg', 'png'].contains(ext)) {
// //                   icon = Icons.image;
// //                   color = Colors.purple;
// //                 } else if (ext == 'pdf') {
// //                   icon = Icons.picture_as_pdf;
// //                   color = Colors.red;
// //                 } else if (ext == 'zip') {
// //                   icon = Icons.folder_zip;
// //                   color = Colors.orange;
// //                   isZip = true;
// //                 }

// //                 return Card(
// //                   elevation: 0,
// //                   color: Colors.white,
// //                   margin: const EdgeInsets.only(bottom: 10),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                   ),
// //                   child: ListTile(
// //                     leading: Container(
// //                       padding: const EdgeInsets.all(8),
// //                       decoration: BoxDecoration(
// //                         color: color.withOpacity(0.1),
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                       child: Icon(icon, color: color),
// //                     ),
// //                     title: Text(
// //                       name,
// //                       style: const TextStyle(fontWeight: FontWeight.w500),
// //                     ),
// //                     subtitle: Text(
// //                       isZip
// //                           ? "Tap to Unzip"
// //                           : "${(file.lengthSync() / 1024).toStringAsFixed(1)} KB",
// //                     ),
// //                     trailing: Icon(
// //                       isZip ? Icons.system_update_alt : Icons.open_in_new,
// //                       size: 20,
// //                       color: Colors.grey,
// //                     ),
// //                     onTap: () {
// //                       if (isZip)
// //                         _handleZipFile(file);
// //                       else
// //                         _openFile(context, file.path);
// //                     },
// //                   ),
// //                 );
// //               },
// //             ),
// //     );
// //   }
// // }

// // 29 SECOND
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:open_file/open_file.dart';
// import 'package:archive/archive_io.dart';
// import 'package:path_provider/path_provider.dart'; // For temp zip creation
// import '../services/api_service.dart'; // To call the Server

// class FolderDetailScreen extends StatefulWidget {
//   final Directory directory;
//   const FolderDetailScreen({super.key, required this.directory});

//   @override
//   State<FolderDetailScreen> createState() => _FolderDetailScreenState();
// }

// class _FolderDetailScreenState extends State<FolderDetailScreen> {
//   List<FileSystemEntity> _files = [];
//   bool _isProcessing = false; // For local unzip
//   bool _isUploading = false; // For cloud upload

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

//   // ==========================================
//   // 1. EXISTING LOCAL UNZIP LOGIC (UNCHANGED)
//   // ==========================================
//   Future<void> _handleZipFile(File zipFile) async {
//     setState(() => _isProcessing = true);
//     try {
//       final bytes = zipFile.readAsBytesSync();
//       final archive = ZipDecoder().decodeBytes(bytes);
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
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Unzip Successful!")));
//       _loadFiles();
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

//   // ==========================================
//   // 2. NEW CLOUD UPLOAD LOGIC
//   // ==========================================
//   Future<void> _processOnCloud() async {
//     setState(() => _isUploading = true);

//     try {
//       // A. Create a temporary ZIP file
//       final tempDir = await getTemporaryDirectory();
//       final zipPath = '${tempDir.path}/upload_payload.zip';
//       final encoder = ZipFileEncoder();
//       encoder.create(zipPath);

//       // B. Add images to ZIP with structure "ITC_test_folder/"
//       int imageCount = 0;
//       for (var entity in _files) {
//         if (entity is File) {
//           String ext = entity.path.split('.').last.toLowerCase();
//           if (['jpg', 'jpeg', 'png'].contains(ext)) {
//             String filename = entity.path.split('/').last;
//             // Add file to zip inside the required folder
//             encoder.addFile(entity, "ITC_test_folder/$filename");
//             imageCount++;
//           }
//         }
//       }
//       encoder.close();

//       if (imageCount == 0) {
//         throw Exception("No images found to upload.");
//       }

//       // C. Send to API
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Uploading to Cloud...")));

//       final result = await ApiService.uploadBatch(File(zipPath));

//       // D. Handle Response
//       if (result['status'] == 'success') {
//         _showResultDialog(result);
//       } else {
//         throw Exception(result['message']);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Cloud Error: $e"), backgroundColor: Colors.red),
//       );
//     } finally {
//       setState(() => _isUploading = false);
//     }
//   }

//   void _showResultDialog(Map<String, dynamic> result) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Analysis Complete"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Job ID: ${result['job_id']}"),
//             const SizedBox(height: 10),
//             const Text(
//               "Result Summary:",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             Text(result['result_folders'].toString()),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(),
//             child: const Text("Close"),
//           ),
//         ],
//       ),
//     );
//   }

//   // ==========================================
//   // 3. UI BUILD
//   // ==========================================
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
//         actions: [
//           // --- THE MISSING CLOUD BUTTON ---
//           IconButton(
//             onPressed: (_isProcessing || _isUploading) ? null : _processOnCloud,
//             icon: _isUploading
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.black,
//                     ),
//                   )
//                 : const Icon(
//                     Icons.cloud_upload_outlined,
//                     color: Color(0xFF2E7D32),
//                   ),
//             tooltip: "Process on Cloud",
//           ),
//           const SizedBox(width: 10),
//         ],
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
//                       if (isZip)
//                         _handleZipFile(file);
//                       else
//                         _openFile(context, file.path);
//                     },
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart'; // For temp zip creation
import '../services/api_service.dart'; // To call the Server

class FolderDetailScreen extends StatefulWidget {
  final Directory directory;
  const FolderDetailScreen({super.key, required this.directory});

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  List<FileSystemEntity> _files = [];
  bool _isProcessing = false; // For local unzip
  bool _isUploading = false; // For cloud upload

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    try {
      if (widget.directory.existsSync()) {
        final files = widget.directory.listSync().whereType<File>().toList()
          ..sort((a, b) => a.path.compareTo(b.path));
        setState(() {
          _files = files;
        });
      }
    } catch (e) {
      debugPrint("Error listing files: $e");
    }
  }

  // ==========================================
  // 1. EXISTING LOCAL UNZIP LOGIC
  // ==========================================
  Future<void> _handleZipFile(File zipFile) async {
    setState(() => _isProcessing = true);
    try {
      final bytes = zipFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File('${widget.directory.path}/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(
            '${widget.directory.path}/$filename',
          ).create(recursive: true);
        }
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unzip Successful!")));
      _loadFiles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unzip Failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _openFile(BuildContext context, String path) async {
    try {
      final result = await OpenFile.open(path);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not open file: ${result.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // ==========================================
  // 2. NEW CLOUD UPLOAD LOGIC
  // ==========================================
  Future<void> _processOnCloud() async {
    setState(() => _isUploading = true);

    try {
      // A. Create a temporary ZIP file
      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/upload_payload.zip';
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      // B. Add images to ZIP with structure "ITC_test_folder/"
      int imageCount = 0;
      for (var entity in _files) {
        if (entity is File) {
          String ext = entity.path.split('.').last.toLowerCase();
          if (['jpg', 'jpeg', 'png'].contains(ext)) {
            String filename = entity.path.split('/').last;
            // Add file to zip inside the required folder
            encoder.addFile(entity, "ITC_test_folder/$filename");
            imageCount++;
          }
        }
      }
      encoder.close();

      if (imageCount == 0) {
        throw Exception("No images found to upload.");
      }

      // C. Send to API
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Uploading to Cloud...")));

      final result = await ApiService.uploadBatch(File(zipPath));

      // D. Handle Response
      if (result['status'] == 'success') {
        _showResultDialog(result);
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cloud Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Analysis Complete"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Job ID: ${result['job_id']}"),
            const SizedBox(height: 10),
            const Text(
              "Result Summary:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(result['result_folders'].toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. UI BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.directory.path.split('/').last,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          // --- THE CLOUD BUTTON ---
          IconButton(
            onPressed: (_isProcessing || _isUploading) ? null : _processOnCloud,
            icon: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(
                    Icons.cloud_upload_outlined,
                    color: Color(0xFF2E7D32),
                  ),
            tooltip: "Process on Cloud",
          ),
          const SizedBox(width: 10),
        ],
      ),
      backgroundColor: const Color(0xFFF4F7F6),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
          ? const Center(child: Text("Empty Folder"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _files.length,
              itemBuilder: (context, index) {
                File file = _files[index] as File;
                String name = file.path.split('/').last;
                String ext = name.split('.').last.toLowerCase();
                IconData icon = Icons.insert_drive_file;
                Color color = Colors.grey;
                bool isZip = false;

                if (['jpg', 'jpeg', 'png'].contains(ext)) {
                  icon = Icons.image;
                  color = Colors.purple;
                } else if (ext == 'pdf') {
                  icon = Icons.picture_as_pdf;
                  color = Colors.red;
                } else if (ext == 'zip') {
                  icon = Icons.folder_zip;
                  color = Colors.orange;
                  isZip = true;
                }

                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      isZip
                          ? "Tap to Unzip"
                          : "${(file.lengthSync() / 1024).toStringAsFixed(1)} KB",
                    ),
                    trailing: Icon(
                      isZip ? Icons.system_update_alt : Icons.open_in_new,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      if (isZip)
                        _handleZipFile(file);
                      else
                        _openFile(context, file.path);
                    },
                  ),
                );
              },
            ),
    );
  }
}
