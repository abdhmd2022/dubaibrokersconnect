import 'dart:convert';
import 'package:a2abrokerapp/pages/listings/property_details_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import 'package:flutter/animation.dart';
import '../../widgets/animated_logo_loader.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;



class ListingsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ListingsScreen({
    super.key,
    required this.userData,

  });
  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  bool isGridView = false;
  String selectedPurpose = "All";
  bool isFormValid = true;
  String selectedCategory = "All";
  List<String> propertyTypes = [];
  List<String> propertyTypeNames = []; // for dropdown display
  Map<String, String> propertyTypeMap = {}; // for id lookup
  bool isPropertyTypesLoading = false;

  String? priceError; // for inline error message
  final TextEditingController _minSizeController = TextEditingController();
  final TextEditingController _maxSizeController = TextEditingController();
  bool isBulkStatusProcessing = false;
  bool isBulkDeleteProcessing = false;
  final Set<String> selectedPropertyIds = {};
  bool selectAll = false;

  List<Map<String, dynamic>> amenitiesList = [];
  List<String> selectedAmenityNames = [];
  List<String> selectedAmenityName = [];
  bool isAmenitiesLoading = true;

  List<Map<String, dynamic>> locations = [];
  bool isLocationsLoading = true;
  String? selectedLocationId = null;
  String? selectedLocationName;

  String? sizeError;
  bool isDialogLoading = false;

  List originalListings = [];

  bool showMyListingsOnly = false;

  bool showMoreFilters = false;
  List<Map<String, dynamic>> allListings = [];
  final TextEditingController _titleSearchController = TextEditingController();
  final TextEditingController _locationSearchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  String? selectedPropertyType;
  String? selectedFurnishing;
  String? selectedStatus;
  int? minSize;
  int? maxSize;
  String? selectedRooms;

  List<Map<String, dynamic>> listings = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMessage;

  int currentPage = 1;
  int totalPages = 1;
  final int limit = 10;
  final ScrollController _scrollController = ScrollController();
  Widget highlightText(String source, String query) {
    if (query.isEmpty) {
      return Text(source, softWrap: true);
    }

    final lower = source.toLowerCase();
    final q = query.toLowerCase();

    if (!lower.contains(q)) {
      return Text(source, softWrap: true);
    }

    List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final index = lower.indexOf(q, start);
      if (index < 0) {
        spans.add(TextSpan(text: source.substring(start)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: source.substring(start, index)));
      }

      spans.add(
        TextSpan(
          text: source.substring(index, index + q.length),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      );

      start = index + q.length;
    }

    return RichText(
      text: TextSpan(
        style:  GoogleFonts.poppins(color: Colors.black, fontSize: 14),
        children: spans,
      ),
    );
  }

  @override
  void initState()  {
    super.initState();

    fetchPropertyTypes();
    fetchListings();
    _scrollController.addListener(_handleScroll);
  }

  String prettyText(String value) {
    return value
        .split('_')
        .map((word) =>
    word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleSearchController.dispose();
    _locationSearchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minSizeController.dispose();
    _maxSizeController.dispose();
    super.dispose();
  }

  Future<void> _fetchAmenities() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseURL/api/tags'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final List data = decoded['data'];

          // filter only AMENITY type and active
          final filtered = data
              .where((e) => e['type'] == 'AMENITY' && e['isActive'] == true)
              .toList();

          setState(() {
            amenitiesList = List<Map<String, dynamic>>.from(filtered);
            isAmenitiesLoading = false;
          });
        }
      } else {
        debugPrint("Failed to load amenities: ${response.body}");
        setState(() => isAmenitiesLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching amenities: $e");
      setState(() => isAmenitiesLoading = false);
    }
  }

  String buildDisplayPath(Map<String, String?> h) {
    final parts = [
      h['emirate'],
      h['neighbourhood'],
      h['cluster'],
      h['building'],
      h['buildingLvl1'],
      h['buildingLvl2'],
    ];

    // Remove null and empty items
    final filtered = parts.where((e) => e != null && e.trim().isNotEmpty).toList();

    return filtered.join(" → ");
  }

  Map<String, String?> extractHierarchy(String fullPath) {
    final parts = fullPath.split('/').map((e) => e.trim()).toList();

    String? emirate;
    String? neighbourhood;
    String? cluster;
    String? building;
    String? buildingLvl1;
    String? buildingLvl2;

    // assign based on count
    if (parts.isNotEmpty) emirate = parts[0];
    if (parts.length > 1) neighbourhood = parts[1];
    if (parts.length > 2) cluster = parts[2];
    if (parts.length > 3) building = parts[3];
    if (parts.length > 4) buildingLvl1 = parts[4];
    if (parts.length > 5) buildingLvl2 = parts[5];

    return {
      "emirate": emirate,
      "neighbourhood": neighbourhood,
      "cluster": cluster,
      "building": building,
      "buildingLvl1": buildingLvl1,
      "buildingLvl2": buildingLvl2,
    };
  }


  Future<void> _fetchLocations() async {
    try {
      setState(() => isLocationsLoading = true);
      final token = await AuthService.getToken();

      // STEP 1: First lightweight request to get pagination.total
      final page1Res = await http.get(
        Uri.parse('$baseURL/api/locations?limit=1'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final decoded1 = jsonDecode(page1Res.body);
      final pagination = decoded1["pagination"];
      final int total = pagination["total"]; // ⭐ REAL TOTAL FROM API

      print("📌 TOTAL FROM API → $total");

      // STEP 2: Fetch ALL RECORDS in ONE API CALL
      final fullRes = await http.get(
        Uri.parse('$baseURL/api/locations?limit=$total'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final decodedFull = jsonDecode(fullRes.body);
      final List data = decodedFull['data'] ?? [];

      print("🔥 FULL LOCATIONS LOADED → ${data.length}");

      // MAP FINAL OUTPUT
      setState(() {
        locations = data.map<Map<String, dynamic>>((loc) {
          final hierarchy = extractHierarchy(loc['fullPath'] ?? "");
          final displayPath = buildDisplayPath(hierarchy);

          return {
            "id": loc['id'],
            "name": loc['name'],
            "level": loc['level'],
            "fullPath": loc['fullPath'],

            "emirate": hierarchy['emirate'],
            "neighbourhood": hierarchy['neighbourhood'],
            "cluster": hierarchy['cluster'],
            "building": hierarchy['building'],
            "buildingLvl1": hierarchy['buildingLvl1'],
            "buildingLvl2": hierarchy['buildingLvl2'],

            "displayPath": displayPath,
          };
        }).toList();

        isLocationsLoading = false;
      });

    } catch (e) {
      debugPrint("❌ Error fetching locations: $e");
      setState(() => isLocationsLoading = false);
    }
  }

  void _validateSizeFields() {
    final min = double.tryParse(_minSizeController.text.trim());
    final max = double.tryParse(_maxSizeController.text.trim());

    if (min != null && max != null && max < min) {
      sizeError = "Max size must be greater than Min size";
    } else {
      sizeError = null;
    }

    _updateFormValidity();
  }

  void _updateFormValidity() {
    setState(() {
      isFormValid = (priceError == null && sizeError == null);
    });
  }

  /// 🔹 Auto-load more when scrolled near bottom
  void _handleScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300 &&
        !isLoadingMore &&
        currentPage < totalPages) {
      fetchMoreListings();
    }
  }

  Future<String?> _createProperty(Map<String, dynamic> data) async {

    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('$baseURL/api/properties'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        /*ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Property created successfully')),
        );*/

        fetchListings();
        // return the property ID
        return decoded['data']?['id'] ?? decoded['id'];


      } else {
        debugPrint('❌ Failed (${response.statusCode}): ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${response.statusCode}: ${decoded["message"] ?? "Failed"}')),
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error creating property: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
      return null;
    }

  }

  Widget _buildAmenitiesTypeAhead(Function(void Function()) setDialogState) {

    final TextEditingController controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Title + Clear All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Amenities",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              if (selectedAmenityName.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() => selectedAmenityName.clear());
                  },
                  child: Text(
                    "Clear All",
                    style: GoogleFonts.poppins(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          TypeAheadField<Map<String, dynamic>>(
            suggestionsCallback: (pattern) async {
              if (pattern.isEmpty) return amenitiesList;
              return amenitiesList
                  .where((a) => (a['name'] ?? '')
                  .toLowerCase()
                  .contains(pattern.toLowerCase()))
                  .toList();
            },
            builder: (context, textEditingController, focusNode) {
              controller.value = textEditingController.value;
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: "Search and select amenities...",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 13.5,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: kPrimaryColor, width: 1.5),
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
              );
            },
            itemBuilder: (context, suggestion) {
              final name = suggestion['name'] ?? 'Unknown';
              final isSelected = selectedAmenityName.contains(name);
              return ListTile(
                dense: true,
                title: Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: isSelected ? kPrimaryColor : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                trailing: Icon(
                  isSelected ? Icons.check_circle : Icons.add_circle_outline,
                  color: isSelected ? kPrimaryColor : Colors.grey,
                ),
              );
            },

            onSelected: (suggestion) {
              final name = suggestion['name'];
              setDialogState(() {
                if (selectedAmenityName.contains(name)) {
                  selectedAmenityName.remove(name);
                } else {
                  selectedAmenityName.add(name);
                }
              });
            },
            decorationBuilder: (context, child) => Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              child: child,
            ),
            hideOnEmpty: true,
            hideOnLoading: true,
          ),

          const SizedBox(height: 12),

          // 🔹 Scrollable Chips with Smooth UI
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: selectedAmenityName.isEmpty
                ? Text(
              "No amenities selected",
              key: const ValueKey('no_amenities'),
              style: GoogleFonts.poppins(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            )
                : ConstrainedBox(
              key: const ValueKey('amenities_wrap'),
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedAmenityName.map((amenity) {
                    return Chip(
                      backgroundColor: kPrimaryColor.withOpacity(0.12),
                      side:
                      BorderSide(color: kPrimaryColor.withOpacity(0.3)),
                      label: Text(
                        amenity,
                        style: GoogleFonts.poppins(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      deleteIcon: const Icon(Icons.close_rounded,
                          size: 16, color: Colors.black54),
                      onDeleted: () {
                        setState(() => selectedAmenityName.remove(amenity));
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildLocationPath(Map<String, dynamic> location) {
    final List<String> path = ["United Arab Emirates"]; // always base country

    // if location has a parent (e.g., Dubai → Marina)
    if (location['parent'] != null && location['parent']['name'] != null) {
      path.add(location['parent']['name']);
    }

    // add the area/city name itself
    if (location['name'] != null) {
      path.add(location['name']);
    }

    return path;
  }

  Future<void> _showCreatePropertyDialog(BuildContext context) async {
    setState(() => isDialogLoading = false
    );
    setState(() => selectedLocationId = null
    );
    setState(() => selectedLocationName = null
    );


    final _formKey = GlobalKey<FormState>();
    List<String> locationFullPath = [];
    bool isLoading = false;
    List<PlatformFile> selectedImages = [];


    final titleC = TextEditingController();
    final refC = TextEditingController(text: "");
    final priceC = TextEditingController();
    final sizeC = TextEditingController();
    final descC = TextEditingController();
    final addressC = TextEditingController();
    final buildingC = TextEditingController();
    final developerC = TextEditingController(text: "Emaar Properties");
    final roomsC = TextEditingController();
    final bathsC = TextEditingController();
    final parkingC = TextEditingController();
    final TextEditingController locationSearchController = TextEditingController();

    String? category ;
    String? transactionType ;
    String? furnishing ;
    String? status ;
    bool isFeatured = false;
    String? selectedPropertyType;
    selectedAmenityName = []; // ✅ ensures no amenity is selected by default

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.transparent,
            child: Center(
              child: ConstrainedBox(constraints: const BoxConstraints(
                maxWidth: 700, // ✅ limits width for desktop/web
                maxHeight: 720, // ✅ keeps popup compact

              ),

              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// ───────────── HEADER ─────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [kPrimaryColor, kAccentColor],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.home_work_rounded,
                                        color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Create Property Listing",
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.black54, size: 24),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),


                          Divider(color: Colors.grey.shade300, thickness: 1),

                          /// ───────────── CATEGORY & TRANSACTION TYPE (SEGMENTED INSIDE CARD) ─────────────
                          Container(
                            margin: const EdgeInsets.only(top: 10, bottom: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade200, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Listing Details",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                /// 🔹 CATEGORY + TRANSACTION TYPE
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Category",
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          _buildToggleChips(
                                            ["RESIDENTIAL", "COMMERCIAL"],
                                            setDialogState: setDialogState, // 👈 pass this when inside dialog

                                            category ?? "",
                                                (val) => setDialogState(() => category = val),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Transaction Type",
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          _buildToggleChips(
                                            ["SALE", "RENT"],
                                            transactionType ?? "",
                                                (val) {
                                              setDialogState(() {
                                                transactionType = val;

                                                // ✅ define new allowed status options
                                                final newStatusOptions = transactionType == "RENT"
                                                    ? ["READY_TO_MOVE", "AVAILABLE_IN_FUTURE"]
                                                    : ["READY_TO_MOVE", "OFF_PLAN", "RENTED"];

                                                // ✅ if current status not valid anymore → reset it
                                                if (status == null || !newStatusOptions.contains(status)) {
                                                  status = newStatusOptions.first;
                                                }
                                              });
                                            },
                                            setDialogState: setDialogState,
                                          ),

                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                /// 🔹 FURNISH + STATUS (dynamic + auto-select + disable logic)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdownField(
                                        "Furnish Status",
                                        ["FURNISHED", "SEMI_FURNISHED", "UNFURNISHED"],
                                        furnishing,
                                            (v) => setState(() => furnishing = v!),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: IgnorePointer(
                                        ignoring: transactionType == null || transactionType!.isEmpty,
                                        child: Opacity(
                                          opacity: transactionType == null || transactionType!.isEmpty
                                              ? 0.5 // 🔒 faded when disabled
                                              : 1,
                                          child: _buildDropdownField(
                                            "Status",
                                            transactionType == "RENT"
                                                ? ["READY_TO_MOVE", "AVAILABLE_IN_FUTURE"]
                                                : ["READY_TO_MOVE", "OFF_PLAN", "RENTED"],
                                            status,
                                                (v) => setDialogState(() => status = v!),
                                          ),

                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          /// ───────────── BASIC INFO ─────────────
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Basic Information",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                _buildDialogTextField("Title", titleC, Icons.home_rounded),
                                const SizedBox(height: 10),

                                /// 🔹 Reference Number + Property Type side by side
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDialogTextField(
                                        "Reference Number",
                                        refC,
                                        Icons.tag_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: isPropertyTypesLoading
                                          ? const Center(child: CircularProgressIndicator())
                                          :_buildCompactDropdown(
                                        title: "Property Type",
                                        value: selectedPropertyType,
                                        items: propertyTypeNames,
                                        onChanged: (val) =>
                                            setState(() => selectedPropertyType = val),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                /// 🔹 Description below the row
                                _buildDialogTextField(
                                  "Description", descC, Icons.description_outlined,
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),



                          const SizedBox(height: 18),

                          /// ───────────── PRICING & SIZE ─────────────
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pricing & Area",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDialogTextField(
                                        "Price (AED)",
                                        priceC,
                                        Icons.currency_exchange_rounded,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDialogTextField(
                                        "Size (sqft)",
                                        sizeC,
                                        Icons.square_foot_rounded,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [ThousandsSeparatorInputFormatter()],

                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Property Details",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDialogTextField(
                                        "Rooms",
                                        roomsC,
                                        Icons.king_bed_rounded,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [ThousandsSeparatorInputFormatter()],

                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDialogTextField(
                                        "Bathrooms",
                                        bathsC,
                                        Icons.bathtub_rounded,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [ThousandsSeparatorInputFormatter()],

                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDialogTextField(
                                        "Parking Spaces",
                                        parkingC,
                                        Icons.local_parking_rounded,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [ThousandsSeparatorInputFormatter()],

                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                              "Property Location",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),

                                isLocationsLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : InkWell(
                                  onTap: () async {
                                    final selected = await showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (ctx) {
                                        return Dialog(
                                          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                                          backgroundColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          child: Center(
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 700,   // 👈 SAME WIDTH
                                                maxHeight: 720,  // 👈 SAME HEIGHT
                                              ),
                                              child: LocationSearchDialog(
                                                locations: locations,
                                                preselectedId: selectedLocationId,  // 🔥 current selected

                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );


                                    if (selected != null) {
                                      final full = selected['displayPath'] ?? "";
                                      final last = full.split(" → ").last; // ⭐ correct separator

                                      setDialogState(() {
                                        selectedLocationId = selected['id'];
                                        selectedLocationName = last;      // 👈 only last level in main dialog
                                      });

                                    }

                                  },

                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade400),
                                      color: Colors.white,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            selectedLocationName ?? "Select Location",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: selectedLocationName == null ? Colors.grey : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.search, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                )

                              ],
                            ),
                          ),

                          SizedBox(height: 10,),

                          if (amenitiesList.isNotEmpty) ...[


                            isAmenitiesLoading
                                ? const Center(child: CircularProgressIndicator())
                                : _buildAmenitiesTypeAhead(setDialogState),
                          ],

                          /*SizedBox(height: 20,),
                          /// ───────────── PROPERTY IMAGES ─────────────
                          Text(
                            "Property Images",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),*/
                         /* const SizedBox(height: 10),

                          Row(
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.upload_rounded, color: Colors.white),
                                label: Text(
                                  "Upload Images",
                                  style: GoogleFonts.poppins(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  final result = await FilePicker.platform.pickFiles(
                                    allowMultiple: true,
                                    type: FileType.image,
                                  );
                                  if (result != null) {
                                    setState(() {
                                      selectedImages = result.files;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "${selectedImages.length} selected",
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (selectedImages.isNotEmpty)
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: selectedImages.map((img) {
                                return Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(
                                        img.bytes!,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedImages.remove(img);
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),

                          const SizedBox(height: 25),
*/
                          const SizedBox(height: 25),

                          /// ───────────── SUBMIT BUTTON ─────────────
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() => isLoading = true);

                                  if (selectedLocationId == null || selectedLocationId!.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please select a valid Location')),
                                    );
                                    setState(() => isLoading = false);
                                    return;
                                  }

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
                                  final selectedTypeId =
                                      propertyTypeMap[selectedPropertyType] ??
                                          "";

                                  final payload = {
                                    "title": titleC.text.trim(),
                                    "reference_number": refC.text.trim(),
                                    "description": descC.text.trim(),
                                    "property_type_id": selectedTypeId,
                                    "location_id": selectedLocationId ?? "",
                                    "broker_id" : brokerId,
                                    "address": selectedLocationName,
                                    "building_name": buildingC.text.trim(),
                                    "master_project_name": "",
                                    "master_developer": developerC.text.trim(),
                                    "category": category ?? "",

                                    "transaction_type": transactionType ?? "",
                                    "price": double.tryParse(priceC.text.replaceAll(',', '')) ?? 0.0,
                                    "currency": "AED",
                                    "rooms": int.tryParse(roomsC.text.replaceAll(',', '')) ?? 0,
                                    "bathrooms": int.tryParse(bathsC.text.replaceAll(',', '')) ?? 0,
                                    "parking_spaces": int.tryParse(parkingC.text.replaceAll(',', '')) ?? 0,
                                    "size_sqft": double.tryParse(sizeC.text.replaceAll(',', '')) ?? 0.0,
                                    "furnished_status": furnishing ?? "",
                                    "status": status ?? "",
                                    //"maintenance_fee": 8500,
                                    "listing_status": "ACTIVE",
                                    "is_featured": false,
                                    "amenities_tag_ids": selectedAmenityName,
                                    "location_full_path": locationFullPath,

                                  };

                                  await _createProperty(payload);
                                  Navigator.pop(context);
                                }
                              },

                              icon: const Icon(Icons.cloud_upload_rounded,
                                  color: Colors.white),
                              label: Text(
                                isLoading ? "Creating..." : "Create Listing",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 26, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                                shadowColor: kPrimaryColor.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),


              )
            ),

          );
        });
      },
    );
  }

  Widget _buildDropdownField(
      String label,
      List<String> items,
      String? selected,
      ValueChanged<String?> onChanged,
      ) {
    return DropdownButtonFormField<String>(
      value: selected != null && items.contains(selected) ? selected : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade700,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

        /// ✅ Always visible border, clean rounded
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey.shade400,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: kPrimaryColor,
            width: 1.3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(
        value: item,
        child: Text(
          prettyText(item),
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> fetchPropertyTypes() async {
    try {
      setState(() => isPropertyTypesLoading = true);

      final token = await AuthService.getToken();
      final url = Uri.parse('$baseURL/api/property-types');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final types = data['data'] as List;

          setState(() {
            propertyTypeNames = types.map((e) => e['name'].toString()).toList();

            propertyTypeMap = {
              for (var e in types) e['name'].toString(): e['id'].toString(),
            };
          });
        }
      } else {
        debugPrint('Failed to load property types: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching property types: $e');
    } finally {
      setState(() => isPropertyTypesLoading = false);
    }
  }

  /// 🔹 Fetch first page (initial or filters)
  Future<void> fetchListings({Map<String, dynamic>? filters}) async {
    setState(() {
      listings.clear();
      allListings.clear();
      isLoading = true;
      errorMessage = null;
      currentPage = 1;
      totalPages = 1;
      listings.clear();
    });
    await _fetchPage(page: 1, filters: filters);
    setState(() => isLoading = false);
  }

  /// 🔹 Fetch next page (pagination)
  Future<void> fetchMoreListings() async {
    if (currentPage >= totalPages) return;

    setState(() => isLoadingMore = true);
    await _fetchPage(page: currentPage + 1);
    setState(() => isLoadingMore = false);
  }

  bool get isFilterApplied {
    return selectedPurpose != "All" ||
        selectedCategory != "All" ||
        selectedPropertyType != null ||
        selectedFurnishing != null ||
        selectedStatus != null ||
        selectedRooms != null ||
        _titleSearchController.text.trim().isNotEmpty ||
        _locationSearchController.text.trim().isNotEmpty ||
        _minPriceController.text.trim().isNotEmpty ||
        _maxPriceController.text.trim().isNotEmpty ||
        _minSizeController.text.trim().isNotEmpty ||
        _maxSizeController.text.trim().isNotEmpty;
  }

  /// 🔹 Core API call for a specific page
  Future<void> _fetchPage({required int page, Map<String, dynamic>? filters}) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('$baseURL/api/properties?page=$page&limit=$limit');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('data -> $data');
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> fetchedListings = data['data'];
          fetchedListings.sort((a, b) {
            final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1900);
            final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1900);
            return dateB.compareTo(dateA); // newest first
          });
          setState(() {

            final parsed = fetchedListings.map<Map<String, dynamic>>((item) {
              final rawLocation = item['location'];

              // ✅ Always make sure location is a Map
              Map<String, dynamic> safeLocation;
              if (rawLocation is Map<String, dynamic>) {
                safeLocation = rawLocation;
              } else if (rawLocation is String) {
                safeLocation = {
                  'name': rawLocation,
                  'completeAddress': rawLocation,
                };
              } else {
                final fallback = item['address'] ?? 'Unknown';
                safeLocation = {
                  'name': fallback,
                  'completeAddress': fallback,
                };
              }
              return {
                'id': item['id'],
                'title': item['title'] ?? 'N/A',
                'referenceNumber': item['referenceNumber'] ?? '-',
                'price': item['price']?.toString() ?? '0',
                'currency': item['currency'] ?? 'AED',
                'amenitiesTagIds' : item['amenitiesTagIds'],
                'transactionType': item['transactionType'] ?? 'Unknown',
                'description': item['description'] ?? '',
                'rooms': item['rooms'] ?? '0',
                'bathrooms': item['bathrooms'] ?? '0',
                'parkingSpaces': item['parkingSpaces'] ?? '0',
                'unit': item['transactionType'] == 'RENT' ? '/yr' : '',
                'location': safeLocation,
                'category': item['category'] ?? 'Residential',

                'sizeSqft': '${item['sizeSqft'] ?? '0'}',
                'propertyType': item['propertyType'] ?? 'Property',
                'listingStatus' : item['listingStatus'] ?? 'Inactive',
                'status': item['status'] ?? 'Unknown',
                'furnishedStatus': item['furnishedStatus'] ?? '',
                'broker': item['broker'] ?? 'N/A',
                'rating': item['broker']?['rating'] ?? 'N/A',
                'image': (item['images'] != null && item['images'].isNotEmpty)
                    ? item['images'][0]
                    : null,
              };
            }).toList();

            final String? currentBrokerId = widget.userData['role'] == 'ADMIN'
                ? null
                : widget.userData['broker']?['id'];

            final filtered = parsed.where((item) {
              final brokerData = item['broker'];
              final brokerId = (brokerData is Map && brokerData['id'] != null)
                  ? brokerData['id']
                  : item['brokerId'];

              final bool isOwner = currentBrokerId == null || brokerId == currentBrokerId;

              if (isOwner) {
                // show EVERYTHING for current broker
                return true;
              }

              // show ONLY ACTIVE listings of other brokers
              return item['listingStatus'] == 'ACTIVE';
            }).toList();


            allListings.addAll(filtered);
            listings = List.from(allListings);



            currentPage = data['pagination']?['page'] ?? page;
            totalPages = data['pagination']?['totalPages'] ?? 1;
          });
        } else {
          setState(() => errorMessage = data['message'] ?? 'No properties found.');
        }
      } else {
        setState(() =>
        errorMessage = 'Failed to load properties (Code: ${response.statusCode})');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error fetching properties: $e');
    }
  }

  Future<void> _togglePropertyStatus(
      String propertyId,
      String currentStatus, {
        bool askConfirmation = true,
        bool refreshAfterAll = true,
      }) async {
    final newStatus = currentStatus == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';

    bool confirm = true;
    if (askConfirmation) {
      confirm = await showDialog<bool>(
        context: context,
        builder: (context) => _buildStatusChangeDialog(newStatus),
      ) ??
          false;
    }

    if (!confirm) return;

    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('$baseURL/api/properties/$propertyId');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'listingStatus': newStatus}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && refreshAfterAll) {
          await fetchListings();
        }
      }
    } catch (e) {
      debugPrint('Error toggling status: $e');
    }
  }

  Widget _buildStatusChangeDialog(String newStatus) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 100, vertical: 24), // 👈 keeps dialog compact
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380), // 👈 limit width
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.help_outline_rounded,
                    color: kPrimaryColor, size: 36),
              ),
              const SizedBox(height: 18),
              Text(
                "Change Listing Status?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Do you want to change this listing status to $newStatus?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                    label: const Text("Cancel"),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.white, size: 18),
                    label: const Text("Yes, Change"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmBulkStatusChange() async {
    if (selectedPropertyIds.isEmpty) return;

    final confirm = await _showConfirmationDialog(
      "Change Status",
      "Do you want to toggle the status of ${selectedPropertyIds.length} selected properties?",
    );
    if (confirm != true) return;

    setState(() => isBulkStatusProcessing = true);

    try {
      for (final id in selectedPropertyIds) {
        final property = listings.firstWhere((e) => e['id'] == id);
        await _togglePropertyStatus(
          id,
          property['listingStatus'],
          askConfirmation: false,
          refreshAfterAll: false,
        );
      }

      selectedPropertyIds.clear();
      selectAll = false;
      await fetchListings();
    } finally {
      setState(() => isBulkStatusProcessing = false);
    }
  }

  Future<void> _confirmBulkDelete() async {
    if (selectedPropertyIds.isEmpty) return;

    final confirm = await _showConfirmationDialog(
      "Delete Properties",
      "Are you sure you want to delete ${selectedPropertyIds.length} selected properties?",
    );
    if (confirm != true) return;

    setState(() => isBulkDeleteProcessing = true);

    try {
      final token = await AuthService.getToken();

      for (final id in selectedPropertyIds) {
        final url = Uri.parse('$baseURL/api/properties/$id');
        await http.delete(url, headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        });
      }

      selectedPropertyIds.clear();
      selectAll = false;
      await fetchListings();
    } finally {
      setState(() => isBulkDeleteProcessing = false);
    }
  }

  Future<bool?> _showConfirmationDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 100, vertical: 24), // 👈 keeps it compact
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 380, // 👈 fixed width for compact look
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 42),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text("Cancel",
                          style: GoogleFonts.poppins(color: Colors.black87)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                      ),
                      child: const Text("Confirm"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewPropertyDetails(Map<String, dynamic> e) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailsScreen(propertyData: e),
      ),
    );
  }

  /// 🔹 Apply Filters
  void _applyFilters() {
    setState(() {
      final titleQuery = _titleSearchController.text.trim().toLowerCase();
      final locationQuery = _locationSearchController.text.trim().toLowerCase();
      final minPrice = double.tryParse(_minPriceController.text) ?? 0;
      final maxPrice = double.tryParse(_maxPriceController.text) ?? double.infinity;

      listings = allListings.where((e) {
        final purposeOk = selectedPurpose == "All" ||
            e['transactionType']?.toString().toLowerCase() ==
                selectedPurpose.toLowerCase();

        final categoryOk = selectedCategory == "All" ||
            e['category']?.toString().toLowerCase() ==
                selectedCategory.toLowerCase();

        final typeOk = selectedPropertyType == null ||
            e['propertyType']?['name'].toString().toLowerCase() ==
                selectedPropertyType!.toLowerCase();

        final furnishingOk = selectedFurnishing == null ||
            e['furnishedStatus']
                ?.toString()
                .toLowerCase()
                .contains(selectedFurnishing!.toLowerCase()) ==
                true;

        final statusOk = selectedStatus == null ||
            e['status']
                ?.toString()
                .toLowerCase()
                .contains(selectedStatus!.toLowerCase()) ==
                true;

        // 🧩 Convert size string like "1200 sqft" into numeric value
        final sizeValue = double.tryParse(
            e['sizeSqft']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0') ??
            0;
        final sizeOk = (minSize == null || sizeValue >= minSize!) &&
            (maxSize == null || sizeValue <= maxSize!);

        // 🏠 Room filtering logic
        final roomsOk = selectedRooms == null ||
            (selectedRooms == "Studio" &&
                e['rooms'].toString().toLowerCase().contains("studio")) ||
            (selectedRooms == "4+" &&
                int.tryParse(e['rooms'].toString()) != null &&
                int.parse(e['rooms'].toString()) >= 4) ||
            (selectedRooms != "Studio" &&
                selectedRooms != "4+" &&
                e['rooms'].toString() == selectedRooms);

        // 🔍 Text-based search
        final searchOk = titleQuery.isEmpty ||
            e['title']?.toString().toLowerCase().contains(titleQuery) == true ||
            e['referenceNumber']?.toString().toLowerCase().contains(titleQuery) == true ||
            e['location']?['completeAddress'].toString().toLowerCase().contains(titleQuery) == true ||
            e['broker']?['displayName'].toString().toLowerCase().contains(titleQuery) == true;

        // 📍 Location search
        final locationOk = locationQuery.isEmpty ||
            e['location']?['completeAddress'].toString().toLowerCase().contains(locationQuery) ==
                true;

        // 💰 Price filtering
        final price = double.tryParse(e['price']?.toString() ?? '0') ?? 0;
        final priceOk = price >= minPrice && price <= maxPrice;

        return purposeOk &&
            categoryOk &&
            typeOk &&
            furnishingOk &&
            statusOk &&
            sizeOk &&
            roomsOk &&
            searchOk &&
            locationOk &&
            priceOk;
      }).toList();
    });

    print("✅ Filtered ${listings.length} / ${allListings.length}");
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isApproved = widget.userData['broker']['approvalStatus'] == "APPROVED";
    final String? currentBrokerId = widget.userData['role'] == 'ADMIN'
        ? null
        : widget.userData['broker']?['id'];


    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ---------- HEADER ----------

        Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 12),
              child:

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 🔹 Left: Screen Title
                  Text(
                    "All Property Listings",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  // 🔹 Right: Create Listing Button
                  if(isApproved)
                  ElevatedButton.icon(
                    onPressed: isDialogLoading
                        ? null // disable button while loading
                        : () async {
                      setState(() => isDialogLoading = true);

                      try {
                        // ✅ Fetch locations & amenities BEFORE showing dialog
                        await _fetchLocations();
                        await _fetchAmenities();

                        // ✅ Now open dialog once everything is ready
                        if (context.mounted) {
                          await _showCreatePropertyDialog(context);
                          setState(() => isDialogLoading = false);
                        }
                      } catch (e) {
                        debugPrint("Error preloading data: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Failed to load data")),
                        );
                      }finally {
                        // ✅ Reset loading state when done or if failed
                        setState(() => isDialogLoading = false);
                      }
                    },
                    icon: isDialogLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                    label: Text(
                      isDialogLoading ? "Loading..." : "Create Listing",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),

                ],
              ),


            ),

            Text(
              "Browse properties from all brokers",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),

          const SizedBox(height: 30),

            /// ---------- FILTER PANEL ----------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// --- PURPOSE + CATEGORY TOGGLES ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ----------- I’m looking to -----------
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kPrimaryColor.withOpacity(0.1),),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "I’m looking to",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildToggleChips(
                                ["All", "Rent", "Sale"],
                                selectedPurpose,
                                    (val) => setState(() => selectedPurpose = val),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),

                      /// ----------- Property Category -----------
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Property Category",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildToggleChips(
                                ["All", "Residential", "Commercial"],
                                selectedCategory,
                                    (val) => setState(() => selectedCategory = val),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  /// --- VIEW + SEARCH + FILTERS ---
                  /// --- VIEW + SEARCH + FILTERS ---
                  Text("View & Filters",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey[700])),
                  const SizedBox(height: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      /// 🔹 Top filter row (view + basic filters)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _viewModeToggle(),
                          _searchField("Search by Title, Ref, Location...", _titleSearchController),
                          _searchField("Search for locations...", _locationSearchController),
                          _priceField("Min Price (AED)", _minPriceController, isMin: true),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _priceField("Max Price (AED)", _maxPriceController, isMin: false),

                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => showMoreFilters = !showMoreFilters),
                            icon: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: const Icon(Icons.filter_alt_outlined,
                                  color: Colors.white, size: 18),
                            ),
                            label: Text(
                              showMoreFilters ? "Hide Filters" : "More Filters",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding:
                              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),

                      /// 🔹 Expandable “More Filters” section
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(height: 1, color: Color(0xFFE0E0E0)),
                              const SizedBox(height: 18),
                              Wrap(
                                runSpacing: 14,
                                spacing: 16,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  isPropertyTypesLoading
                                      ? SizedBox(
                                    width: 180,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,

                                          child: CircularProgressIndicator(),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Loading...",
                                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  )
                                      : _buildCompactDropdown(
                                    title: "Property Type",
                                    value: selectedPropertyType,   // stores property name (e.g. "Apartment")
                                    items: propertyTypeNames,      // list of strings
                                    onChanged: (val) => setState(() => selectedPropertyType = val),
                                  ),



                                  _buildCompactDropdown(
                                    title: "No. of Rooms",
                                    value: selectedRooms,
                                    items: ["Studio", "1", "2", "3", "4+", "Penthouse"],
                                    onChanged: (val) {
                                      setState(() => selectedRooms = val);
                                    },
                                  ),
                                  _buildCompactDropdown(
                                    title: "Furnishing",
                                    value: selectedFurnishing,
                                    items: ["Furnished", "Semi-Furnished", "Unfurnished"],
                                    onChanged: (val) {
                                      setState(() => selectedFurnishing = val);
                                    },
                                  ),
                                  _buildCompactDropdown(
                                    title: "Status",
                                    value: selectedStatus,
                                    items: ["Ready_to_Move", "Off-Plan", "Rented", "Available_in_Future"],
                                    onChanged: (val) {
                                      setState(() => selectedStatus = val);
                                    },
                                  ),
                                  _sizeField("Min Size (sqft)", _minSizeController, isMin: true),

                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _sizeField("Max Size (sqft)", _maxSizeController, isMin: false),


                                    ],
                                  ),


                                ],
                              ),
                            ],
                          ),
                        ),
                        crossFadeState: showMoreFilters
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),

                      const SizedBox(height: 24),

                      /// 🔹 Always visible Apply + Reset Buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    /// 🔹 Reset simple filters
                                    selectedPurpose = "All";
                                    selectedCategory = "All";

                                    /// 🔹 Reset dropdown filters
                                    selectedPropertyType = null;
                                    selectedFurnishing = null;
                                    selectedStatus = null;
                                    selectedRooms = null;

                                    /// 🔹 Reset text fields & controllers
                                    _minPriceController.clear();
                                    _maxPriceController.clear();
                                    _minSizeController.clear();
                                    _maxSizeController.clear();
                                    _titleSearchController.clear();
                                    _locationSearchController.clear();

                                    /// 🔹 Reset values & validation states
                                    minSize = null;
                                    maxSize = null;

                                    priceError = null;
                                    sizeError = null;
                                    isFormValid = true;

                                    /// 🔹 Collapse more filters
                                    showMoreFilters = false;

                                    /// 🔹 Restore all listings
                                    listings = List.from(allListings);
                                  });
                                },
                                icon: const Icon(Icons.refresh, color: Colors.black54),
                                label: Text(
                                  "Reset Filters",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: isFormValid ? _applyFilters : null, // disable when invalid
                                icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                label: Text(
                                  "Apply",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFormValid ? kPrimaryColor : Colors.grey.shade400,
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),



                            ],
                          ),
                          if (priceError != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.redAccent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      priceError!,
                                      style: GoogleFonts.poppins(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            height: 22,
                            child: AnimatedOpacity(
                              opacity: sizeError != null ? 1 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4, top: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        sizeError ?? "",
                                        style: GoogleFonts.poppins(
                                          color: Colors.redAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        ],
                      )

                    ],
                  ),

                ],
              ),
            ),

            const SizedBox(height: 30),


            if (listings.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 🔘 Select All Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: selectAll,
                          activeColor: kPrimaryColor,
                          onChanged: (checked) {
                            setState(() {
                              selectAll = checked ?? false;
                              if (selectAll) {
                                selectedPropertyIds.clear();
                                for (final e in listings) {
                                  final brokerData = e['broker'];
                                  final brokerId = (brokerData is Map && brokerData['id'] != null)
                                      ? brokerData['id']
                                      : e['brokerId'];
                                  final bool isOwner =
                                      currentBrokerId == null || brokerId == currentBrokerId;
                                  if (isOwner) {
                                    selectedPropertyIds.add(e['id'].toString());
                                  }
                                }
                              } else {
                                selectedPropertyIds.clear();
                              }
                            });
                          },
                        ),

                        Text(
                          "Select All",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // ✅ Show "x out of y selected"
                        Text(
                          "${selectedPropertyIds.length} out of ${listings.length} selected",
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),



                    // 🔘 Action Buttons
                    Row(
                      children: [
                        if (isBulkStatusProcessing)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: isBulkStatusProcessing || selectedPropertyIds.isEmpty
                              ? null
                              : () => _confirmBulkStatusChange(),
                          icon: const Icon(Icons.sync_alt_rounded, size: 18),
                          label: Text(
                            isBulkStatusProcessing ? "Updating..." : "Change Status",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (isBulkDeleteProcessing)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(),
                            ),
                          ),

                        ElevatedButton.icon(
                          onPressed: isBulkDeleteProcessing || selectedPropertyIds.isEmpty
                              ? null
                              : () => _confirmBulkDelete(),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: Text(
                            isBulkDeleteProcessing ? "Deleting..." : "Delete",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],

                    ),



                  ],
                ),
              ),

            /// ---------- LISTINGS ----------
            if (isLoading)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    AnimatedLogoLoader(assetPath: 'assets/collabrix_logo.png'),
                  ],
                ),
              )


            else if (errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(errorMessage!,
                      style: GoogleFonts.poppins(
                          color: Colors.redAccent, fontSize: 14)),
                ),
              )
            else if (listings.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('No listings found.',
                        style: GoogleFonts.poppins(
                            color: Colors.grey.shade600, fontSize: 14)),
                  ),
                )
              else
                Column(
                  children: [
                    isGridView
                        ? _buildGridListings(width, currentBrokerId)
                        : _buildListListings(currentBrokerId),

                    if (isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: AnimatedLogoLoader(assetPath: 'assets/collabrix_logo.png'),),
                      ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Modern Grid View (with icons & more info)
  int hoveredIndex = -1; // put this at the top of your state

  Widget _buildGridListings(double width, String? currentBrokerId) {
    // Sort descending (newest first)
    final sortedListings = List<Map<String, dynamic>>.from(listings)
      ..sort((a, b) {
        // Extract broker IDs
        final brokerA = a['broker']?['id'] ?? a['brokerId'];
        final brokerB = b['broker']?['id'] ?? b['brokerId'];

        final bool aIsOwner = brokerA == currentBrokerId;
        final bool bIsOwner = brokerB == currentBrokerId;

        // 1️⃣ Owner listings come first
        if (aIsOwner && !bIsOwner) return -1;
        if (!aIsOwner && bIsOwner) return 1;

        // 2️⃣ If both are owner or both are not → sort by createdAt desc
        final dateA = DateTime.tryParse(a['createdAt'] ?? a['created_at'] ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['createdAt'] ?? b['created_at'] ?? '') ?? DateTime(1900);

        return dateB.compareTo(dateA);
      });

    return GridView.builder(
      shrinkWrap: true,
      controller: _scrollController,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: width < 900 ? 2 : 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.78,
      ),
      itemCount: sortedListings.length,
      itemBuilder: (context, index) {
        final e = sortedListings[index];
        final brokerData = e['broker'];
        final brokerId = (brokerData is Map && brokerData['id'] != null)
            ? brokerData['id']
            : e['brokerId'];
        final bool isOwner = currentBrokerId == null || brokerId == currentBrokerId;


        Widget selectionBox = isOwner
            ? Checkbox(
          value: selectedPropertyIds.contains(e['id']),
          activeColor: kPrimaryColor,
          onChanged: (checked) {
            setState(() {
              if (checked == true) {
                selectedPropertyIds.add(e['id']);
              } else {
                selectedPropertyIds.remove(e['id']);
              }
            });
          },
        )
            : const SizedBox.shrink(); // 🚫 no checkbox for non-owners

        final active = e['listingStatus'] == 'ACTIVE';
        final furnished = (e['furnishedStatus'] ?? 'UNFURNISHED')
            .toString()
            .replaceAll('_', ' ')                // make "SEMI_FURNISHED" → "SEMI FURNISHED"
            .toLowerCase()                      // → "semi furnished"
            .replaceFirstMapped(
          RegExp(r'^\w'),
              (m) => m.group(0)!.toUpperCase(), // capitalize first letter → "Semi furnished"
        );
        return MouseRegion(
          onEnter: (_) => setState(() => hoveredIndex = index),
          onExit: (_) => setState(() => hoveredIndex = -1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            transform: hoveredIndex == index
                ? (Matrix4.identity()..translate(0.0, -6.0, 0.0))
                : Matrix4.identity(),

            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Colors.white],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.06),
                  blurRadius: hoveredIndex == index ? 12 : 10,
                  offset: const Offset(0, 6),

                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼 Property Image + hover zoom
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      AnimatedScale(
                        duration: const Duration(milliseconds: 250),
                        scale: hoveredIndex == index ? 1.05 : 1.0,
                        child: Container(
                          height: 130,
                          width: double.infinity,
                          color: Colors.grey.shade100,
                          child: Image.asset(
                            'assets/collabrix_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // 🏷 Category badge on top-left
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.apartment_rounded,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                e['category'] ?? 'Property',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 🔹 Status chip top-right
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _badge(
                            e['listingStatus'] ?? '',
                            active ? Colors.green : Colors.grey,
                            icon: active ? Icons.verified_rounded : Icons.block_rounded
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 🏷 Select Checkbox + Title + Ref
                Row(
                  children: [
                    selectionBox,

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e['title'] ?? 'N/A',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Ref: ${e['referenceNumber'] ?? '-'}",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 💰 Price + Type + Status
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.start,
                  children: [
                    // 💰 Price Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          Text(
                            "${e['currency']} ${NumberFormat('#,###').format(int.parse(e['price']?? 0))}${e['unit'] ?? ''}",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),

                    // 🏠 Type Badge
                    _badge(
                      (() {
                        final pt = e['propertyType'];
                        if (pt == null) return 'Type';
                        if (pt is Map && pt['name'] != null) return pt['name'].toString();
                        return pt.toString(); // fallback if it's already a string or number
                      })(),
                      Colors.orange,
                      icon: Icons.home_work_outlined,
                    ),


                    // 🟢 Status Badge
                    _badge(
                      toSentenceCase(e['status'] ?? 'Unknown'),
                      Colors.teal,
                      icon: Icons.home_rounded,
                    ),

                  ],
                ),



                const SizedBox(height: 8),

                // 🛏️ Details icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _iconInfo(Icons.king_bed_outlined, "${e['rooms'] ?? 0}"),
                    _iconInfo(Icons.bathtub_outlined, "${e['bathrooms'] ?? 0}"),
                    _iconInfo(Icons.square_foot, e['sizeSqft'] ?? ''),
                    _iconInfo(Icons.local_parking_rounded, "${e['parkingSpaces'] ?? 0}"),
                    _iconInfo(
                      Icons.chair_alt_outlined,
                      furnished!)

                  ],
                ),

                const SizedBox(height: 10),

                // 📍 Location
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          e['location']['completeAddress'] ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.redAccent.shade700,
                            fontWeight: FontWeight.w500,

                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),


                const Spacer(),



                // 👤 Broker + Rating
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.brown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.brown.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.brown),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "${e['broker']['displayName']}  ⭐ ${e['rating'] ?? '-'}",
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: Colors.brown.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                 SizedBox(height: 10),

                const Divider(
                  color: Colors.grey,
                  thickness: 0.8,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 🟢 Active / Inactive Switch (Left side)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: e['listingStatus'] == 'ACTIVE',
                          activeColor: Colors.white,
                          activeTrackColor: Colors.green,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade400,
                          onChanged: isOwner
                              ? (bool value) async => await _togglePropertyStatus(e['id'], e['listingStatus'])
                              : null, // disabled for non-owner
                        ),
                        const SizedBox(width: 6),
                        Text(
                          e['listingStatus'] == 'ACTIVE' ? "Active" : "Inactive",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: e['listingStatus'] == 'ACTIVE'
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    // ✏️ Edit + 👁 View Chips (Right side)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✏️ Edit Chip
                        if (isOwner)
                          InkWell(
                          onTap: () async {
                            await _showEditPropertyDialog(context, e);
                          },

                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  "Edit",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (isOwner) const SizedBox(width: 10),

                        // 👁 View Chip
                        InkWell(
                         onTap: () => _viewPropertyDetails(e),
                         borderRadius: BorderRadius.circular(20),
                          child: Container(

                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.visibility_outlined,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  "View",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🔹 Modern List View (with full details + icons)
  Widget _buildListListings(String? currentBrokerId) {
    // Sort descending (newest first)
    final sortedListings = List<Map<String, dynamic>>.from(listings)
      ..sort((a, b) {
        // Extract broker IDs
        final brokerA = a['broker']?['id'] ?? a['brokerId'];
        final brokerB = b['broker']?['id'] ?? b['brokerId'];

        final bool aIsOwner = brokerA == currentBrokerId;
        final bool bIsOwner = brokerB == currentBrokerId;

        // 1️⃣ Owner listings come first
        if (aIsOwner && !bIsOwner) return -1;
        if (!aIsOwner && bIsOwner) return 1;

        // 2️⃣ If both are owner or both are not → sort by createdAt desc
        final dateA = DateTime.tryParse(a['createdAt'] ?? a['created_at'] ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['createdAt'] ?? b['created_at'] ?? '') ?? DateTime(1900);

        return dateB.compareTo(dateA);
      });



    return Column(
      children: sortedListings.map((e) {
        final brokerData = e['broker'];
        final brokerId = (brokerData is Map && brokerData['id'] != null)
            ? brokerData['id']
            : e['brokerId'];
        final bool isOwner = currentBrokerId == null || brokerId == currentBrokerId;


        Widget selectionBox = isOwner
            ? Checkbox(
          value: selectedPropertyIds.contains(e['id']),
          activeColor: kPrimaryColor,
          onChanged: (checked) {
            setState(() {
              if (checked == true) {
                selectedPropertyIds.add(e['id']);
              } else {
                selectedPropertyIds.remove(e['id']);
              }
            });
          },
        )
            : const SizedBox.shrink(); // 🚫 no checkbox for non-owners



        final active = e['listingStatus'] == 'ACTIVE';
        final furnished = (e['furnishedStatus'] ?? 'UNFURNISHED')
            .toString()
            .replaceAll('_', ' ')                // make "SEMI_FURNISHED" → "SEMI FURNISHED"
            .toLowerCase()                      // → "semi furnished"
            .replaceFirstMapped(
          RegExp(r'^\w'),
              (m) => m.group(0)!.toUpperCase(), // capitalize first letter → "Semi furnished"
        );

        return Stack(
          children: [
            // 🔹 Card Base
            Container(
              margin: const EdgeInsets.only(bottom: 18, top: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🖼 Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey.shade100,
                      child: Image.asset(
                        'assets/collabrix_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // 🏠 Property Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Title & Ref
                        // 🔹 Checkbox + Title & Ref
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            selectionBox,

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e['title'] ?? 'N/A',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Ref: ${e['referenceNumber'] ?? '-'}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),


                        const SizedBox(height: 10),

                        // 💰 Price & 📍 Location Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            // 💰 Price Chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green.shade400, Colors.green.shade600],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  Text(
                                    "${e['currency']} ${NumberFormat('#,###').format(int.parse(e['price']?? 0))}${e['unit'] ?? ''}",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 📍 Location Chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 14, color: Colors.redAccent),
                                  const SizedBox(width: 4),
                                  Text(
                                    e['location']['completeAddress'] ?? "Unknown",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.redAccent.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                ],
                              ),
                            ),

                            // 💼 Transaction Type Chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.indigo.withOpacity(0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.indigo),
                                  const SizedBox(width: 4),
                                  Text(
                                    'For ${(e['transactionType'] ?? 'Unknown').toString()}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.indigo.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          ],
                        ),



                        const SizedBox(height: 10),

                        // 🛏️ Info Icons Row
                        Row(
                          children: [
                            _iconInfo(Icons.king_bed_outlined, "${e['rooms'] ?? 0}"),
                            _iconInfo(Icons.bathtub_outlined, "${e['bathrooms'] ?? 0}"),
                            _iconInfo(Icons.square_foot, e['size'] ?? ''),
                            _iconInfo(Icons.local_parking_rounded, "${e['parkingSpaces'] ?? 0}"),

                            _iconInfo(
                                Icons.chair_alt_outlined,
                                furnished!)
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 🏷️ Badges Row
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _badge(e['category'] ?? 'Category', Colors.blue,
                                icon: Icons.apartment_rounded),
                            _badge(
                              (() {
                                final pt = e['propertyType'];
                                if (pt == null) return 'Type';
                                if (pt is Map && pt['name'] != null) return pt['name'].toString();
                                return pt.toString(); // fallback if it's already a string or number
                              })(),
                              Colors.orange,
                              icon: Icons.home_work_outlined,
                            ),

                            _badge(
                              toSentenceCase(e['status'] ?? 'Unknown'),
                              Colors.teal,
                              icon: Icons.home_rounded,
                            ),

                          ],
                        ),

                        const SizedBox(height: 10),

// 🔸 Divider line above action buttons
                        Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                          height: 10,
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 🟢 Active / Inactive Switch (Left side)
                            if(isOwner)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: e['listingStatus'] == 'ACTIVE',
                                  activeColor: Colors.white,
                                  activeTrackColor: Colors.green,
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: Colors.grey.shade400,
                                  onChanged: isOwner
                                      ? (bool value) async => await _togglePropertyStatus(e['id'], e['listingStatus'])
                                      : null, // disabled for non-owner
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  e['listingStatus'] == 'ACTIVE' ? "Active" : "Inactive",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: e['listingStatus'] == 'ACTIVE'
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            if(!isOwner)
                              Spacer(),

                            // ✏️ Edit + 👁 View Chips (Right side)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ✏️ Edit Chip
                                if (isOwner)
                                  InkWell(
                                  onTap: () async {
                                    await _showEditPropertyDialog(context, e);
                                  },

                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Edit",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),


                                if (isOwner) const SizedBox(width: 10),


                                // 👁 View Chip
                                InkWell(
                                  onTap: () => _viewPropertyDetails(e),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.visibility_outlined,
                                            color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          "View",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),




                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🟢 Floating ACTIVE Badge (Top-Right Corner)
            Positioned(
              top: 24,
              right: 24,
              child: _badge(
                e['listingStatus'] ?? 'Status',
                active ? Colors.green : Colors.grey,
                icon: active ? Icons.verified_rounded : Icons.block_rounded,
              ),
            ),

            // 👤 Broker Chip
            Positioned(
              bottom: 92,
              right: 18,
              child:Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.brown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.brown.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline,
                        size: 14, color: Colors.brown),
                    const SizedBox(width: 4),
                    Text(
                      "${e['broker']['displayName']}  ⭐ ${e['rating'] ?? '-'}",
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: Colors.brown.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _iconInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _sizeField(String label, TextEditingController controller, {bool isMin = false}) {
    return SizedBox(
      width: 160,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')), // allow int & 2 decimals
        ],
        onChanged: (v) {
          _validateSizeFields();
          if (v.isNotEmpty) {
            if (isMin) {
              minSize = double.tryParse(v)?.toInt();
            } else {
              maxSize = double.tryParse(v)?.toInt();
            }
          } else {
            if (isMin) {
              minSize = null;
            } else {
              maxSize = null;
            }
          }
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: sizeError != null && !isMin
                  ? Colors.redAccent
                  : Colors.grey.shade400,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: sizeError != null && !isMin
                  ? Colors.redAccent
                  : kPrimaryColor,
              width: 1.3,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        style: GoogleFonts.poppins(fontSize: 13),
      ),
    );
  }

  Widget _buildToggleChips(
      List<String> options,
      String selected,
      Function(String) onSelected, {
        Function(void Function())? setDialogState, // 👈 optional now
      }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: options.map((option) {
          final isActive = selected == option;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  // 👇 if inside dialog → use setDialogState, else → use outer setState
                  if (setDialogState != null) {
                    setDialogState(() => onSelected(option));
                  } else {
                    setState(() => onSelected(option));
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isActive ? kPrimaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? kPrimaryColor : Colors.grey.shade300,
                    ),
                    boxShadow: [
                      if (isActive)
                        BoxShadow(
                          color: kPrimaryColor.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : Colors.black87,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 🔹 Reusable badge
  Widget _badge(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField(String hint, TextEditingController controller) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true,
          fillColor: kFieldBackgroundColor,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: kPrimaryColor, width: 1.2)),
        ),
      ),
    );
  }

  Widget _priceField(String hint, TextEditingController controller, {bool isMin = false}) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')), // ✅ allow int & 2-decimal float
        ],
        onChanged: (value) {
          final minVal = double.tryParse(_minPriceController.text) ?? 0;
          final maxVal = double.tryParse(_maxPriceController.text) ?? 0;

          // ✅ Validation logic
          if (_minPriceController.text.isNotEmpty &&
              _maxPriceController.text.isNotEmpty &&
              maxVal < minVal) {
            setState(() => priceError = "Max Price should be greater than Min Price");
          } else {
            setState(() => priceError = null);
          }
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.currency_exchange, size: 18, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true,
          fillColor: kFieldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: kPrimaryColor, width: 1.2),
          ),
          errorText: (isMin || !isMin) ? null : null, // handled separately
        ),
      ),
    );
  }

  Widget _viewModeToggle() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _viewButton(Icons.list_rounded, "List", false),
          SizedBox(width: 8,),

          _viewButton(Icons.grid_view_outlined, "Grid", true),

        ],
      ),
    );
  }

  Widget _viewButton(IconData icon, String label, bool isGrid) {
    final active = isGridView == isGrid;
    return GestureDetector(
      onTap: () => setState(() => isGridView = isGrid),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active ? kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? Colors.transparent : Colors.grey.shade300,
            width: 1.2,
          ),
          boxShadow: active
              ? [
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? Colors.white : Colors.black87),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.poppins(
                    color: active ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight:
                    active ? FontWeight.w600 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditPropertyDialog(

      BuildContext context, Map<String, dynamic> propertyData) async {
    final _formKey = GlobalKey<FormState>();
    bool isLoading = false;



    final titleC = TextEditingController(text: propertyData['title'] ?? '');
    final priceC = TextEditingController(text: propertyData['price']?.toString() ?? '');
    final sizeC = TextEditingController(
        text: propertyData['sizeSqft']?.toString().replaceAll(' sqft', '') ?? '');
    final descC = TextEditingController(text: propertyData['description'] ?? '');

    String? category = propertyData['category'] ?? 'RESIDENTIAL';
    String? furnishing = propertyData['furnishedStatus'] ?? 'UNFURNISHED';
    String? status = propertyData['status'] ?? 'READY_TO_MOVE';

    String transactionType = propertyData['transactionType'] ?? "RENT";
    List<String> allowedStatusOptions =
    transactionType == "RENT"
        ? ["READY_TO_MOVE", "AVAILABLE_IN_FUTURE"]
        : ["READY_TO_MOVE", "RENTED", "OFF_PLAN", "AVAILABLE_IN_FUTURE"];

    if (!allowedStatusOptions.contains(status)) {
      status = allowedStatusOptions.first;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700, maxHeight: 650),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Edit Property",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.black54),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        /// Title
                        _buildDialogTextField("Title", titleC, Icons.title),
                        const SizedBox(height: 14),

                        /// Price + Size
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogTextField(
                                "Price (AED)",
                                priceC,
                                Icons.price_change_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDialogTextField(
                                "Size (sqft)",
                                sizeC,
                                Icons.square_foot_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        /// Category + Furnishing
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogDropdown(
                                "Category",
                                category,
                                Icons.category_outlined,
                                ["RESIDENTIAL", "COMMERCIAL", "INDUSTRIAL", "LAND"],
                                    (v) => setState(() => category = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDialogDropdown(
                                "Furnishing",
                                furnishing,
                                Icons.chair_alt_outlined,
                                ["FURNISHED", "SEMI_FURNISHED", "UNFURNISHED"],
                                    (v) => setState(() => furnishing = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _buildDialogDropdown(
                          "Status",
                          status,
                          Icons.home_work_outlined,
                          allowedStatusOptions,
                              (v) => setState(() => status = v),
                        ),





                        const SizedBox(height: 14),

                        /// Description
                        _buildDialogTextField(
                          "Description",
                          descC,
                          Icons.description_outlined,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 28),

                        /// Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => isLoading = true);

                              try {
                                final token = await AuthService.getToken();
                                final url = Uri.parse(
                                    '$baseURL/api/properties/${propertyData['id']}');

                                final body = {
                                  'title': titleC.text.trim(),
                                  'price': double.tryParse(priceC.text) ?? 0,
                                  'sizeSqft': double.tryParse(sizeC.text) ?? 0,
                                  'category': category,
                                  'furnishedStatus': furnishing,
                                  'status': status,
                                  'description': descC.text.trim(),
                                };

                                print('edit body -> $body');

                                final response = await http.put(
                                  url,
                                  headers: {
                                    'Content-Type': 'application/json',
                                    'Authorization': 'Bearer $token',
                                  },
                                  body: jsonEncode(body),
                                );

                                print('response  -> ${response.body}');

                                if (response.statusCode == 200) {
                                  final data = jsonDecode(response.body);
                                  if (data['success'] == true) {
                                    Navigator.pop(context);
                                    /*ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Property updated successfully!'),
                                        backgroundColor: Colors.green,
                                      ),

                                    );*/
                                    fetchListings();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(data['message'] ?? 'Update failed'),
                                      backgroundColor: Colors.redAccent,
                                    ));
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Server Error: ${response.statusCode}'),
                                    backgroundColor: Colors.redAccent,
                                  ));
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.redAccent,
                                ));
                              } finally {
                                setState(() => isLoading = false);
                              }
                            },
                            icon: isLoading
                                ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(),
                            )
                                : const Icon(Icons.save_rounded, color: Colors.white),
                            label: Text(
                              isLoading ? "Updating..." : "Save Changes",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }



  /// ✳️ Input Field with Icon



  Widget _buildDialogTextField(String label, TextEditingController controller,
      IconData icon,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters, // ✅ add this line

      validator: (v) => v == null || v.trim().isEmpty ? 'Required field' : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: kPrimaryColor),
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kPrimaryColor, width: 1.3),
        ),
      ),
    );
  }

  /// ✳️ Dropdown with Icon
  Widget _buildDialogDropdown(String label, String? value, IconData icon,
      List<String> items, Function(String?) onChanged) {
    return Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white, // 👈 makes dropdown menu background white

        ),
    child: DropdownButtonFormField<String>(

      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: kPrimaryColor),
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kPrimaryColor, width: 1.3),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(
        value: e,
        child: Text(
          prettyText(e),
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
        ),
      ))
          .toList(),
    ),);
  }


}


