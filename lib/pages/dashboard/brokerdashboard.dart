import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_logo_loader.dart';
import '../listings/listings_screen.dart';
import 'package:http/http.dart' as http;

import '../listings/property_details_screen.dart';

class BrokerDashboardContent extends StatelessWidget {
  final VoidCallback? onNavigateToListings;
  final VoidCallback? onNavigateToRequirements;
  final VoidCallback? onNavigateToMyTransactions;
  final VoidCallback? onNavigateToBrokers;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToA2aForms;


  final Map<String, dynamic> userData;

  const BrokerDashboardContent({super.key, required this.userData,
  this.onNavigateToListings,
  this.onNavigateToRequirements,
  this.onNavigateToMyTransactions,
  this.onNavigateToBrokers,
  this.onNavigateToProfile,
  this.onNavigateToA2aForms,
  });

  void _viewPropertyDetails(BuildContext context, Map<String, dynamic> property) {
    print('property -> $property');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailsScreen(propertyData: property),
      ),
    );
  }


  Widget buildRequirementDrawerPanel(BuildContext context, Map<String, dynamic> req, VoidCallback onClose) {
    final broker = req['broker'] ?? {};
    final location = (req['locations'] != null && req['locations'].isNotEmpty)
        ? req['locations'][0]['completeAddress']
        : 'N/A';

    final priceRange = (req['transactionType'] == 'RENT')
        ? "AED ${req['minPrice']} - ${req['maxPrice']} /yr"
        : "AED ${req['minPrice']} - ${req['maxPrice']}";
    // 🌐 Social Links Section
    final social = broker['socialLinks'] as Map<String, dynamic>? ?? {};

    final hasAnySocial = [
      social['linkedin'],
      social['instagram'],
      social['facebook'],
      social['twitter'],
    ].any((link) => link != null && link.toString().isNotEmpty);

    return Material(
      color: Colors.white,
      elevation: 20,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        bottomLeft: Radius.circular(30),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            bottomLeft: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.1),
              blurRadius: 25,
              spreadRadius: 3,
              offset: const Offset(-5, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(26),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [kPrimaryColor, kAccentColor],
                      ).createShader(bounds),
                      child: Text("Requirement Overview",
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [kPrimaryColor.withOpacity(0.9), kAccentColor],
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: onClose,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // --- Requirement Info ---
                _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(Icons.apartment_rounded, "Requirement Details"),
                      const SizedBox(height: 10),

                      // 🏷️ Basic Info
                      _infoRow(Icons.title_rounded, "Title", req['title']),
                      _infoRow(Icons.apartment_rounded, "Property Type", req['propertyTypeName']),
                      _infoRow(Icons.location_on_outlined, "Location", location),
                      _infoRow(Icons.numbers_rounded, "Reference", req['referenceNumber']),
                      _infoRow(Icons.category_outlined, "Category", req['category']),
                      _infoRow(Icons.compare_arrows_rounded, "Type", req['transactionType']),
                      _infoRow(Icons.timeline_rounded, "Listing", req['listingStatus']),

                      const SizedBox(height: 10),

                      // 💰 Price Range
                      _sectionHeader(Icons.monetization_on_rounded, "Price Range"),
                      const SizedBox(height: 6),
                      _infoRow(Icons.trending_up_rounded, "Min Price", "AED ${req['minPrice'] ?? 'N/A'}"),
                      _infoRow(Icons.trending_down_rounded, "Max Price", "AED ${req['maxPrice'] ?? 'N/A'}"),

                      const SizedBox(height: 10),

                      // 📏 Size Range
                      _sectionHeader(Icons.square_foot_rounded, "Size Range (sqft)"),
                      const SizedBox(height: 6),
                      _infoRow(Icons.expand_less_rounded, "Min Size", "${req['minSizeSqft'] ?? 'N/A'} sqft"),
                      _infoRow(Icons.expand_more_rounded, "Max Size", "${req['maxSizeSqft'] ?? 'N/A'} sqft"),

                      const SizedBox(height: 10),

                      // 📝 Description
                      _sectionHeader(Icons.description_outlined, "Description"),
                      const SizedBox(height: 6),
                      Text(
                        req['requirementDescription']?.toString().isNotEmpty == true
                            ? req['requirementDescription']
                            : 'No description provided',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),




                const SizedBox(height: 10),

                // --- Broker Info ---
                _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(Icons.person_pin_rounded, "Broker Information"),
                      const SizedBox(height: 14),

                      // 👤 Broker Profile Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(
                              broker['user']?['avatar'] ??
                                  'https://via.placeholder.com/100',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  broker['displayName'] ?? 'N/A',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                Text(
                                  broker['email'] ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey.shade700),
                                ),
                                Text(
                                  broker['mobile'] ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 🏢 Basic Info
                      _infoRow(Icons.location_city_rounded, "Address", broker['address']),
                      _infoRow(Icons.web_asset_rounded, "Website", broker['website']),
                      _infoRow(Icons.badge_rounded, "RERA", broker['reraNumber']),


                      if (hasAnySocial) ...[
                        const SizedBox(height: 18),
                        _sectionHeader(Icons.share_rounded, "Social Links"),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (social['linkedin'] != null && social['linkedin'].toString().isNotEmpty)
                              _socialIconButton(
                                icon: FontAwesomeIcons.linkedin, // ✅ authentic icon
                                label: "Linkedin",
                                url: social['linkedin'],
                                iconColor: const Color(0xFF0A66C2),
                              ),
                            if (social['instagram'] != null && social['instagram'].toString().isNotEmpty)
                              _socialIconButton(
                                icon: FontAwesomeIcons.instagram, // ✅ authentic icon
                                label: "Instagram",
                                url: social['instagram'],
                                iconColor: const Color(0xFFE4405F),
                              ),
                            if (social['facebook'] != null && social['facebook'].toString().isNotEmpty)
                              _socialIconButton(
                                icon: FontAwesomeIcons.facebook, // ✅ authentic icon
                                label: "Facebook",
                                url: social['facebook'],
                                iconColor: const Color(0xFF1877F2),
                              ),
                            if (social['twitter'] != null && social['twitter'].toString().isNotEmpty)
                              _socialIconButton(
                                icon: FontAwesomeIcons.xTwitter, // ✅ authentic icon
                                label: "Twitter",
                                url: social['twitter'],
                                iconColor: Colors.black,
                              ),
                          ],
                        ),
                      ],


                      // ⭐ Specializations
                      if (broker['specializations'] != null &&
                          broker['specializations'].isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _sectionHeader(Icons.star_rate_rounded, "Specializations"),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: List.generate(
                            broker['specializations'].length,
                                (i) => _tag(broker['specializations'][i]),
                          ),
                        ),
                      ],

                      // 🌍 Languages
                      if (broker['languages'] != null &&
                          broker['languages'].isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _sectionHeader(Icons.language_rounded, "Languages"),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: List.generate(
                            broker['languages'].length,
                                (i) => _tag(broker['languages'][i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),






              ],
            ),
          ),
        ),
      ),
    );
  }
  void _openRequirementDrawer(BuildContext context, Map<String, dynamic> req) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        return Align(
          alignment: Alignment.centerRight,
          child: buildRequirementDrawerPanel(context, req, () {
            Navigator.pop(context);
          }),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation =
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(animation);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final String fullName =
    '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
    final bool isVerified = userData['broker']['isVerified'] == true;
    final bool isApproved = userData['broker']['approvalStatus'] == "APPROVED";

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Align(
        alignment: Alignment.topCenter, // 👈 ensures top placement
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
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
                  if (isApproved)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child:
                      _roleChip("Approved", Colors.orange, Icons.approval_rounded),
                    ),
                  if (isVerified)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child:
                      _roleChip("Verified", Colors.green, Icons.verified_rounded),
                    ),
                ],
              ),

              if (!isVerified && !isApproved)
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

                  return FutureBuilder(
                    future: () async {
                      final token = await AuthService.getToken();
                      final response = await http.get(
                        Uri.parse('$baseURL/api/brokers/${userData['broker']['id']}/stats'),
                        headers: {'Authorization': 'Bearer $token'},
                      );
                      return jsonDecode(response.body);
                    }(),
                    builder: (context, snapshot) {
                      /*  if (!snapshot.hasData) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 80),
                          AnimatedLogoLoader(assetPath: 'assets/collabrix_logo.png'),
                        ],
                      ),
                    );
                  }*/

                      final data = snapshot.data?['data'] ?? {};
                      final properties = data['properties'] ?? {};
                      final requirements = data['requirements'] ?? {};
                      final brokers = data['brokers'] ?? {};

                      final activeListings = properties['active']?.toString() ?? '0';
                      final activeRequirements = requirements['active']?.toString() ?? '0';
                      final approvedBrokers = brokers['approved']?.toString() ?? '0';

                      return Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _statCard(
                            "Active Listings",
                            activeListings,
                            Icons.home_work_outlined,
                            Colors.blue,
                            Colors.blue.shade50,
                            cardWidth,
                          ),
                          _statCard(
                            "Active Requirements",
                            activeRequirements,
                            Icons.pending_actions,
                            Colors.orange,
                            Colors.orange.shade50,
                            cardWidth,
                          ),
                          _statCard(
                            "Approved Brokers",
                            approvedBrokers,
                            Icons.verified_user,
                            Colors.green,
                            Colors.green.shade50,
                            cardWidth,
                          ),
                        ],
                      );
                    },
                  );

                },
              ),

              const SizedBox(height: 30),

              /// ---------- MANAGEMENT TOOLS ----------


              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 3.3,
                children: [
                  /*_actionCard(
                    context,

                    "My Listings",
                    "Manage and update your property listings in real-time.",
                    "Open Listings",
                    kPrimaryColor,
                    onTap: onNavigateToListings,
                  ),*/

                  /*  _actionCard(
                    context,

                    "Client Requirements",
                    "View and match client requirements with suitable properties.",
                    "View Requirements",
                    Colors.orange,
                    outline: true,
                    onTap: onNavigateToRequirements,
                  ),*/

                  _actionCard(
                    context,
                    "Broker Directory",
                    "Explore and connect with other verified brokers",
                    "View Directory",
                    Icons.apartment_rounded,
                    onTap: onNavigateToBrokers,
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
                      children: [
                        // ---- Title with Icon ----
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.black87, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              "My Profile",
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
                          'Manage your profile and credentials',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ---- Themed Blue Button ----
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: onNavigateToProfile,
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
                              "My Profile",
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

                ],
              ),
              const SizedBox(height: 30),

// ---------- LATEST ACTIVE LISTINGS ----------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Latest Listings",
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),

                        ),
                        TextButton(
                          onPressed: onNavigateToListings,
                          child: const Text("View All →"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder(
                      future: () async {
                        final token = await AuthService.getToken();
                        return await http.get(
                          Uri.parse('$baseURL/api/properties?page=1&limit=100'),
                          headers: {'Authorization': 'Bearer $token'},
                        );
                      }(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 80),
                                AnimatedLogoLoader(assetPath: 'assets/collabrix_logo.png'),
                              ],
                            ),
                          );
                        }

                        final response = jsonDecode(snapshot.data!.body);
                        final all = (response['data'] ?? []) as List;

                        // ✅ Filter only active listings
                        final active = all.where((item) {
                          final status =
                          (item['listingStatus'] ?? '').toString().trim().toLowerCase();
                          return status == 'active';
                        }).toList();

                        // ✅ Sort by newest first
                        active.sort((a, b) {
                          final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
                          final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
                          return bDate.compareTo(aDate);
                        });

                        final latest = active.take(5).toList();

                        if (latest.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text("No active listings available."),
                          );
                        }

                        return Column(
                          children: latest.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;

                            final isEven = index % 2 == 0;
                            final bgColor = isEven ? Colors.grey.shade50 : Colors.white;

                            String completeAddress = "";

                          // Get location safely
                            final loc = item['location'];

                            // Case 1: location is a Map
                            if (loc is Map<String, dynamic>) {
                              completeAddress = loc['completeAddress']?.toString() ?? "";
                            }
                            // Case 2: location is string
                            else if (loc is String) {
                              completeAddress = loc;
                            }
                            // Case 3: location is null → use address or empty
                            else {
                              completeAddress = item['address']?.toString() ?? "";
                            }

                            // Final fallback
                            if (completeAddress.isEmpty) {
                              completeAddress = "Unknown";
                            }



                            print('completeAddress -> $completeAddress');
                            final transaction = (item['transactionType'] ?? '').toString();
                            final numPrice = double.tryParse(item['price']?.toString() ?? '') ?? 0;
                            final formattedPrice = NumberFormat('#,##0').format(numPrice);
                            final price = "${item['currency'] ?? 'AED'} $formattedPrice";
                            final size = item['sizeSqft']?.toString() ?? '-';


                            final rentTag = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),

                              child: Text(
                                transaction,
                                style: GoogleFonts.poppins(
                                  color: Colors.green.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            rentTag,
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                item['title'] ?? 'Untitled Property',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          price,
                                          style: GoogleFonts.poppins(
                                            color: Colors.blueAccent.shade400,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined,
                                                size: 13, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                "$completeAddress • ${item['sizeSqft'] ?? ''} sqft",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    onPressed: () => _viewPropertyDetails(context, item),
                                    icon: const Icon(Icons.arrow_forward_ios_rounded,
                                        size: 13, color: kPrimaryColor),
                                    label: const Text(
                                      "View",
                                      style: TextStyle(
                                        color: kPrimaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: kPrimaryColor, width: 1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );

                      },
                    ),
                  ],
                ),
              ),

