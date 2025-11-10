import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import 'package:http/http.dart' as http;

class ImportFromPropertyFinderScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ImportFromPropertyFinderScreen({super.key,
    required this.userData,
  });

  @override
  State<ImportFromPropertyFinderScreen> createState() => _ImportFromPropertyFinderScreenState();
}

class _ImportFromPropertyFinderScreenState extends State<ImportFromPropertyFinderScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 1;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? selectedPropertyTypeId;
  List<Map<String, dynamic>> allPropertyTypes = [];
  List<Map<String, dynamic>> filteredPropertyTypes = [];
  bool _loadingPropertyTypes = false;
  bool _isImporting = false; // 👈 ADD THIS LINE
  // --- State variables ---
  List<Map<String, dynamic>> allAmenities = [];
  List<Map<String, dynamic>> selectedAmenities = [];
  bool _loadingAmenities = false;

  // Step 3 controllers
  final TextEditingController titleC = TextEditingController();
  final TextEditingController parkingC = TextEditingController();

  final TextEditingController refNoC = TextEditingController();
  final TextEditingController locationC = TextEditingController();
  final TextEditingController sizeC = TextEditingController();
  final TextEditingController rentC = TextEditingController();
  final TextEditingController descriptionC = TextEditingController();
  final TextEditingController amenityController = TextEditingController();


  String? propertyType = "";
  String? rooms = "Studio";
  String? importedRooms = "Studio";

  String? bathrooms = "1";
  String? importedBathrooms = "1";

  String? status = "READY_TO_MOVE";

  String? furnishing = "FURNISHED";

  String lookingFor = "";
  String category = "";
  final TextEditingController propertyfinderUrlC = TextEditingController();

  Future<void> _fetchPropertyTypes() async {
    setState(() => _loadingPropertyTypes = true);

    final token = await AuthService.getToken();
    final url = Uri.parse("$baseURL/api/property-types");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'] ?? [];

        setState(() {
          allPropertyTypes = data
              .where((e) => e['isActive'] == true)
              .map<Map<String, dynamic>>((e) => {
            "id": e['id'],
            "name": e['name'],
            "category": e['category'],
          })
              .toList();

          // Initially filter based on the current category selection
          filteredPropertyTypes = allPropertyTypes
              .where((e) => e['category'].toUpperCase() == category.toUpperCase())
              .toList();
        });
      } else {
        debugPrint("⚠️ Failed to fetch property types: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching property types: $e");
    } finally {
      setState(() => _loadingPropertyTypes = false);
    }
  }

  Future<void> _submitListing() async {
    final token = await AuthService.getToken();
    final url = "$baseURL/api/properties";

    // ✅ Determine broker_id based on user role
    String? brokerId;
    final userRole = widget.userData['role'];
    if (userRole == "ADMIN") {
      brokerId = widget.userData['broker']?['id'];
    } else if (userRole == "BROKER") {
      brokerId = widget.userData['id'];
    }

    if (brokerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Broker ID not found — cannot create listing"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }


    // ✅ Build request body
    final Map<String, dynamic> body = {
      "broker_id": brokerId,
      "title": titleC.text.trim(),
      "reference_number": refNoC.text.trim(),
      "description": descriptionC.text.trim(),
      "property_type_id": selectedPropertyTypeId,
      "location_name": locationC.text,
      "category": category ?? "RESIDENTIAL",

      "transaction_type": (lookingFor == "Rent") ? "RENT" : "SALE",
      "price": rentC.text.isEmpty ? 0 : int.tryParse(rentC.text.replaceAll(',', '')) ?? 0,
      "currency": "AED",
      "rooms": (rooms == "Studio")
          ? "Studio"
          : (rooms == "5+" && importedRooms != null
          ? importedRooms
          : rooms),
      "bathrooms": (bathrooms == "5+" && importedBathrooms != null
          ? importedBathrooms
          : bathrooms),
      "parking_spaces": int.tryParse(parkingC.text) ?? 0,
      "size_sqft": int.tryParse(sizeC.text.replaceAll(',', '')) ?? 0,
      "furnished_status": furnishing ?? "UNFURNISHED",
      "status": status ?? "READY_TO_MOVE",
      "listing_status": "ACTIVE",
      "is_featured": true,
      "amenities_tag_ids": selectedAmenities.map((a) => a['id']).toList(),

    };



    print("📤 Create Listing Body => ${jsonEncode(body)}");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Listing created successfully!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        print("❌ Failed: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to create listing (${response.body})"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("⚠️ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error occurred while creating listing"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importPropertfinderData() async {
    if (propertyfinderUrlC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter a Property Finder property URL."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 20, right: 20, left: 100),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isImporting = true);
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseURL/api/properties/analyze-propertyfinder-url');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"url": propertyfinderUrlC.text.trim()}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'];

        // 🧩 Basic Info
        titleC.text = data['title']?.toString() ?? '';
        descriptionC.text = data['description']?.toString() ?? '';
        refNoC.text = data['reference_number']?.toString() ?? '';

        // 🏙 Address and Location
        locationC.text = data['address']?.toString() ??
            (data['location_full_path'] != null
                ? (data['location_full_path'] as List).join(', ')
                : '');

        // 💰 Price and Size
        rentC.text = data['price'] != null
            ? NumberFormat('#,###').format(data['price'])
            : '';
        sizeC.text = data['size_sqft'] != null
            ? data['size_sqft'].toString()
            : '';

        // 🏡 Rooms and Bathrooms
        importedRooms = data['rooms']?.toString() ?? '';
        importedBathrooms = data['bathrooms']?.toString() ?? '';

        rooms = (data['rooms'] != null &&
            double.tryParse(data['rooms'].toString()) != null &&
            double.parse(data['rooms'].toString()) > 5)
            ? "5+"
            : data['rooms']?.toString();

        bathrooms = (data['bathrooms'] != null &&
            double.tryParse(data['bathrooms'].toString()) != null &&
            double.parse(data['bathrooms'].toString()) > 5)
            ? "5+"
            : data['bathrooms']?.toString();

        parkingC.text = (data['parking_spaces'] ?? '0').toString();

        // 🛋 Furnishing and Property Type
        furnishing = data['furnished_status']?.toString() ?? '';
        propertyType = data['property_type_name']?.toString();

        // ✅ Try to auto-select property type from master list
        if (propertyType != null &&
            propertyType!.isNotEmpty &&
            allPropertyTypes.isNotEmpty) {
          final match = allPropertyTypes.firstWhere(
                (e) =>
            e['name'].toString().toLowerCase() ==
                propertyType!.toLowerCase(),
            orElse: () => {},
          );
          if (match.isNotEmpty) {
            setState(() {
              propertyType = match['name'];
              selectedPropertyTypeId = match['id'];
            });
          }
        }


        // 🧱 Category & Transaction Type
        category = data['category'] ?? '';
        lookingFor = (data['transaction_type']?.toString().toUpperCase() ==
            'SALE')
            ? 'Sale'
            : 'Rent';

        // ✅ Amenities Mapping
        final List<String> apiAmenities =
        List<String>.from(data['amenities'] ?? []);

        allAmenities = apiAmenities.map((name) {
          return {
            "id": name.toLowerCase().replaceAll(' ', '_'),
            "name": name,
            "description": null,
            "type": "AMENITY",
            "color": "#4CAF50",
          };
        }).toList();

        selectedAmenities = List<Map<String, dynamic>>.from(allAmenities);

        // 🏁 Move to next step
        _goToStep(3);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ?? "Failed to extract property details."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error importing data: $e"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isImporting = false);
    }
  }

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
    _fetchPropertyTypes(); // 👈 fetch master list

    // _fetchAmenities();
  }


  Future<void> _fetchAmenities() async {
    setState(() => _loadingAmenities = true);
    final url = Uri.parse("$baseURL/api/tags");

    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];

        setState(() {
          allAmenities = data
              .where((tag) =>
          tag['type'] == 'AMENITY' &&
              tag['isActive'] == true &&
              tag['isVerified'] == true)
              .map<Map<String, dynamic>>((tag) => {
            "id": tag['id'],
            "name": tag['name'],
            "color": tag['color'] ?? "#4CAF50",
          })
              .toList();
        });
      } else {
        debugPrint("⚠️ Failed to fetch amenities: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching amenities: $e");
    } finally {
      setState(() => _loadingAmenities = false);
    }
  }


  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _controller.forward(from: 0);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 750, // keep width limit
              ),
              child: IntrinsicHeight( // 👈 auto adjusts height to its content
                child: Container(

                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildStepIndicator(),
                      const SizedBox(height: 30),
                      Expanded(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildCurrentStep(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),)
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // 🔙 Back icon for navigating steps (not popping screen)
        if (_currentStep > 1)
          InkWell(
            onTap: () => _goToStep(_currentStep - 1),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Colors.black87,
              ),
            ),
          ),
        if (_currentStep > 1) const SizedBox(width: 12),

        // 🟩 Import icon
        Container(
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.import_export_rounded, color: kPrimaryColor, size: 24),
        ),
        const SizedBox(width: 10),

        // 🏷️ Dynamic header title
        Text(
          _currentStep == 1
              ? "Import from Property Finder"
              : _currentStep == 2
              ? "Importing Property URL"
              : "Review Imported Data",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    const double stepCircleSize = 80;
    const double stepSpacing = 135; // distance between circles

    return Center(
      child: SizedBox(
        width: (stepSpacing ) + (stepCircleSize * 3),
        height: stepCircleSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- Connecting Lines Between Circles
            Positioned(
              top: (stepCircleSize / 4) - 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Line between step 1 & 2
                  Container(
                    width: stepSpacing,
                    height: 4,
                    color: _currentStep > 1
                        ? kPrimaryColor
                        : Colors.grey.shade200,
                  ),
                  // Line between step 2 & 3
                  Container(
                    width: stepSpacing,
                    height: 4,
                    color: _currentStep > 2
                        ? kPrimaryColor
                        : Colors.grey.shade200,
                  ),
                ],
              ),
            ),

            // --- Step Circles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepCircle(1, "Select Type"),
                _buildStepCircle(2, "Import URL"),
                _buildStepCircle(3, "Review Data"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final bool isActive = _currentStep >= step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? kPrimaryColor : Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? kPrimaryColor : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildStepOne();
      case 2:
        return _buildStepTwo();
      case 3:
        return _buildStepThree();
      default:
        return Container();
    }
  }

  Widget _buildStepOne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What type of property are you importing? *",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟦 I'm Looking For Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "I'm looking to",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        _buildSegmentedButton(
                          "Rent",
                          lookingFor == "Rent",
                              () => setState(() => lookingFor = "Rent"),
                          Icons.sell_outlined,
                        ),
                        _buildSegmentedButton(
                          "Sale",
                          lookingFor == "Sale",
                              () => setState(() => lookingFor = "Sale"),
                          Icons.shopping_cart_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // 🟧 Property Category Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Property Category",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        _buildSegmentedButton(
                          "Residential",
                          category == "Residential",
                              () => setState(() {
                            category = "Residential";
                            filteredPropertyTypes = allPropertyTypes
                                .where((e) => e['category'].toUpperCase() == category.toUpperCase())
                                .toList();
                          }),

                          Icons.home_outlined,
                        ),
                        _buildSegmentedButton(
                          "Commercial",
                          category == "Commercial",
                              () => setState(() {
                            category = "Commercial";
                            filteredPropertyTypes = allPropertyTypes
                                .where((e) => e['category'].toUpperCase() == category.toUpperCase())
                                .toList();
                          }),
                          Icons.apartment_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 60),

        // ✅ Validation added here
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (lookingFor.isEmpty || category.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Please select both 'I'm looking to' and 'Property Category' before continuing.",
                            style: GoogleFonts.poppins(fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(
                      bottom: 20,   // distance from bottom
                      right: 20,    // distance from right edge
                      left: 100,    // limit from left so it doesn’t stretch full width
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }
              _goToStep(2);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "Next: Import Data",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.5,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ),

      ],
    );
  }

  Widget _buildStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: kPrimaryColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Selected: $category property for $lookingFor",
                  style: GoogleFonts.poppins(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 0),


        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // URL TextField (takes most width)
            Expanded(
              flex: 4,
              child: TextField(
                controller: propertyfinderUrlC,
                decoration: InputDecoration(
                  labelText: "Property Finder Property URL *",
                  prefixIcon: const Icon(Icons.link, color: kPrimaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 🟢 Import Data button
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _importPropertfinderData,
              icon: _isImporting
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey, // 👈 grey loader
                ),
              )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(
                _isImporting ? "Importing..." : "Import Data", // 👈 dynamic label
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isImporting
                    ? Colors.grey.shade200 // 👈 grey background while loading
                    : const Color(0xFF4CAF50),
                foregroundColor: _isImporting ? Colors.grey.shade700 : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
              ),
            ),

          ],
        ),


        const SizedBox(height: 8),

