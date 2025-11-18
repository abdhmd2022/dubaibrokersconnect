import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_logo_loader.dart';

class RequirementsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const RequirementsScreen({super.key,
    required this.userData,
  });

  @override
  State<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends State<RequirementsScreen> {
  // -------- Data Lists ----------
  List<dynamic> requirements = [];
  List<dynamic> propertyTypes = [];
  List<dynamic> allLocations = [];
  List<String> selectedLocationIds = [];
  List<dynamic> filteredRequirements = []; // locally filtered
  bool isBulkStatusProcessing = false;
  bool isBulkDeleteProcessing = false;
  bool showMyRequirements = false; // declare this in your state
  final minPriceC = TextEditingController();
  final maxPriceC = TextEditingController();
  final minSizeC = TextEditingController();
  final maxSizeC = TextEditingController();

  List<String> selectedRequirementIds = [];
  bool selectAll = false;
  bool showingMyRequirements = false;

  TextEditingController locationSearchC = TextEditingController();
  // -------- Filters ----------
  String selectedTransaction = "ALL";
  String selectedCategory = "ALL";
  String searchQuery = "";

  // -------- UI States ----------
  bool isLoading = false;
  bool gridView = false;
  int currentPage = 1;
  int totalPages = 1;

  // Drawer control
  Map<String, dynamic>? selectedRequirement;
  bool showDrawer = false;

  @override
  void initState() {
    super.initState();
    _fetchRequirements();
    _fetchPropertyTypesAndLocations();

  }


  // ============ FETCH REQUIREMENTS ============
  Future<void> _fetchRequirements({int page = 1}) async {
    setState(() => isLoading = true);

    try {
      final token = await AuthService.getToken();

      final query = <String, String>{
        'page': '$page',
        'limit': '10',
      };

      if (selectedCategory != "ALL") query['category'] = selectedCategory;
      if (searchQuery.isNotEmpty) query['search'] = searchQuery;

      final uri = Uri.parse('$baseURL/api/requirements')
          .replace(queryParameters: query);

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        // THE CORRECT LIST → from your actual API response
        List fetched = body['data'] ?? [];

        print("API Returned Requirements Count = ${fetched.length}");

        // ⭐ Apply transaction filter
        if (selectedTransaction != "ALL") {
          fetched = fetched
              .where((r) => r['transactionType'] == selectedTransaction)
              .toList();
        }

        final currentBrokerId = widget.userData['broker']['id'];

        // ⭐ Sort: My requirements first
        fetched.sort((a, b) {
          final isAOwner = a['brokerId'] == currentBrokerId;
          final isBOwner = b['brokerId'] == currentBrokerId;

          if (isAOwner && !isBOwner) return -1;
          if (!isAOwner && isBOwner) return 1;
          return 0;
        });

        // ⭐ Separate mine vs others
        final ownReqs =
        fetched.where((r) => r['brokerId'] == currentBrokerId).toList();

        final otherReqs = fetched
            .where((r) => r['brokerId'] != currentBrokerId)
            .where((r) => r['broker']?['approvalStatus'] == "APPROVED")
            .toList();

        final finalList = [...ownReqs, ...otherReqs];

        print("My Requirements = ${ownReqs.length}");
        print("Other Approved Requirements = ${otherReqs.length}");
        print("Final Total = ${finalList.length}");

        // ⭐ SINGLE setState ONLY
        setState(() {
          requirements = finalList;
          filteredRequirements = finalList;

          currentPage = body['pagination']?['page'] ?? 1;
          totalPages = body['pagination']?['totalPages'] ?? 1;
        });

      } else {
        debugPrint("❌ Failed: ${response.statusCode}");
        debugPrint(response.body);
      }
    } catch (e) {
      debugPrint("⚠️ Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchPropertyTypesAndLocations() async {
    try {
      final token = await AuthService.getToken();

      final propRes = await http.get(
        Uri.parse('$baseURL/api/property-types'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final locRes = await http.get(
        Uri.parse('$baseURL/api/locations'),
        headers: {'Authorization': 'Bearer $token'},
      );


      if (propRes.statusCode == 200) {
        propertyTypes = json.decode(propRes.body)['data'] ?? [];
      }
      if (locRes.statusCode == 200) {
        final jsonBody = json.decode(locRes.body);
        final data = jsonBody['data'] as List<dynamic>;
        debugPrint("🟢 Received ${data.length} raw locations from API");

        // Prepare formatted list
        formattedLocations = data.map<Map<String, dynamic>>((loc) {
          final parent = loc['parent'] != null ? loc['parent']['name'] : '';
          final label = parent.isNotEmpty ? "${loc['name']} ($parent)" : loc['name'];
          return {'id': loc['id'], 'label': label};
        }).toList();

        debugPrint("🟢 formattedLocations.length = ${formattedLocations.length}");
        if (formattedLocations.isNotEmpty) {
          debugPrint("✅ Sample: ${formattedLocations.first}");
        }

        setState(() {
          allLocations = data;
        });


      }
      else {
        debugPrint("❌ Failed to load locations. Body: ${locRes.body}");
      }
    } catch (e) {
      debugPrint("Error fetching property types / locations: $e");
    }
  }

  // ---------------- EDIT DIALOG ----------------
  Future<void> _openEditDialog(Map<String, dynamic> req) async {
    await _fetchPropertyTypesAndLocations();

    // 🏷️ Tag states
    List<Map<String, dynamic>> allTags = [];
    List<String> selectedTagIds = [];

    // 🔹 Fetch tags from API
    Future<void> _fetchTags() async {
      try {
        final token = await AuthService.getToken();
        final res = await http.get(
          Uri.parse('$baseURL/api/tags'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          allTags = List<Map<String, dynamic>>.from(data['data']);
        } else {
          debugPrint("Failed to fetch tags: ${res.statusCode}");
        }
      } catch (e) {
        debugPrint("Error fetching tags: $e");
      }
    }

    await _fetchTags();

    if (req['keywordsTagIds'] != null && req['keywordsTagIds'] is List) {
      selectedTagIds = List<String>.from(req['keywordsTagIds']);
    }



    final formKey = GlobalKey<FormState>();
    final titleC = TextEditingController(text: req['title'] ?? '');
    final refC = TextEditingController(text: req['referenceNumber'] ?? '');
    final descC = TextEditingController(text: req['requirementDescription'] ?? '');
    final minPriceC = TextEditingController(text: req['minPrice']?.toString() ?? '');
    final maxPriceC = TextEditingController(text: req['maxPrice']?.toString() ?? '');
    final minSizeC = TextEditingController(text: req['minSizeSqft']?.toString() ?? '');
    final maxSizeC = TextEditingController(text: req['maxSizeSqft']?.toString() ?? '');

    String? propertyTypeId = req['propertyTypeId'];
    List<String> locationIds = req['locations'] != null
        ? List<String>.from(req['locations'].map((x) => x['id']))
        : [];
    // Add this helper inside the same widget/class:
    String? _normalizeFurnished(String value) {
      final v = value.toLowerCase();
      if (v.contains("semi")) return "Semi-Furnished";
      if (v.contains("un")) return "Unfurnished";
      if (v.contains("fur")) return "Furnished";
      return null;
    }
    String transactionType = req['transactionType'] ?? 'SALE';
    String category = req['category'] ?? 'RESIDENTIAL';
    String? rooms = req['rooms'] != null && req['rooms'].isNotEmpty ? req['rooms'][0] : null;
    String? furnishedStatus = req['furnishedStatus'] != null && req['furnishedStatus'].isNotEmpty
        ? _normalizeFurnished(req['furnishedStatus'][0])
        : null;


    DateTime? expireDate = req['autoExpireDate'] != null
        ? DateTime.tryParse(req['autoExpireDate'])
        : null;
    bool isSubmitting = false;

    InputDecoration modernInputDecoration({
      required String label,
      required IconData icon,
      String? hint,
      String? suffix,
    }) {
      return InputDecoration(
        prefixIcon: Icon(icon, color: kPrimaryColor),
        suffixText: suffix,
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kPrimaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      );
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 12,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;

            return StatefulBuilder(
              builder: (context, setDialogState) {
                Future<void> update() async {
                  if (!formKey.currentState!.validate()) return;
                  setDialogState(() => isSubmitting = true);

                  try {
                    final token = await AuthService.getToken();
                    final body = {
                      "title": titleC.text.trim(),
                      "reference_number": refC.text.trim(),
                      "requirement_description": descC.text.trim(),
                      "property_type_id": propertyTypeId,
                      "location_ids": locationIds,
                      "rooms": rooms != null ? [rooms] : [],
                      "min_size_sqft": int.tryParse(minSizeC.text) ?? 0,
                      "max_size_sqft": int.tryParse(maxSizeC.text) ?? 0,
                      "min_price": int.tryParse(minPriceC.text) ?? 0,
                      "max_price": int.tryParse(maxPriceC.text) ?? 0,
                      "furnished_status": furnishedStatus != null ? [furnishedStatus] : [],
                      "category": category,
                      "transaction_type": transactionType,
                      "auto_expire_date": expireDate?.toIso8601String(),
                      "keywords_tag_ids": selectedTagIds,
                    };

                    final res = await http.put(
                      Uri.parse('$baseURL/api/requirements/${req['id']}'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                      body: json.encode(body),
                    );

                    if (res.statusCode == 200) {
                      Navigator.pop(context);
                      _fetchRequirements();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Requirement updated successfully!')),
                      );
                    } else {
                      debugPrint("Failed: ${res.body}");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: ${res.statusCode}')),
                      );
                    }
                  } catch (e) {
                    debugPrint("Error updating requirement: $e");
                  } finally {
                    setDialogState(() => isSubmitting = false);
                  }
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Edit Requirement",
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 26),
                                color: Colors.grey.shade700,
                                onPressed: () => Navigator.pop(context),
                                splashRadius: 22,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // --- Form Grid ---
                          Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: [
                              SizedBox(
                                width: isWide ? 400 : double.infinity,
                                child: TextFormField(
                                  controller: titleC,
                                  decoration: modernInputDecoration(
                                    label: "Requirement Title *",
                                    icon: Icons.title_rounded,
                                    hint: "e.g., Young couple seeking 2BR in Downtown",
                                  ),
                                  validator: (v) => v!.isEmpty ? "Enter title" : null,
                                ),
                              ),
                              SizedBox(
                                width: isWide ? 400 : double.infinity,
                                child: TextFormField(
                                  controller: refC,
                                  decoration: modernInputDecoration(
                                    label: "Reference Number *",
                                    icon: Icons.confirmation_number_outlined,
                                    hint: "e.g., REQ-001",
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: isWide ? 400 : double.infinity,
                                child: DropdownButtonFormField<String>(
                                  value: transactionType,
                                  decoration: modernInputDecoration(
                                    label: "Looking To",
                                    icon: Icons.swap_horiz_rounded,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: "SALE", child: Text("Buy")),
                                    DropdownMenuItem(value: "RENT", child: Text("Rent")),
                                    DropdownMenuItem(value: "SALE_AND_RENT", child: Text("Rent & Buy")),
                                  ],
                                  onChanged: (v) => setDialogState(() => transactionType = v!),
                                ),
                              ),
                              SizedBox(
                                width: isWide ? 400 : double.infinity,
                                child: DropdownButtonFormField<String>(
                                  value: category,
                                  decoration: modernInputDecoration(
                                    label: "Property Category",
                                    icon: Icons.category_outlined,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: "RESIDENTIAL", child: Text("Residential")),
                                    DropdownMenuItem(value: "COMMERCIAL", child: Text("Commercial")),
                                  ],
                                  onChanged: (v) => setDialogState(() => category = v!),
                                ),
                              ),
                              SizedBox(
                                width: isWide ? 400 : double.infinity,
                                child: DropdownButtonFormField<String>(
                                  decoration: modernInputDecoration(
                                    label: "Property Type *",
                                    icon: Icons.apartment_rounded,
                                  ),
                                  value: propertyTypeId,
                                  items: propertyTypes
                                      .map<DropdownMenuItem<String>>(
                                          (item) => DropdownMenuItem(
                                        value: item['id'],
                                        child: Text(item['name']),
                                      ))
                                      .toList(),
                                  onChanged: (val) => setDialogState(() => propertyTypeId = val),
                                ),
                              ),
                              SizedBox(
                                width: isWide ? 400 : double.infinity,
                                child: DropdownButtonFormField<String>(
                                  value: rooms,
                                  decoration: modernInputDecoration(
                                    label: "Rooms",
                                    icon: Icons.meeting_room_outlined,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: "Studio", child: Text("Studio")),
                                    DropdownMenuItem(value: "1", child: Text("1")),
                                    DropdownMenuItem(value: "2", child: Text("2")),
                                    DropdownMenuItem(value: "3", child: Text("3")),
                                    DropdownMenuItem(value: "4", child: Text("4")),
                                    DropdownMenuItem(value: "5", child: Text("5")),
                                    DropdownMenuItem(value: "5+", child: Text("5+")),
                                  ],
                                  onChanged: (v) => setDialogState(() => rooms = v),
                                ),
                              ),
                              SizedBox(
                                width: isWide ? 400 : double.infinity,
                                child: DropdownButtonFormField<String>(
                                  value: furnishedStatus,
                                  decoration: modernInputDecoration(
                                    label: "Furnished Status",
                                    icon: Icons.chair_alt_rounded,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: "Furnished", child: Text("Furnished")),
                                    DropdownMenuItem(value: "Semi-Furnished", child: Text("Semi-Furnished")),
                                    DropdownMenuItem(value: "Unfurnished", child: Text("Unfurnished")),
                                  ],
                                  onChanged: (v) => setDialogState(() => furnishedStatus = v),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // 📍 Locations
                          Text("Preferred Locations *",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TypeAheadField<Map<String, dynamic>>(
                            suggestionsCallback: (pattern) {
                              if (pattern.isEmpty) {
                                return formattedLocations;
                              }
                              return formattedLocations
                                  .where((loc) => loc['label']
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                                  .toList();
                            },
                            itemBuilder: (context, suggestion) {
                              final isSelected = locationIds.contains(suggestion['id']);
                              return ListTile(
                                leading: Icon(Icons.location_on, color: kPrimaryColor),
                                title: Text(suggestion['label']),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle, color: kPrimaryColor)
                                    : null,
                              );
                            },
                            onSelected: (suggestion) {
                              setDialogState(() {
                                if (locationIds.contains(suggestion['id'])) {
                                  locationIds.remove(suggestion['id']);
                                } else {
                                  locationIds.add(suggestion['id']);
                                }
                              });
                            },
                            builder: (context, controller, focusNode) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: modernInputDecoration(
                                  label: "Search & Select Locations",
                                  icon: Icons.search_rounded,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: locationIds.map((id) {
                              final loc = formattedLocations.firstWhere(
                                    (l) => l['id'] == id,
                                orElse: () => {},
                              );
                              if (loc.isEmpty) return const SizedBox();
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12.withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Text(loc['label'],
                                          style: GoogleFonts.poppins(color: Colors.white)),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => setDialogState(() => locationIds.remove(id)),
                                        child: const Icon(Icons.close_rounded,
                                            size: 17, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // 🏷️ Tags (replaces keywords section)
                          Text("Tags", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),

                          TypeAheadField<Map<String, dynamic>>(
                            suggestionsCallback: (pattern) {
                              final query = pattern.toLowerCase();
                              return allTags.where((tag) {
                                final name = (tag['name'] ?? '').toLowerCase();
                                return name.contains(query) && !selectedTagIds.contains(tag['id']);
                              }).toList();
                            },


                            itemBuilder: (context, suggestion) {


                              return ListTile(
                                leading: const Icon(Icons.sell_outlined, color: Colors.teal),
                                title: Text(
                                  suggestion['name'],
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                ),
                                trailing: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                            onSelected: (suggestion) {
                              setDialogState(() {
                                selectedTagIds.add(suggestion['id']);
                              });
                            },
                            builder: (context, controller, focusNode) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: modernInputDecoration(
                                  label: "Search Tags",
                                  icon: Icons.sell_outlined,
                                  hint: "Search & select multiple tags",
                                ),
                              );
                            },

                          ),

                          const SizedBox(height: 8),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: selectedTagIds.map((id) {
                              final tag = allTags.firstWhere(
                                    (t) => t['id'] == id,
                                orElse: () => {},
                              );
                              if (tag.isEmpty) return const SizedBox();


                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12.withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.sell_outlined,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Text(tag['name'] ?? '',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => setDialogState(() => selectedTagIds.remove(id)),
                                        child: const Icon(Icons.close_rounded,
                                            size: 17, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // 📝 Description
                          TextFormField(
                            controller: descC,
                            maxLines: 4,
                            decoration: modernInputDecoration(
                              label: "Requirement Description *",
                              icon: Icons.description_outlined,
                              hint: "Describe your client's needs in detail...",
                            ),
                            validator: (v) => v!.isEmpty ? "Enter description" : null,
                          ),

                          const SizedBox(height: 24),

                          // 📅 Expiry Date
                          TextButton.icon(
                            icon: const Icon(Icons.calendar_today_rounded, color: Colors.black87),
                            label: Text(
                              expireDate == null
                                  ? "Pick Expiry Date"
                                  : "Expires on: ${expireDate!.toLocal().toString().split(' ')[0]}",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black87),
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: expireDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) setDialogState(() => expireDate = date);
                            },
                          ),

                          const SizedBox(height: 32),

                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: isSubmitting ? null : update,
                              icon: isSubmitting
                                  ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                                  : const Icon(Icons.save_rounded, color: Colors.white),
                              label: Text(
                                isSubmitting ? "Saving..." : "Update Requirement",
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }

  final searchC = TextEditingController();


  // ============ HEADER ============
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Broker Requirements",
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
        Row(
          children: [


        OutlinedButton.icon(
          onPressed: () {
            setState(() => showMyRequirements = !showMyRequirements);
            _applyFilters();
          },

          icon: Icon(
        showMyRequirements ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: showMyRequirements ? Colors.white : kPrimaryColor,
        size: 20,
        ),
        label: Text(
        "Show My Requirements",
        style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        color: showMyRequirements ? Colors.white : kPrimaryColor,
        ),
        ),
        style: OutlinedButton.styleFrom(
    backgroundColor:
    showMyRequirements ? kPrimaryColor : Colors.transparent,
    side: BorderSide(color: kPrimaryColor, width: 1.4),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    ),



    const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
              label:  Text("Post Requirement",
                style: GoogleFonts.poppins(
                color: Colors.white
              ),),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        )
      ],
    );
  }

  // ============ FILTER PANEL ============
  Widget _buildFilterPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🏷️ TRANSACTION FILTER CONTAINER
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Client is looking to",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip("All", "ALL", selectedTransaction, (v) {
                            setState(() {
                              selectedTransaction = v;
                              _applyFilters(); // ✅ unified filter logic
                            });
                          }),
                          _buildFilterChip("Rent", "RENT", selectedTransaction, (v) {
                            setState(() {
                              selectedTransaction = v;
                              _applyFilters(); // ✅ unified filter logic
                            });
                          }),
                          _buildFilterChip("Buy", "SALE", selectedTransaction, (v) {
                            setState(() => selectedTransaction = v);
                            _applyFilters();
                          }),

                        ],
                      ),

                    ],
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // 🏠 CATEGORY FILTER CONTAINER
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Property Category",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip("All", "ALL", selectedCategory, (v) {
                            setState(() {
                              selectedCategory = v;
                              _applyFilters(); // ✅ unified filter logic
                            });
                          }),

                          _buildFilterChip("Residential", "RESIDENTIAL", selectedCategory,  (v) {
                          setState(() => selectedCategory = v);
                          _applyFilters();
                          }),

                          _buildFilterChip("Commercial", "COMMERCIAL", selectedCategory, (v) {
                            setState(() => selectedCategory = v);
                            _applyFilters();
                          }),
                        ],
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
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
                      color: Colors.black12.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModernSegment(
                      icon: Icons.list_rounded,
                      label: "List",
                      isSelected: !gridView,
                      onTap: () => setState(() => gridView = false),
                    ),
                    _buildModernSegment(
                      icon: Icons.grid_view_rounded,
                      label: "Grid",
                      isSelected: gridView,
                      onTap: () => setState(() => gridView = true),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              // 🔍 SEARCH + LOCATION ROW
              Row(

                children: [
                  // 🔍 SEARCH FIELD (LEFT)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child:TextField(
                        controller: searchC, // ✅ Add controller

                        decoration: InputDecoration(

                          hintText: "Search by Title, Description or Location...",
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() => searchQuery = val.trim().toLowerCase());
                          _applyFilters();
                        },

                      ),

                    ),
                  ),

                  const SizedBox(width: 12),

                  // 📍 LOCATION SEARCH FIELD (from existing requirements)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: TypeAheadField<Map<String, dynamic>>(
                        suggestionsCallback: (pattern) async {
                          // 🧩 Extract unique locations from all requirements
                          final allLocations = requirements
                              .expand((req) => (req['locations'] as List?) ?? [])
                              .toList();

                          // 🧩 Make unique list by location name/id
                          final uniqueLocations = {
                            for (var loc in allLocations)
                              loc['id']: {
                                'id': loc['id'],
                                'label': loc['completeAddress'] ?? loc['name'] ?? 'Unknown'
                              }
                          }.values.toList();

                          // 🧩 Filter by pattern
                          if (pattern.isEmpty) return uniqueLocations;
                          return uniqueLocations
                              .where((loc) =>
                              loc['label'].toLowerCase().contains(pattern.toLowerCase()))
                              .toList();
                        },
                        itemBuilder: (context, suggestion) {
                          final isSelected = selectedLocationIds.contains(suggestion['id']);
                          return ListTile(
                            dense: true,
                            title: Text(
                              suggestion['label'],
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: kPrimaryColor, size: 18)
                                : null,
                          );
                        },
                        onSelected: (suggestion) {
                          setState(() {
                            if (selectedLocationIds.contains(suggestion['id'])) {
                              selectedLocationIds.remove(suggestion['id']);
                            } else {
                              selectedLocationIds.add(suggestion['id']);
                            }
                          });
                          _applyFilters(); // ✅ apply location-wise filter
                        },
                        hideOnEmpty: true,
                        hideOnLoading: true,
                        builder: (context, controller, focusNode) {
                          return Container(
                            constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  // 🏷 Selected location chips
                                  ...selectedLocationIds.map((id) {
                                    final allLocations = requirements
                                        .expand((req) => (req['locations'] as List?) ?? [])
                                        .toList();
                                    final loc = allLocations.firstWhere(
                                          (l) => l['id'] == id,
                                      orElse: () => {'label': 'Unknown'},
                                    );
                                    return Chip(
                                      backgroundColor: kPrimaryColor.withOpacity(0.1),
                                      label: Text(
                                        loc['completeAddress'] ?? loc['name'] ?? 'Unknown',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      deleteIcon: const Icon(Icons.close_rounded,
                                          size: 16, color: Colors.black54),
                                      onDeleted: () {
                                        setState(() => selectedLocationIds.remove(id));
                                        _applyFilters();
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(color: kPrimaryColor.withOpacity(0.4)),
                                      ),
                                      visualDensity:
                                      const VisualDensity(horizontal: -2, vertical: -2),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    );
                                  }).toList(),

                                  // ✏️ Inline search input
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child:  ConstrainedBox(
                                      constraints:
                                      const BoxConstraints(minWidth: 100, maxWidth: 250),
                                      child: TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: InputBorder.none,
                                          hintText: "Search & select locations...",
                                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                                        ),
                                        style: GoogleFonts.poppins(
                                          fontSize: 13.5,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  )

                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),


                ],
              ),


              const SizedBox(height: 14),

              // ⚙️ MORE FILTERS + GRID TOGGLE ROW
              Row(
                children: [



                  // More Filters button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor:
                      showMoreFilters ? kPrimaryColor : Colors.white,
                      foregroundColor:
                      showMoreFilters ? Colors.white : Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: showMoreFilters
                              ? kPrimaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: showMoreFilters ? Colors.white : kPrimaryColor,
                    ),
                    label: Text(
                      showMoreFilters ? "Hide Filters" : "More Filters",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    onPressed: () {
                      setState(() => showMoreFilters = !showMoreFilters);
                    },
                  ),


                  // Grid/List toggle button




    ],
              ),
            ],
          ),




          const SizedBox(height: 10),
          _buildMoreFilters(),

          const SizedBox(height: 16),

          // --- Clear Filters Button ---
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.filter_alt_off_outlined, color: Colors.redAccent),
                label: Text(
                  "Clear All Filters",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.redAccent.withOpacity(0.08),
                ),
                onPressed: () {
                  setState(() {
                    /// 🔹 Reset all dropdowns & text fields
                    selectedCategory = "ALL";
                    selectedTransaction = "ALL";
                    selectedPropertyType = null;
                    selectedRooms = null;
                    selectedFurnishing = null;

                    minPriceC.clear();
                    maxPriceC.clear();
                    minSizeC.clear();
                    maxSizeC.clear();

                    /// 🔹 Reset location filters
                    selectedLocationIds.clear();

                    searchC.clear(); // ✅ clear text field

                    /// 🔹 Reset search
                    searchQuery = '';

                    /// 🔹 Reset show-my toggle
                    showMyRequirements = false;

                    /// ✅ Apply fresh filters (shows full list)
                    _applyFilters();
                  });
                },
              ),

            ],
          )
        ],
      ),
    );
  }

