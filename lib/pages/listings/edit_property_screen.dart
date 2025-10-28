import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../services/auth_service.dart';

class EditPropertyScreen extends StatefulWidget {
  final Map<String, dynamic> propertyData;

  const EditPropertyScreen({super.key, required this.propertyData});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _sizeController;
  late TextEditingController _descriptionController;

  String? selectedCategory;
  String? selectedFurnishing;
  String? selectedStatus;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    final data = widget.propertyData;
    _titleController = TextEditingController(text: data['title'] ?? '');
    _priceController = TextEditingController(text: data['price']?.toString() ?? '');
    _sizeController = TextEditingController(text: data['size']?.toString().replaceAll(' sqft', '') ?? '');
    _descriptionController = TextEditingController(text: data['description'] ?? '');

    selectedCategory = data['category'] ?? 'Residential';
    selectedFurnishing = data['furnished'] ?? 'Unfurnished';
    selectedStatus = data['status'] ?? 'Ready to Move';
  }

  Future<void> _updateProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('$baseURL/api/properties/${widget.propertyData['id']}');

      final body = {
        'title': _titleController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0,
        'sizeSqft': double.tryParse(_sizeController.text) ?? 0,
        'category': selectedCategory,
        'furnishedStatus': selectedFurnishing,
        'status': selectedStatus,
        'description': _descriptionController.text.trim(),
      };

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Property updated successfully"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          _showError(data['message'] ?? 'Update failed.');
        }
      } else {
        _showError('Server error (${response.statusCode})');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text("Edit Property"),
        backgroundColor: kPrimaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField("Title", _titleController),
                const SizedBox(height: 16),
                _buildTextField("Price (AED)", _priceController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField("Size (sqft)", _sizeController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildDropdown("Category", selectedCategory, [
                  "Residential",
                  "Commercial",
                  "Industrial",
                  "Land"
                ], (v) => setState(() => selectedCategory = v)),
                const SizedBox(height: 16),
                _buildDropdown("Furnishing", selectedFurnishing, [
                  "Furnished",
                  "Semi-Furnished",
                  "Unfurnished"
                ], (v) => setState(() => selectedFurnishing = v)),
                const SizedBox(height: 16),
                _buildDropdown("Status", selectedStatus, [
                  "Ready to Move",
                  "Off-Plan",
                  "Rented",
                  "Available in Future"
                ], (v) => setState(() => selectedStatus = v)),
                const SizedBox(height: 16),
                _buildTextField("Description", _descriptionController,
                    maxLines: 5),
                const SizedBox(height: 30),

                /// Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _updateProperty,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.save_outlined, color: Colors.white),
                    label: Text(
                      isLoading ? "Updating..." : "Save Changes",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (v) => v == null || v.trim().isEmpty ? 'Required field' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kPrimaryColor, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String label,
      String? value,
      List<String> items,
      Function(String?) onChanged,
      ) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kPrimaryColor, width: 1.4),
        ),
      ),
      items: items
          .map((e) =>
          DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.poppins())))
          .toList(),
    );
  }
}
