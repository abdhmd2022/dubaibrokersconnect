import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

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

  final List<Map<String, dynamic>> listings = [
    {
      'title': 'Studio Flat',
      'ref': '1019501231296',
      'price': '35,000',
      'unit': '/yr',
      'location': 'Dubai / Al Karama',
      'category': 'Residential',
      'size': '500 sq ft',
      'type': 'Apartment',
      'status': 'Inactive',
    },
    {
      'title': 'Pool View - Multiple Options',
      'ref': '1019501231295',
      'price': '66,000',
      'unit': '/yr',
      'location': 'Dubai / JVC District 11 / AKA Residence',
      'category': 'Residential',
      'size': '735 sq ft',
      'type': 'Apartment',
      'status': 'Active',
    },
    {
      'title': '2BHK',
      'ref': '12345',
      'price': '70,000',
      'unit': '/yr',
      'location': 'Dubai',
      'category': 'Residential',
      'size': '1,200 sq ft',
      'type': 'Apartment',
      'status': 'Inactive',
    },
  ];

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
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kPrimaryColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text("My Listings",
                          style: GoogleFonts.poppins(color: kPrimaryColor)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      label: Text("Create",
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
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
            isGridView ? _buildGridListings(width) : _buildListListings(),
          ],
        ),
      ),
    );


  }
  void _applyFilters() {
    final filters = {
      "purpose": selectedPurpose,
      "category": selectedCategory,
      "propertyType": selectedPropertyType,
      "minSize": minSize,
      "maxSize": maxSize,
      "rooms": selectedRooms,
      "furnishing": selectedFurnishing,
      "status": selectedStatus,
    };

    print("✅ Applied Filters: $filters");

    // TODO: Call your API here with these parameters
    // Example:
    // fetchListings(filters);
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



  /// ---------- SEARCH FIELD ----------
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

  /// ---------- VIEW TOGGLE ----------
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

  /// ---------- LIST VIEW ----------
  Widget _buildListListings() {
    return Column(
      children: listings.map((e) {
        final active = e['status'] == 'Active';
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home_work, color: Colors.grey, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['title'],
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text("Ref: ${e['ref']}",
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text("AED ${e['price']}${e['unit']}",
                            style: GoogleFonts.poppins(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const SizedBox(width: 10),
                        Icon(Icons.location_on_outlined,
                            color: Colors.grey.shade600, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(e['location'],
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.grey[700]),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _badge(e['category'], Colors.blue),
                        const SizedBox(width: 6),
                        _badge(e['status'],
                            active ? Colors.green : Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _iconButton(Icons.edit_outlined, Colors.orange),
                  const SizedBox(height: 8),
                  _iconButton(Icons.remove_red_eye_outlined, kPrimaryColor),
                ],
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  /// ---------- GRID VIEW ----------
  Widget _buildGridListings(double width) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: width < 900 ? 2 : 3,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      physics: const NeverScrollableScrollPhysics(),
      children: listings.map((e) {
        final active = e['status'] == 'Active';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                const Icon(Icons.home_filled, color: Colors.grey, size: 40),
              ),
              const SizedBox(height: 10),
              Text(e['title'],
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text("Ref: ${e['ref']}",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text("AED ${e['price']}${e['unit']}",
                  style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _badge(e['category'], Colors.blue),
                  const SizedBox(width: 6),
                  _badge(e['status'], active ? Colors.green : Colors.grey),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _iconButton(Icons.edit_outlined, Colors.orange),
                  const SizedBox(width: 8),
                  _iconButton(Icons.remove_red_eye_outlined, kPrimaryColor),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// ---------- UTIL BADGES ----------
  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: GoogleFonts.poppins(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  /// ---------- ICON BUTTON ----------
  Widget _iconButton(IconData icon, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
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



