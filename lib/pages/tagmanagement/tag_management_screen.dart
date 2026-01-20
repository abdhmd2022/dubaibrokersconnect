import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import 'dart:ui' as ui;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({Key? key}) : super(key: key);

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  bool _loading = true;
  List<dynamic> _tags = [];
  List<dynamic> _filteredTags = [];
  List<String> _selectedTagIds = [];
  final TextEditingController _searchC = TextEditingController();
  bool _bulkUpdating = false;
  bool _bulkDeleting = false;

  @override
  void initState() {
    super.initState();
    _fetchTags();
  }

  Future<void> _fetchTags() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseURL/api/tags');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _tags = data['data'];
          _filteredTags = _tags;
          _loading = false;
          _selectedTagIds.clear();
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Error fetching tags: $e');
    }
  }

  Future<void> _deleteTag(BuildContext context, String id) async {
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
              'Delete Tag',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete this tag?',
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
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


    if (confirm == true) {
      final token = await AuthService.getToken();
      final url = Uri.parse('$baseURL/api/tags/$id');
      try {
        await http.delete(url, headers: {'Authorization': 'Bearer $token'});
        //_fetchTags(); // uncomment if needed to refresh list
        /*ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tag deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );*/
      } catch (e) {
        debugPrint('Delete error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete tag'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedTagIds.isEmpty) return;

    // Show confirmation once
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(Icons.delete_forever_rounded,
                      color: Colors.redAccent, size: 40),
                ),
                const SizedBox(height: 18),
                Text(
                  "Confirm Deletion",
                  style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Text(
                  "Are you sure you want to delete the selected tags?\nThis action cannot be undone.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      color: Colors.grey.shade700,
                      fontSize: 14.5,
                      height: 1.5),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.pop(false),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text("Cancel"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      onPressed: () => context.pop(true),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text("Yes, Delete"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        shadowColor: Colors.redAccent.withOpacity(0.3),
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

    if (confirm != true) return;

    // Proceed with deletion silently
    setState(() => _bulkDeleting = true);
    final token = await AuthService.getToken();

    try {
      for (final id in _selectedTagIds) {
        final url = Uri.parse('$baseURL/api/tags/$id');
        await http.delete(url, headers: {'Authorization': 'Bearer $token'});
      }

      await _fetchTags();

      /*ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selected tags deleted successfully"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );*/
    } catch (e) {
      debugPrint('Bulk delete error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to delete some tags"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _bulkDeleting = false);
    }
  }


  Future<void> _updateTagStatus(Map<String, dynamic> tag, bool newStatus) async {

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
                newStatus ? 'Activate Tag' : 'Deactivate Tag',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to ${newStatus ? 'activate' : 'deactivate'} "${tag['name']}"?',
            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 15),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => context.pop(true),
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

    final token = await AuthService.getToken();
    final url = Uri.parse('$baseURL/api/tags/${tag['id']}');
    try {
      setState(() {
        tag['isActive'] = newStatus;
      });
      await http.put(url,

          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({
            "is_active": newStatus,
          }));


    } catch (e) {
      debugPrint('Status update error: $e');
    }
  }


  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedTagIds = _filteredTags.map((t) => t['id'] as String).toList();
      } else {
        _selectedTagIds.clear();
      }
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedTagIds.contains(id)) {
        _selectedTagIds.remove(id);
      } else {
        _selectedTagIds.add(id);
      }
    });
  }

  Future<void> _openCreateTagDialog() async {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    String type = "FEATURE";
    String color = "#4ECDC4";
    bool isActive = true;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Create New Tag",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Name Field
                    TextField(
                      controller: nameC,
                      decoration: InputDecoration(
                        labelText: "Tag Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descC,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dropdown for Type
                    DropdownButtonFormField<String>(
                      value: type,
                      items: const [
                        DropdownMenuItem(value: "FEATURE", child: Text("FEATURE")),
                        DropdownMenuItem(value: "AMENITY", child: Text("AMENITY")),
                        DropdownMenuItem(value: "KEYWORD", child: Text("KEYWORD")),
                      ],
                      onChanged: (val) => setDialogState(() => type = val!),
                      decoration: InputDecoration(
                        labelText: "Type",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                          if (nameC.text.trim().isEmpty) return;
                          setDialogState(() => isSubmitting = true);

                          await _createTag({
                            "name": nameC.text.trim(),
                            "description": descC.text.trim(),
                            "type": type,
                            "isActive": true,
                          });

                          setDialogState(() => isSubmitting = false);
                          context.pop();
                        },
                        child: isSubmitting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          "Create Tag",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createTag(Map<String, dynamic> body) async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseURL/api/tags');


    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _fetchTags();
        /*ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tag created successfully")),
        );*/
      } else {
        debugPrint("Failed to create tag: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create tag")),
        );
      }
    } catch (e) {
      debugPrint('Create tag error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        onPressed: () {
          // TODO: open create tag dialog (same as previous version)
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left side (icon + title + subtitle)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.sell_outlined, color: kPrimaryColor, size: 24),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Tag Management",
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Manage all user-created amenities, keywords, and feature tags",
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),

                        // Right side: Create Button
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, color: Colors.white, size: 18),
                          label: const Text(
                            "Create Tag",
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _openCreateTagDialog,
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),

            // WHITE CONTAINER — fills remaining height
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20,right:20, top: 8,bottom:40),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(20),

                  // 👇 Scrollable content inside, gives GridView bounded height
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // All Tags + Search + Select all rows here
                      _buildHeaderRow(),

                      if(_tags.isNotEmpty)...[
                        const SizedBox(height: 24),
                        _buildSelectAllRow(),
                        const SizedBox(height: 16),


                      ],


                      // 🧩 Expanded inside container gives GridView a height
                      Expanded(
                        child: _loading
                            ? _buildShimmerGrid()
                            : _filteredTags.isEmpty
                            ? Center(
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: kPrimaryColor.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 🏷 Icon
                                Container(
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(18),
                                  child: Icon(
                                    Icons.label_off_rounded,
                                    color: kPrimaryColor,
                                    size: 42,
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // 🗒 Title
                                Text(
                                  "No Tags Found",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // 💬 Subtitle
                                Text(
                                  "There are currently no tags to display.\nCreate new tags using the button above.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),


                              ],
                            ),
                          ),
                        )


                            : MasonryGridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          itemCount: _filteredTags.length,
                          itemBuilder: (context, index) {
                            final tag = _filteredTags[index];
                            final isSelected = _selectedTagIds.contains(tag['id']);
                            return _buildTagCard(tag, isSelected);
                          },
                        )

                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagCard(Map<String, dynamic> tag, bool isSelected) {
    final bool isActive = tag['isActive'] == true;
    String description = tag['description'] ?? "";
    if (description.isEmpty) description = 'N/A';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.transparent,
          width: isSelected ? 1.4 : 1,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      margin:  const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ lets height adjust automatically
        children: [
          // 🏷 Title Row — Checkbox + Name
          Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: kPrimaryColor,
                onChanged: (_) => _toggleSelect(tag['id']),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Text(
                      tag['name'] ?? '',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5,
                        color: Colors.black87,
                      ),
                    ),
                    _buildModernStatusSwitch(tag),

                  ],
                )
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 🔖 Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: _getTypeColor(tag['type']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getTypeColor(tag['type']).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getTypeIcon(tag['type']),
                  color: _getTypeColor(tag['type']),
                  size: 13,
                ),
                const SizedBox(width: 3),
                Text(
                  tag['type']?.toString().toUpperCase() ?? "UNKNOWN",
                  style: GoogleFonts.poppins(
                    color: _getTypeColor(tag['type']),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 📝 Description with show more / show less
          LayoutBuilder(
            builder: (context, constraints) {
              final maxLines = 2; // show only first 3 lines
              final textSpan = TextSpan(
                text: 'Description: ',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(
                    text: description,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              );

              final textPainter = TextPainter(
                text: textSpan,
                maxLines: maxLines,
                textDirection: ui.TextDirection.ltr,
              )..layout(maxWidth: constraints.maxWidth);

              final isOverflowing = textPainter.didExceedMaxLines;
              bool expanded = false;

              return StatefulBuilder(
                builder: (context, setInnerState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        textSpan,
                        maxLines: expanded ? null : maxLines,
                        overflow: TextOverflow.fade,
                        softWrap: true,
                      ),
                      if (isOverflowing)
                        GestureDetector(
                          onTap: () => setInnerState(() => expanded = !expanded),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              expanded ? "Show less" : "Show more",
                              style: GoogleFonts.poppins(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),


          const SizedBox(height: 8),

          // ⚙️ Bottom Bar — Switch + Delete
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [

                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  tooltip: "Delete",
                  onPressed: () async {
                    await _deleteTag(context,tag['id']);
                    _fetchTags();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatusSwitch(Map<String, dynamic> tag) {
    final isActive = tag['isActive'] == true;
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
              onTap: () => _updateTagStatus(tag, !isActive),
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

  Color _getTypeColor(String? type) {
    switch (type?.toUpperCase()) {
      case 'FEATURE':
        return Colors.blueAccent;
      case 'AMENITY':
        return Colors.teal;
      case 'KEYWORD':
        return Colors.deepOrangeAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type?.toUpperCase()) {
      case 'FEATURE':
        return Icons.star_outline_rounded;
      case 'AMENITY':
        return Icons.home_work_outlined;
      case 'KEYWORD':
        return Icons.tag_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        mainAxisExtent: 165,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
    );
  }
  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "All Tags (${_filteredTags.length})",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(
          width: 260,
          child: TextField(
            controller: _searchC,
            decoration: InputDecoration(
              hintText: "Search tags...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              setState(() {
                _filteredTags = _tags
                    .where((t) =>
                (t['name'] as String)
                    .toLowerCase()
                    .contains(val.toLowerCase()) ||
                    (t['type'] as String)
                        .toLowerCase()
                        .contains(val.toLowerCase()))
                    .toList();
                _selectedTagIds.clear();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectAllRow() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          // Deep soft shadow for elevation
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          // Ambient glow effect for modern depth
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ✅ Checkbox and label
          Checkbox(
            value: _selectedTagIds.length == _filteredTags.length &&
                _filteredTags.isNotEmpty,
            onChanged: (val) => _toggleSelectAll(val),
            activeColor: kPrimaryColor,
          ),
          Text(
            "Select all visible tags",
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const Spacer(),

          // ✅ Actions (only visible when something is selected)
          if (_selectedTagIds.isNotEmpty)
            Row(
              children: [
                // 🟣 Update Status Button with loader
                ElevatedButton.icon(
                  icon: _bulkUpdating
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.sync_alt_rounded, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shadowColor: kPrimaryColor.withOpacity(0.4),
                    elevation: 6,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _bulkUpdating ? null : _bulkToggleStatus,
                  label: Text(
                    _bulkUpdating ? "Updating..." : "Update Status",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, letterSpacing: 0.2),
                  ),
                ),

                const SizedBox(width: 12),

                // 🔴 Delete Button with loader
                ElevatedButton.icon(
                  icon: _bulkDeleting
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.delete_outline, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.redAccent.withOpacity(0.4),
                    elevation: 6,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _bulkDeleting ? null : _bulkDelete,
                  label: Text(
                    _bulkDeleting ? "Deleting..." : "Delete",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, letterSpacing: 0.2),
                  ),
                ),
              ],
            ),

        ],
      ),
    );
  }
  Future<void> _bulkToggleStatus() async {
    if (_selectedTagIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 40),
                ),
                const SizedBox(height: 18),
                Text(
                  "Confirm Status Update",
                  style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Text(
                  "Do you want to update the status of all selected tags?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      color: Colors.grey.shade700,
                      fontSize: 14.5,
                      height: 1.5),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.pop(false),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text("Cancel"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      onPressed: () => context.pop(true),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text("Yes, Update"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        shadowColor: kPrimaryColor.withOpacity(0.3),
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

    if (confirm != true) return;

    setState(() => _bulkUpdating = true);
    final token = await AuthService.getToken();

    try {
      for (final id in _selectedTagIds) {
        final tag = _tags.firstWhere((t) => t['id'] == id);
        final newStatus = !(tag['isActive'] == true);

        await http.put(
          Uri.parse('$baseURL/api/tags/$id'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({"is_active": newStatus}),
        );
      }

      await _fetchTags();

     /* ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected tags status updated successfully'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );*/

    } catch (e) {
      debugPrint('Bulk toggle error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update tag statuses'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _bulkUpdating = false);
    }
  }


  String _formatDate(String? isoString) {
    if (isoString == null) return '-';
    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat('dd-MMM-yyyy').format(date);
    } catch (_) {
      return '-';
    }
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '-';
    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat('hh:mm a').format(date);
    } catch (_) {
      return '-';
    }
  }


}