// ---------- LATEST REQUIREMENTS ----------

              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Latest Requirements",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: onNavigateToRequirements,
                          child: const Text("View All →"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    FutureBuilder(
                      future: () async {
                        final token = await AuthService.getToken();
                        return await http.get(
                          Uri.parse('$baseURL/api/requirements?page=1&limit=100'),
                          headers: {'Authorization': 'Bearer $token'},
                        );
                      }(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 80),
                                AnimatedLogoLoader(assetPath: 'assets/collabrix_logo.png'),
                              ],
                            ),
                          );
                        }

                        final response = jsonDecode(snapshot.data!.body);
                        final all = (response['data'] ?? []) as List;

                        // ✅ Filter only active
                        final active = all.where((r) {
                          final status = (r['listingStatus'] ?? '').toString().toLowerCase();
                          return status == 'active';
                        }).toList();

                        // ✅ Sort newest first
                        active.sort((a, b) {
                          final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
                          final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
                          return bDate.compareTo(aDate);
                        });

                        final latest = active.take(5).toList();

                        if (latest.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text("No active requirements available."),
                          );
                        }

                        return Column(
                          children: latest.asMap().entries.map((entry) {
                            final index = entry.key;
                            final r = entry.value;

                            final isEven = index % 2 == 0;
                            final bgColor = isEven ? Colors.grey.shade50 : Colors.white;

                            final transaction = (r['transactionType'] ?? '').toString();
                            final location = (r['locations'] != null && r['locations'].isNotEmpty)
                                ? r['locations'][0]['completeAddress'] ?? 'Unknown'
                                : 'Unknown';

                            print('locations -> $location');

                            final numMinPrice = double.tryParse(r['minPrice']?.toString() ?? '') ?? 0;
                            final numMaxPrice = double.tryParse(r['maxPrice']?.toString() ?? '') ?? 0;
                            final formattedMin = NumberFormat('#,##0').format(numMinPrice);
                            final formattedMax = NumberFormat('#,##0').format(numMaxPrice);

                            final priceRange = "${r['currency'] ?? 'AED'} $formattedMin"
                                "${numMaxPrice > 0 ? ' - $formattedMax' : ''}";

                            final minSize = r['minSizeSqft'] ?? '-';
                            final maxSize = r['maxSizeSqft'] ?? '-';
                            final sizeRange = "$minSize - $maxSize sqft";

                            // 🏠 Rooms exact list
                            final List<dynamic> roomList = (r['rooms'] ?? []);
                            final roomText = roomList.isNotEmpty
                                ? roomList.map((room) => "${room.toString()} BR").join(' • ')
                                : "N/A";

                            final tag = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                transaction,
                                style: GoogleFonts.poppins(
                                  color: Colors.green.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );

                            final roomChip = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.king_bed_outlined,
                                      color: Colors.orange, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    roomText,
                                    style: GoogleFonts.poppins(
                                      color: Colors.orange.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200, width: 0.7),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            tag,

                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                r['title'] ?? 'Untitled Requirement',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              priceRange,
                                              style: GoogleFonts.poppins(
                                                color: Colors.blueAccent.shade400,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 6),

                                            roomChip,
                                          ],
                                        ),

                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined,
                                                size: 13, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                "$location • $sizeRange",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    onPressed: () => _openRequirementDrawer(context, r),
                                    icon: const Icon(Icons.arrow_forward_ios_rounded,
                                        size: 13, color: kPrimaryColor),
                                    label: const Text(
                                      "View",
                                      style: TextStyle(
                                        color: kPrimaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: kPrimaryColor, width: 1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding:
                                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );

                      },
                    ),
                  ],
                ),
              )


            ],
          ),
        )
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
        children: [
          // ---- Title with Icon ----
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



  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [kPrimaryColor, kAccentColor],
          ).createShader(bounds),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 14.5, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [kPrimaryColor, kAccentColor],
            ).createShader(bounds),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13.5),
                children: [
                  TextSpan(
                      text: "$label: ",
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(
                      text: value != null && value.toString().isNotEmpty
                          ? value.toString()
                          : "N/A",
                      style: const TextStyle(fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(color: kPrimaryColor, fontSize: 12.5),
      ),
    );
  }
  Widget _socialIconButton({
    required IconData icon,
    required String label,
    required String url,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
