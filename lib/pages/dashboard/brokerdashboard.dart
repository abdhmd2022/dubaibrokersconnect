import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants.dart';
import 'admindashboard.dart';
import 'package:a2abrokerapp/pages/login/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


class BrokerDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;
  const BrokerDashboard({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fullName =
    '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
    final email = userData['email'] ?? '';
    final avatar = userData['avatar'] ?? '';
    final isAdmin = userData['role'] == 'ADMIN';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                // --- Fixed top logo ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  child: SizedBox(
                    height: 150,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Image.asset('assets/collabrix_logo.png'),
                    ),
                  ),
                ),

                // --- Scrollable middle menu section ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        _buildSidebarItem(Icons.dashboard, "Dashboard", true),
                        _buildSidebarItem(Icons.home_work, "Listings", false),
                        _buildSidebarItem(Icons.assignment, "Requirements", false),
                        _buildSidebarItem(Icons.people, "Broker Directory", false),
                        _buildSidebarItem(Icons.person, "View My Profile", false),
                        _buildSidebarItem(Icons.swap_horiz, "My Transactions", false),
                        _buildSidebarItem(Icons.help_outline, "FAQs", false),
                      ],
                    ),
                  ),
                ),

                // --- Fixed bottom section (switch + profile + logout) ---
                Divider(color: Colors.grey.shade300),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // ---- Profile Card with "View as Broker" Switch ----
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isAdmin)...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AdminDashboard(userData: userData),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),

                                          child: Center(
                                            child: Text("Admin",
                                                style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey.shade700)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {

                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: kPrimaryColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text("Broker",
                                                style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    color: kPrimaryColor)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],




                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: avatar.isNotEmpty
                                      ? NetworkImage(avatar)
                                      : const AssetImage('assets/collabrix_logo.png') as ImageProvider,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(fullName,
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600, fontSize: 13)),
                                      Text(email,
                                          style: GoogleFonts.poppins(
                                              fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isAdmin
                                      ? Icons.admin_panel_settings
                                      : Icons.badge_outlined,
                                  color: isAdmin ? Colors.orange : Colors.blue,
                                  size: 20,
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => _showLogoutDialog(context),
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: Text(
                          "Logout",
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      ),


                    ],
                  ),
                ),

              ],
            ),
          ),

          /// ---------- MAIN CONTENT ----------
          Expanded(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text("Broker Dashboard",
                          style: GoogleFonts.poppins(
                              fontSize: 28, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 10),
                      _roleChip("Broker", Colors.blue, Icons.badge),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Welcome back, $fullName (Broker)",
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 40),

                  // Summary Cards
                  LayoutBuilder(builder: (context, constraints) {
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
                        _summaryCard("Active Listings", "8", Icons.home_work,
                            Colors.blue.shade100, Colors.blue, cardWidth),
                        _summaryCard("Collaborations", "4", Icons.handshake,
                            Colors.teal.shade100, Colors.teal, cardWidth),
                        _summaryCard("Pending Deals", "2", Icons.access_time,
                            Colors.amber.shade100, Colors.orange, cardWidth),
                        _summaryCard("Completed", "5", Icons.verified,
                            Colors.green.shade100, Colors.green, cardWidth),
                      ],
                    );
                  }),
                  const SizedBox(height: 40),

                  // Recent Collaborations
                  Text("Recent Collaborations",
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  _buildRecentCollaborations(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sidebar item
  static Widget _buildSidebarItem(IconData icon, String title, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon,
            color: active ? kPrimaryColor : Colors.grey.shade700, size: 22),
        title: Text(title,
            style: GoogleFonts.poppins(
                color: active ? kPrimaryColor : Colors.black87,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: active ? kPrimaryColor.withOpacity(0.08) : null,
        onTap: () {},
      ),
    );
  }

  /// Role Chip
  static Widget _roleChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.poppins(
                  color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  /// Summary Card
  static Widget _summaryCard(String title, String count, IconData icon,
      Color bgColor, Color iconColor, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(count,
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  /// Recent Collaborations
  static Widget _buildRecentCollaborations() {
    final List<Map<String, dynamic>> collaborations = [
      {
        'broker': 'Ali Khan',
        'project': 'Downtown Heights',
        'status': 'In Progress',
        'color': Colors.orange
      },
      {
        'broker': 'Sana Ahmed',
        'project': 'Palm Residence',
        'status': 'Completed',
        'color': Colors.green
      },
      {
        'broker': 'Zain Malik',
        'project': 'Marina Towers',
        'status': 'Pending',
        'color': Colors.blue
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: collaborations.map((item) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: (item['color'] as Color).withOpacity(0.1),
              child: Icon(Icons.business, color: item['color'] as Color),
            ),
            title: Text(item['project'],
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text("Broker: ${item['broker']}",
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(item['status'],
                  style: GoogleFonts.poppins(
                      color: item['color'] as Color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360), // limit width
            child: Dialog(
              elevation: 12,
              backgroundColor: Colors.white, // solid white background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout, color: Colors.red, size: 30),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "Confirm Logout",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Are you sure you want to log out from your account?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                              const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.clear();

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginPage()),
                                    (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              padding:
                              const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: kPrimaryColor,
                            ),
                            child: Text(
                              "Logout",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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
      },
    );
  }

}
