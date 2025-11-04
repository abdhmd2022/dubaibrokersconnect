import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../dashboard/broker_shell.dart';
import '../dashboard/brokerdashboard.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

class BrokerSetupPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const BrokerSetupPage({super.key, required this.userData});

  @override
  State<BrokerSetupPage> createState() => _BrokerSetupPageState();
}

class _BrokerSetupPageState extends State<BrokerSetupPage> {
  /// Form Key
  final _formKey = GlobalKey<FormState>();
  bool sameAsMobile = true;

  String? fullMobileNumber;
  String? fullWhatsappNumber;
  /// Controllers
  final displayNameC = TextEditingController();
  final profileTitleC = TextEditingController();
  final bioC = TextEditingController();
  final emailC = TextEditingController();
  final phoneC = TextEditingController();
  final mobileC = TextEditingController();
  final whatsappC = TextEditingController();
  final websiteC = TextEditingController();
  final addressC = TextEditingController();
  final cityC = TextEditingController();
  final stateC = TextEditingController();
  final countryC = TextEditingController(text: "UAE");
  final postalCodeC = TextEditingController();

  final List<String> categories = ["RESIDENTIAL", "COMMERCIAL"];
  List<String> selectedCategories = [];
  /// Company details
  final companyC = TextEditingController();
  final licenseC = TextEditingController();
  final reraC = TextEditingController();
  final establishC = TextEditingController();

  /// BRN details
  final brnNumberC = TextEditingController();
  DateTime? brnIssueDate;
  DateTime? brnExpiryDate;

  /// Social Links
  final linkedinC = TextEditingController();
  final twitterC = TextEditingController();
  final facebookC = TextEditingController();

  /// State toggles
  bool isFreelancer = false;
  bool hasBRN = false;
  bool isPrivileged = false;
  bool isLoading = false;

