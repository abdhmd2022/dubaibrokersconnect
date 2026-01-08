import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../../widgets/animated_logo_loader.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:http/browser_client.dart';

import '../../widgets/web_image_widget.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;


  final String brokerId;
  const ProfileScreen({super.key, required this.brokerId,
    required this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin{
  Map<String, dynamic>? broker;
  bool loading = true;
  late final AnimationController _tooltipController;
  final List<String> categories = ["RESIDENTIAL", "COMMERCIAL"];
  bool isFreelancer = false;

  final List<String> specializations = [
    "Luxury Properties",
    "Dubai Marina",
    "Downtown Dubai",
    "Commercial Properties",
    "Residential Sales"
  ];
  final List<String> languages = ["English", "Arabic", "Hindi", "Urdu"];

  bool error = false;
  String activeSection = "Listings";
  String hoveredSocial = '';

  OverlayEntry? _activeTooltip;
  bool _tooltipVisible = false;

  @override
  void initState() {
    super.initState();

    _tooltipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Default selection based on broker verification
    final isVerified = widget.userData['broker']['isVerified'] == true;
    activeSection = isVerified ? "Listings" : "Reviews";

    fetchBrokerById();
  }

  void _hideTooltip() {
    _activeTooltip?.remove();
    _activeTooltip = null;
    _tooltipVisible = false;

  }

  @override
  void dispose() {
    _tooltipController.dispose();
    _hideTooltip();
    super.dispose();
  }

  Widget _statusTag({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> fetchBrokerById() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseURL/api/brokers/${widget.brokerId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          broker = jsonData['data'];

          // print('broker ----> $broker');

          loading = false;
        });
      } else {
        setState(() {
          error = true;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = true;
        loading = false;
      });
    }
  }

  Future<void> _launch(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> updateBrokerField(Map<String, dynamic> payload) async {

    print('payload -> $payload');
    try {
      final token = await AuthService.getToken();

      final response = await http.put(
        Uri.parse('$baseURL/api/brokers/${widget.brokerId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print("Field updated");
      } else {
        final decoded = jsonDecode(response.body);

        final String message =
            decoded['message'] ??
                decoded['error'] ??
                'Something went wrong';

        _showSnack(message);
        print("Update failed: ${response.body}");
      }
    } catch (e) {
      print("Error updating broker: $e");
    }
  }
  void _showSnack(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  void _openEditProfileDialog() {
    bool isSaving = false;
    String? dialogError;

    print('broker ---> $broker');
    final displayNameC = TextEditingController(text: broker!['displayName'] ?? '');
    final profileTitleC = TextEditingController(text: broker!['brokerTitle'] ?? '');
    final bioC = TextEditingController(text: broker!['bio'] ?? '');
    final websiteC = TextEditingController(text: broker!['website'] ?? '');

    final addressC = TextEditingController(text: broker!['address'] ?? '');
    final cityC = TextEditingController(text: broker!['city'] ?? '');
    final stateC = TextEditingController(text: broker!['state'] ?? '');
    final countryC = TextEditingController(text: broker!['country'] ?? 'UAE');
    final postalCodeC = TextEditingController(text: broker!['postalCode'] ?? '');

    final companyC = TextEditingController(text: broker!['companyName'] ?? '');
    final licenseC = TextEditingController(text: broker!['licenseNumber'] ?? '');
    final reraC = TextEditingController(text: broker!['reraNumber'] ?? '');

    final linkedinC = TextEditingController(text: broker!['socialLinks']?['linkedin'] ?? '');
    final twitterC = TextEditingController(text: broker!['socialLinks']?['twitter'] ?? '');
    final facebookC = TextEditingController(text: broker!['socialLinks']?['facebook'] ?? '');

    List<String> selectedCategories =
    List<String>.from(broker!['categories'] ?? []);



    List<String> selectedLangs =
    List<String>.from(broker!['languages'] ?? []);

    List<String> selectedSpecs =
    List<String>.from(broker!['specializations'] ?? []);

    bool isFreelancer = broker!['companyName'] == null;
    bool hasBRN = broker!['brnNumber'] != null;

    final brnNumberC = TextEditingController(text: broker!['brnNumber'] ?? '');

    DateTime? brnIssueDate = broker!['brnIssuesDate'] != null
        ? DateTime.parse(broker!['brnIssuesDate'])
        : null;


    DateTime? brnExpiryDate = broker!['brnExpiryDate'] != null
        ? DateTime.parse(broker!['brnExpiryDate'])
        : null;


    Uint8List? selectedImageBytes;
    String? selectedImageName;
    String? uploadedImageUrl;
    String fullWhatsappNumber = broker!['whatsappno'] ?? "";
    final TextEditingController whatsappC = TextEditingController(
      text: fullWhatsappNumber.replaceAll("+971", ""),
    );

    final String savedMobile = broker!['mobile'] ?? ""; // e.g. +971585554845
    final String savedWhatsapp = broker!['whatsappno'] ?? "";

    final TextEditingController mobileC = TextEditingController();

    String fullMobileNumber = broker!['mobile'] ?? "";

    bool sameAsMobile = broker!['mobile'] == broker!['whatsappno'];


    Widget _buildTextField(
        TextEditingController controller,
        String label, {
          bool required = false,
          TextInputType keyboardType = TextInputType.text,
          IconData? icon,
        }) {
      final focusNode = FocusNode();

      return StatefulBuilder(
        builder: (context, setInnerState) {
          focusNode.addListener(() => setInnerState(() {}));

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: focusNode.hasFocus
                      ? kPrimaryColor.withOpacity(0.08)
                      : Colors.black12.withOpacity(0.04),
                  blurRadius: focusNode.hasFocus ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              validator: required
                  ? (v) => v == null || v.trim().isEmpty
                  ? 'Please enter $label'
                  : null
                  : null,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                floatingLabelStyle: GoogleFonts.poppins(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: icon != null
                    ? Padding(
                  padding: const EdgeInsets.only(left: 10, right: 6),
                  child: Icon(
                      icon,
                      size: 20,
                      color: focusNode.hasFocus
                          ? kPrimaryColor
                          : kPrimaryColor
                  ),
                )
                    : null,
                prefixIconConstraints:
                const BoxConstraints(minWidth: 40, maxHeight: 26),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: kPrimaryColor.withOpacity(0.9),
                    width: 1.6,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
              ),
            ),
          );
        },
      );
    }



    Widget _buildMultilineField(
        TextEditingController controller,
        String label, {
          bool required = true,
          IconData? icon,
        }) {
      final focusNode = FocusNode();

      return StatefulBuilder(
        builder: (context, setInnerState) {
          focusNode.addListener(() => setInnerState(() {}));

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: focusNode.hasFocus
                      ? kPrimaryColor.withOpacity(0.08)
                      : Colors.black12.withOpacity(0.04),
                  blurRadius: focusNode.hasFocus ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              validator: required
                  ? (v) =>
              v == null || v.trim().isEmpty ? 'Please enter $label' : null
                  : null,
              decoration: InputDecoration(
                labelText: label,
                alignLabelWithHint: true,
                labelStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                floatingLabelStyle: GoogleFonts.poppins(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                prefixIcon: icon != null
                    ? Padding(
                  padding: const EdgeInsets.only(left: 10, right: 6),
                  child: Icon(
                    icon,
                    size: 20,
                    color: focusNode.hasFocus
                        ? kPrimaryColor
                        : Colors.grey.shade500,
                  ),
                )
                    : null,
                prefixIconConstraints:
                const BoxConstraints(minWidth: 40, maxHeight: 26),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: kPrimaryColor.withOpacity(0.9),
                    width: 1.6,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
              ),
            ),
          );
        },
      );
    }

    Widget _buildMultiSelect(
        String label,
        List<String> options,
        List<String> selectedList,
        void Function(VoidCallback) setStateDialog,

        ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Label
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
          ),

          // Chip Group
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              final isSelected = selectedList.contains(option);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 0),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    colors: [kPrimaryColor, kPrimaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  color: isSelected
                      ? null
                      : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? kPrimaryColor.withOpacity(0.8)
                        : Colors.grey.shade300,
                    width: 1.2,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: kPrimaryColor.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    setStateDialog(() {
                      if (isSelected) {
                        selectedList.remove(option);
                      } else {
                        selectedList.add(option);
                      }
                    });
                  },
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        Text(
                          option,
                          style: GoogleFonts.poppins(
                            color: isSelected
                                ? Colors.white
                                : Colors.black87.withOpacity(0.8),
                            fontSize: 13.8,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }
    Widget _buildSwitch(String text, bool value, Function(bool) onChanged) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          Switch(activeColor: kPrimaryColor, value: value, onChanged: onChanged),
        ],
      );
    }

    Future<void> _pickDate(
        bool isIssue,
        void Function(VoidCallback) setStateDialog,
        ) async {
      final picked = await showDatePicker(
        context: context,

        // 🔴 If expiry date → cannot be before issue date
        firstDate: isIssue
            ? DateTime(2015)
            : (brnIssueDate ?? DateTime.now()),

        lastDate: DateTime(2035),

        // 🔴 Initial date logic
        initialDate: isIssue
            ? (brnIssueDate ?? DateTime.now())
            : (brnExpiryDate ??
            brnIssueDate ??
            DateTime.now()),
      );

      if (picked != null) {
        setStateDialog(() {
          if (isIssue) {
            brnIssueDate = picked;

            // 🔴 Auto-fix expiry if it becomes invalid
            if (brnExpiryDate != null &&
                brnExpiryDate!.isBefore(brnIssueDate!)) {
              brnExpiryDate = null;
            }
          } else {
            brnExpiryDate = picked;
          }
        });
      }
    }



    Widget _buildDateField(String label, DateTime? value, bool isIssue,  void Function(VoidCallback) setStateDialog,
        ) {
      return GestureDetector(
        onTap: () => _pickDate(isIssue,  setStateDialog,
        ),
        child: Container(
          key: ValueKey(value?.toIso8601String() ?? 'empty'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: kFieldBackgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value == null
                    ? "Select $label"
                    : "$label: ${DateFormat('dd-MMM-yyyy').format(value)}",

                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
              ),
              const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        displayNameC.text = broker!['displayName'];
        mobileC.text = broker!['mobile'];
        whatsappC.text = broker!['whatsappno'];
        bool copyWhatsapp = false;
        String selectedCode = "+971";

        return StatefulBuilder(
          builder: (context, setStateDialog) {

            Future<void> pickImage() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                allowMultiple: false,
                withData: true,
              );

              if (result != null && result.files.isNotEmpty) {
                selectedImageBytes = result.files.first.bytes;
                 selectedImageName = result.files.first.name; // ✅ Actual file name

                setStateDialog(() {}); // refresh UI in dialog
              }
            }

            Future<String?> uploadProfileImage(Uint8List fileBytes, String? originalFileName, BuildContext context) async {
              try {
                final token = await AuthService.getToken();
                final url = Uri.parse('$baseURL/api/upload/avatar');

                // ✅ BrowserClient for web uploads
                final client = BrowserClient()..withCredentials = false;
                final request = http.MultipartRequest("POST", url);
                request.headers['Authorization'] = "Bearer $token";

                // ✅ Use actual file name if available, else skip filename entirely
                final multipartFile = http.MultipartFile.fromBytes(
                  'avatar', // <-- backend expects this exact key
                  fileBytes,
                  filename: originalFileName?.isNotEmpty == true ? originalFileName : null,
                  contentType: MediaType("image", "jpeg"),
                );

                request.files.add(multipartFile);

                final streamed = await client.send(request);
                final response = await http.Response.fromStream(streamed);

                print("🛰️ Upload status: ${response.statusCode}");
                print("📤 Upload response: ${response.body}");

                if (response.statusCode == 200) {
                  final decoded = jsonDecode(response.body);

                  // ✅ Your backend returns avatar under data.user.avatar
                  final avatarUrl = decoded['data']?['user']?['broker']?['avatar'];

                  if (avatarUrl != null && avatarUrl.isNotEmpty) {

                    return avatarUrl;
                  } else {
                    print("⚠️ Avatar URL not found in response: $decoded");
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("⚠️ Upload failed (${response.statusCode})"),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }

                return null;
              } catch (e) {
                print("❌ Upload error: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("❌ Error uploading: $e"),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return null;
              }
            }

            bool _validateCompanyAndBRN() {
              void showError(String msg) {
                setStateDialog(() {
                  dialogError = msg;
                });
              }

              // 🏢 Company checks
              if (!isFreelancer) {
                if (companyC.text.trim().isEmpty) {
                  showError("Company name is required");
                  return false;
                }
                if (licenseC.text.trim().isEmpty) {
                  showError("License number is required");
                  return false;
                }
                if (reraC.text.trim().isEmpty) {
                  showError("RERA number is required");
                  return false;
                }
              }

              // 🆔 BRN checks
              if (!isFreelancer && hasBRN) {
                if (brnNumberC.text.trim().isEmpty) {
                  showError("BRN number is required");
                  return false;
                }
                if (brnIssueDate == null) {
                  showError("BRN issue date is required");
                  return false;
                }
                if (brnExpiryDate == null) {
                  showError("BRN expiry date is required");
                  return false;
                }
                // 🔴 NEW: expiry must be after issue
                if (brnExpiryDate!.isBefore(brnIssueDate!)) {
                  showError("BRN expiry date must be after issue date");
                  return false;
                }
              }

              // ✅ Clear error if everything is fine
              setStateDialog(() => dialogError = null);
              return true;
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 80),
              child: Center(
                child: Container(
                    width: 600,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // BACK + TITLE
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Edit Profile",
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (widget.userData['role'] == "ADMIN") ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.workspace_premium, size: 16, color: Colors.orange.shade700),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Admin",
                                        style: GoogleFonts.poppins(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ]
                            ],
                          ),




                          const SizedBox(height: 28),

                          // ================= PERSONAL INFORMATION =================
                          Text("Personal Information",
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),

                          // UPLOAD PICTURE
                          Text("Upload Picture",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: pickImage,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                  side: BorderSide(color: Colors.grey.shade400, width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.upload, size: 18, color: Colors.black54),
                                    const SizedBox(width: 10),
                                    Text("Choose File",
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 20),

                              // IMAGE PREVIEW
                              if (selectedImageBytes != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    selectedImageBytes!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          _buildTextField(displayNameC, "Display Name", required: true),
                          const SizedBox(height: 14),

                          // _buildTextField(profileTitleC, "Profile Title"),
                          // const SizedBox(height: 14),

                          _buildMultilineField(bioC, "Bio"),


                          const SizedBox(height: 22),

                          // 🌍 MOBILE FIELD — EXACT SAME AS YOUR CODE
                          IntlPhoneField(
                            initialValue: savedMobile,   // <-- THIS auto-selects UAE and fills number correctly
                            pickerDialogStyle:  PickerDialogStyle(width: 400),
                            decoration: InputDecoration(
                              labelText: 'Mobile Number',
                              filled: true,
                              fillColor: Colors.white,
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                              floatingLabelStyle: GoogleFonts.poppins(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: kPrimaryColor, width: 1.6),
                              ),
                            ),

                            // 🔄 When user types Mobile
                            onChanged: (phone) {
                              fullMobileNumber = phone.completeNumber;
                            },

                            validator: (phone) {
                              if (phone == null || phone.number.isEmpty) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),

                          // 🟩 Checkbox: SAME AS MOBILE
                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.9,
                                child: Checkbox(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  activeColor: kPrimaryColor,
                                  value: sameAsMobile,
                                  onChanged: (val) {
                                    setStateDialog(() {
                                      sameAsMobile = val ?? false;

                                      if (sameAsMobile) {
                                        // Copy mobile → WhatsApp
                                        whatsappC.text = mobileC.text;
                                        fullWhatsappNumber = fullMobileNumber;
                                      } else {
                                        // CLEAR WhatsApp field completely
                                        whatsappC.clear();
                                        fullWhatsappNumber = "";
                                      }
                                    });
                                  },
                                ),

                              ),
                              Text(
                                "Same as WhatsApp number",
                                style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.black87),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // 🌍 WHATSAPP FIELD — HIDE IF SAME AS MOBILE
                          if (!sameAsMobile)
                            IntlPhoneField(
                              key: ValueKey("whatsapp_field_${sameAsMobile}") , // IMPORTANT: forces rebuild

                              initialCountryCode: 'AE',
                              initialValue: fullWhatsappNumber.isNotEmpty ? fullWhatsappNumber : null,
                              pickerDialogStyle:  PickerDialogStyle(width: 400),
                              decoration: InputDecoration(
                                labelText: 'WhatsApp Number',
                                filled: true,
                                fillColor: Colors.white,
                                labelStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                                floatingLabelStyle: GoogleFonts.poppins(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: kPrimaryColor, width: 1.6),
                                ),
                              ),

                              onChanged: (phone) {
                                fullWhatsappNumber = phone.completeNumber;

                                // ALSO update controller so clear() works
                                whatsappC.text = phone.number;

                                },

                              validator: (phone) {
                                if (!sameAsMobile && (phone == null || phone.number.isEmpty)) {
                                  return 'Please enter a valid WhatsApp number';
                                }
                                return null;
                              },
                            ),




// ================= SPECIALIZATION & LANGUAGES =================
                          const SizedBox(height: 10),

                          Text("Professional Details",
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),

                          _buildMultiSelect("Specializations", specializations, selectedSpecs,  setStateDialog,
                          ),
                          const SizedBox(height: 16),

                          _buildMultiSelect("Languages", languages, selectedLangs,  setStateDialog,
                          ),
                          const SizedBox(height: 16),

                          _buildMultiSelect("Categories", categories, selectedCategories,  setStateDialog,
                          ),
// ================= ADDRESS =================
                          const SizedBox(height: 24),


                          Text("Address Details",
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),

                          _buildTextField(addressC, "Address"),
                          const SizedBox(height: 14),

                          _buildTextField(cityC, "City"),
                          const SizedBox(height: 14),

                          _buildTextField(stateC, "State"),
                          const SizedBox(height: 14),

                          _buildTextField(countryC, "Country"),
                          const SizedBox(height: 14),

                          _buildTextField(postalCodeC, "Postal Code",
                              keyboardType: TextInputType.number),
// ================= COMPANY INFO =================
                          const SizedBox(height: 24),

                          Text("Company Information",
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),

                          _buildSwitch("I am a Freelancer", isFreelancer, (v) {
                            setStateDialog(() => isFreelancer = v);
                          }),

                          if (!isFreelancer) ...[
                            const SizedBox(height: 16),
                            _buildTextField(companyC, "Company Name"),
                            const SizedBox(height: 14),
                            _buildTextField(licenseC, "License Number"),
                            const SizedBox(height: 14),
                            _buildTextField(reraC, "RERA Number (ORN)"),
                          ],

                          if(!isFreelancer)...[
                            // ================= BRN INFO =================
                            const SizedBox(height: 24),

                            Text("BRN Information",
                                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),

                            _buildSwitch("I have a BRN", hasBRN, (v) {
                              setStateDialog(() => hasBRN = v);
                            }),

                            if (hasBRN) ...[
                              const SizedBox(height: 16),
                              _buildTextField(brnNumberC, "BRN Number"),
                              const SizedBox(height: 14),
                              _buildDateField("Issue Date", brnIssueDate, true,setStateDialog),
                              const SizedBox(height: 14),
                              _buildDateField("Expiry Date", brnExpiryDate, false,setStateDialog),
                            ],

                          ],

// ================= ONLINE PRESENCE =================
                          const SizedBox(height: 24),

                          Text("Online Presence",
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),

                          _buildTextField(websiteC, "Website"),
                          const SizedBox(height: 14),

                          _buildTextField(linkedinC, "LinkedIn"),
                          const SizedBox(height: 14),

                          _buildTextField(twitterC, "Twitter"),
                          const SizedBox(height: 14),

                          _buildTextField(facebookC, "Facebook"),

                          // ✅ ERROR MESSAGE MUST BE HERE
                          if (dialogError != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      dialogError!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // SAVE BUTTON
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () async {

                                // 🔴 VALIDATION FIRST
                                if (!_validateCompanyAndBRN()) return;



                                setStateDialog(() => isSaving = true);
                                // 1️⃣ Upload image if selected
                                if (selectedImageBytes != null) {
                                   uploadedImageUrl = await uploadProfileImage(selectedImageBytes!, selectedImageName, context);

                                }

                                // 2️⃣ Prepare data to update
                                Map<String, dynamic> payload = {
                                  "display_name": displayNameC.text.trim(),

                                  "bio": bioC.text.trim(),
                                  "website": websiteC.text.trim(),
                                  "address": addressC.text.trim(),
                                  "city": cityC.text.trim(),
                                  "state": stateC.text.trim(),
                                  "country": countryC.text.trim(),
                                  "postal_code": postalCodeC.text.trim(),


                                  "mobile": fullMobileNumber,
                                  "whatsappno": fullWhatsappNumber,

                                  "categories": selectedCategories,
                                  "languages": selectedLangs,
                                  "specializations": selectedSpecs,

                                  "companyName": isFreelancer ? null : companyC.text.trim(),
                                  "licenseNumber": isFreelancer ? null : licenseC.text.trim(),
                                  "reraNumber": isFreelancer ? null : reraC.text.trim(),

                                  "brnNumber": isFreelancer ? null : hasBRN ? brnNumberC.text.trim() : null,
                                  "brn_issues_date":isFreelancer ? null : brnIssueDate != null
                                      ? DateFormat('yyyy-MM-dd').format(brnIssueDate!)
                                      : null,
                                  "brn_expiry_date": isFreelancer ? null : brnExpiryDate != null
                                      ? DateFormat('yyyy-MM-dd').format(brnExpiryDate!)
                                      : null,

                                  "social_links": {
                                    "linkedin": linkedinC.text.trim(),
                                    "twitter": twitterC.text.trim(),
                                    "facebook": facebookC.text.trim(),
                                  },

                                };

                                // 3️⃣ Send to API
                                await updateBrokerField( payload);

                                // 4️⃣ Close dialog
                                Navigator.pop(context);

                                // 5️⃣ Refresh profile
                                await fetchBrokerById();
                              },

                              icon: isSaving? SizedBox(
                              width: 18,   // smaller size
                              height: 18,  // smaller size
                              child: CircularProgressIndicator(
                              strokeWidth: 2, // thinner stroke
                              ),
                                  ):  Icon(Icons.check_circle,
                                  color: Colors.white, size: 18),
                              label: isSaving? Text(
                              "Saving...",
                                  style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                                  ):
                                   Text("Save Changes",
                                style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                                ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                ),
              ),
            );
          });

      },
    );


  }

  Widget buildSocialLinksBody() {
    if (broker!['socialLinks'].entries
        .where((entry) =>
    entry.value != null &&
        entry.value.toString().trim().isNotEmpty)
        .isNotEmpty) {


      return Wrap(
        spacing: 14,
        runSpacing: 12,
        children: broker!['socialLinks'].entries.map<Widget>((entry) {
          final platform = entry.key.toLowerCase();
          final link = entry.value.toString().trim();

          IconData icon;
          Gradient? gradient;
          Color solidColor;

          switch (platform) {
            case 'linkedin':
              icon = FontAwesomeIcons.linkedinIn;
              gradient = const LinearGradient(
                colors: [Color(0xFF0077B5), Color(0xFF0E6791)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );
              solidColor = const Color(0xFF0077B5);
              break;
            case 'instagram':
              icon = FontAwesomeIcons.instagram;
              gradient = const LinearGradient(
                colors: [
                  Color(0xFFF58529),
                  Color(0xFFDD2A7B),
                  Color(0xFF8134AF)
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              );
              solidColor = const Color(0xFFE1306C);
              break;
            case 'facebook':
              icon = FontAwesomeIcons.facebookF;
              gradient = const LinearGradient(
                colors: [Color(0xFF1877F2), Color(0xFF145DBF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );
              solidColor = const Color(0xFF1877F2);
              break;
            case 'twitter':
            case 'x':
              icon = FontAwesomeIcons.xTwitter;
              gradient = const LinearGradient(
                colors: [Color(0xFF000000), Color(0xFF333333)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );
              solidColor = Colors.black87;
              break;
            default:
              icon = FontAwesomeIcons.globe;
              gradient = const LinearGradient(
                colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );
              solidColor = kPrimaryColor;
          }

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => hoveredSocial = platform),
            onExit: (_) => setState(() => hoveredSocial = ''),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: hoveredSocial == platform ? 1.08 : 1.0,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final url = link.startsWith("http")
                      ? link
                      : "https://${link.replaceAll('@', '')}";
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: hoveredSocial == platform
                            ? solidColor.withOpacity(0.25)
                            : Colors.black12.withOpacity(0.05),
                        blurRadius: hoveredSocial == platform ? 10 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: hoveredSocial == platform
                          ? solidColor.withOpacity(0.5)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (rect) =>
                            gradient!.createShader(rect),
                        child:
                        Icon(icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        platform[0].toUpperCase() + platform.substring(1),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );


    }
    else
    {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Text(
          "No social links found",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

    }


  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: AnimatedLogoLoader(assetPath: 'assets/collabrix_logo.png'),),
      );
    }

    if (error || broker == null) {
      return Scaffold(
        backgroundColor: backgroundColor,

        body: Center(
          child: Text("Failed to load broker details.",
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.black54)),
        ),
      );
    }

    final name = broker!['displayName'] ?? '';
    final company = broker!['companyName'] ?? '';
    final verified = broker!['isVerified'] == true;
    final approvalStatus = (broker!['approvalStatus'] ?? '').toString().toUpperCase();
    final isAdmin = widget.userData['role'] == 'ADMIN';

    final avatar = broker?['avatar'];

    print('avatarr -> $baseURL/$avatar');
    final email = broker!['email'];
    final phone = broker!['mobile'];
    final whatsapp = broker!['whatsappno'] ?? broker!['mobile'] ?? "0";

    final bio = broker!['bio'] ?? '';
    final rating = broker!['rating'] ?? 'N/A';
    final requirements = broker!['requirements'] ?? [];
    final reviews = broker!['reviews'] ?? [];
    final properties = broker!['properties'] ?? [];
    final List<String> languages = List<String>.from(broker?['languages'] ?? []);
    final List<String> categories = List<String>.from(broker?['categories'] ?? []);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1400,   // fix deployment bug
            ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          // 👤 Avatar
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: kPrimaryColor.withOpacity(0.08),
                            child: ClipOval(
                              child: avatar != null && avatar.isNotEmpty

                                  ? WebCompatibleImage(
                                imageUrl: (avatar.toString().startsWith('http://') || avatar.toString().startsWith('https://'))
                                    ? avatar.toString()
                                    : '$baseURL/$avatar',
                                width: 90,
                                height: 90,
                                fallback: Image.asset(
                                  'assets/collabrix_logo.png',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.contain,
                                ),
                              )
                                  : Image.asset(
                                'assets/collabrix_logo.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          const SizedBox(width: 24),

                          // 🧾 Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name + Verified Status
                                Row(
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // APPROVAL TAGS
                                    if (approvalStatus == "APPROVED")
                                      _statusTag(
                                        icon: Icons.approval_rounded,
                                        label: "Approved",
                                        color: Colors.orange.shade700,
                                        bg: Colors.orange.shade50,
                                        border: Colors.orange.shade300,
                                      )
                                    else if (approvalStatus == "PENDING")
                                      _statusTag(
                                        icon: Icons.hourglass_empty_outlined,
                                        label: "Not Approved",
                                        color: Colors.blue.shade800,
                                        bg: Colors.blue.shade50,
                                        border: Colors.blue.shade300,
                                      )
                                    else
                                      _statusTag(
                                        icon: Icons.cancel_outlined,
                                        label: "Not Approved",
                                        color: Colors.red.shade700,
                                        bg: Colors.red.shade50,
                                        border: Colors.red.shade300,
                                      ),

                                    const SizedBox(width: 8),

                                    // VERIFIED TAG
                                    if (verified)
                                      _statusTag(
                                        icon: Icons.verified,
                                        label: "Verified",
                                        color: Colors.green.shade700,
                                        bg: Colors.green.shade50,
                                        border: Colors.green.shade300,
                                      ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: _openEditProfileDialog,
                                      borderRadius: BorderRadius.circular(50),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12.withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.edit,
                                          color: kPrimaryColor,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // 🏢 Company
                                if (company.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.business_outlined,
                                          color: Colors.black54, size: 16),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          company,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ]
                                else...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.business_outlined,
                                          color: Colors.black54, size: 16),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          "Freelancer",
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
    ],


                                // 🏷️ Categories
                                if (categories.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: categories.map((cat) {
                                      final isResidential =
                                          cat.toUpperCase() == "RESIDENTIAL";
                                      final gradient = isResidential
                                          ? const LinearGradient(
                                        colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                          : const LinearGradient(
                                        colors: [Color(0xFFFFA751), Color(0xFFFF5F6D)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      );

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: gradient,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12.withOpacity(0.1),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          cat,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // 📞 Contact Icons
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _contactButton(Icons.call, "Call", "tel:$phone", phone: phone),
                              const SizedBox(height: 10),
                              _contactButton(
                                FontAwesomeIcons.whatsapp,
                                "WhatsApp",
                                "https://wa.me/${whatsapp.toString().replaceAll('+', '')}",
                              ),
                              const SizedBox(height: 10),
                              _contactButton(
                                  Icons.email_outlined, "Email", "mailto:$email"),
                            ],
                          ),
                        ],
                      ),


                    ],
                  ),
                ),



                const SizedBox(height: 30),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statCard("Reputation Score", "0", Icons.bar_chart),
                    _statCard("Average Rating", rating.toString(), Icons.star),
                    _statCard("Completed Deals", "0", Icons.check_circle_outline),
                    _statCard("AI Review Score", "N/A", Icons.memory),
                  ],
                ),

                const SizedBox(height: 40),

                // --- ABOUT + SEGMENTED SECTION SIDE BY SIDE ---
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double maxW = constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : MediaQuery.of(context).size.width;

                    final double halfWidth = (maxW - 40) / 2;
                    return
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LEFT: About Section
                          Container(
                            width: halfWidth,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "About ${name.split(" ").first}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  bio.isNotEmpty ? bio : "No description available.",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    color: Colors.black87,
                                  ),
                                ),

                                // 🌐 Languages & Social Links Section (auto-hide if empty)
                                if ((languages.isNotEmpty) ||
                                    (broker!['socialLinks'] != null && broker!['socialLinks'].isNotEmpty))
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 🗣️ Languages
                                      if (languages.isNotEmpty) ...[
                                        const SizedBox(height: 24),
                                        Text(
                                          "Languages",
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 8,
                                          children: languages.map((lang) {
                                            return Container(
                                              padding:
                                              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.teal.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.teal.shade200, width: 0.6),
                                              ),
                                              child: Text(
                                                lang,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.teal.shade800,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],

                                      // 🔗 Social Links
                                      if (broker!['socialLinks'] != null &&
                                          broker!['socialLinks'].isNotEmpty) ...[
                                        const SizedBox(height: 28),
                                        Text(
                                          "Social Links",
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        buildSocialLinksBody()
                                      ],
                                    ],
                                  )
                              ],
                            ),
                          ),

                          const SizedBox(width: 40),

                          // RIGHT: Segmented Bar + Dynamic Content
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Segmented Bar with full width
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(14.0),
                                        topRight: Radius.circular(14.0),
                                      ),


                                      border: Border.all(color: Colors.grey.shade200, width: 1.2),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [

                                        if(widget.userData['broker']['isVerified'])...[
                                          _buildSegmentButton("Listings", count: properties.length),
                                          _buildSegmentButton("Requirements", count: requirements.length),
                                        ],


                                        _buildSegmentButton(
                                          "Reviews",
                                          count: reviews.where((r) => r['status'] == "APPROVED").length,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 0),

                                  // Dynamic content area
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    child: activeSection == "Listings"
                                        ? _buildListings(properties)
                                        : activeSection == "Requirements"
                                        ? _buildRequirements(requirements)
                                        : _buildReviews(reviews),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        ],
                      );


                  },
                ),






              ],
            ),
          ),),)

    );
  }

  Widget _buildSegmentButton(String label, {int count = 0}) {
    final bool isActive = activeSection == label;
    final bool isVerified = widget.userData['broker']['isVerified'] == true;
    final approved = broker!['approvalStatus'] == true;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => activeSection = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 0),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
              colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isActive ? null : Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 1),
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              left: label == "Listings" || (!isVerified && label == "Reviews")
                  ? BorderSide(color: Colors.grey.shade300, width: 1)
                  : BorderSide.none,
              right: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            borderRadius: BorderRadius.horizontal(
              left: label == "Listings" ||
                  (!isVerified && label == "Reviews")
                  ? const Radius.circular(12)
                  : Radius.zero,
              right: label == "Reviews" ? const Radius.circular(12) : Radius.zero,
            ),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                  color: isActive ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Colors.white.withOpacity(0.9)
                      : kPrimaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: isActive
                        ? Colors.white.withOpacity(0.8)
                        : Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  "$count",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? kPrimaryColor : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components ---
  Widget _statCard(String title, String value, IconData icon) {
    // 🎨 Dynamic gradient colors for each type
    LinearGradient gradient;
    if (icon == Icons.star) {
      gradient = const LinearGradient(
        colors: [Color(0xFFFFC107), Color(0xFFFF9800)], // Gold / Amber
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (icon == Icons.bar_chart) {
      gradient = const LinearGradient(
        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)], // Blue shades
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (icon == Icons.check_circle) {
      gradient = const LinearGradient(
        colors: [Color(0xFF00B09B), Color(0xFF96C93D)], // Green shades
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (icon == Icons.memory) {
      gradient = const LinearGradient(
        colors: [Color(0xFF7F00FF), Color(0xFFE100FF)], // deep violet → magenta
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

    } else {
      gradient = LinearGradient(
        colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.7)], // Default
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🌈 Gradient Icon Container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),

            const SizedBox(width: 14),

            // 📊 Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildListings(List data) {
    if (data.isEmpty) return _emptyMessage("No listings available.");

    return Column(

      children: data.map((p) {
        final title = p['title'] ?? "Untitled Property";
        final price = double.tryParse(p['price'] ?? '0') ?? 0;
        final formattedPrice = price >= 1000
            ? "AED ${(price / 1000)}K"
            : "AED $price";
        final category = p['category'] ?? "N/A";
        final type = p['transactionType'] ?? "N/A";
        final image = (p['images'] != null && p['images'].isNotEmpty)
            ? p['images'][0]
            : null;

        final gradient = category.toUpperCase() == "RESIDENTIAL"
            ? const LinearGradient(
          colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : const LinearGradient(
          colors: [Color(0xFFFFA751), Color(0xFFFF5F6D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

        return Container(
          padding: const EdgeInsets.only(left: 22,right:22, top: 0,bottom:0),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),

            border: Border.all(color: Colors.grey.shade200.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
             /* // 🏙️ Image section
              if (image != null)

                ClipRRect(
                  borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: Image.network(
                    image,
                    height: 140,
                    width: 180,
                    fit: BoxFit.cover,

                  )
                )

              else
                Container(
                  height: 140,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16)),
                  ),
                  child: Icon(Icons.image_not_supported_outlined,
                      size: 40, color: Colors.grey.shade400),
                ),*/

              Container(
                width: 50,
                height: 50,

                decoration: BoxDecoration(

                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Color(0xFF0072FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.apartment,
                    color: Colors.white, size: 22),
              ),

              const SizedBox(width: 16),
              // 📄 Info section
              Expanded(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🏷️ Title
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // 💰 Price
                      Text(
                        formattedPrice,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 🧩 Category and Type chips
                      Wrap(
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: gradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              category,
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              type,
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal.shade700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


  Widget _buildRequirements(List data) {
    if (data.isEmpty) return _emptyMessage("No requirements found.");

    final formatter = NumberFormat.decimalPattern(); // for 1,000 style formatting

    return LayoutBuilder(
      builder: (context, constraints) {

        final isWide = constraints.maxWidth > 800;
        return Wrap(
          spacing: 20,
          runSpacing: 8,
          children: data.map<Widget>((req) {
            final title = req['title'] ?? "Untitled Requirement";
            final category = req['category'] ?? "N/A";
            final transaction = req['transactionType'] ?? "N/A";

            final minRaw = num.tryParse(req['minPrice'] ?? '') ?? 0;
            final maxRaw = num.tryParse(req['maxPrice'] ?? '') ?? 0;

            final minPrice = minRaw > 0 ? formatter.format(minRaw) : "—";
            final maxPrice = maxRaw > 0 ? formatter.format(maxRaw) : "—";

            return Container(
              width: isWide ? (constraints.maxWidth / 2) - 24 : double.infinity,
              padding: const EdgeInsets.only(left: 22,right:22, top: 12,bottom:12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),

              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌈 Gradient Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF0072FF).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.assignment_outlined,
                        color: Colors.white, size: 22),
                  ),

                  const SizedBox(width: 16),

                  // 📋 Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Meta line
                        Row(
                          children: [
                            Icon(Icons.layers_outlined,
                                size: 15, color: Colors.grey.shade600),
                            const SizedBox(width: 5),
                            Text(
                              category,
                              style: GoogleFonts.poppins(
                                fontSize: 13.2,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.swap_horiz_rounded,
                                size: 15, color: Colors.grey.shade600),
                            const SizedBox(width: 5),
                            Text(
                              transaction,
                              style: GoogleFonts.poppins(
                                fontSize: 13.2,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Divider(color: Colors.grey.shade200, height: 10),

                        const SizedBox(height: 8),

                        // Price range
                        Row(
                          children: [
                            Icon(Icons.monetization_on_outlined,
                                size: 16, color: Colors.teal.shade700),
                            const SizedBox(width: 5),
                            Text(
                              "AED $minPrice - AED $maxPrice",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.teal.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildReviews(List data) {
    // 🔹 Keep only approved reviews
    final approvedReviews =
    data.where((r) => (r['status'] ?? '').toString().toUpperCase() == 'APPROVED').toList();

    if (approvedReviews.isEmpty) return _emptyMessage("No reviews available yet.");

    return Column(
      children: approvedReviews.map((r) {
        final reviewer = r['reviewer']?['displayName'] ?? "Anonymous";
        final avatar = r['reviewer']?['user']?['broker']['avatar'];
        final rating = r['rating'] ?? 0;
        final comment = r['comment'] ?? '';

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: avatar != null ? NetworkImage('$baseURL/$avatar') : null,
                backgroundColor: Colors.white,
                child: avatar == null
                    ? Text(
                  _getInitials(reviewer),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewer,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        rating,
                            (index) => const Icon(Icons.star,
                            color: Colors.amber, size: 16),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comment,
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

// helper for initials
  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }


  Widget _emptyMessage(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(text,
            style:
            GoogleFonts.poppins(color: Colors.black54, fontSize: 14.5)),
      ),
    );
  }


  Widget _contactButton(IconData icon, String label, String url, {String? phone}) {
    final Color baseColor = label == "WhatsApp"
        ? Colors.green
        : (label == "Email" ? Colors.orange.shade700 : kPrimaryColor);

    final buttonKey = GlobalKey();

    return SizedBox(
      width: 180,
      child: ElevatedButton.icon(
        key: buttonKey,
        onPressed: () async {
          // ✅ For Flutter Web: only show tooltip
          if (label == "Call" && phone != null && phone.isNotEmpty) {
            _hideTooltip();

            // Wait for frame to build (ensure context is attached)
            await Future.delayed(Duration(milliseconds: 20));

            final renderBox = buttonKey.currentContext?.findRenderObject() as RenderBox?;
            if (renderBox == null) return; // nothing to show if button not visible

            final position = renderBox.localToGlobal(Offset.zero);
            final size = renderBox.size;
            final overlay = Navigator.of(context).overlay;
            if (overlay == null) return;

            final overlaySize = MediaQuery.of(context).size;
            final showAbove = position.dy > overlaySize.height / 2;

            _activeTooltip = OverlayEntry(
              builder: (context) => Positioned(
                left: position.dx - 70,
                top: showAbove
                    ? position.dy - 85
                    : position.dy + size.height + 10,
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _tooltipController..forward(from: 0),
                    curve: Curves.easeIn,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: kPrimaryColor.withOpacity(0.3),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.phone,
                                    color: kPrimaryColor, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Broker Contact",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  fontSize: 13.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            phone,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );

            overlay.insert(_activeTooltip!);
            _tooltipVisible = true;

            // Auto dismiss after 3s
            Future.delayed(const Duration(seconds: 2)).then((_) {
              if (mounted) _hideTooltip();
            });
            return;
          }

          // ✅ Handle WhatsApp and Email for Web
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          }
        },
        icon: Icon(icon, size: 16, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: baseColor,
          shadowColor: baseColor.withOpacity(0.25),
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }


}
