import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants.dart';

class UnverifiedBrokerDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UnverifiedBrokerDashboard({
    super.key,
    required this.userData,

  });
  @override
  State<UnverifiedBrokerDashboard> createState() => UnverifiedBrokerDashboardState();
}

class UnverifiedBrokerDashboardState extends State<UnverifiedBrokerDashboard> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Align(
        alignment: Alignment.topCenter, // 👈 ensures top placement
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(40, 40, 40, 30), // top padding instead of centering
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// --- Heading
              Row(
                children: [
                  Text(
                    "Dashboard",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: kPrimaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.business_center_rounded,
                            size: 14, color: kPrimaryColor),
                        const SizedBox(width: 4),
                        Text(
                          "Broker",
                          style: GoogleFonts.poppins(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Welcome ${widget.userData['broker'] != null ? widget.userData['broker']!['displayName'] : widget.userData['name'] ?? ""} ",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 30),

              /// --- Profile Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 22, color: Colors.black87),
                        const SizedBox(width: 8),
                        Text(
                          "Profile Status",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    /// --- Status Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFB74D), width: 1),
                      ),
                      child: Text(
                        "Pending Review",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFEF6C00),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      "Your profile is under review by our admin team",
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFFE082),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Note:",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFEF6C00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Your profile is not visible in the broker directory while under review.",
                              style: GoogleFonts.poppins(
                                color: Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              /// --- Two Cards (Update Profile & Browse Directory)
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      icon: Icons.person,
                      title: "View Profile",
                      description: "Review your profile while waiting for approval",
                      buttonLabel: "View Profile",
                      color: kPrimaryColor,
                      onPressed: () {
                        context.go('/broker/profile');
                      }
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildInfoCard(
                      icon: Icons.apartment_rounded,
                      title: "Browse Directory",
                      description: "Explore our community of real estate professionals",
                      buttonLabel: "View Directory",
                      color: Colors.black87,
                      outlined: true,
                        onPressed: () {
                          context.go('/broker/brokers');
                        }
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

  /// --- Reusable Card Builder
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonLabel,
    required Color color,
    bool outlined = false,
    required VoidCallback? onPressed,

  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onPressed,


              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                outlined ? Colors.white : color, // filled or outline
                side: outlined
                    ? BorderSide(color: Colors.grey.shade400)
                    : BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonLabel,
                    style: GoogleFonts.poppins(
                      color: outlined ? Colors.black87 : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: outlined ? Colors.black87 : Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
