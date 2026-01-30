import 'dart:io';
import 'dart:math'; // Required for splitting batches
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class ServerUploadScreen extends StatefulWidget {
  const ServerUploadScreen({super.key});

  @override
  State<ServerUploadScreen> createState() => _ServerUploadScreenState();
}

class _ServerUploadScreenState extends State<ServerUploadScreen> {
  List<FileSystemEntity> _allFiles = [];
  FileSystemEntity? _selectedItem;
  bool _isLoading = false;
  bool _isUploading = false;
  String _uploadStatus = "";

  @override
  void initState() {
    super.initState();
    _loadSmartList();
  }

  // --- 0. HEALTH CHECK ---
  Future<void> _checkServerHealth() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Pinging Server...")));
    try {
      final Uri url = Uri.parse("https://api.tabletorus.com/");
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        _showSuccessDialog("Server is Online!", "Response:\n${response.body}");
      } else {
        _showErrorDialog("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("Connection Failed.\nError: $e");
    }
  }

  // --- 1. SMART SCAN ---
  Future<void> _loadSmartList() async {
    setState(() => _isLoading = true);
    // Request permissions (Android only)
    await [Permission.storage, Permission.manageExternalStorage].request();

    List<FileSystemEntity> foundItems = [];

    // SCAN BOTH PATHS (Laptop & Android)
    List<String> pathsToCheck = [
      r'C:\Users\kaust\OneDrive\Documents\xyzitc', // Laptop
      '/storage/emulated/0/Download/AgriSync_Files', // Android AgriSync_Files
    ];

    for (var path in pathsToCheck) {
      Directory dir = Directory(path);
      if (await dir.exists()) {
        try {
          var items = dir.listSync();
          foundItems.addAll(items);
        } catch (e) {
          print("Error reading $path: $e");
        }
      }
    }

    // Sort Newest First
    foundItems.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );

