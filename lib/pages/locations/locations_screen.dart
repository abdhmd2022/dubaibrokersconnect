import 'package:a2abrokerapp/services/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart';
import 'package:http/browser_client.dart';

class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({Key? key}) : super(key: key);

  @override
  State<LocationManagementScreen> createState() => _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  String? _selectedFileName;
  Uint8List? _selectedBytes;
  bool _isUploading = false;


  Future<void> _uploadCsv() async {
    if (_selectedBytes == null) return;

    setState(() => _isUploading = true);

    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseURL/api/locations/bulk-upload");

      if (kIsWeb) {
        // 🔥 Browser-safe client
        final client = BrowserClient()..withCredentials = false;

        // Create multipart
        final request = http.MultipartRequest("POST", url);

        request.headers['Authorization'] = "Bearer $token";

        request.files.add(
          http.MultipartFile.fromBytes(
            'file',                    // MUST match backend
            _selectedBytes!,
            filename: _selectedFileName,
            contentType: MediaType("text", "csv"),   // 👈 FIX

          ),
        );

        final streamed = await client.send(request);
        final response = await http.Response.fromStream(streamed);

        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() {
            _selectedBytes = null;
            _selectedFileName = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("CSV uploaded successfully!"), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed: ${response.body}"), backgroundColor: Colors.red),
          );
        }
      }
      else {
        // 📱 Mobile/desktop uses normal MultipartRequest
        var req = http.MultipartRequest("POST", url);
        req.headers['Authorization'] = 'Bearer $token';

        req.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _selectedBytes!,
            filename: _selectedFileName,
          ),
        );

        var res = await req.send();
        var body = await http.Response.fromStream(res);

        if (body.statusCode == 200 || body.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("CSV uploaded successfully!"), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: ${body.body}"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }

    setState(() => _isUploading = false);
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("CSV uploaded successfully!"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${response.body}"), backgroundColor: Colors.red),
      );
    }
  }


  Future<void> _pickCsvFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true, // 🔥 IMPORTANT for Web
    );

    if (result != null) {
      setState(() {
        _selectedBytes = result.files.single.bytes;   // WEB SAFE
        _selectedFileName = result.files.single.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        onPressed: () {
          // TODO: Add manual location add
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 📍 HEADER (Top-Left)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [

                        Text(
                          "",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),


              SizedBox(height: 20,),
              // MAIN CARD
              Container(
                width: 650,
                padding: const EdgeInsets.fromLTRB(30, 32, 30, 36),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // center everything
                  children: [


                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.location_on_outlined,
                              color: kPrimaryColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Import Locations from CSV",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      )
                    ),

                    SizedBox(height: 18),
                    // INFO BOX
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Updated: ",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                    "The system now supports 6-level location hierarchy: Emirate → Neighbourhood → Cluster → Building → Building Level 1 → Building Level 2. The system automatically avoids creating duplicates based on the full location path.",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      color: Colors.black87,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // CSV Upload Section
                    Text(
                      "Upload CSV File",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedFileName ?? "No file selected",
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade700,
                                fontSize: 13.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: _pickCsvFile,
                            icon: const Icon(Icons.upload_file_outlined,
                                size: 18),
                            label: Text(
                              "Choose File",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: kPrimaryColor,
                              backgroundColor:
                              kPrimaryColor.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Supported File Types (.csv only)",
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Upload Button
                    ElevatedButton.icon(
                      onPressed: _selectedBytes == null || _isUploading
                          ? null
                          : () {
                        _uploadCsv();
                      },
                      icon: _isUploading
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,

                        ),
                      )
                          : const Icon(Icons.cloud_upload_outlined, size: 20),
                      label: Text(
                        _isUploading ? "Uploading..." : "Upload and Process",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedBytes == null
                            ? Colors.grey.shade300
                            : kPrimaryColor,
                        foregroundColor: _selectedBytes == null
                            ? Colors.grey.shade600
                            : Colors.white,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
