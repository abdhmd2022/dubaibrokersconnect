import 'package:a2abrokerapp/pages/recent_activities/recent_activities_controller.dart';
import 'package:a2abrokerapp/pages/recent_activities/recent_activities_model.dart';
import 'package:flutter/cupertino.dart';
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

  Future<void> _loadInitial() async {
    await controller.loadActivities();
    setState(() {
      isInitialLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Padding(
        padding: const EdgeInsets.all(20),
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

            /// 🔷 CONTENT
            Expanded(
              child: isInitialLoading
                  ? const Center(child: CircularProgressIndicator())
                  : controller.activities.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                controller: scrollController,
                itemCount: controller.activities.length,
                itemBuilder: (context, index) {
                  final item = controller.activities[index];
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

  String _formatTime(String date) {
    final dt = DateTime.parse(date);
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}