// ------------- MORE FILTERS SECTION -------------
  bool showMoreFilters = false;
  String? selectedPropertyType;
  String? selectedRooms;
  String? selectedFurnishing;

  Widget _buildMoreFilters() {
    if (!showMoreFilters) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minPriceC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Min Price",
                    suffixText: "AED",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _applyFilters(), // ✅ triggers live
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: maxPriceC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Max Price",
                    suffixText: "AED",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: minSizeC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Min Size",
                    suffixText: "sqft",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: maxSizeC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Max Size",
                    suffixText: "sqft",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
              ),
              /*const SizedBox(width: 12),

              ElevatedButton.icon(
                onPressed: _applyFilters, // ✅ apply manually
                icon: const Icon(Icons.filter_alt, size: 18),
                label: const Text("Apply"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),*/
            ],
          ),

          const SizedBox(height: 14),

          // --- Dropdowns Row ---

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedPropertyType,
                  decoration: const InputDecoration(
                    labelText: "All Property Types",
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: '', child: Text("All Property Types")),
                    ...propertyTypes.map<DropdownMenuItem<String>>((item) {
                      return DropdownMenuItem(
                        value: item['id'],
                        child: Text(item['name']),
                      );
                    }).toList(),
                  ],

                  onChanged: (val) {
                    setState(() => selectedPropertyType = val);
                    _applyFilters(); // ✅ apply instantly when changed
                  },

                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedRooms,
                  decoration: const InputDecoration(
                    labelText: "Any Rooms",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Any Rooms')),
                    DropdownMenuItem(value: '1', child: Text('1 Room')),
                    DropdownMenuItem(value: '2', child: Text('2 Rooms')),
                    DropdownMenuItem(value: '3', child: Text('3 Rooms')),
                    DropdownMenuItem(value: '4', child: Text('4 Rooms')),
                    DropdownMenuItem(value: '5', child: Text('5 Rooms')),
                    DropdownMenuItem(value: '5+', child: Text('5+ Rooms')),
                  ],
                  onChanged: (val) {
                    setState(() => selectedRooms = val);
                    _applyFilters(); // ✅ instantly filter
                  },
                ),


              ),
              const SizedBox(width: 10),
              Expanded(
                child:DropdownButtonFormField<String>(
                  value: selectedFurnishing,
                  decoration: const InputDecoration(
                    labelText: "Any Furnishing",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text("Any Furnishing")),
                    DropdownMenuItem(value: "FURNISHED", child: Text("Furnished")),
                    DropdownMenuItem(value: "SEMI_FURNISHED", child: Text("Semi Furnished")),
                    DropdownMenuItem(value: "UNFURNISHED", child: Text("Unfurnished")),
                  ],
                  onChanged: (val) {
                    setState(() => selectedFurnishing = val);
                    _applyFilters(); // ✅ trigger instant filtering
                  },
                ),

              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label,
      String value,
      String selected,
      Function(String) onTap,
      ) {
    final bool isActive = value == selected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isActive ? kPrimaryColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? kPrimaryColor : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: isActive
            ? [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ]
            : [],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 16,
                color: isActive ? Colors.white : kPrimaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: isActive ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }





