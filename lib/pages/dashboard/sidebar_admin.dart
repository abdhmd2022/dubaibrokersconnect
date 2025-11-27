import 'package:a2abrokerapp/pages/dashboard/brokerdashboard.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../login/login_page.dart';
import 'broker_shell.dart';

class AdminSidebar extends StatelessWidget {
  final Map<String, dynamic> userData;
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminSidebar({
    super.key,
    required this.userData,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.dashboard, 'label': 'Dashboard'},
      {'icon': Icons.home_work, 'label': 'Listings'},
      {'icon': Icons.assignment, 'label': 'Requirements'},
      {'icon': Icons.people, 'label': 'Broker Directory'},
      {'icon': Icons.person, 'label': 'Profile'},
      // {'icon': Icons.swap_horiz, 'label': 'My Transactions'},
      {'icon': Icons.assignment_outlined, 'label': 'A2A Forms'},
      {
        'icon': Icons.cloud_download_outlined,
        'label': 'Import from Bayut',
        'badge': Icons.workspace_premium_rounded, // 👑 admin-style badge

      },
      {
        'icon': Icons.cloud_download_outlined,
        'label': 'Import from Property Finder',
        'badge': Icons.workspace_premium_rounded, // 👑 admin-style badge
      },

      {
        'icon': Icons.account_tree_outlined,
        'label': 'Broker Management',
        'badge': Icons.workspace_premium_rounded, // 👑 admin-style badge
      },
      {
        'icon': Icons.loyalty_outlined,
        'label': 'Tag Management',
        'badge': Icons.workspace_premium_rounded, // 👑 admin-style badge
      },
      {
        'icon': Icons.apartment_outlined,
        'label': 'Property Types',
        'badge': Icons.workspace_premium_rounded, // 👑 admin-style badge
      },
      {
        'icon': Icons.pin_drop_outlined,
        'label': 'Locations',
        'badge': Icons.workspace_premium_rounded, // 👑 admin-style badge
      },
    ];

    final fullName = '${userData['firstName']} ${userData['lastName']}';
    final avatar = userData['avatar'] ?? '';

    return Container(
      width: 250,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        children: [
          Image.asset('assets/collabrix_logo.png', height: 60),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final active = i == selectedIndex;
                final item = items[i];
                final hasBadge = item['badge'] != null;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 0),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                  decoration: BoxDecoration(
                    color: active ? Colors.white.withOpacity(0.7) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: active
                        ? [
                      BoxShadow(
                        color: kPrimaryColor.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                    ]
                        : [],
                    border: active
                        ? Border.all(color: kPrimaryColor.withOpacity(0.15), width: 1)
                        : null,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onItemSelected(i),
                    splashColor: kAccentColor.withOpacity(0.1),
                    hoverColor: kPrimaryColor.withOpacity(0.05),
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      child: Row(
                        children: [
                          /// --- Left gradient bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 4,
                            height: 26,
                            decoration: BoxDecoration(
                              gradient: active
                                  ? const LinearGradient(
                                colors: [Color(0xFF42A5F5), Color(0xFF478DE0)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                                  : null,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 12),

                          /// --- Gradient Icon
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: active
                                    ? [kPrimaryColor, kAccentColor]
                                    : [Colors.grey.shade500, Colors.grey.shade400],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),

                          /// --- Label
                          Expanded(
                            child: Text(
                              item['label'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: active
                                    ? kPrimaryColor
                                    : Colors.grey.shade800,
                                fontWeight:
                                active ? FontWeight.w600 : FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),

                          /// --- 👑 Admin badge
                          if (hasBadge)
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(),
          _ProfileSection(userData: userData),
        ],
      ),
    );
  }
}


/// ---------- PROFILE SECTION (Admin Sidebar) ----------
class _ProfileSection extends StatefulWidget {
  final Map<String, dynamic> userData;

  const _ProfileSection({required this.userData});

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  bool isAdminView = true;

  @override
  Widget build(BuildContext context) {
    //final fullName = '${widget.userData['firstName']} ${widget.userData['lastName']}';
    final fullName = '${widget.userData['broker']['displayName']}';

    final email = widget.userData['email'] ?? '';
    final isAdmin = widget.userData['role'] == 'ADMIN';
// If Admin → get from user directly
// If Broker → get from broker.avatar
    final avatar = widget.userData['broker']?['avatar'];

    print('avatarrr -> $avatar');
    return Column(
      children: [
        // --- Segmented Role Toggle ---
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _buildToggleButton(
                label: "Admin",
                active: isAdminView,
                color: kPrimaryColor,
                onTap: () => setState(() => isAdminView = true),
              ),
              _buildToggleButton(
                label: "Broker",
                active: !isAdminView,
                color: kPrimaryColor,
                onTap: () {
                  if (isAdminView) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BrokerShell(
                          userData: widget.userData,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // --- User Card with Crown Badge Below Email ---
        Container(
          padding: const EdgeInsets.all(14),
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
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: avatar.isNotEmpty
                    ? NetworkImage('$baseURL/$avatar')
                    : const AssetImage('assets/collabrix_logo.png') as ImageProvider,
              ),
              const SizedBox(width: 12),

              // --- Name + Email + Badge ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.workspace_premium_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Admin",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --- Logout Button ---
        TextButton.icon(
          onPressed: () => _showLogoutDialog(context),
          icon: const Icon(Icons.logout, color: Colors.red),
          label: Text(
            "Logout",
            style: GoogleFonts.poppins(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// --- Toggle Button ---
  Widget _buildToggleButton({
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
              colors: [color, kPrimaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: active ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: active ? Colors.white : Colors.grey[800],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// --- Logout Dialog ---
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, color: Colors.red, size: 40),
              const SizedBox(height: 16),
              Text(
                "Confirm Logout?",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                "Are you sure you want to logout?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel",
                        style: GoogleFonts.poppins(color: Colors.grey[700])),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                    ),
                    onPressed: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      prefs.clear();
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: Text("Logout",
                        style: GoogleFonts.poppins(color: Colors.white)),
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
}


