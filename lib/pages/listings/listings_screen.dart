import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;
import 'package:flutter/animation.dart';
import '../../widgets/animated_logo_loader.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;


class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}


class _ListingsScreenState extends State<ListingsScreen> {
  bool isGridView = false;
  String selectedPurpose = "All";
  String selectedCategory = "All";
  bool showMoreFilters = false;
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

  @override
  void initState() {
    super.initState();
    fetchListings();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  /// 🔹 Fetch first page (initial or filters)
  Future<void> fetchListings({Map<String, dynamic>? filters}) async {
    setState(() {
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
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> fetchedListings = data['data'];

          setState(() {
            listings.addAll(fetchedListings.map((item) {
              return {
                'id': item['id'],
                'title': item['title'] ?? 'N/A',
                'ref': item['referenceNumber'] ?? '-',
                'price': item['price']?.toString() ?? '0',
                'currency': item['currency'] ?? 'AED',
                'unit': item['transactionType'] == 'RENT' ? '/yr' : '',
                'location': item['location']?['completeAddress'] ?? 'Unknown',
                'category': item['category'] ?? 'Residential',
                'size': '${item['sizeSqft'] ?? '0'} sqft',
                'type': item['propertyType']?['name'] ?? 'Property',
                'listingStatus' : item['listingStatus'] ?? 'Inactive',
                'status': item['status'] ?? 'Unknown',
                'furnished': item['furnishedStatus'] ?? '',
                'broker': item['broker']?['displayName'] ?? 'N/A',
                'rating': item['broker']?['rating'] ?? 'N/A',
                'image': (item['images'] != null && item['images'].isNotEmpty)
                    ? item['images'][0]
                    : null,
              };
            }).toList());

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

  /// 🔹 Apply Filters
  void _applyFilters() {
    final filters = {
      "purpose": selectedPurpose == "All" ? null : selectedPurpose,
      "category": selectedCategory == "All" ? null : selectedCategory,
      "propertyType": selectedPropertyType,
      "minSize": minSize,
      "maxSize": maxSize,
      "rooms": selectedRooms,
      "furnishing": selectedFurnishing,
      "listingStatus": selectedStatus,
    }..removeWhere((key, value) => value == null);

    print("✅ Applying filters: $filters");
    fetchListings(filters: filters);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("All Property Listings",
                        style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text("Browse properties from all brokers",
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey[600])),
                  ],
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
                                ["All", "Rent", "Buy"],
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
                  Text("View & Filters",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey[700])),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _viewModeToggle(), // background changed to white below
                      _searchField("Search by Title, Ref, Location..."),
                      _searchField("Search for locations..."),
                      _searchField("Min Price (AED)"),
                      _searchField("Max Price (AED)"),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => showMoreFilters = !showMoreFilters),
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
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),


                    ],
                  ),

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
                              _buildCompactDropdown(
                                title: "Property Type",
                                value: selectedPropertyType,
                                items: ["Apartment", "Villa", "Townhouse", "Office", "Warehouse"],
                                onChanged: (val) => setState(() => selectedPropertyType = val),
                              ),
                              _buildCompactDropdown(
                                title: "No. of Rooms",
                                value: selectedRooms,
                                items: ["Studio", "1", "2", "3", "4+", "Penthouse"],
                                onChanged: (val) => setState(() => selectedRooms = val),
                              ),
                              _buildCompactDropdown(
                                title: "Furnishing",
                                value: selectedFurnishing,
                                items: ["Furnished", "Semi-Furnished", "Unfurnished"],
                                onChanged: (val) => setState(() => selectedFurnishing = val),
                              ),
                              _buildCompactDropdown(
                                title: "Status",
                                value: selectedStatus,
                                items: ["Ready to Move", "Off-Plan", "Rented", "Available in Future"],
                                onChanged: (val) => setState(() => selectedStatus = val),
                              ),
                              _buildCompactField(
                                label: "Min Size (sqft)",
                                onChanged: (v) => setState(() => minSize = int.tryParse(v ?? '')),
                              ),
                              _buildCompactField(
                                label: "Max Size (sqft)",
                                onChanged: (v) => setState(() => maxSize = int.tryParse(v ?? '')),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: ElevatedButton.icon(
                                  onPressed: _applyFilters,
                                  icon: const Icon(Icons.check_circle_outline,
                                      color: Colors.white, size: 18),
                                  label: Text("Apply",
                                      style: GoogleFonts.poppins(
                                          color: Colors.white, fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryColor,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 22, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
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
                ],
              ),
            ),

            const SizedBox(height: 30),

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
                        ? _buildGridListings(width)
                        : _buildListListings(),
                    if (isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
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

  Widget _buildGridListings(double width) {
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
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final e = listings[index];
        final active = e['listingStatus'] == 'ACTIVE';
        final furnished = e['furnished']?.toString().toLowerCase().contains('furnish') ?? false;

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

                // 🏷 Title + Ref
                Text(
                  e['title'] ?? 'N/A',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text("Ref: ${e['ref'] ?? '-'}",
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[600])),

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
                            "${e['currency']} ${e['price']}${e['unit'] ?? ''}",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🏠 Type Badge
                    _badge(
                      e['type'] ?? 'Type',
                      Colors.orange,
                      icon: Icons.home_work_outlined,
                    ),

                    // 🟢 Status Badge
                    _badge(
                      e['status'] ?? 'Status',
                      Colors.teal,
                      icon: Icons.home,
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
                    _iconInfo(Icons.square_foot, e['size'] ?? ''),
                    _iconInfo(
                      furnished
                          ? Icons.chair_alt_outlined
                          : Icons.weekend_outlined,
                      furnished ? "Furnished" : "Unfurnished",
                    ),
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
                          e['location'] ?? 'Unknown',
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
                          "${e['broker']}  ⭐ ${e['rating'] ?? '-'}",
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
                )

              ],
            ),
          ),
        );
      },
    );
  }

  /// 🔹 Modern List View (with full details + icons)
  Widget _buildListListings() {
    return Column(
      children: listings.map((e) {
        final active = e['listingStatus'] == 'ACTIVE';
        final furnished = e['furnished']?.toString().toLowerCase().contains('furnish') ?? false;

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
                        Text(
                          e['title'] ?? 'N/A',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Ref: ${e['ref'] ?? '-'}",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
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
                                    "${e['currency']} ${e['price']}${e['unit'] ?? ''}",
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
                                    e['location'] ?? 'Unknown',
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
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 🛏️ Info Icons Row
                        Row(
                          children: [
                            _iconInfo(Icons.king_bed_outlined, "${e['rooms'] ?? 0}"),
                            _iconInfo(Icons.bathtub_outlined, "${e['bathrooms'] ?? 0}"),
                            _iconInfo(Icons.square_foot, e['size'] ?? ''),
                            _iconInfo(
                              furnished ? Icons.chair_alt_outlined : Icons.weekend_outlined,
                              furnished ? "Furnished" : "Unfurnished",
                            ),
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
                            _badge(e['type'] ?? 'Type', Colors.orange,
                                icon: Icons.home_work_outlined),
                            _badge(e['status'] ?? 'Unknown', Colors.teal,
                                icon: Icons.home_rounded),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 👤 Broker Chip
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
                              const Icon(Icons.person_outline,
                                  size: 14, color: Colors.brown),
                              const SizedBox(width: 4),
                              Text(
                                "${e['broker']}  ⭐ ${e['rating'] ?? '-'}",
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


  Widget _buildToggleChips(
      List<String> options, String selected, Function(String) onSelected) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kPrimaryColor.withOpacity(0.1),),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: options.map((option) {
          final isActive = selected == option;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => onSelected(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isActive ? kPrimaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? kPrimaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : Colors.black87,
                        fontSize: 13,
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

  Widget _searchField(String hint) {
    return SizedBox(
      width: 200,
      child: TextField(
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

}



Widget _buildDropdown({
  required String title,
  required String? value,
  required List<String> items,
  required Function(String?) onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey[700])),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) =>
            DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: kPrimaryColor),
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ],
  );
}

Widget _buildTextField({
  required String label,
  required Function(String?) onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey[700])),
      const SizedBox(height: 6),
      TextField(
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: label,
          hintStyle:
          GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: kPrimaryColor),
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ],
  );
}

Widget _buildCompactDropdown({
  required String title,
  required String? value,
  required List<String> items,
  required Function(String?) onChanged,
}) {
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
            e,
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



