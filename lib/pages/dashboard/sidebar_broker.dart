import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../login/login_page.dart';
import 'admin_shell.dart';

class BrokerSidebar extends StatelessWidget {
  final Map<String, dynamic> userData;
  final int selectedIndex;
  final Function(int) onItemSelected;

  const BrokerSidebar({
    super.key,
    required this.userData,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isVerified = userData['broker']['isVerified'] == true;

    final items = [
      {'icon': Icons.dashboard, 'label': 'Dashboard'},
      {'icon': Icons.home_work, 'label': 'Listings'},
      {'icon': Icons.assignment, 'label': 'Requirements'},
      {'icon': Icons.people, 'label': 'Broker Directory'},
      {'icon': Icons.person, 'label': 'Profile'},
      {'icon': Icons.swap_horiz, 'label': 'My Transactions'},
      {'icon': Icons.assignment_outlined, 'label': 'A2A Forms'},
    ];

    return Container(
      width: 250,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        children: [
          Image.asset('assets/collabrix_logo.png', height: 60),
          const SizedBox(height: 30),

          /// -------- SCROLLABLE MENU --------
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final active = i == selectedIndex;
                final item = items[i];

                // disable A2A Forms & My Transactions if broker not verified
                final bool isRestricted = !isVerified && (i==1 || i==2||i == 5 || i == 6);

                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 0),
                  opacity: isRestricted ? 0.45 : 1,
                  child: AnimatedContainer(
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
                      splashColor:
                      isRestricted ? Colors.transparent : kAccentColor.withOpacity(0.1),
                      hoverColor:
                      isRestricted ? Colors.transparent : kPrimaryColor.withOpacity(0.05),
                      onTap: isRestricted
                          ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Your account is not verified yet. Access to this section is restricted.",
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.orangeAccent,
                          ),
                        );
                      }
                          : () => onItemSelected(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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

                            if (isRestricted)
                              const Icon(
                                Icons.lock_outline,
                                color: Colors.grey,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(),

          /// -------- PROFILE SECTION --------
          _ProfileSection(userData: userData),
        ],
      ),
    );
  }
}


/// ---------- PROFILE SECTION ----------
class _ProfileSection extends StatefulWidget {
  final Map<String, dynamic> userData;
  const _ProfileSection({required this.userData});

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  bool isBrokerView = true;

  @override
  Widget build(BuildContext context) {
    final fullName = '${widget.userData['broker']['displayName'] ?? ''}'.trim();

    final name = fullName.isNotEmpty ? fullName : {widget.userData['broker']['displayName']}.isNotEmpty ? '${widget.userData['broker']['displayName']}':  "";
    final email = widget.userData['broker']['email'] ?? '';
    final avatar = widget.userData['avatar'] ?? '';
    final bool isVerified = widget.userData['broker']['isVerified'] == true;
    final String role = widget.userData['role']?.toString().toUpperCase() ?? 'BROKER';


    return Column(
      children: [


        // Segmented role toggle (Broker ↔ Admin)
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [

              if (role == 'ADMIN') // 👈 only show toggle if admin
              _buildToggleButton(
                label: "Admin",
                active: !isBrokerView,
                color: Colors.orange,
                onTap: () {
                  if (isBrokerView) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminShell(userData: widget.userData),
                      ),
                    );
                  }
                },
              ),

              _buildToggleButton(
                label: "Broker",
                active: isBrokerView,
                color: kPrimaryColor,
                onTap: () => setState(() => isBrokerView = true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),


        // User profile info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: avatar.isNotEmpty
                        ? NetworkImage(avatar)
                        : const AssetImage('assets/collabrix_logo.png') as ImageProvider,
                  ),
                  if (isVerified)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified,
                            size: 16, color: Colors.green),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.black87),
                        overflow: TextOverflow.ellipsis),
                    Text(email,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis),
                    if (!isVerified)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Text(
                                "Not Verified",
                                style: GoogleFonts.poppins(
                                  color: Colors.redAccent,
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



        const SizedBox(height: 20),

        // Logout button
        TextButton.icon(
          onPressed: () => _showLogoutDialog(context),
          icon: const Icon(Icons.logout, color: Colors.red),
          label: Text("Logout",
              style: GoogleFonts.poppins(color: Colors.red)),
        ),
      ],
    );
  }

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
            color: active ? color : Colors.transparent,
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
}

/// ---------- MODERN LOGOUT DIALOG ----------
void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400),
        child:  Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, color: Colors.red, size: 38),
              const SizedBox(height: 14),
              Text("Confirm Logout",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 18)),
              const SizedBox(height: 10),
              Text("Are you sure you want to log out?",
                  style: GoogleFonts.poppins(color: Colors.grey[600])),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("Cancel",
                        style: GoogleFonts.poppins(color: Colors.black87)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      prefs.clear();
                      Navigator.pop(ctx);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
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