    setState(() {
      _allFiles = foundItems;
      _isLoading = false;
    });
  }

  // --- 2. NEW LOGIC: RASPBERRY PI ZIP HANDLING ---
  Future<void> _processAndUpload() async {
    if (_selectedItem == null) return;

    List<File> allImages = [];
    String? tempExtractPath; // To clean up extracted files later if needed

    try {
      // STEP A: LOCATE IMAGES (Handle Zip inside Folder)
      if (_selectedItem is Directory) {
        Directory dir = _selectedItem as Directory;
        List<FileSystemEntity> content = dir.listSync();

        // 1. Check if there is a ZIP file inside this folder (The Raspberry Pi flow)
        File? piZipFile;
        try {
          var zips = content.where(
            (e) => e is File && e.path.toLowerCase().endsWith('.zip'),
          );
          if (zips.isNotEmpty) {
            piZipFile = zips.first as File;
          }
        } catch (e) {
          print("Error scanning for zip: $e");
        }

        if (piZipFile != null) {
          // --- FLOW 1: ZIP FOUND (RASPBERRY PI STRUCTURE) ---
          setState(() {
            _isUploading = true;
            _uploadStatus = "Unzipping received file...";
          });

          // Create a temp directory to extract the Pi's zip
          final tempDir = await getTemporaryDirectory();
          tempExtractPath =
              '${tempDir.path}/pi_extract_${DateTime.now().millisecondsSinceEpoch}';

          // Extract the Zip
          // We wrap in a Future to ensure it doesn't freeze the UI completely
          await Future.delayed(Duration.zero, () {
            extractFileToDisk(piZipFile!.path, tempExtractPath!);
          });

          print("--- [DEBUG] Extracted Zip to: $tempExtractPath");

          // Now collect images from the EXTRACTED folder
          Directory extractedDir = Directory(tempExtractPath!);
          if (await extractedDir.exists()) {
            allImages = extractedDir
                .listSync(recursive: true)
                .where((e) {
                  if (e is File) {
                    String ext = e.path.split('.').last.toLowerCase();
                    return ['jpg', 'jpeg', 'png'].contains(ext) &&
                        !e.path.split('/').last.startsWith('.');
                  }
                  return false;
                })
                .cast<File>()
                .toList();
          }
        } else {
          // --- FLOW 2: NO ZIP (LEGACY / TESTING STRUCTURE) ---
          // Just look for loose images in the folder
          allImages = dir
              .listSync(recursive: true)
              .where((e) {
                if (e is File) {
                  String ext = e.path.split('.').last.toLowerCase();
                  return ['jpg', 'jpeg', 'png'].contains(ext) &&
                      !e.path.split('/').last.startsWith('.');
                }
                return false;
              })
              .cast<File>()
              .toList();
        }
      } else {
        _showErrorDialog("Please select a FOLDER.");
        return;
      }

      if (allImages.isEmpty) {
        _showErrorDialog(
          "No images found.\n(Looked for loose images OR a .zip file containing images)",
        );
        return;
      }

      // STEP B: START BATCHING (Existing Logic)
      setState(() {
        _isUploading = true;
        _uploadStatus = "Found ${allImages.length} images. Starting...";
      });

      // BATCH SIZE = 1 (Safe for Timeout)
      int batchSize = 1;
      int totalBatches = (allImages.length / batchSize).ceil();
      List<String> reportLog = [];

      for (int i = 0; i < totalBatches; i++) {
        int start = i * batchSize;
        int end = min(start + batchSize, allImages.length);
        List<File> chunk = allImages.sublist(start, end);

        setState(() {
          _uploadStatus = "Uploading Batch ${i + 1} of $totalBatches...";
        });

        print(
          "--- [DEBUG] Processing Batch ${i + 1}: ${chunk.length} images ---",
        );

        // 1. Create Safe Zip for this chunk (API Structure)
        File chunkZip = await _createSafeZip(chunk, i);

        // 2. Upload
        final result = await ApiService.uploadBatch(chunkZip);

        if (result['status'] == 'success') {
          reportLog.add("Batch ${i + 1}: Success (Job: ${result['job_id']})");
        } else {
          reportLog.add("Batch ${i + 1}: FAILED (${result['message']})");
        }
      }

      // STEP C: DONE
      _showFinalResult(reportLog);
    } catch (e) {
      _showErrorDialog("Process Stopped: $e");
    } finally {
      setState(() {
        _isUploading = false;
        _uploadStatus = "";
      });
      // Optional: Clean up temp extract folder
      if (tempExtractPath != null) {
        Directory(
          tempExtractPath,
        ).delete(recursive: true).catchError((_) => null);
      }
    }
  }

  // Helper: Creates zip with 'ITC_test_folder'
  Future<File> _createSafeZip(List<File> images, int batchIndex) async {
    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/temp_batch_$batchIndex.zip';

    // Clean up old file
    File oldFile = File(zipPath);
    if (await oldFile.exists()) await oldFile.delete();

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    for (var file in images) {
      String name = file.path.split(Platform.pathSeparator).last;
      // CRITICAL: Put inside specific folder for Server
      encoder.addFile(file, "ITC_test_folder/$name");
    }
    encoder.close();
    return File(zipPath);
  }

  // --- UI DIALOGS ---
  void _showFinalResult(List<String> logs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Batch Upload Complete"),
        content: SizedBox(
          height: 300,
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: logs.length,
            itemBuilder: (ctx, i) =>
                Text(logs[i], style: const TextStyle(fontSize: 12)),
          ),
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

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.green)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Select Folder",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_tethering, color: Colors.blue),
            onPressed: _checkServerHealth,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSmartList,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F7F6),
      body: Column(
        children: [
          Expanded(
            child: _allFiles.isEmpty
                ? const Center(child: Text("No Folders Found"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _allFiles.length,
                    itemBuilder: (context, index) {
                      FileSystemEntity entity = _allFiles[index];
                      String name = entity.path
                          .split(Platform.pathSeparator)
                          .last;
                      bool isSelected = _selectedItem?.path == entity.path;

                      // Only show folders
                      IconData icon = entity is Directory
                          ? Icons.folder
                          : Icons.insert_drive_file;
                      Color iconColor = entity is Directory
                          ? Colors.orange
                          : Colors.grey;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedItem = entity),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE8F5E9)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xFF2E7D32),
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: ListTile(
                            leading: Icon(
                              icon,
                              color: isSelected
                                  ? const Color(0xFF2E7D32)
                                  : iconColor,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF2E7D32),
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _uploadStatus,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (_isUploading || _selectedItem == null)
                    ? null
                    : _processAndUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8F000),
                  foregroundColor: Colors.black,
                ),
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : const Text(
                        "Upload to Server",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
