import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_logo_loader.dart' show AnimatedLogoLoader;

class AdminDashboardContent extends StatefulWidget {
  final Map<String, dynamic> userData;


  const AdminDashboardContent({super.key,
    required this.userData,


  });

  @override
  State<AdminDashboardContent> createState() => _AdminDashboardContentState();
}

class _AdminDashboardContentState extends State<AdminDashboardContent> {

  int totalBrokers = 0;
  int approvedBrokers = 0;
  int pendingBrokers = 0;
  int verifiedBrokers = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBrokerStats();
  }

  Future<void> _fetchBrokerStats() async {
    final token = await AuthService.getToken();

    try {
      final response = await http.get(
        Uri.parse('$baseURL/api/admin/stats'), // 🔹 Replace with your API URL
        headers: {
          'Authorization': 'Bearer $token', // 🔹 Add your token logic
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final getjson = json.decode(response.body);
        final data =  getjson['data'];

        print('data -> $data');

        setState(() {
          totalBrokers = data['brokers']['total'] ?? 0;
          approvedBrokers = data['brokers']['approved'] ?? 0;
          pendingBrokers = data['brokers']['pending'] ?? 0;
          verifiedBrokers = data['brokers']['verified'] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        debugPrint('Failed to fetch broker stats: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error fetching broker stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.userData;
    final String fullName =
    '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
    final String email = userData['email'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Align(
        alignment: Alignment.topCenter, // 👈 ensures top placement
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child:  isLoading?

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                AnimatedLogoLoader(assetPath: 'assets/collabrix_logo.png'),

              ],
            ),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ---------- HEADER ----------
              Row(
                children: [
                  Text(
                    "Admin Dashboard",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _roleChip("Admin", Colors.orange, Icons.workspace_premium_rounded),
                  const SizedBox(width: 6),
                  _roleChip("Broker", Colors.blue, Icons.badge_outlined),
                ],
              ),

              const SizedBox(height: 40),

              /// ---------- STATISTICS ----------
              LayoutBuilder(
                builder: (context, constraints) {
                  double cardWidth = (constraints.maxWidth - 60) / 4;
                  if (constraints.maxWidth < 1000) {
                    cardWidth = (constraints.maxWidth - 40) / 2;
                  }
                  if (constraints.maxWidth < 600) {
                    cardWidth = constraints.maxWidth - 40;
                  }

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _statCard("Total Brokers", "$totalBrokers", Icons.people,
                          Colors.blue, Colors.blue.shade50, cardWidth),
                      _statCard("Approved", "$approvedBrokers",
                          Icons.verified_user, Colors.green,
                          Colors.green.shade50, cardWidth),
                      _statCard("Pending", "$pendingBrokers",
                          Icons.access_time, Colors.orange,
                          Colors.orange.shade50, cardWidth),
                      _statCard("Verified", "$verifiedBrokers", Icons.star,
                          Colors.purple, Colors.purple.shade50, cardWidth),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              /// ---------- MANAGEMENT TOOLS ----------
              Text(
                "Administrative Tools",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth < 1000 ? 1 : 2;
                  double aspectRatio = constraints.maxWidth < 800 ? 2.5 : 3.0;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: aspectRatio,
                    children: [

                      _actionCard(
                        context,
                        "Manage Brokers",
                        "Review and approve broker profiles",
                        "Open Admin Panel",
                        Icons.settings,
                        onTap: () {
                          context.go('/admin/broker-management');
                        },
                      ),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            // ---- Title with Icon ----

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person, color: Colors.black87, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Broker Directory',
                                      style: GoogleFonts.poppins(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // ---- Description ----
                                Text(
                                  'Explore and connect with other verified brokers',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),


                            const SizedBox(height: 20),

                            // ---- Themed Blue Button ----
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.go('/admin/brokers');
                                },

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white , // 👈 dynamic color
                                  side: BorderSide(
                                    color: kPrimaryColor.withOpacity(0.3), // 👈 soft border tone
                                    width: 1.0,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: kPrimaryColor,
                                  size: 18,
                                ),
                                label: Text(
                                  "View Directory",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /* _actionCard(
                    "System Settings",
                    "Update roles, permissions, and system-wide configurations.",
                    "Manage Settings",
                    Colors.orange,
                    onPressed: () {
                      // 🔹 Navigate to Settings
                    },
                  ),
                  _actionCard(
                    "Broker Activities",
                    "Track and review broker performance insights.",
                    "View Activities",
                    null,
                    outline: true,
                    status: "Active",
                    statusColor: Colors.green,
                    onPressed: () {
                      // 🔹 Navigate to Activities
                    },
                  ),*/
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

  }

  /// ---------- ROLE CHIP ----------
  static Widget _roleChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// ---------- STAT CARD ----------
  static Widget _statCard(String title, String count, IconData icon, Color color,
      Color bgColor, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.white, bgColor.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          Text(count,
              style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  /// ---------- ACTION CARD ----------
  static Widget _actionCard(
      BuildContext context,
      String title,
      String desc,
      String btnText,
      IconData icon,

      {
        Color? color, // 👈 optional custom color
        Color? borderColor,
        VoidCallback? onTap,
      }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ---- Title with Icon ----
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.black87, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ---- Description ----
              Text(
                desc,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ---- Themed Blue Button ----
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? kPrimaryColor, // 👈 dynamic color

                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                btnText,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