// 🧩 Helper text below field
        Text(
          "Paste the full URL of the Property Finder property listing. The system will extract basic property details automatically.",
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 12.5,
          ),
        ),

        /*const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              label: const Text("Back"),
              onPressed: () => _goToStep(1),
            ),

          ],
        ),*/
      ],
    );


  }


  Widget _buildParkingField() {
    return TextField(
      controller: parkingC,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.left, // 👈 digits aligned left
      decoration: InputDecoration(
        labelText: "Parking Spaces",
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: Container(
          margin: const EdgeInsets.only(right: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    int value = int.tryParse(parkingC.text) ?? 0;
                    value++;
                    parkingC.text = value.toString();
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    int value = int.tryParse(parkingC.text) ?? 0;
                    if (value > 0) value--;
                    parkingC.text = value.toString();
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
      onChanged: (val) {
        final parsed = int.tryParse(val);
        if (parsed == null || parsed < 0) {
          parkingC.text = "0";
          parkingC.selection = TextSelection.fromPosition(
            TextPosition(offset: parkingC.text.length),
          );
        }
      },
    );
  }

  Widget _buildStepThree() {
    final isRent = lookingFor == "Rent";
    final priceLabel = isRent ? "Annual Rent (AED)" : "Price (AED)";

    // 🧭 Status options based on selection
    final List<String> statusOptions = isRent
        ? ["READY_TO_MOVE", "AVAILABLE_FROM_NOW"]
        : ["READY_TO_MOVE", "OFF_PLAN", "RENTED"];


    status = statusOptions.first;

    // 🏠 Room & Bathroom options (dropdown)
    final List<String> roomOptions = ["Studio","1", "2", "3", "4", "5", "5+"];
    final List<String> bathOptions = ["1", "2", "3", "4", "5", "5+"];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const SizedBox(height: 10),

          // --- Row 1 ---
          Row(
            children: [
              Expanded(child: _buildTextField("Property Title", titleC)),
              const SizedBox(width: 24),
              Expanded(child: _buildTextField("Reference Number", refNoC)),
            ],
          ),
          const SizedBox(height: 20),

          // --- Row 2 ---
          Row(
            children: [
              Expanded(child: _buildTextField("Location", locationC)),
              const SizedBox(width: 24),
              Expanded(
                child: _loadingPropertyTypes
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _buildDropdown(
                  "Property Type",
                  filteredPropertyTypes.map((e) => e['name'] as String).toList(),
                  propertyType,
                      (val) {
                    setState(() {
                      propertyType = val;

                      // 🧭 Find matching ID from list
                      final match = allPropertyTypes.firstWhere(
                            (e) => e['name'] == val,
                        orElse: () => {},
                      );
                      if (match.isNotEmpty) {
                        selectedPropertyTypeId = match['id'];
                      }
                    });
                  },
                ),
              ),


            ],
          ),
          const SizedBox(height: 20),

          // --- Row 3 (Rooms & Bathrooms) ---
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  "Rooms",
                  roomOptions,
                  rooms,
                      (val) => setState(() => rooms = val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  "Bathrooms",
                  bathOptions,
                  bathrooms,
                      (val) => setState(() => bathrooms = val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildParkingField()),

            ],
          ),
          const SizedBox(height: 20),

          // --- Row 4 ---
          // --- Row 4 (Price, Status, and Size) ---
          Row(
            children: [
              // 💰 Price / Annual Rent
              Expanded(child: _buildTextField(priceLabel, rentC)),

              const SizedBox(width: 16),

              // 📏 Size in Sq Ft
              Expanded(
                child: _buildTextField("Size (sqft)", sizeC),
              ),

              const SizedBox(width: 16),

              // 🏗️ Status
              Expanded(
                child: _buildDropdown(
                  "Status",
                  statusOptions,
                  status,
                      (val) => setState(() => status = val),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- Row 5 ---
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  "Furnished Status",
                  ["FURNISHED", "UNFURNISHED", "SEMI-FURNISHED"],
                  furnishing,
                      (val) => setState(() => furnishing = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- Description ---
          _buildTextField("Property Description", descriptionC, maxLines: 7),
          const SizedBox(height: 20),

          // --- Amenities ---
          Text(
            "Amenities",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _loadingAmenities
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TypeAheadField<Map<String, dynamic>>(
                  controller: amenityController,
                  suggestionsCallback: (pattern) {
                    final lower = pattern.toLowerCase();
                    final selectedIds =
                    selectedAmenities.map((a) => a['id']).toSet();

                    return allAmenities
                        .where((tag) =>
                        tag['name']
                            .toLowerCase()
                            .contains(lower))
                        .toList();
                  },
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: "Search and add amenities...",
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    );
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      leading: Icon(Icons.local_offer_outlined,
                          color: kPrimaryColor),
                      title: Text(
                        suggestion['name'],
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        suggestion['description'] ?? '',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    );
                  },
                  onSelected: (tag) {
                    setState(() {
                      if (!selectedAmenities
                          .any((a) => a['id'] == tag['id'])) {
                        selectedAmenities.add(tag);
                      }
                      amenityController.clear();
                    });
                  },
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: selectedAmenities.map((amenity) {
                    final color = kPrimaryColor;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.95),
                            color.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(-2, -2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                              Text("Amenity: ${amenity['name']}"),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.only(
                                  bottom: 24, right: 20),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                  Colors.white.withOpacity(0.95),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                amenity['name'],
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  setState(() => selectedAmenities
                                      .removeWhere((a) =>
                                  a['id'] == amenity['id']));
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  margin:
                                  const EdgeInsets.only(left: 2),
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withOpacity(0.25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
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
            ),
          ),

          const SizedBox(height: 30),

          // --- Action Buttons ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /*TextButton.icon(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                label: const Text("Back"),
                onPressed: () => _goToStep(2),
              ),*/
              Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text("Create Listing"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _submitListing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: kPrimaryColor,
      labelStyle: GoogleFonts.poppins(
        color: selected ? Colors.white : Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildSegmentedButton(
      String label,
      bool selected,
      VoidCallback onTap,
      IconData icon,
      ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? kPrimaryColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? kPrimaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: selected ? Colors.white : Colors.grey.shade700,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,

      keyboardType: (
          label.toLowerCase().contains('price') ||
              label.toLowerCase().contains('rent')  ||
              label.toLowerCase().contains('parking')
      )
          ? TextInputType.number
          : TextInputType.text,

      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (val) {
        // 💰 Auto-format price with commas
        if (label.toLowerCase().contains('price') || label.toLowerCase().contains('rent')) {
          final plain = val.replaceAll(',', '');
          if (plain.isEmpty) return;
          final num value = num.tryParse(plain) ?? 0;
          final formatted = NumberFormat('#,###').format(value);
          controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      },
    );
  }



  Widget _buildDropdown(String label, List<String> options, String? value,
      Function(String?) onChanged) {
    return SizedBox(
      width: 450,

      child: DropdownButtonFormField<String>(
        value: options.contains(value) ? value : null, // ✅ safe check
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        items: options
            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(

          ),)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }



}