Widget _buildCompactDropdown({
  required String title,
  required String? value,
  required List<String> items,
  required Function(String?) onChanged,
}) {

  String prettyText(String value) {
    return value
        .split('_')
        .map((word) =>
    word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
  return SizedBox(
    width: 180,
    child: DropdownButtonFormField<String>(
      value: (value != null && items.contains(value)) ? value : null,
      decoration: InputDecoration(
        labelText: title,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade700,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

        /// ✅ Always visible border, clean rounded
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey.shade400,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: kPrimaryColor,
            width: 1.3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      hint: Text(
        "Select",
        style: GoogleFonts.poppins(
          color: Colors.grey.shade500,
          fontStyle: FontStyle.normal,
          fontSize: 12.5,
        ),
      ),

      /// 🔹 Dropdown popup styling
      dropdownColor: Colors.white, // Light purple background

      iconEnabledColor: Colors.grey.shade700,
      items: items
          .map(
            (e) => DropdownMenuItem(
          value: e,
          child: Text(
            prettyText(e),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      )
          .toList(),
      onChanged: onChanged,
    ),
  );
}



Widget _buildCompactField({
  required String label,
  required Function(String?) onChanged,
}) {
  return SizedBox(
    width: 160,
    child: TextFormField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true), // ✅ allow int & double
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')), // ✅ allows numbers + one dot + 2 decimals max
      ],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade700,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: kPrimaryColor, width: 1.3),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 13),
      onChanged: onChanged,
    ),
  );
}


