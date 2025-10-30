import 'dart:convert';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_logo_loader.dart';
import '../dashboard/admin_shell.dart';

class PropertyTypesScreen extends StatefulWidget {
  const PropertyTypesScreen({super.key});

  @override
  State<PropertyTypesScreen> createState() => _PropertyTypesScreenState();
}

class _PropertyTypesScreenState extends State<PropertyTypesScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> allTypes = [];
  bool isLoading = false;
  bool isGridView = true;
  String selectedTab = 'RESIDENTIAL';
  bool _isHoveringBack = false;

  final Duration fadeDuration = const Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    fetchPropertyTypes();
  }

  Future<void> fetchPropertyTypes() async {
    setState(() => isLoading = true);
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseURL/api/property-types'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() => allTypes = jsonResponse['data']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching property types: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }



  List<dynamic> get filteredTypes => allTypes.where((t) {
    final category = (t['category'] ?? '').toString().toUpperCase();
    return selectedTab.toUpperCase() == category;
  }).toList();

  Future<void> toggleActive(Map<String, dynamic> item) async {
    final newStatus = !item['isActive'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: Colors.white,
          elevation: 10,
          title: Row(
            children: [
              Icon(
                newStatus ? Icons.toggle_on_rounded : Icons.toggle_off_outlined,
                color: newStatus ? Colors.green.shade600 : Colors.red.shade600,
                size: 30,
              ),
              const SizedBox(width: 8),
              Text(
                newStatus ? 'Activate Property Type' : 'Deactivate Property Type',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to ${newStatus ? 'activate' : 'deactivate'} "${item['name']}"?',
            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 15),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                newStatus ? Colors.green.shade600 : Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(newStatus ? 'Activate' : 'Deactivate'),
            ),
          ],
        );
      },
    );

    // 🚫 User cancelled
    if (confirm != true) return;

    // ✅ Proceed only after confirmation
    setState(() => item['isActive'] = newStatus);

    try {
      final token = await AuthService.getToken();
      final response = await http.put(
        Uri.parse('$baseURL/api/property-types/${item['id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'is_active': newStatus}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final message = responseData['message'] ??
            (newStatus
                ? 'Property type activated successfully'
                : 'Property type deactivated successfully');

        /*ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor:
            newStatus ? Colors.green.shade600 : Colors.red.shade600,
          ),
        );*/
      } else {
        setState(() => item['isActive'] = !newStatus);
        final errorMsg =
            responseData['message'] ?? 'Failed to update property type status';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      setState(() => item['isActive'] = !newStatus);
      debugPrint('Error toggling status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error while updating status'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> deletePropertyType(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(
              'Delete Property Type',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete this property type?',
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // 🚫 Cancel pressed
    if (confirm != true) return;

    // ✅ Proceed to delete
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse('$baseURL/api/property-types/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        fetchPropertyTypes();
        /*ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property type deleted successfully')),
        );*/
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete property type (${response.statusCode})'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting property type: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting property type: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> showAddEditDialog({Map<String, dynamic>? existing}) async {
    final nameC = TextEditingController(text: existing?['name'] ?? '');
    final slugC = TextEditingController(text: existing?['slug'] ?? '');
    final descC = TextEditingController(text: existing?['description'] ?? '');
    final sortC =
    TextEditingController(text: existing?['sortOrder']?.toString() ?? '0');
    String selectedCategory = (existing?['category'] ?? 'RESIDENTIAL').toString().toUpperCase();
    String selectedTransaction = (existing?['transactionType'] ?? 'RENT').toString().toUpperCase();
    final isEdit = existing != null;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Container(
          padding: const EdgeInsets.all(26),
          width: 520,
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏷️ Title
                Row(
                  children: [
                    Icon(
                      isEdit ? Icons.edit_note_rounded : Icons.add_box_rounded,
                      color: kPrimaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEdit
                          ? 'Edit Property Type'
                          : 'Add New Property Type',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 🏘️ Property Name
                _buildTextField(
                  'Property Name',
                  nameC,
                  hint: 'e.g. Apartment',
                  icon: Icons.home_work_rounded,
                ),

// 🏡 Category Dropdown
                _buildDropdown(
                  label: 'Category',
                  icon: Icons.category_rounded,
                  value: selectedCategory,
                  items: const ['RESIDENTIAL', 'COMMERCIAL'],
                  onChanged: (val) => selectedCategory = val!,
                ),

// 💼 Transaction Type Dropdown
                _buildDropdown(
                  label: 'Transaction Type',
                  icon: Icons.swap_horiz_rounded,
                  value: displayTransaction(selectedTransaction),
                  items: const ['Rent Only', 'Sale Only', 'Sale & Rent'],
                  onChanged: (val) => selectedTransaction = backendTransaction(val!),
                ),
                // 🔗 Slug
                /*_buildTextField(
                  'Slug',
                  slugC,
                  hint: 'auto-generated or unique key',
                  icon: Icons.link_rounded,
                ),*/


                // 📝 Description
                _buildTextField(
                  'Description',
                  descC,
                  hint: 'Short description about property type',
                  maxLines: 2,
                  icon: Icons.description_outlined,
                ),

                // 🔢 Sort Order
                _buildTextField(
                  'Sort Order',
                  sortC,
                  hint: 'Display order (e.g. 1, 2, 3)',
                  keyboardType: TextInputType.number,
                  icon: Icons.sort_rounded,
                ),




                const SizedBox(height: 26),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (nameC.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enter name')),
                          );
                          return;
                        }

                        final token = await AuthService.getToken();
                        final body = isEdit
                            ? {
                          "name": nameC.text.trim(),
                          "slug": nameC.text.trim(),
                          "description": descC.text.trim(),
                          "sort_order": int.tryParse(sortC.text) ?? 0,
                          "category": selectedCategory,
                          "transaction_type": selectedTransaction,
                          "is_active": existing['isActive'] ?? true,
                        }
                            : {
                          "name": nameC.text.trim(),
                          "slug": nameC.text.trim(),
                          "description": descC.text.trim(),
                          "sort_order": int.tryParse(sortC.text) ?? 0,
                          "category": selectedCategory,
                          "transaction_type": selectedTransaction,
                          "isActive": true,
                        };


                        print('body sending -> $body');

                        final url = isEdit
                            ? '$baseURL/api/property-types/${existing['id']}'
                            : '$baseURL/api/property-types';
                        print('url -> ${url}');

                        final headers = {
                          'Content-Type': 'application/json',
                          'Authorization': 'Bearer $token',
                        };
                        print('token -> ${token}');

                        final response = isEdit
                            ? await http.put(Uri.parse(url),
                            headers: headers, body: jsonEncode(body))
                            : await http.post(Uri.parse(url),
                            headers: headers, body: jsonEncode(body));

                        print('response -> ${response.body}');
                        if (response.statusCode == 200 ||
                            response.statusCode == 201) {
                          Navigator.pop(context);
                          fetchPropertyTypes();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isEdit
                                ? 'Property type updated successfully'
                                : 'Property type added successfully'),
                            backgroundColor: Colors.green.shade600,
                          ));
                        }
                      },
                      icon:
                      Icon(isEdit ? Icons.save_rounded : Icons.add_rounded),
                      label: Text(isEdit ? 'Update' : 'Create'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
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

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        String? hint,
        IconData? icon,
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.3, // consistent line height
            ),
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(icon,
                    color: kPrimaryColor.withOpacity(0.8), size: 20),
              )
                  : null,
              prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
              filled: true,
              fillColor: kFieldBackgroundColor,
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade500,
                fontSize: 13.5,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14, // balanced vertical alignment
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: kAccentColor.withOpacity(0.2), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kPrimaryColor, width: 1.3),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) => ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 250),
              child: Container(
                decoration: BoxDecoration(
                  color: kFieldBackgroundColor,
                  borderRadius: BorderRadius.circular(18),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: value,
                  icon: Icon(Icons.arrow_drop_down_rounded,
                      color: kPrimaryColor.withOpacity(0.8)),
                  dropdownColor: Colors.white, // ✅ white dropdown background
                  borderRadius: BorderRadius.circular(12),
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon, color: kPrimaryColor.withOpacity(0.8)),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: InputBorder.none,
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  items: items
                      .map(
                        (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          e,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _viewTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.black54),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          const SizedBox(height: 10),


          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.home_work_rounded, color: kPrimaryColor, size: 30),
              const SizedBox(width: 10),
              Text(
                'Property Types',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFFFB300)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child:  Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Admin Only",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // 🔘 Grid / List switch (tab-like)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _viewTabButton(
                      label: 'Grid',
                      icon: Icons.grid_view_rounded,
                      isSelected: isGridView,
                      onTap: () => setState(() => isGridView = true),
                    ),
                    _viewTabButton(
                      label: 'List',
                      icon: Icons.list_alt,
                      isSelected: !isGridView,
                      onTap: () => setState(() => isGridView = false),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ➕ Add Property Button
              ElevatedButton.icon(
                onPressed: () => showAddEditDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Property Type'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),


          const SizedBox(height: 25),
          Container(
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
              children: [
                _buildTabButton('RESIDENTIAL'),
                _buildTabButton('COMMERCIAL'),
              ],
            ),
          ),

          const SizedBox(height: 25),
          Expanded(
              child: isLoading
                  ? const Center(child:  AnimatedLogoLoader(assetPath: 'assets/collabrix_logo.png'),)
                  : filteredTypes.isEmpty
                  ? _buildEmptyState()
                  : isGridView
                  ? _buildGridView(width)
                  : _buildListView()),
        ]),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isResidential = selectedTab.toUpperCase() == 'RESIDENTIAL';
    final icon = isResidential
        ? Icons.home_work_rounded
        : Icons.business_rounded;
    final label = isResidential ? 'Residential' : 'Commercial';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No $label Property Types Found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adding a new $label property type.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String displayTransaction(String value) {
    switch (value) {
      case 'RENT':
        return 'Rent Only';
      case 'SALE':
        return 'Sale Only';
      case 'SALE_AND_RENT':
        return 'Sale & Rent';
      default:
        return value;
    }
  }

  String backendTransaction(String display) {
    switch (display) {
      case 'Rent Only':
        return 'RENT';
      case 'Sale Only':
        return 'SALE';
      case 'Sale & Rent':
        return 'SALE_AND_RENT';
      default:
        return display.toUpperCase();
    }
  }

  Widget _buildTabButton(String tab) {
    final selected = selectedTab.toUpperCase() == tab.toUpperCase();

    // 🧮 Calculate counts dynamically
    final residentialCount = allTypes
        .where((t) => (t['category'] ?? '').toString().toUpperCase() == 'RESIDENTIAL')
        .length;

    final commercialCount = allTypes
        .where((t) => (t['category'] ?? '').toString().toUpperCase() == 'COMMERCIAL')
        .length;

    final count = tab == 'RESIDENTIAL' ? residentialCount : commercialCount;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? kPrimaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tab == 'Residential' ? Icons.home_filled : Icons.business_rounded,
                size: 18,
                color: selected ? Colors.white : Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                "${tab[0]}${tab.substring(1).toLowerCase()} ($count)",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(double width) {
    final crossAxisCount = width < 900
        ? 2
        : width < 1400
        ? 3
        : 4;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: filteredTypes.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, i) {
        final item = filteredTypes[i];
        return _modernPropertyCard(item);
      },
    );
  }

  Widget _modernPropertyCard(Map<String, dynamic> item) {
    final isActive = item['isActive'] == true;

    return Container(
      padding: const EdgeInsets.all(20),
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
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.25)
              : Colors.grey.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷️ Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item['name'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusSwitch(item),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.6),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  (item['category'] ?? '')
                      .toString()
                      .toLowerCase()
                      .replaceFirstMapped(RegExp(r'^[a-z]'), (m) => m[0]!.toUpperCase()),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),

              if(item['transactionType'] !=null)...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item['transactionType'] == 'RENT'
                        ? Colors.green.shade100
                        : item['transactionType'] == 'SALE'
                        ? Colors.orange.shade100
                        : item['transactionType'] == "null"? Colors.teal.shade100:Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayTransaction(item['transactionType'] ?? ""),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item['transactionType'] == 'RENT'
                          ? Colors.green.shade800
                          : item['transactionType'] == 'SALE'
                          ? Colors.orange.shade800:
                      item['transactionType'] == 'null'
                          ? Colors.teal.shade800
                          : Colors.teal.shade800,
                    ),
                  ),
                ),
              ]

            ],
          ),
          const SizedBox(height: 10),




          // 🧩 Description
          Text(
            item['description'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: Colors.black54,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // ⚙️ Footer Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.blue.shade100, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort_rounded, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      "Sort Order: ${item['sortOrder'] ?? 0}",
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_rounded, color: Colors.teal),
                    onPressed: () => showAddEditDialog(existing: item),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon:
                    const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: () => deletePropertyType(item['id']),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
  Widget _buildStatusSwitch(Map<String, dynamic> item) {
    final isActive = item['isActive'] == true;
    bool hovering = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => hovering = true),
          onExit: (_) => setState(() => hovering = false),
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: isActive ? 'Deactivate' : 'Activate',
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: const TextStyle(color: Colors.white, fontSize: 12),
            waitDuration: const Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: () => toggleActive(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 56,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: isActive
                      ? (hovering
                      ? Colors.green.shade600
                      : Colors.green.shade500)
                      : (hovering
                      ? Colors.grey.shade400
                      : Colors.grey.shade300),
                  boxShadow: hovering
                      ? [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                      : [],
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      alignment: isActive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusBadge(bool active) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: active ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(8)),
    child: Text(active ? 'Active' : 'Inactive',
        style: GoogleFonts.poppins(
            fontSize: 12,
            color: active ? Colors.green.shade800 : Colors.red.shade800,
            fontWeight: FontWeight.w600)),
  );

  Widget _buildListView() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DataTable2(
                headingRowHeight: 52,
                dataRowHeight: 58,
                columnSpacing: 16,
                horizontalMargin: 16,
                minWidth: constraints.maxWidth,
                headingRowColor: WidgetStateProperty.all(
                    kPrimaryColor.withOpacity(0.08)),
                headingTextStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.black87,
                ),
                dataTextStyle: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: Colors.black87,
                ),
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                columns: const [
                  DataColumn2(label: Text('Name'), size: ColumnSize.S),
                  //DataColumn2(label: Text('Slug'), size: ColumnSize.S),
                  DataColumn2(label: Text('Description'), size: ColumnSize.L),
                  DataColumn2(label: Text('Sort Order'), size: ColumnSize.S),
                  DataColumn2(label: Text('Status'), size: ColumnSize.S),
                  DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                ],
                rows: filteredTypes.map((item) {
                  final bool active = item['isActive'];
                  return DataRow(
                    color: WidgetStateProperty.all(Colors.transparent),
                    cells: [
                      DataCell(Text(item['name'] ?? '')),
                      //DataCell(Text(item['slug'] ?? '')),
                      DataCell(Text(
                        item['description'] ?? '',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      )),
                      DataCell(Text(item['sortOrder'].toString())),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            active ? "Active" : "Inactive",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.green.shade800
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _actionIcon(
                              icon: Icons.edit,
                              color: Colors.teal,
                              tooltip: "Edit",
                              onTap: () =>
                                  showAddEditDialog(existing: item),
                            ),
                            const SizedBox(width: 6),
                            _actionIcon(
                              icon: active
                                  ? Icons.toggle_on_rounded
                                  : Icons.toggle_off_outlined,
                              color:
                              active ? Colors.green : Colors.grey.shade500,
                              //size: 38,
                              tooltip:
                              active ? "Deactivate" : "Activate",
                              onTap: () => toggleActive(item),
                            ),
                            const SizedBox(width: 6),
                            _actionIcon(
                              icon: Icons.delete_outline,
                              color: Colors.red,
                              tooltip: "Delete",
                              onTap: () => deletePropertyType(item['id']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
    double size = 26,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }

}
