import 'dart:async';
import 'package:a2abrokerapp/pages/recent_activities/recent_activities_controller.dart';
import 'package:a2abrokerapp/pages/recent_activities/recent_activities_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RecentActivitiesPage extends StatefulWidget {
  const RecentActivitiesPage({super.key});

  @override
  State<RecentActivitiesPage> createState() =>
      _RecentActivitiesPageState();
}

class _RecentActivitiesPageState extends State<RecentActivitiesPage> {
  final controller = RecentActivitiesController();
  final scrollController = ScrollController();

  bool isInitialLoading = true;

  final TextEditingController searchController = TextEditingController();

  List<RecentActivity> filteredActivities = [];
  String searchQuery = "";
  DateTime? startDate;
  DateTime? endDate;

  Future<void> _loadInitial() async {
    await controller.loadActivities();

    filteredActivities = controller.activities;

    setState(() {
      _applySearch(searchQuery);

      isInitialLoading = false;
    });
  }

  void _applySearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase();

      filteredActivities = controller.activities.where((item) {
        final title = item.title.toLowerCase();
        final desc = item.description.toLowerCase();
        final type = item.activityType.toLowerCase();
        final activityDate = DateTime.parse(item.createdAt).toLocal();
        final activityDay = DateTime(activityDate.year, activityDate.month, activityDate.day);

        final start = startDate == null
            ? null
            : DateTime(startDate!.year, startDate!.month, startDate!.day);

        final end = endDate == null
            ? null
            : DateTime(endDate!.year, endDate!.month, endDate!.day);

        final matchesDate =
            (start == null || !activityDay.isBefore(start)) &&
                (end == null || !activityDay.isAfter(end));

        // 🔎 text search
        final matchesText = searchQuery.isEmpty ||
            title.contains(searchQuery) ||
            desc.contains(searchQuery) ||
            type.contains(searchQuery);

        // 📅 date filter

        return matchesText && matchesDate;
      }).toList();
    });
  }

  Timer? _debounce;

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applySearch(value);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    scrollController.dispose();
    super.dispose();
  }

  String formatDateTime(String date) {
    final utcTime = DateTime.parse(date);

    // ✅ Convert to device local timezone
    final localTime = utcTime.toLocal();

    // ✅ Format
    return DateFormat("dd MMM yyyy • hh:mm a").format(localTime);
  }

  @override
  void initState() {
    super.initState();
    _loadInitial();

    scrollController.addListener(() async {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        await controller.loadActivities();
        setState(() {});
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Padding(
        padding: const EdgeInsets.only(right:20, top: 40,bottom: 20,left: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔷 HEADER
            Text(
              "Recent Activities",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Track all system and broker activities",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: "Search activities...",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: Colors.grey[400],
                  ),

                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: Colors.grey[500],
                  ),

                  suffixIcon: searchController.text.isNotEmpty
                      ? GestureDetector(
                    onTap: () {
                      searchController.clear();
                      _applySearch("");
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.grey,
                    ),
                  )
                      : null,

                  filled: true,
                  fillColor: Colors.white,

                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.blue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _dateFilterCard(
                    label: "Start Date",
                    date: startDate,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          setState(() {
                            startDate = picked;

                            // 🚨 reset end date if it's before start date
                            if (endDate != null && endDate!.isBefore(startDate!)) {
                              endDate = null;
                            }
                          });
                          _applySearch(searchQuery);
                        }
                      }
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dateFilterCard(
                    label: "End Date",
                    date: endDate,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? startDate ?? DateTime.now(),
                          firstDate: startDate ?? DateTime(2020), // 🚨 key fix
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          setState(() {
                            endDate = picked;
                          });


                          _applySearch(searchQuery);
                        }
                      }
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () {
                setState(() {
                  searchQuery = "";
                  searchController.clear();
                  startDate = null;
                  endDate = null;
                  filteredActivities = controller.activities;
                });
              },
              child: const Text("Clear Filters"),
            ),

            const SizedBox(height: 20),

            /// 🔷 CONTENT
            Expanded(
              child: isInitialLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredActivities.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                controller: scrollController,
                itemCount: filteredActivities.length,
                itemBuilder: (context, index) {
                  final item = filteredActivities[index];
                  return _activityCard(item);
                },

              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎴 ACTIVITY CARD (LIKE YOUR LISTINGS UI)
  Widget _activityCard(RecentActivity item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔷 TOP ROW (Title + Date)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 📝 TITLE
              Expanded(
                child: Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              /// ⏱ DATE TIME (TOP RIGHT)
              Text(
                formatDateTime(item.createdAt),
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// 📄 DESCRIPTION
          Text(
            item.description,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 10),

          /// 🏷 OPTIONAL TYPE BADGE
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getColor(item.activityType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.activityType.replaceAll("_", " ").toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: _getColor(item.activityType),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColor(String type) {
    switch (type) {
      /*case "profile_approved":
        return Colors.green;
      case "profile_created":
        return Colors.green;
      case "PROPERTY_CREATED":
        return Colors.blue;
      case "profile_updated":
        return Colors.green;
      case "profile_verified":
        return Colors.green;
      case "profile_rejected":
        return Colors.red;
      case "transaction_completed":
        return Colors.blue;
      case "new_transaction":
        return Colors.orange;
      case "review_created":
        return Colors.purple;*/
      default:
        return Colors.grey;
    }
  }
  /// ❌ EMPTY STATE
  Widget _emptyState() {
    return Center(
      child: Text(
        "No recent activities found",
        style: GoogleFonts.poppins(color: Colors.grey),
      ),
    );
  }
}
Widget _dateFilterCard({
  required String label,
  required DateTime? date,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date == null
                      ? "Select"
                      : DateFormat("dd MMM yyyy").format(date),
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ],
      ),
    ),
  );
}