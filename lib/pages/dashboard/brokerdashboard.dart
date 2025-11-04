import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants.dart';
import '../listings/listings_screen.dart';

class BrokerDashboardContent extends StatelessWidget {
  final VoidCallback? onNavigateToListings;
  final VoidCallback? onNavigateToRequirements;
  final VoidCallback? onNavigateToTransactions;
  final VoidCallback? onNavigateToBrokers;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToA2aForms;


  final Map<String, dynamic> userData;

  const BrokerDashboardContent({super.key, required this.userData,
  this.onNavigateToListings,
  this.onNavigateToRequirements,
  this.onNavigateToTransactions,
  this.onNavigateToBrokers,
  this.onNavigateToProfile,
  this.onNavigateToA2aForms,
  });

  @override
  Widget build(BuildContext context) {
    final String fullName =
    '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
    final bool isVerified = userData['broker']['isVerified'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ---------- HEADER ----------
          Row(
            children: [
              Text(
                "Broker Dashboard",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 10),
              _roleChip("Broker", kPrimaryColor, Icons.badge_outlined),
              if (isVerified)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child:
                  _roleChip("Verified", Colors.green, Icons.verified_rounded),
                ),
            ],
          ),

          if (!isVerified)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "Your account is not verified yet",
                    style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 40),

          /// ---------- SAMPLE CARDS / STATS ----------
          LayoutBuilder(
            builder: (context, constraints) {
              double cardWidth = (constraints.maxWidth - 60) / 3;
              if (constraints.maxWidth < 1000) cardWidth = (constraints.maxWidth - 40) / 2;
              if (constraints.maxWidth < 600) cardWidth = constraints.maxWidth - 40;

              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _statCard("Active Listings", "34",
                      Icons.home_work_outlined, Colors.blue, Colors.blue.shade50, cardWidth),
                  _statCard("Pending Deals", "7",
                      Icons.pending_actions, Colors.orange, Colors.orange.shade50, cardWidth),
                  _statCard("Closed Deals", "12",
                      Icons.verified_user, Colors.green, Colors.green.shade50, cardWidth),
                ],
              );
            },
          ),

          const SizedBox(height: 40),

          /// ---------- MANAGEMENT TOOLS ----------
          Text(
            "Broker Tools",
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth < 800 ? 1 : 2;
              double aspectRatio = constraints.maxWidth < 800 ? 2.0 : 2.5;

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
                    "My Listings",
                    "Manage and update your property listings in real-time.",
                    "Open Listings",
                    kPrimaryColor,
                    onTap: onNavigateToListings,
                  ),

                  _actionCard(
                    context,

                    "Client Requirements",
                    "View and match client requirements with suitable properties.",
                    "View Requirements",
                    Colors.orange,
                    outline: true,
                    onTap: onNavigateToRequirements,
                  ),
                  _actionCard(
                    context,
                    "Transactions",
                    "Track ongoing and completed transactions easily.",
                    "View Transactions",
                    Colors.teal,
                    onTap: () {
                      // 🔹 Navigate to Manage Brokers screen
                    },
                  ),
                  _actionCard(
                    context,
                    "Broker Directory",
                    "Explore and connect with other verified brokers.",
                    "Open Directory",
                    null,
                    outline: true,
                    onTap: onNavigateToBrokers,
                  ),
                ],
              );
            },
          ),
        ],
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
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(title, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          Text(count,
              style: GoogleFonts.poppins(
                  fontSize: 26, fontWeight: FontWeight.w700, color: Colors.black87)),
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
      Color? color, {
        bool outline = false,
        VoidCallback? onTap,
      }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(desc, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: outline ? Colors.white : color ?? kPrimaryColor,
                side: outline
                    ? BorderSide(color: Colors.grey.shade300)
                    : BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: onTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    btnText,
                    style: GoogleFonts.poppins(
                      color: outline ? Colors.black87 : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward,
                      size: 16, color: outline ? Colors.black87 : Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
