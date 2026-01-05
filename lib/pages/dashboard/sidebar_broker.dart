import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../../widgets/web_image_widget.dart';
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
    final bool isApproved = userData['broker']['approvalStatus'] == "APPROVED";
    final bool isVerified = userData['broker']['isVerified'] == true;

    final items = [
      {'icon': Icons.dashboard, 'label': 'Dashboard'},
      {'icon': Icons.home_work, 'label': 'Listings'},
      {'icon': Icons.assignment, 'label': 'Requirements'},
      {'icon': Icons.people, 'label': 'Broker Directory'},
      {'icon': Icons.person, 'label': 'Profile'},
      // {'icon': Icons.swap_horiz, 'label': 'My Transactions'},
      {'icon': Icons.assignment_outlined, 'label': 'A2A Forms'},
      /*{
        'icon': Icons.cloud_download_outlined,
        'label': 'Import from Bayut',
      },
      {
        'icon': Icons.cloud_download_outlined,
        'label': 'Import from Property Finder',
      },*/
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
                final bool restrictedByApproval =
                    !isApproved && (i == 1 || i == 2 || i == 5 || i == 6 || i == 7 || i == 8);

                final bool restrictedByVerification = (!isVerified && i == 5);

                final bool isRestricted = restrictedByApproval || restrictedByVerification;

                if (isRestricted) {
                  return const SizedBox.shrink();
                }


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
                    splashColor: kAccentColor.withOpacity(0.1),
                    hoverColor: kPrimaryColor.withOpacity(0.05),
                    onTap: () => onItemSelected(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      child: Row(
                        children: [
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
                          Expanded(
                            child: Text(
                              item['label'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color:
                                active ? kPrimaryColor : Colors.grey.shade800,
                                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
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
    final isAdmin = widget.userData['role'] == 'ADMIN';

    final avatar = widget.userData['broker']?['avatar'];
    print('avatar r -> $avatar');

    // Determine the full image URL - handle both absolute and relative paths
    final String? imageUrl = (avatar != null && avatar.toString().isNotEmpty)
        ? (avatar.toString().startsWith('http://') || avatar.toString().startsWith('https://'))
        ? avatar.toString()
        : '$baseURL/$avatar'
        : null;

    final name = fullName.isNotEmpty ? fullName : {widget.userData['broker']['displayName']}.isNotEmpty ? '${widget.userData['broker']['displayName']}':  "";
    final email = widget.userData['broker']['email'] ?? '';
    final bool isVerified = widget.userData['broker']['isVerified'] == true;
    final bool isApproved = widget.userData['broker']['approvalStatus'] == "APPROVED";
    String finalStatus = "";

    if (isApproved && isVerified) {
      finalStatus = "Verified";
    } else if (isApproved && !isVerified) {
      finalStatus = "Approved";
    } else {
      finalStatus = "Not Approved";
    }

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
                    backgroundColor: Colors.grey.shade200,
                    child: imageUrl != null
                        ? ClipOval(
                      child: WebCompatibleImage(
                        imageUrl: imageUrl,
                        width: 40,
                        height: 40,
                        fallback: Image.asset(
                          'assets/collabrix_logo.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                        : Image.asset(
                      'assets/collabrix_logo.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
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
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: finalStatus == "Verified"
                              ? Colors.green.withOpacity(0.12)
                              : finalStatus == "Approved"
                              ? Colors.orange.withOpacity(0.12)
                              : Colors.redAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: finalStatus == "Verified"
                                ? Colors.green.withOpacity(0.6)
                                : finalStatus == "Approved"
                                ? Colors.orange.withOpacity(0.6)
                                : Colors.redAccent.withOpacity(0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              finalStatus == "Verified"
                                  ? Icons.verified_rounded
                                  : finalStatus == "Approved"
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              size: 14,
                              color: finalStatus == "Verified"
                                  ? Colors.green
                                  : finalStatus == "Approved"
                                  ? Colors.orange
                                  : Colors.redAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              finalStatus,
                              style: GoogleFonts.poppins(
                                color: finalStatus == "Verified"
                                    ? Colors.green
                                    : finalStatus == "Approved"
                                    ? Colors.orange
                                    : Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )


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
