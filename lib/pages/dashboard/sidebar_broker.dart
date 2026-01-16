import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../../services/session_service.dart';
import '../../widgets/web_image_widget.dart';
import '../login/login_page.dart';

class BrokerSidebar extends StatelessWidget {
  final Map<String, dynamic> userData;

  const BrokerSidebar({
    super.key,
    required this.userData,
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
      {'icon': Icons.assignment_outlined, 'label': 'A2A Forms'},
    ];

    final routes = [
      '/broker/dashboard',
      '/broker/listings',
      '/broker/requirements',
      '/broker/brokers',
      '/broker/profile',
      '/broker/forms',
    ];

    final location = GoRouterState.of(context).uri.toString();

    return Container(
      width: 250,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        children: [
          Image.asset('assets/collabrix_logo.png', height: 60),
          const SizedBox(height: 30),

          /// -------- MENU --------
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final bool restrictedByApproval =
                    !isApproved && (i == 1 || i == 2 || i == 5);

                final bool restrictedByVerification =
                (!isVerified && i == 5);

                if (restrictedByApproval || restrictedByVerification) {
                  return const SizedBox.shrink();
                }

                final active = location.startsWith(routes[i]);
                final item = items[i];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 0),
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
                    onTap: () => context.go(routes[i], extra: userData),
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
                                color: active ? kPrimaryColor : Colors.grey.shade800,
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
    final fullName = widget.userData['broker']['displayName'] ?? '';
    final email = widget.userData['broker']['email'] ?? '';
    final role = widget.userData['role']?.toString().toUpperCase() ?? 'BROKER';
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

    final avatar = widget.userData['broker']?['avatar'];
    final imageUrl = avatar != null && avatar.toString().isNotEmpty
        ? avatar.toString().startsWith('http')
        ? avatar
        : '$baseURL/$avatar'
        : null;

    return Column(
      children: [
        /// --- Role Toggle ---
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (role == 'ADMIN')
                _buildToggleButton(
                  label: "Admin",
                  active: !isBrokerView,
                  color: Colors.orange,
                  onTap: () {
                    context.go('/admin/dashboard', extra: widget.userData);
                  },
                ),
              _buildToggleButton(
                label: "Broker",
                active: isBrokerView,
                color: kPrimaryColor,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        /// --- User Card ---
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

                  /// ✅ VERIFIED / UNVERIFIED TICK
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
                    Text(
                      fullName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      email,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 2),

                    /// ✅ Instagram-style verification tick

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

        /// --- Logout ---
        TextButton.icon(
          onPressed: () => showLogoutConfirmation(context),

          icon: const Icon(Icons.logout, color: Colors.red),
          label: Text("Logout",
              style: GoogleFonts.poppins(color: Colors.red)),
        ),
      ],
    );
  }

  Future<void> performLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 🔥 CRITICAL: clear cached user
    SessionService.clearSession();

    // 🔐 GoRouter-safe logout
    context.go('/login');
  }

  Future<void> showLogoutConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ---------- HEADER ----------
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      "Confirm Logout",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// ---------- MESSAGE ----------
                Text(
                  "Are you sure you want to logout from your account?",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                /// ---------- ACTIONS ----------
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
        );
      },
    );

    if (confirmed == true) {
      await performLogout(context);
    }
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