  @override
  void initState() {

    super.initState();

    final firstName = widget.userData['firstName'] ?? '';
    final lastName = widget.userData['lastName'] ?? '';

    // Pre-fill display name if available
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      displayNameC.text = "$firstName $lastName".trim();
    }
  }

  /// Hardcoded lists (editable later for API)
  final List<String> specializations = [
    "Luxury Properties",
    "Dubai Marina",
    "Downtown Dubai",
    "Commercial Properties",
    "Residential Sales"
  ];
  final List<String> languages = ["English", "Arabic", "Hindi", "Urdu"];

  /// Selected chip values
  List<String> selectedSpecs = [];
  List<String> selectedLangs = [];

  /// ------------------------------
  /// API CALL: Create Broker Profile
  /// ------------------------------
  Future<void> _createBrokerProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final userId = widget.userData['id'];
    print('user id -> $userId');

    final body = {
      "display_name": displayNameC.text.trim(),
      "userId": userId,
      "company_name": isFreelancer ? null : companyC.text.trim(),
      "bio": bioC.text.trim(),
      "license_number": isFreelancer ? null : licenseC.text.trim(),
      "rera_number": isFreelancer ? null : reraC.text.trim(),
      "establishment_license": isFreelancer ? null : establishC.text.trim(),
      "address": addressC.text.trim(),
      "city": cityC.text.trim(),
      "state": stateC.text.trim(),
      "country": countryC.text.trim(),
      "postal_code": postalCodeC.text.trim(),
      "phone":fullMobileNumber ?? '',
      "mobile": fullMobileNumber ?? '',
      "whatsapp": fullWhatsappNumber ?? '',

      "email": emailC.text.trim(),
      "categories": selectedCategories,
      "website": websiteC.text.trim(),
      "social_links": {
        "linkedin": linkedinC.text.trim(),

        "twitter": twitterC.text.trim(),
        "facebook": facebookC.text.trim(),
      },
      "specializations": selectedSpecs,
      "languages": selectedLangs,
    };


    print('body -> $body');

    final url = Uri.parse('$baseURL/api/brokers');

    try {
      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);
      print('done -> $data');


      if (res.statusCode == 201 && data['success'] == true) {

        final url = Uri.parse('$baseURL/api/auth/me');

        print('url -> $url');
        try {
          final res = await http.get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json'},
          );


          final data_user = jsonDecode(res.body);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BrokerShell(userData: data_user['data']['user'])),
          );
        }
        catch (e)
        {

        }



      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to create broker profile'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to server → $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ------------------------------
  /// DATE PICKER HANDLER
  /// ------------------------------
  Future<void> _pickDate(bool isIssue) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isIssue) {
          brnIssueDate = picked;
        } else {
          brnExpiryDate = picked;
        }
      });
    }
  }

  /// ------------------------------
  /// BUILD METHOD
  /// ------------------------------
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: backgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// ---------- MAIN TITLE ----------
                        Center(
                          child: Column(
                            children: [
                              Text(
                                "Broker Profile Setup",
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: kPrimaryColor,
                                ),
                              ),

                              const SizedBox(height: 6),
                              Text(
                                "Complete your broker profile to continue",
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// ---------- PERSONAL INFO ----------
                        _buildCard([
                          _buildSectionHeader(Icons.person_outline, "Personal Information"),

                          const SizedBox(height: 14),
                          _buildTextField(displayNameC,
                              "Display Name",
                              required: true,
                               icon: Icons.person),
                          const SizedBox(height: 14),
                          _buildTextField(profileTitleC, "Profile Title",
                              required: false,
                              icon: Icons.group),
                          const SizedBox(height: 14),
                          _buildMultiSelect("Specializations", specializations, selectedSpecs,),
                          const SizedBox(height: 14),
                          _buildMultiSelect("Languages", languages, selectedLangs),
                          const SizedBox(height: 14),

                          _buildMultiSelect("Category", categories, selectedCategories),
                          const SizedBox(height: 14),

                          _buildMultilineField(bioC, "Bio"),
                        ]),

                        const SizedBox(height: 26),

                        /// ---------- CONTACT INFO ----------
                        _buildCard([
                          _buildSectionHeader(Icons.call_outlined, "Contact Information"),
                          const SizedBox(height: 14),

                          _buildTextField(
                            emailC,
                            "Email",
                            required: true,
                            keyboardType: TextInputType.emailAddress,
                            icon: Icons.email_outlined,
                          ),
                          /* const SizedBox(height: 14),
                            _buildTextField(
                              phoneC,
                              "Phone",
                              keyboardType: TextInputType.phone,
                              icon: Icons.phone_outlined,
                            ),*/
                          const SizedBox(height: 14),

                          // 🌍 MOBILE FIELD
                          IntlPhoneField(
                            controller: mobileC,
                            pickerDialogStyle: PickerDialogStyle(width: 400),
                            initialCountryCode: 'AE',
                            decoration: InputDecoration(
                              labelText: 'Mobile Number',
                              filled: true,
                              fillColor: Colors.white,
                              labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
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
                              fullMobileNumber = phone.completeNumber;


                              if (sameAsMobile) {
                                setState(() {
                                  fullWhatsappNumber = phone.completeNumber;
                                  whatsappC.text = phone.number; // keep controller text consistent too
                                });
                              }
                            },

                            onCountryChanged: (country) {
                              debugPrint('Country changed: ${country.name} (${country.dialCode})');
                            },
                            validator: (phone) {
                              if (phone == null || phone.number.isEmpty) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),



// ✅ Checkbox below Mobile field
                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.9,
                                child: Checkbox(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  activeColor: kPrimaryColor,
                                  value: sameAsMobile,
                                  onChanged: (val) {
                                    setState(() {
                                      sameAsMobile = val ?? false;

                                      if (sameAsMobile) {
                                        // ✅ Mirror both text and full number
                                        whatsappC.text = mobileC.text;
                                        fullWhatsappNumber = fullMobileNumber;
                                      } else {
                                        // ✅ Fully clear both text and stored number
                                        whatsappC.clear();
                                        fullWhatsappNumber = null;
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

// 🌍 WHATSAPP FIELD — Hides automatically if sameAsMobile is true
                          if (!sameAsMobile)
                            IntlPhoneField(
                              controller: whatsappC,
                              pickerDialogStyle: PickerDialogStyle(width: 400),
                              initialCountryCode: 'AE',
                              decoration: InputDecoration(
                                labelText: 'WhatsApp Number',
                                filled: true,
                                fillColor: Colors.white,
                                labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
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
                              },
                              validator: (phone) {
                                if (!sameAsMobile && (phone == null || phone.number.isEmpty)) {
                                  return 'Please enter a valid WhatsApp number';
                                }
                                return null;
                              },
                            ),





                          const SizedBox(height: 14),
                          _buildTextField(
                            websiteC,
                            "Website",
                            keyboardType: TextInputType.url,
                            icon: Icons.language_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            addressC,
                            "Address",
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            cityC,
                            "City",
                            icon: Icons.location_city_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            stateC,
                            "State",
                            icon: Icons.map_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            countryC,
                            "Country",
                            icon: Icons.flag_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            postalCodeC,
                            "Postal Code",
                            keyboardType: TextInputType.number,
                            icon: Icons.local_post_office_outlined,
                          ),
                        ]),

                        const SizedBox(height: 26),

                        /// ---------- COMPANY INFO ----------
                        _buildCard([
                          _buildSectionHeader(Icons.business_center_outlined, "Company Information"),
                          const SizedBox(height: 14),

                          _buildSwitch("I am a Freelancer", isFreelancer, (v) {
                            setState(() => isFreelancer = v);
                          }),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: !isFreelancer
                                ? Column(
                              key: const ValueKey("companySection"),
                              children: [
                                const SizedBox(height: 10),
                                _buildCard([
                                  _buildTextField(
                                    companyC,
                                    "Company Name",
                                    icon: Icons.business_outlined,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildTextField(
                                    licenseC,
                                    "License Number",
                                    keyboardType: TextInputType.text,
                                    icon: Icons.badge_outlined,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildTextField(
                                    reraC,
                                    "RERA Number",
                                    keyboardType: TextInputType.text,
                                    icon: Icons.confirmation_number_outlined,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildTextField(
                                    establishC,
                                    "Establishment License",
                                    keyboardType: TextInputType.text,
                                    icon: Icons.apartment_outlined,
                                  ),
                                ]),

                              ],
                            )
                                : const SizedBox.shrink(),
                          ),
                        ]),

                        const SizedBox(height: 26),

                        /// ---------- BRN INFO ----------
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: !isFreelancer
                              ? Column(
                            key: const ValueKey("brnSection"),
                            children: [
                              _buildCard([
                                _buildSectionHeader(Icons.receipt_long_outlined, "BRN Information"),
                                const SizedBox(height: 14),

                                _buildSwitch("I have a BRN", hasBRN, (v) {
                                  setState(() => hasBRN = v);
                                }),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: hasBRN
                                      ? Column(
                                    key: const ValueKey("brnDetails"),
                                    children: [
                                      const SizedBox(height: 10),
                                      _buildTextField(
                                        brnNumberC,
                                        "BRN Number",
                                        icon: Icons.confirmation_number_outlined,
                                      ),
                                      const SizedBox(height: 14),
                                      _buildDateField("Issue Date", brnIssueDate, true),
                                      const SizedBox(height: 14),
                                      _buildDateField("Expiry Date", brnExpiryDate, false),
                                      /*const SizedBox(height: 14),
                                      _buildUploadPlaceholder("Upload BRN Card Copy"),*/

                                    ],
                                  )
                                      : const SizedBox.shrink(),
                                ),
                              ]),
                            ],
                          )
                              : const SizedBox.shrink(),
                        ),



                        /// ---------- SOCIAL LINKS ----------
                        _buildCard([
                          _buildSectionHeader(Icons.language_outlined, "Social Links"),
                          const SizedBox(height: 14),

                          _buildTextField(linkedinC, "LinkedIn"),
                          const SizedBox(height: 14),
                          _buildTextField(twitterC, "Twitter"),
                          const SizedBox(height: 14),
                          _buildTextField(facebookC, "Facebook"),
                        ]),

                        /*const SizedBox(height: 26),

                        /// ---------- PRIVILEGE & UPLOAD ----------
                        _buildCard([
                          _buildSectionHeader(Icons.star_outline, "Privilege & Uploads"),
                          const SizedBox(height: 14),

                          _buildSwitch("Is Privileged Broker", isPrivileged, (v) {
                            setState(() => isPrivileged = v);
                          }),
                          const SizedBox(height: 14),
                          _buildUploadPlaceholder("Upload Profile Picture"),
                        ]),*/

                        const SizedBox(height: 40),

                        /// ---------- CREATE BUTTON ----------
                        Center(child: _buildCreateButton(MediaQuery.of(context).size.width)),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        )

    );
  }

  /// ------------------------------
  /// WIDGET HELPERS
  /// ------------------------------
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

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


  Widget _buildSwitch(String text, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        Switch(activeColor: kPrimaryColor, value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? value, bool isIssue) {
    return GestureDetector(
      onTap: () => _pickDate(isIssue),
      child: Container(
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

  Widget _buildMultiSelect(
      String label,
      List<String> options,
      List<String> selectedList,
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
                  setState(() {
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


  Widget _buildUploadPlaceholder(String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      width: double.infinity,
      decoration: BoxDecoration(
        color: kFieldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.upload_file_outlined, color: Colors.grey),
          const SizedBox(width: 10),
          Text(label,
              style:
              GoogleFonts.poppins(color: Colors.black54, fontSize: 14.5)),
        ],
      ),
    );
  }

  Widget _buildCreateButton(double width) {
    return SizedBox(
      width: width > 500 ? 400 : double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : _createBrokerProfile,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryColor, kAccentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : Text(
              "Create",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

