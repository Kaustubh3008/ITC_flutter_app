import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config.dart'; // Import config for ports if needed later

class MessageBoxScreen extends StatefulWidget {
  const MessageBoxScreen({super.key});

  @override
  State<MessageBoxScreen> createState() => _MessageBoxScreenState();
}

class _MessageBoxScreenState extends State<MessageBoxScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  RawDatagramSocket? _socket;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _socket?.close();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    try {
      // Using UDP_PORT from config or hardcoded 5000 is fine as logic is same
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 5000);
      _socket!.broadcastEnabled = true;

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? dg = _socket!.receive();
          if (dg != null) {
            String msg = utf8.decode(dg.data).trim();
            if (msg.startsWith("MSG_FROM_PI:")) {
              String content = msg.replaceAll("MSG_FROM_PI:", "");
              setState(() {
                _messages.add("Pi: $content");
              });
            }
          }
        }
      });
    } catch (e) {
      debugPrint("Error binding socket: $e");
    }
  }

  Future<void> _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    if (_socket == null) {
      await _startListening();
    }

    try {
      String payload = "MSG:$text";
      _socket?.send(
        utf8.encode(payload),
        InternetAddress('255.255.255.255'),
        5000,
      );
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Message Box",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF4F7F6),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Send Message to Device",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF191825),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Type your message here...",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.black),
                label: Text(
                  _isSending ? "Sending..." : "Send Message",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8F000),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Incoming Messages",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: _messages.isEmpty
                    ? Center(
                        child: Text(
                          "No incoming messages",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFC8E6C9),
                                ),
                              ),
                              child: Text(
                                _messages[index],
                                style: GoogleFonts.poppins(
                                  color: Colors.green[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