// ------------------- BUILD REQUIREMENT LIST -------------------

// ------------------- REQUIREMENT CARD -------------------
  Widget _buildRequirementCard(Map<String, dynamic> e) {
    final broker = e['broker'] ?? {};
    final brokerId = widget.userData['broker']?['id'];
    final isOwnRequirement = e['brokerId'] == brokerId;
    String formatTransactionType(String value) {
      if (value.isEmpty) return "N/A";

      value = value.toLowerCase();

      if (value == "sale") return "Sale";
      if (value == "rent") return "Rent";
      if (value == "sale_and_rent") return "Sale and Rent";

      // fallback → first letter capital
      return value[0].toUpperCase() + value.substring(1);
    }

    final propertyType = e['propertyType']?['name'] ?? 'N/A';
    final category = e['category'] ?? 'N/A';
    final transactionType = e['transactionType'] ?? 'N/A';
    final listing = e['listingStatus'] ?? 'ACTIVE';
    final furnished = (e['furnishedStatus'] as List?)?.join(', ') ?? 'N/A';
    final rooms = (e['rooms'] as List?)?.join(', ') ?? 'N/A';
    final description = e['requirementDescription'] ?? '';
    final isActive = listing == 'ACTIVE';
    final createdAt = DateTime.tryParse(e['createdAt'] ?? '');
    final formattedDate =
    createdAt != null ? DateFormat('dd-MMM-yyyy').format(createdAt) : '-';
    final minPrice = e['minPrice'] ?? '-';
    final maxPrice = e['maxPrice'] ?? '-';
    final priceRange = transactionType == 'RENT'
        ? "AED $minPrice - $maxPrice /yr"
        : "AED $minPrice - $maxPrice";


    return Stack(
      children: [
        // 🔹 Base Card
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
                  child: Image.asset('assets/collabrix_logo.png',
                      fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 14),

              // 🔹 Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Checkbox + Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isOwnRequirement)
                          Checkbox(
                            value: selectedRequirementIds.contains(e['id']),
                            activeColor: kPrimaryColor,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  selectedRequirementIds.add(e['id']);
                                } else {
                                  selectedRequirementIds.remove(e['id']);
                                }

                                // ✅ Update selectAll only for own requirements
                                final ownReqs = requirements
                                    .where((r) => r['brokerId'] == brokerId)
                                    .toList();
                                selectAll = selectedRequirementIds.length ==
                                    ownReqs.length;
                              });
                            },
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e['title'] ?? 'Untitled Requirement',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Created on: $formattedDate",
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

                    // 💰 Price, Locations, Transaction Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _chipWithGradient(
                          Icons.monetization_on_rounded,
                          priceRange,
                          [Colors.green.shade400, Colors.green.shade600],
                        ),
                        ...(e['locations'] as List?)
                            ?.map((loc) => _chip(
                          Icons.location_on_outlined,
                          loc['completeAddress'] ??
                              loc['name'] ??
                              'Unknown',
                          Colors.redAccent,
                        ))
                            .toList() ??
                            [
                              _chip(Icons.location_on_outlined, 'N/A',
                                  Colors.redAccent),
                            ],
                        _chip(
                          Icons.swap_horiz_rounded,
                          'For ${formatTransactionType(transactionType)}',
                          Colors.indigo,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 🛏 Info Icons Row
                    Row(
                      children: [
                        _iconInfo(Icons.king_bed_outlined, "$rooms Rooms"),
                        _iconInfo(Icons.chair_alt_outlined, furnished),
                        _iconInfo(Icons.category_rounded, propertyType),
                        _iconInfo(Icons.apartment_rounded, category),
                      ],
                    ),

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    Divider(
                        color: Colors.grey.shade300, thickness: 1, height: 10),

                    // 🔘 Status Switch + Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 🟢 Status Switch (only if own)
                        if (isOwnRequirement)
                          Row(
                            children: [
                              Switch(
                                value: isActive,
                                activeColor: Colors.white,
                                activeTrackColor: Colors.green,
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: Colors.grey.shade400,
                                onChanged: (val) async {
                                  await _toggleStatus(e['id'], isActive);
                                },
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isActive ? "Active" : "Inactive",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color:
                                  isActive ? Colors.green : Colors.grey,
                                ),
                              ),
                            ],
                          )
                        else
                          const Spacer(), // ✅ keeps "View" aligned right

                        // ✏️ Edit + 👁 View
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isOwnRequirement)
                              _gradientButton(
                                icon: Icons.edit_outlined,
                                text: "Edit",
                                colors: const [
                                  Color(0xFFFFA726),
                                  Color(0xFFFF7043)
                                ],
                                onTap: () => _openEditDialog(e),
                              ),
                            const SizedBox(width: 10),
                            _gradientButton(
                              icon: Icons.visibility_outlined,
                              text: "View",
                              colors: const [
                                Color(0xFF1976D2),
                                Color(0xFF0D47A1)
                              ],
                              onTap: () {
                                setState(() {
                                  selectedRequirement = e;
                                  showDrawer = true;
                                });
                              },
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

        // 🟢 Floating ACTIVE Badge
        Positioned(
          top: 24,
          right: 24,
          child: _badge(
            listing,
            isActive ? Colors.green : Colors.grey,
            icon:
            isActive ? Icons.verified_rounded : Icons.block_rounded,
          ),
        ),

        // 👤 Broker Info (Bottom-Right)
        Positioned(
          bottom: 92,
          right: 18,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  "${broker['displayName'] ?? 'N/A'} ⭐ ${broker['rating'] ?? '-'}",
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: Colors.brown.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 💰 Gradient Chip (for price etc.)
  Widget _chipWithGradient(IconData icon, String text, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

// 📍 Solid Color Chip (for location, type, etc.)
  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

// ✏️ Gradient Button (for Edit/View)
  Widget _gradientButton({
    required IconData icon,
    required String text,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

// 🏷️ Badge (for floating Active/Inactive chip)
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


// ------------------- SMALL HELPERS -------------------
  Widget _iconInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade800,
            ),
            overflow: TextOverflow.visible,
          ),
        ),
        SizedBox(width: 12,)
      ],
    );
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
                "Change Requirement Status?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Do you want to change this requirement's status to $newStatus?",
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

  Future<void> _toggleStatus(String id, bool isActive) async {
    bool? confirm = true;
    final newStatus = isActive ? "INACTIVE" : "ACTIVE";

    confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildStatusChangeDialog(newStatus),
    );
    if (!confirm!) return;

    try {
      final token = await AuthService.getToken();
      final response = await http.put(
        Uri.parse('$baseURL/api/requirements/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',

        },
        body: jsonEncode({"listing_status": newStatus}),
      );

      print('new status -> $newStatus , url -> ${Uri.parse('$baseURL/api/requirements/$id')}');
      if (response.statusCode == 200) {
        /*ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text('Requirement marked as $newStatus successfully!')),
        );*/
        _fetchRequirements();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status')),
        );
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }



  Widget _buildTag(String text) {
    return Chip(
      label: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: Colors.teal.shade900,
        ),
      ),
      backgroundColor: Colors.teal.withOpacity(0.08),
      side: BorderSide(color: Colors.teal.withOpacity(0.25)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    );
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


  Future<void> _confirmBulkStatusChange() async {
    if (selectedRequirementIds.isEmpty) return;

    final confirm = await _showConfirmationDialog(
      "Change Status",
      "Do you want to toggle the status for all selected requirements?",
    );
    if (confirm != true) return;

    setState(() => isBulkStatusProcessing = true);

    try {
      final token = await AuthService.getToken();
      final brokerId = widget.userData['broker']?['id'];

      // ✅ Filter: Only include requirements owned by current broker
      final ownSelectedIds = selectedRequirementIds.where((id) {
        final req = requirements.firstWhere(
              (r) => r['id'].toString() == id.toString(),
          orElse: () => {},
        );
        return req['brokerId'] == brokerId;
      }).toList();

      // Skip if nothing owned
      if (ownSelectedIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No own requirements selected.')),
        );
        setState(() => isBulkStatusProcessing = false);
        return;
      }

      // 🔁 Loop only through own selected
      for (final id in ownSelectedIds) {
        final req = requirements.firstWhere(
              (r) => r['id'].toString() == id.toString(),
          orElse: () => {},
        );

        if (req.isEmpty) continue;

        final currentStatus =
        (req['listingStatus'] ?? req['listing_status'] ?? 'INACTIVE')
            .toString()
            .toUpperCase();
        final newStatus = currentStatus == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';

        await http.put(
          Uri.parse('$baseURL/api/requirements/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({"listing_status": newStatus}),
        );
      }

      await _fetchRequirements(); // Refresh the list
    } catch (e) {
      debugPrint("Bulk status update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status.')),
      );
    }

    setState(() {
      isBulkStatusProcessing = false;
      selectAll = false;
      selectedRequirementIds.clear();
    });
  }

  Future<void> _confirmBulkDelete() async {
    if (selectedRequirementIds.isEmpty) return;

    final confirm = await _showConfirmationDialog(
      "Delete Requirements",
      "Do you really want to delete all selected requirements?",
    );
    if (confirm != true) return;

    setState(() => isBulkDeleteProcessing = true);

    try {
      final token = await AuthService.getToken();
      final brokerId = widget.userData['broker']?['id'];

      // ✅ Filter: Only delete own requirements
      final ownSelectedIds = selectedRequirementIds.where((id) {
        final req = requirements.firstWhere(
              (r) => r['id'].toString() == id.toString(),
          orElse: () => {},
        );
        return req['brokerId'] == brokerId;
      }).toList();

      if (ownSelectedIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No own requirements selected for deletion.')),
        );
        setState(() => isBulkDeleteProcessing = false);
        return;
      }

      for (final id in ownSelectedIds) {
        await http.delete(
          Uri.parse('$baseURL/api/requirements/$id'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected requirements deleted successfully!')),
      );
      await _fetchRequirements();
    } catch (e) {
      debugPrint("Bulk delete error: $e");
    }

    setState(() {
      isBulkDeleteProcessing = false;
      selectAll = false;
      selectedRequirementIds.clear();
    });
  }



  // ============ PAGINATION ============
  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: currentPage > 1
              ? () => _fetchRequirements(page: currentPage - 1)
              : null,
        ),
        Text("Page $currentPage of $totalPages",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages
              ? () => _fetchRequirements(page: currentPage + 1)
              : null,
        ),
      ],
    );
  }

  void _applyFilters() {
    final brokerId = widget.userData['broker']?['id'];

    // 👤 Base list (Show My Requirements or All)
    List filtered = showMyRequirements
        ? requirements.where((r) => r['brokerId'] == brokerId).toList()
        : List.from(requirements);

    // 🏢 Category Filter
    if (selectedCategory != null &&
        selectedCategory!.isNotEmpty &&
        selectedCategory != "ALL") {
      filtered = filtered.where((r) {
        final cat = r['category']?.toString().toUpperCase() ?? '';
        return cat == selectedCategory!.toUpperCase();
      }).toList();
    }


    // 🔁 Transaction Type Filter
    if (selectedTransaction != null &&
        selectedTransaction!.isNotEmpty &&
        selectedTransaction != "ALL") {
      filtered = filtered.where((r) {
        final type = r['transactionType']?.toString().toUpperCase() ?? '';
        return type == selectedTransaction!.toUpperCase();
      }).toList();
    }

    // 🏠 Property Type Filter
    if (selectedPropertyType != null && selectedPropertyType!.isNotEmpty) {
      filtered = filtered
          .where((r) => r['propertyTypeId'] == selectedPropertyType)
          .toList();
    }


    // 🛏 Rooms Filter
    if (selectedRooms != null && selectedRooms!.isNotEmpty) {
      filtered = filtered.where((r) {
        final roomList = (r['rooms'] as List?)
            ?.map((e) => int.tryParse(e.toString()) ?? 0)
            .toList() ??
            [];

        if (selectedRooms == '5+') {
          // ✅ Include all with 5 or more rooms
          return roomList.any((room) => room >= 5);
        } else {
          final selectedRoomNum = int.tryParse(selectedRooms!) ?? 0;
          return roomList.contains(selectedRoomNum);
        }
      }).toList();
    }

    // 🪑 Furnishing Filter
    if (selectedFurnishing != null && selectedFurnishing!.isNotEmpty) {
      filtered = filtered.where((r) {
        final furnishingList = (r['furnishedStatus'] as List?)
            ?.map((e) => e.toString().toUpperCase())
            .toList() ??
            [];

        return furnishingList.contains(selectedFurnishing!.toUpperCase());
      }).toList();
    }


    // 📍 Location Filter (multi-select)
    if (selectedLocationIds.isNotEmpty) {
      filtered = filtered.where((r) {
        final locations = (r['locations'] as List?) ?? [];
        final locationIds = locations
            .map((loc) => loc['id']?.toString())
            .whereType<String>()
            .toList();
        return selectedLocationIds.any(
                (selId) => locationIds.contains(selId.toString()));
      }).toList();
    }

    // 💰 Price Range Filter
    final minPrice = double.tryParse(minPriceC.text) ?? 0;
    final maxPrice = double.tryParse(maxPriceC.text) ?? double.infinity;
    if (minPriceC.text.isNotEmpty || maxPriceC.text.isNotEmpty) {
      filtered = filtered.where((r) {
        final rMin = double.tryParse(
          (r['minPrice'] ?? '').toString().replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
            0;

        final rMax = double.tryParse(
          (r['maxPrice'] ?? '').toString().replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
            0;

        return (rMax >= minPrice && rMin <= maxPrice);
      }).toList();
    }

    // 📏 Size Range Filter
    final minSize = double.tryParse(minSizeC.text) ?? 0;
    final maxSize = double.tryParse(maxSizeC.text) ?? double.infinity;
    if (minSizeC.text.isNotEmpty || maxSizeC.text.isNotEmpty) {
      filtered = filtered.where((r) {
        final rMin = double.tryParse(
            (r['minSizeSqft'] ?? '').toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        final rMax = double.tryParse(
            (r['maxSizeSqft'] ?? '').toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

        return (rMax >= minSize && rMin <= maxSize);
      }).toList();
    }

    // 🔍 Search Filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        final title = r['title']?.toString().toLowerCase() ?? '';
        final desc =
            r['requirementDescription']?.toString().toLowerCase() ?? '';
        final locationNames = (r['locations'] as List?)
            ?.map((l) =>
            (l['name'] ?? l['completeAddress'] ?? '')
                .toString()
                .toLowerCase())
            .join(' ') ??
            '';
        return title.contains(searchQuery) ||
            desc.contains(searchQuery) ||
            locationNames.contains(searchQuery);
      }).toList();
    }

    setState(() => filteredRequirements = filtered);
  }


  // ================= RIGHT-SIDE DRAWER PANEL =================

  @override
  Widget build(BuildContext context) {
    final list = filteredRequirements.isNotEmpty ? filteredRequirements : [];
    final brokerId = widget.userData['broker']?['id'];
    final ownFilteredRequirements = filteredRequirements
        .where((r) => r['brokerId'] == brokerId)
        .toList();
    return Stack(
      children: [
        Scaffold(
          backgroundColor: backgroundColor,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 18,),

                /// 🧭 Fixed Header (stays on top)
                _buildHeader(),
                const SizedBox(height: 10),

                /// 🧾 Scrollable Content (everything below header)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterPanel(),

                        if (requirements.isNotEmpty && ownFilteredRequirements.length>0)
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
                            child: Builder(builder: (context) {
                              final brokerId = widget.userData['broker']?['id'];
                              final ownFilteredRequirements = filteredRequirements
                                  .where((r) => r['brokerId'] == brokerId)
                                  .toList();

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // 🔘 Select All Checkbox + Count
                                  Row(
                                    children: [
                                      if(ownFilteredRequirements.length>0)

                                        Checkbox(
                                        value: selectAll,
                                        activeColor: kPrimaryColor,
                                        onChanged: (checked) {
                                          setState(() {
                                            selectAll = checked ?? false;

                                            if (selectAll) {
                                              // ✅ Only select your own requirements
                                              selectedRequirementIds = ownFilteredRequirements
                                                  .map((e) => e['id'].toString())
                                                  .toList();
                                            } else {
                                              selectedRequirementIds.clear();
                                            }
                                          });
                                        },
                                      ),
                                      if(ownFilteredRequirements.length>0)
                                      Text(
                                        "Select All",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "${selectedRequirementIds.length} out of ${ownFilteredRequirements.length} selected",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13.5,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),

                                  if(ownFilteredRequirements.length>0)

                                  // 🔘 Action Buttons
                                  Row(
                                    children: [
                                      if (isBulkStatusProcessing)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 12),
                                          child: SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      ElevatedButton.icon(
                                        onPressed: isBulkStatusProcessing ||
                                            selectedRequirementIds.isEmpty
                                            ? null
                                            : () => _confirmBulkStatusChange(),
                                        icon: const Icon(Icons.sync_alt_rounded, size: 18),
                                        label: Text(
                                          isBulkStatusProcessing
                                              ? "Updating..."
                                              : "Change Status",
                                          style:
                                          GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kPrimaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      if (isBulkDeleteProcessing)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 12),
                                          child: SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      ElevatedButton.icon(
                                        onPressed: isBulkDeleteProcessing ||
                                            selectedRequirementIds.isEmpty
                                            ? null
                                            : () => _confirmBulkDelete(),
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        label: Text(
                                          isBulkDeleteProcessing
                                              ? "Deleting..."
                                              : "Delete",
                                          style:
                                          GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }),
                          ),

                        /// 🧱 Grid/List Section
                        isLoading
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 80),
                              AnimatedLogoLoader(assetPath: 'assets/collabrix_logo.png'),
                            ],
                          ),
                        )
                            : list.isEmpty
                            ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 100),
                            child: Text(
                              "No requirements found",
                              style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey),
                            ),
                          ),
                        )
                            : gridView
                            ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width < 900 ? 2 : 3,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.78,
                          ),

                          itemCount: list.length,
                          itemBuilder: (_, i) =>
                              _buildRequirementGridCard(list[i], i),
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: list.length,
                          itemBuilder: (_, i) =>
                              _buildRequirementCard(list[i]),
                        ),

                        const SizedBox(height: 20),

                        /// 🔻 Pagination
                        _buildPagination(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ===== Drawer overlay background =====
        if (showDrawer)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            opacity: showDrawer ? 0.4 : 0.0,
            child: GestureDetector(
              onTap: () => setState(() => showDrawer = false),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),

        // --- Drawer Panel Animation ---
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          right: showDrawer ? 0 : -MediaQuery.of(context).size.width * 0.45,
          top: 0,
          bottom: 0,
          child: AnimatedOpacity(
            opacity: showDrawer ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: AnimatedScale(
              scale: showDrawer ? 1.0 : 0.96,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              child: buildRequirementDrawerPanel(
                context,
                selectedRequirement ?? {},
                    () => setState(() => showDrawer = false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSegment({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? kPrimaryColor
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
            : [],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: kPrimaryColor.withOpacity(0.2),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : kPrimaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : kPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget buildRequirementDrawerPanel(BuildContext context, Map<String, dynamic> req, VoidCallback onClose) {
    final broker = req['broker'] ?? {};
    final location = (req['locations'] != null && req['locations'].isNotEmpty)
        ? req['locations'][0]['completeAddress']
        : 'N/A';

    final priceRange = (req['transactionType'] == 'RENT')
        ? "AED ${req['minPrice']} - ${req['maxPrice']} /yr"
        : "AED ${req['minPrice']} - ${req['maxPrice']}";
    // 🌐 Social Links Section
    final social = broker['socialLinks'] as Map<String, dynamic>? ?? {};

    final hasAnySocial = [
      social['linkedin'],
      social['instagram'],
      social['facebook'],
      social['twitter'],
    ].any((link) => link != null && link.toString().isNotEmpty);

    return Material(
      color: Colors.white,
      elevation: 20,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        bottomLeft: Radius.circular(30),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            bottomLeft: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.1),
              blurRadius: 25,
              spreadRadius: 3,
              offset: const Offset(-5, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(26),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [kPrimaryColor, kAccentColor],
                      ).createShader(bounds),
                      child: Text("Requirement Overview",
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [kPrimaryColor.withOpacity(0.9), kAccentColor],
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: onClose,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // --- Requirement Info ---
                _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(Icons.apartment_rounded, "Requirement Details"),
                      const SizedBox(height: 10),

                      // 🏷️ Basic Info
                      _infoRow(Icons.title_rounded, "Title", req['title']),
                      _infoRow(Icons.apartment_rounded, "Property Type", req['propertyTypeName']),
                      _infoRow(Icons.location_on_outlined, "Location", location),
                      _infoRow(Icons.numbers_rounded, "Reference", req['referenceNumber']),
                      _infoRow(Icons.category_outlined, "Category", req['category']),
                      _infoRow(Icons.compare_arrows_rounded, "Type", req['transactionType']),
                      _infoRow(Icons.timeline_rounded, "Listing", req['listingStatus']),

                      const SizedBox(height: 10),

                      // 💰 Price Range
                      _sectionHeader(Icons.monetization_on_rounded, "Price Range"),
                      const SizedBox(height: 6),
                      _infoRow(Icons.trending_up_rounded, "Min Price", "AED ${req['minPrice'] ?? 'N/A'}"),
                      _infoRow(Icons.trending_down_rounded, "Max Price", "AED ${req['maxPrice'] ?? 'N/A'}"),

                      const SizedBox(height: 10),

                      // 📏 Size Range
                      _sectionHeader(Icons.square_foot_rounded, "Size Range (sqft)"),
                      const SizedBox(height: 6),
                      _infoRow(Icons.expand_less_rounded, "Min Size", "${req['minSizeSqft'] ?? 'N/A'} sqft"),
                      _infoRow(Icons.expand_more_rounded, "Max Size", "${req['maxSizeSqft'] ?? 'N/A'} sqft"),

                      const SizedBox(height: 10),

                      // 📝 Description
                      _sectionHeader(Icons.description_outlined, "Description"),
                      const SizedBox(height: 6),
                      Text(
                        req['requirementDescription']?.toString().isNotEmpty == true
                            ? req['requirementDescription']
                            : 'No description provided',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),




                const SizedBox(height: 10),

                // --- Broker Info ---
                _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(Icons.person_pin_rounded, "Broker Information"),
                      const SizedBox(height: 14),

                      // 👤 Broker Profile Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(
                              broker['user']?['avatar'] ??
                                  'https://via.placeholder.com/100',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  broker['displayName'] ?? 'N/A',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                Text(
                                  broker['email'] ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey.shade700),
                                ),
                                Text(
                                  broker['mobile'] ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 🏢 Basic Info
                      _infoRow(Icons.location_city_rounded, "Address", broker['address']),
                      _infoRow(Icons.web_asset_rounded, "Website", broker['website']),
                      _infoRow(Icons.badge_rounded, "RERA", broker['reraNumber']),


          if (hasAnySocial) ...[
        const SizedBox(height: 18),
    _sectionHeader(Icons.share_rounded, "Social Links"),
    const SizedBox(height: 10),
    Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
    if (social['linkedin'] != null && social['linkedin'].toString().isNotEmpty)
    _socialIconButton(
      icon: FontAwesomeIcons.linkedin, // ✅ authentic icon
    label: "Linkedin",
    url: social['linkedin'],
    iconColor: const Color(0xFF0A66C2),
    ),
    if (social['instagram'] != null && social['instagram'].toString().isNotEmpty)
    _socialIconButton(
      icon: FontAwesomeIcons.instagram, // ✅ authentic icon
    label: "Instagram",
    url: social['instagram'],
    iconColor: const Color(0xFFE4405F),
    ),
    if (social['facebook'] != null && social['facebook'].toString().isNotEmpty)
    _socialIconButton(
      icon: FontAwesomeIcons.facebook, // ✅ authentic icon
    label: "Facebook",
    url: social['facebook'],
    iconColor: const Color(0xFF1877F2),
    ),
    if (social['twitter'] != null && social['twitter'].toString().isNotEmpty)
    _socialIconButton(
      icon: FontAwesomeIcons.xTwitter, // ✅ authentic icon
    label: "Twitter",
    url: social['twitter'],
    iconColor: Colors.black,
    ),
    ],
    ),
    ],


    // ⭐ Specializations
                      if (broker['specializations'] != null &&
                          broker['specializations'].isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _sectionHeader(Icons.star_rate_rounded, "Specializations"),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: List.generate(
                            broker['specializations'].length,
                                (i) => _tag(broker['specializations'][i]),
                          ),
                        ),
                      ],

                      // 🌍 Languages
                      if (broker['languages'] != null &&
                          broker['languages'].isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _sectionHeader(Icons.language_rounded, "Languages"),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: List.generate(
                            broker['languages'].length,
                                (i) => _tag(broker['languages'][i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),






              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialIconButton({
    required IconData icon,
    required String label,
    required String url,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [kPrimaryColor, kAccentColor],
          ).createShader(bounds),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 14.5, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [kPrimaryColor, kAccentColor],
            ).createShader(bounds),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13.5),
                children: [
                  TextSpan(
                      text: "$label: ",
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(
                      text: value != null && value.toString().isNotEmpty
                          ? value.toString()
                          : "N/A",
                      style: const TextStyle(fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(color: kPrimaryColor, fontSize: 12.5),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }


  List<Map<String, dynamic>> formattedLocations = [];

  void _prepareLocations(List<dynamic> allLocations) {
    formattedLocations = allLocations.map<Map<String, dynamic>>((loc) {
      final parent = loc['parent'] != null ? loc['parent']['name'] : '';
      final label = parent.isNotEmpty ? "${loc['name']} ($parent)" : loc['name'];
      return {'id': loc['id'], 'label': label};
    }).toList();
  }


// ============ CREATE & EDIT REQUIREMENT DIALOGS ============


// ---------------- CREATE DIALOG ----------------
  Future<void> _openCreateDialog() async {
    final tagController = TextEditingController();
    List<Map<String, dynamic>> allTags = [];
    List<String> selectedTagIds = [];

    Future<void> _fetchTags() async {
      try {
        final token = await AuthService.getToken();
        final res = await http.get(
          Uri.parse('$baseURL/api/tags'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          allTags = List<Map<String, dynamic>>.from(data['data']);
        } else {
          debugPrint("Failed to fetch tags: ${res.statusCode}");
        }
      } catch (e) {
        debugPrint("Error fetching tags: $e");
      }
    }

    await _fetchTags();

    await _fetchPropertyTypesAndLocations();

    final formKey = GlobalKey<FormState>();
    final titleC = TextEditingController();
    final refC = TextEditingController();
    final descC = TextEditingController();
    final minPriceC = TextEditingController();
    final maxPriceC = TextEditingController();
    final minSizeC = TextEditingController();
    final maxSizeC = TextEditingController();

    String? propertyTypeId;
    List<String> locationIds = [];
    String transactionType = 'SALE';
    String category = 'RESIDENTIAL';
    String? rooms;
    String? furnishedStatus;
    List<String> keywords = [];
    bool isSubmitting = false;

    InputDecoration modernInputDecoration({
      required String label,
      required IconData icon,
      String? hint,
      String? suffix,
    }) {
      return InputDecoration(
        prefixIcon: Icon(icon, color: kPrimaryColor),
        suffixText: suffix,
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kPrimaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      );
    }

    await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return Dialog(
              backgroundColor: Colors.white,
              elevation: 12,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;

                return StatefulBuilder(
                    builder: (context, setDialogState) {
                      Future<void> submit() async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSubmitting = true);

                        try {
                          final token = await AuthService.getToken();
                          final autoExpireDate = DateTime.now()
                              .add(const Duration(days: 30))
                              .toIso8601String();

                          final body = {
                            "title": titleC.text.trim(),
                            "reference_number": refC.text.trim(),
                            "requirement_description": descC.text.trim(),
                            "property_type_id": propertyTypeId,
                            "location_ids": locationIds,
                            if (widget.userData['role'].toLowerCase() == 'admin')
                              "broker_id": widget.userData['broker']['id'],
                            "rooms": rooms != null ? [rooms] : [],
                            "min_size_sqft": int.tryParse(minSizeC.text) ?? 0,
                            "max_size_sqft": int.tryParse(maxSizeC.text) ?? 0,
                            "min_price": int.tryParse(minPriceC.text) ?? 0,
                            "max_price": int.tryParse(maxPriceC.text) ?? 0,
                            "furnished_status":
                            furnishedStatus != null ? [furnishedStatus] : [],
                            "category": category,
                            "keywords_tag_ids": selectedTagIds,
                            "transaction_type": transactionType,
                            "is_mortgage_buyer": false,
                            "auto_expire_date": autoExpireDate,
                          };

                          final res = await http.post(
                            Uri.parse('$baseURL/api/requirements'),
                            headers: {
                              'Content-Type': 'application/json',
                              'Authorization': 'Bearer $token',
                            },
                            body: json.encode(body),
                          );

                          if (res.statusCode == 200 || res.statusCode == 201) {
                            Navigator.pop(context);
                            _fetchRequirements();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                  Text('Requirement created successfully!')),
                            );
                          } else {
                            debugPrint("Failed: ${res.body}");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: ${res.statusCode}')),
                            );
                          }
                        } catch (e) {
                          debugPrint("Error posting requirement: $e");
                        } finally {
                          setDialogState(() => isSubmitting = false);
                        }
                      }

                      return ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: SingleChildScrollView(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                              child: Form(
                                  key: formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                    // Header
                                    Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Post a Requirement",
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 26),
                                        color: Colors.grey.shade700,
                                        onPressed: () => Navigator.pop(context),
                                        splashRadius: 22,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // All top fields
                                  Wrap(
                                    spacing: 20,
                                    runSpacing: 20,
                                    children: [
                                  SizedBox(
                                  width: isWide ? 400 : double.infinity,
                                    child: TextFormField(
                                      controller: titleC,
                                      decoration: modernInputDecoration(
                                        label: "Requirement Title *",
                                        icon: Icons.title_rounded,
                                        hint:
                                        "e.g., Young couple seeking 2BR in Downtown",
                                      ),
                                      validator: (v) =>
                                      v!.isEmpty ? "Enter title" : null,
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? 400 : double.infinity,
                                    child: TextFormField(
                                      controller: refC,
                                      decoration: modernInputDecoration(
                                        label: "Reference Number *",
                                        icon: Icons.confirmation_number_outlined,
                                        hint: "e.g., REQ-001",
                                      ),
                                      validator: (v) =>
                                      v!.isEmpty ? "Enter reference" : null,
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? 400 : double.infinity,
                                    child: DropdownButtonFormField<String>(
                                      value: transactionType,
                                      decoration: modernInputDecoration(
                                        label: "Looking To",
                                        icon: Icons.swap_horiz_rounded,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                            value: "SALE", child: Text("Buy")),
                                        DropdownMenuItem(
                                            value: "RENT", child: Text("Rent")),
                                        DropdownMenuItem(
                                            value: "SALE_AND_RENT",
                                            child: Text("Rent & Buy")),
                                      ],
                                      onChanged: (v) =>
                                          setDialogState(() => transactionType = v!),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? 400 : double.infinity,
                                    child: DropdownButtonFormField<String>(
                                      value: category,
                                      decoration: modernInputDecoration(
                                        label: "Property Category",
                                        icon: Icons.category_outlined,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                            value: "RESIDENTIAL",
                                            child: Text("Residential")),
                                        DropdownMenuItem(
                                            value: "COMMERCIAL",
                                            child: Text("Commercial")),
                                      ],
                                      onChanged: (v) =>
                                          setDialogState(() => category = v!),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? 400 : double.infinity,
                                    child: DropdownButtonFormField<String>(
                                      decoration: modernInputDecoration(
                                        label: "Property Type *",
                                        icon: Icons.apartment_rounded,
                                      ),
                                      value: propertyTypeId,
                                      items: propertyTypes
                                          .map<DropdownMenuItem<String>>((item) =>
                                          DropdownMenuItem(
                                            value: item['id'],
                                            child: Text(item['name']),
                                          ))
                                          .toList(),
                                      onChanged: (val) =>
                                          setDialogState(() => propertyTypeId = val),
                                      validator: (v) =>
                                      v == null ? "Select property type" : null,
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? 400 : double.infinity,
                                    child: DropdownButtonFormField<String>(
                                      value: rooms,
                                      decoration: modernInputDecoration(
                                        label: "Rooms",
                                        icon: Icons.meeting_room_outlined,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                            value: "Studio", child: Text("Studio")),
                                        DropdownMenuItem(value: "1", child: Text("1")),
                                        DropdownMenuItem(value: "2", child: Text("2")),
                                        DropdownMenuItem(value: "3", child: Text("3")),
                                        DropdownMenuItem(value: "4", child: Text("4")),
                                        DropdownMenuItem(value: "5", child: Text("5")),
                                        DropdownMenuItem(
                                            value: "5+", child: Text("5+")),
                                      ],
                                      onChanged: (v) =>
                                          setDialogState(() => rooms = v),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? 400 : double.infinity,
                                    child: DropdownButtonFormField<String>(
                                      value: furnishedStatus,
                                      decoration: modernInputDecoration(
                                        label: "Furnished Status",
                                        icon: Icons.chair_alt_rounded,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                            value: "Furnished",
                                            child: Text("Furnished")),
                                        DropdownMenuItem(
                                            value: "Semi-Furnished",
                                            child: Text("Semi-Furnished")),
                                        DropdownMenuItem(
                                            value: "Unfurnished",
                                            child: Text("Unfurnished")),
                                      ],
                                      onChanged: (v) =>
                                          setDialogState(() => furnishedStatus = v),
                                    ),
                                  ),
                                      // 🏙️ Locations Section
                                      SizedBox(
                                        width: isWide ? 820 : double.infinity,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Preferred Locations *",
                                                style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 6),
                                            TypeAheadField<Map<String, dynamic>>(
                                              suggestionsCallback: (pattern) {
                                                if (pattern.isEmpty) {
                                                  return formattedLocations;
                                                }
                                                return formattedLocations
                                                    .where((loc) => loc['label']
                                                    .toLowerCase()
                                                    .contains(
                                                    pattern.toLowerCase()))
                                                    .toList();
                                              },
                                              itemBuilder: (context, suggestion) {
                                                final isSelected = locationIds
                                                    .contains(suggestion['id']);
                                                return ListTile(
                                                  leading: Icon(Icons.location_on,
                                                      color: kPrimaryColor),
                                                  title: Text(suggestion['label']),
                                                  trailing: isSelected
                                                      ? Icon(Icons.check_circle,
                                                      color: kPrimaryColor)
                                                      : null,
                                                );
                                              },
                                              onSelected: (suggestion) {
                                                setDialogState(() {
                                                  if (locationIds
                                                      .contains(suggestion['id'])) {
                                                    locationIds.remove(suggestion['id']);
                                                  } else {
                                                    locationIds.add(suggestion['id']);
                                                  }
                                                });
                                              },
                                              builder: (context, controller, focusNode) {
                                                return TextField(
                                                  controller: controller,
                                                  focusNode: focusNode,
                                                  decoration: modernInputDecoration(
                                                    label: "Search Locations",
                                                    icon: Icons.search_rounded,
                                                    hint:
                                                    "Search & select multiple locations",
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: locationIds.map((id) {
                                                final loc = formattedLocations.firstWhere(
                                                      (l) => l['id'] == id,
                                                  orElse: () => {},
                                                );
                                                if (loc.isEmpty) return const SizedBox();

                                                return AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200),
                                                  curve: Curves.easeOut,
                                                  decoration: BoxDecoration(
                                                    color: kPrimaryColor,
                                                    borderRadius:
                                                    BorderRadius.circular(30),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black12
                                                            .withOpacity(0.05),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 3),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 14, vertical: 8),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.location_on,
                                                            color: Colors.white, size: 16),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          loc['label'],
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 13.5,
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        GestureDetector(
                                                          onTap: () => setDialogState(
                                                                  () => locationIds.remove(id)),
                                                          child: const Icon(
                                                              Icons.close_rounded,
                                                              size: 17,
                                                              color: Colors.white),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 💰 Price Range
                                      SizedBox(
                                        width: isWide ? 400 : double.infinity,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                keyboardType: TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                ],
                                                controller: minPriceC,
                                                decoration: modernInputDecoration(
                                                  label: "Min Price",
                                                  icon: Icons.attach_money_rounded,
                                                  suffix: "AED د.إ",
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextFormField(
                                                keyboardType: TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                ],
                                                controller: maxPriceC,
                                                decoration: modernInputDecoration(
                                                  label: "Max Price",
                                                  icon: Icons.attach_money_rounded,
                                                  suffix: "AED د.إ",
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 📏 Size Range
                                      SizedBox(
                                        width: isWide ? 400 : double.infinity,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: minSizeC,
                                                keyboardType: TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                ],
                                                decoration: modernInputDecoration(
                                                  label: "Min Size",
                                                  icon: Icons.square_foot_rounded,
                                                  suffix: "sqft",
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextFormField(
                                                controller: maxSizeC,
                                                keyboardType: TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                ],
                                                decoration: modernInputDecoration(
                                                  label: "Max Size",
                                                  icon: Icons.square_foot_rounded,
                                                  suffix: "sqft",
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                      const SizedBox(height: 24),

                                      // 🏷️ Tags Section
                                      Text("Tags", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),

                                      TypeAheadField<Map<String, dynamic>>(
                                        suggestionsCallback: (pattern) {
                                          final query = pattern.toLowerCase();
                                          return allTags.where((tag) {
                                            final name = (tag['name'] ?? '').toLowerCase();
                                            return name.contains(query) && !selectedTagIds.contains(tag['id']);
                                          }).toList();
                                        },
                                        itemBuilder: (context, suggestion) {
                                          return ListTile(
                                            leading: const Icon(Icons.sell_outlined, color: Colors.teal),
                                            title: Text(
                                              suggestion['name'],
                                              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                            ),
                                            trailing: Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: kPrimaryColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          );
                                        },
                                        onSelected: (suggestion) {
                                          setDialogState(() {
                                            selectedTagIds.add(suggestion['id']);
                                          });
                                        },
                                        builder: (context, controller, focusNode) {
                                          return TextField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            decoration: modernInputDecoration(
                                              label: "Search Tags",
                                              icon: Icons.sell_outlined,
                                              hint: "Search & select multiple tags",
                                            ),
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 8),

// Display Selected Tag Chips
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: selectedTagIds.map((id) {
                                          final tag = allTags.firstWhere(
                                                (t) => t['id'] == id,
                                            orElse: () => {},
                                          );
                                          if (tag.isEmpty) return const SizedBox();


                                          return AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            decoration: BoxDecoration(
                                              color: kPrimaryColor,
                                              borderRadius: BorderRadius.circular(30),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12.withOpacity(0.05),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.sell_outlined, color: Colors.white, size: 16),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    tag['name'] ?? '',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  GestureDetector(
                                                    onTap: () => setDialogState(() => selectedTagIds.remove(id)),
                                                    child: const Icon(Icons.close_rounded, size: 17, color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),

                                      const SizedBox(height: 24),

                                      // 📝 Description
                                      TextFormField(
                                        controller: descC,
                                        maxLines: 4,
                                        decoration: modernInputDecoration(
                                          label: "Requirement Description *",
                                          icon: Icons.description_outlined,
                                          hint: "Describe your client's needs in detail...",
                                        ),
                                        validator: (v) =>
                                        v!.isEmpty ? "Enter description" : null,
                                      ),

                                      const SizedBox(height: 32),

                                      // 🚀 Submit Button
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          onPressed: isSubmitting ? null : submit,
                                          icon: isSubmitting
                                              ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2, color: Colors.white),
                                          )
                                              : const Icon(Icons.send_rounded,
                                              color: Colors.white),
                                          label: Text(
                                            isSubmitting ? "Posting..." : "Post Requirement",
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kPrimaryColor,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 28, vertical: 14),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14)),
                                            elevation: 5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ),
                          ),
                      );
                    },
                );
              }),
          );
        },
    );
  }

// Add this field at the top of your State class
  int hoveredIndex = -1;

  Widget _buildRequirementGridCard(Map<String, dynamic> e, int index) {
    final broker = e['broker'] ?? {};
    final brokerId = widget.userData['broker']?['id'];
    final isOwnRequirement = e['brokerId'] == brokerId;
    String formatTransactionType(String value) {
      if (value.isEmpty) return "N/A";

      value = value.toLowerCase();

      if (value == "sale") return "Sale";
      if (value == "rent") return "Rent";
      if (value == "sale_and_rent") return "Sale and Rent";

      // fallback → first letter capital
      return value[0].toUpperCase() + value.substring(1);
    }

    final propertyType = e['propertyType']?['name'] ?? 'N/A';
    final location = (e['locations'] != null && e['locations'].isNotEmpty)
        ? e['locations'][0]['completeAddress']
        : 'N/A';
    final category = e['category'] ?? 'N/A';
    final transactionType = e['transactionType'] ?? 'N/A';
    final listing = e['listingStatus'] ?? 'ACTIVE';
    final furnished = (e['furnishedStatus'] as List?)?.join(', ') ?? 'N/A';
    final rooms = (e['rooms'] as List?)?.join(', ') ?? 'N/A';
    final description = e['requirementDescription'] ?? '';
    final isActive = listing == 'ACTIVE';
    final createdAt = DateTime.tryParse(e['createdAt'] ?? '');
    final formattedDate =
    createdAt != null ? DateFormat('dd-MMM-yyyy').format(createdAt) : '-';
    final minPrice = e['minPrice'] ?? '-';
    final maxPrice = e['maxPrice'] ?? '-';
    final priceRange = transactionType == 'RENT'
        ? "AED $minPrice - $maxPrice /yr"
        : "AED $minPrice - $maxPrice";

    final bool isHovered = hoveredIndex == index;
    final bool isSelected = selectedRequirementIds.contains(e['id']);

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit: (_) => setState(() => hoveredIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform:
        isHovered ? (Matrix4.identity()..translate(0.0, -6.0, 0.0)) : Matrix4.identity(),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.06),
              blurRadius: isHovered ? 12 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Title + Date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOwnRequirement)
                  Checkbox(
                  value:  isSelected,
                  activeColor: kPrimaryColor,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selectedRequirementIds.add(e['id']);
                      } else {
                        selectedRequirementIds.remove(e['id']);
                      }
                      final ownReqs = requirements
                          .where((r) => r['brokerId'] == brokerId)
                          .toList();
                      selectAll = selectedRequirementIds.length == ownReqs.length;
                    });
                  },
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e['title'] ?? 'Untitled Requirement',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Created on: $formattedDate",
                      style:
                      GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),

              ],
            ),

            const SizedBox(height: 8),

            // 💰 Price + Location + Type chips
            // 💰 Price, Locations (multi), Transaction Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chipWithGradient(
                  Icons.monetization_on_rounded,
                  priceRange,
                  [Colors.green.shade400, Colors.green.shade600],
                ),

                // 📍 Multiple Location Chips
                ...(e['locations'] as List?)
                    ?.map((loc) => _chip(
                  Icons.location_on_outlined,
                  loc['completeAddress'] ?? loc['name'] ?? 'Unknown',
                  Colors.redAccent,
                ))
                    .toList() ??
                    [
                      _chip(Icons.location_on_outlined, 'N/A', Colors.redAccent),
                    ],

                _chip(
                  Icons.swap_horiz_rounded,
                  'For ${formatTransactionType(transactionType)}',
                  Colors.indigo,
                ),
              ],
            ),


            const SizedBox(height: 8),

            // 🛏 Info (all 4 in one wrap)
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _iconInfo(Icons.king_bed_outlined, "$rooms Rooms"),
                _iconInfo(Icons.chair_alt_outlined, furnished),
                _iconInfo(Icons.category_rounded, propertyType),
                _iconInfo(Icons.apartment_rounded, category),
              ],
            ),


            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54, height: 1.4),
              ),
            ],

            const Spacer(),

            // 👤 Broker info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      "${broker['displayName'] ?? 'N/A'} ⭐ ${broker['rating'] ?? '-'}",
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

            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade300, thickness: 1, height: 10),
            const SizedBox(height: 6),

            // 🔘 Status switch + Edit/View
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isOwnRequirement)
                // 🟢 Active switch
                Row(
                  children: [
                    Switch(
                      value: isActive,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade400,
                      onChanged: (val) async {
                        await _toggleStatus(e['id'], isActive);
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? "Active" : "Inactive",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                )
                else
                const Spacer(), // keeps alignment for others
                // ✏️ Edit + 👁 View
                Row(
                  children: [
                    if (isOwnRequirement)
                      _gradientButton(
                      icon: Icons.edit_outlined,

                      text: "Edit",
                      colors: const [Color(0xFFFFA726), Color(0xFFFF7043)],
                      onTap: () => _openEditDialog(e),
                    ),
                    if (isOwnRequirement) const SizedBox(width: 8),
                    _gradientButton(
                      icon: Icons.visibility_outlined,
                      text: "View",
                      colors: const [Color(0xFF1976D2), Color(0xFF0D47A1)],
                      onTap: () {
                        setState(() {
                          selectedRequirement = e;
                          showDrawer = true;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



}