class LocationSearchDialog extends StatefulWidget {
  final List locations;
  final String? preselectedId;

  const LocationSearchDialog({
    super.key,
    required this.locations,
    this.preselectedId,
  });

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  final TextEditingController searchC = TextEditingController();
  final ScrollController _scrollC = ScrollController();

  List filtered = [];
  String query = "";

  @override
  void initState() {
    super.initState();
    filtered = [];

    /// Auto-scroll AFTER dialog builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.preselectedId != null) {
        final index = widget.locations.indexWhere(
                (loc) => loc['id'] == widget.preselectedId);

        if (index != -1) {
          // Approx 55px per item height
          final double offset = index * 55.0;
          _scrollC.jumpTo(offset);
        }
      }
    });
  }

  void runSearch(String value) {
    setState(() {
      query = value.trim().toLowerCase();

      if (query.isEmpty) {
        filtered = [];
        return;
      }

      filtered = widget.locations
          .where((loc) =>
          loc['displayPath'].toString().toLowerCase().contains(query))
          .take(80)
          .toList();
    });
  }

  Widget highlightText(String text, String query, bool isSelected) {
    if (query.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.black,
        ),
      );
    }

    final lower = text.toLowerCase();
    final index = lower.indexOf(query.toLowerCase());

    if (index == -1) {
      return Text(
        text,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.black,
        ),
      );
    }

    final before = text.substring(0, index);
    final match = text.substring(index, index + query.length);
    final after = text.substring(index + query.length);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: before,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          TextSpan(
            text: match,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: after,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 500,
        child: Column(
          children: [
            /// ---- SEARCH BAR ----
            TextField(
              controller: searchC,
              autofocus: true,
              onChanged: runSearch,
              decoration: InputDecoration(
                hintText: "Search location...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// ---- RESULTS LIST ----
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                child: Text(
                  query.isEmpty
                      ? "Start typing to search..."
                      : "No matching results",
                  style: const TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                controller: _scrollC,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final loc = filtered[i];
                  final bool isSelected = widget.preselectedId != null &&
                      widget.preselectedId!.toString() == loc['id'].toString();


                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color:
                      isSelected ? Colors.blue.withOpacity(0.08) : null,
                      border: isSelected
                          ? Border.all(color: Colors.blue, width: 1.5)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      dense: true,
                      title: highlightText(
                          loc['displayPath'], query, isSelected),
                      onTap: () => Navigator.pop(context, loc),
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

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove any commas before parsing
    final cleaned = newValue.text.replaceAll(',', '');

    if (double.tryParse(cleaned) == null) {
      return oldValue; // invalid input (non-numeric)
    }

    final formatted = _formatter.format(double.parse(cleaned));

    // Calculate cursor position from the end
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
