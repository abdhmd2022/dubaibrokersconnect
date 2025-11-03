import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/animated_logo_loader.dart';

class BrokerProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;


  final String brokerId;
  const BrokerProfileScreen({super.key, required this.brokerId,
  required this.userData});

  @override
  State<BrokerProfileScreen> createState() => _BrokerProfileScreenState();
}

class _BrokerProfileScreenState extends State<BrokerProfileScreen> {
  Map<String, dynamic>? broker;
  bool loading = true;
  bool error = false;
  String activeSection = "Listings";
  String hoveredSocial = '';

  @override
  void initState() {
    super.initState();


    // Default selection based on broker verification
    final isVerified = widget.userData['broker']['isVerified'] == true;
    activeSection = isVerified ? "Listings" : "Reviews";

    fetchBrokerById();
  }

  Future<void> fetchBrokerById() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseURL/api/brokers/${widget.brokerId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          broker = jsonData['data'];

          loading = false;
        });
      } else {
        setState(() {
          error = true;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = true;
        loading = false;
      });
    }
  }

  Future<void> _launch(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: AnimatedLogoLoader(assetPath: 'assets/collabrix_logo.png'),),
      );
    }

    if (error || broker == null) {
      return Scaffold(
        backgroundColor: backgroundColor,

        body: Center(
          child: Text("Failed to load broker details.",
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.black54)),
        ),
      );
    }

    final name = broker!['displayName'] ?? '';
    final company = broker!['companyName'] ?? '';
    final verified = broker!['isVerified'] == true;
    final avatar = broker!['user']?['avatar'];
    final email = broker!['email'];
    final phone = broker!['mobile'];
    final bio = broker!['bio'] ?? '';
    final rating = broker!['rating'] ?? 'N/A';
    final requirements = broker!['requirements'] ?? [];
    final reviews = broker!['reviews'] ?? [];
    final properties = broker!['properties'] ?? [];
    final List<String> languages = List<String>.from(broker?['languages'] ?? []);
    final List<String> categories = List<String>.from(broker?['categories'] ?? []);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
        Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 🔙 Back Button
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios_new,
                      size: 13, color: kPrimaryColor),
                  const SizedBox(width: 4),
                  Text(
                    "Back to Broker Directory",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: kPrimaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🧑‍💼 Header Content
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 👤 Avatar
                CircleAvatar(
                  radius: 45,
                  backgroundColor: kPrimaryColor.withOpacity(0.08),
                  child: ClipOval(
                    child: avatar != null && avatar.isNotEmpty
                        ? Image.network(
                      avatar,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/collabrix_logo.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                        );
                      },
                    )
                        : Image.asset(
                      'assets/collabrix_logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // 🧾 Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Verified Status
                      Row(
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (verified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.shade300,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.verified,
                                      color: Colors.green.shade700, size: 16),
                                  const SizedBox(width: 3),
                                  Text(
                                    "Verified",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.redAccent.shade400,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.cancel_outlined,
                                      color: Colors.redAccent.shade700, size: 16),
                                  const SizedBox(width: 3),
                                  Text(
                                    "Not Verified",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.redAccent.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // 🏢 Company
                      if (company.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.business_outlined,
                                color: Colors.black54, size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                company,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],


    // 🏷️ Categories
                      if (categories.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: categories.map((cat) {
                            final isResidential =
                                cat.toUpperCase() == "RESIDENTIAL";
                            final gradient = isResidential
                                ? const LinearGradient(
                              colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                                : const LinearGradient(
                              colors: [Color(0xFFFFA751), Color(0xFFFF5F6D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            );

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: gradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                cat,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // 📞 Contact Icons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _contactButton(Icons.call, "Call", "tel:$phone", phone: phone),
                    const SizedBox(height: 10),
                    _contactButton(
                        FontAwesomeIcons.whatsapp,
                        "WhatsApp",
                        "https://wa.me/${phone.toString().replaceAll('+', '')}"),
                    const SizedBox(height: 10),
                    _contactButton(Icons.email_outlined, "Email", "mailto:$email"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),


        const SizedBox(height: 30),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statCard("Reputation Score", "0", Icons.bar_chart),
                _statCard("Average Rating", rating.toString(), Icons.star),
                _statCard("Completed Deals", "0", Icons.check_circle_outline),
                _statCard("AI Review Score", "N/A", Icons.memory),
              ],
            ),

            const SizedBox(height: 40),

            // --- ABOUT + SEGMENTED SECTION SIDE BY SIDE ---
            LayoutBuilder(
              builder: (context, constraints) {
                final double halfWidth = (constraints.maxWidth - 40) / 2;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT: About Section
                    Container(
                      width: halfWidth,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "About ${name.split(" ").first}",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            bio.isNotEmpty ? bio : "No description available.",
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              color: Colors.black87,
                            ),
                          ),

                          // 🌐 Languages & Social Links Section (auto-hide if empty)
                          if ((languages.isNotEmpty) ||
                              (broker!['socialLinks'] != null && broker!['socialLinks'].isNotEmpty))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🗣️ Languages
                                if (languages.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  Text(
                                    "Languages",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 8,
                                    children: languages.map((lang) {
                                      return Container(
                                        padding:
                                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.teal.shade200, width: 0.6),
                                        ),
                                        child: Text(
                                          lang,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.teal.shade800,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],

                                // 🔗 Social Links
                                if (broker!['socialLinks'] != null &&
                                    broker!['socialLinks'].isNotEmpty) ...[
                                  const SizedBox(height: 28),
                                  Text(
                                    "Social Links",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  Wrap(
                                    spacing: 14,
                                    runSpacing: 12,
                                    children: broker!['socialLinks'].entries.map<Widget>((entry) {
                                      final platform = entry.key.toLowerCase();
                                      final link = entry.value.toString().trim();

                                      IconData icon;
                                      Gradient? gradient;
                                      Color solidColor;

                                      switch (platform) {
                                        case 'linkedin':
                                          icon = FontAwesomeIcons.linkedinIn;
                                          gradient = const LinearGradient(
                                            colors: [Color(0xFF0077B5), Color(0xFF0E6791)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          );
                                          solidColor = const Color(0xFF0077B5);
                                          break;
                                        case 'instagram':
                                          icon = FontAwesomeIcons.instagram;
                                          gradient = const LinearGradient(
                                            colors: [
                                              Color(0xFFF58529),
                                              Color(0xFFDD2A7B),
                                              Color(0xFF8134AF)
                                            ],
                                            begin: Alignment.bottomLeft,
                                            end: Alignment.topRight,
                                          );
                                          solidColor = const Color(0xFFE1306C);
                                          break;
                                        case 'facebook':
                                          icon = FontAwesomeIcons.facebookF;
                                          gradient = const LinearGradient(
                                            colors: [Color(0xFF1877F2), Color(0xFF145DBF)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          );
                                          solidColor = const Color(0xFF1877F2);
                                          break;
                                        case 'twitter':
                                        case 'x':
                                          icon = FontAwesomeIcons.xTwitter;
                                          gradient = const LinearGradient(
                                            colors: [Color(0xFF000000), Color(0xFF333333)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          );
                                          solidColor = Colors.black87;
                                          break;
                                        default:
                                          icon = FontAwesomeIcons.globe;
                                          gradient = const LinearGradient(
                                            colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          );
                                          solidColor = kPrimaryColor;
                                      }

                                      return MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        onEnter: (_) => setState(() => hoveredSocial = platform),
                                        onExit: (_) => setState(() => hoveredSocial = ''),
                                        child: AnimatedScale(
                                          duration: const Duration(milliseconds: 200),
                                          scale: hoveredSocial == platform ? 1.08 : 1.0,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(14),
                                            onTap: () async {
                                              final url = link.startsWith("http")
                                                  ? link
                                                  : "https://${link.replaceAll('@', '')}";
                                              if (await canLaunchUrl(Uri.parse(url))) {
                                                await launchUrl(Uri.parse(url),
                                                    mode: LaunchMode.externalApplication);
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(14),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: hoveredSocial == platform
                                                        ? solidColor.withOpacity(0.25)
                                                        : Colors.black12.withOpacity(0.05),
                                                    blurRadius: hoveredSocial == platform ? 10 : 6,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                                border: Border.all(
                                                  color: hoveredSocial == platform
                                                      ? solidColor.withOpacity(0.5)
                                                      : Colors.grey.shade200,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ShaderMask(
                                                    shaderCallback: (rect) =>
                                                        gradient!.createShader(rect),
                                                    child:
                                                    Icon(icon, color: Colors.white, size: 18),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    platform[0].toUpperCase() + platform.substring(1),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            )
                        ],
                      ),
                    ),

                    const SizedBox(width: 40),

                    // RIGHT: Segmented Bar + Dynamic Content
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Segmented Bar with full width
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(14.0),
                                topRight: Radius.circular(14.0),
                                ),


                                border: Border.all(color: Colors.grey.shade200, width: 1.2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [

                                  if(widget.userData['broker']['isVerified'])...[
                                    _buildSegmentButton("Listings", count: properties.length),
                                    _buildSegmentButton("Requirements", count: requirements.length),
                                  ],


                                  _buildSegmentButton(
                                    "Reviews",
                                    count: reviews.where((r) => r['status'] == "APPROVED").length,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 0),

                            // Dynamic content area
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: activeSection == "Listings"
                                  ? _buildListings(properties)
                                  : activeSection == "Requirements"
                                  ? _buildRequirements(requirements)
                                  : _buildReviews(reviews),
                            ),
                          ],
                        ),
                      ),
                    ),

                  ],
                );
              },
            ),






          ],
        ),
      ),
    );
  }
  Widget _buildSegmentButton(String label, {int count = 0}) {
    final bool isActive = activeSection == label;
    final bool isVerified = widget.userData['broker']['isVerified'] == true;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => activeSection = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 0),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
              colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isActive ? null : Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 1),
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              left: label == "Listings" || (!isVerified && label == "Reviews")
                  ? BorderSide(color: Colors.grey.shade300, width: 1)
                  : BorderSide.none,
              right: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            borderRadius: BorderRadius.horizontal(
              left: label == "Listings" ||
                  (!isVerified && label == "Reviews")
                  ? const Radius.circular(12)
                  : Radius.zero,
              right: label == "Reviews" ? const Radius.circular(12) : Radius.zero,
            ),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                  color: isActive ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Colors.white.withOpacity(0.9)
                      : kPrimaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: isActive
                        ? Colors.white.withOpacity(0.8)
                        : Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  "$count",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? kPrimaryColor : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components ---
  Widget _statCard(String title, String value, IconData icon) {
    // 🎨 Dynamic gradient colors for each type
    LinearGradient gradient;
    if (icon == Icons.star) {
      gradient = const LinearGradient(
        colors: [Color(0xFFFFC107), Color(0xFFFF9800)], // Gold / Amber
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (icon == Icons.bar_chart) {
      gradient = const LinearGradient(
        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)], // Blue shades
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (icon == Icons.check_circle) {
      gradient = const LinearGradient(
        colors: [Color(0xFF00B09B), Color(0xFF96C93D)], // Green shades
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (icon == Icons.memory) {
      gradient = const LinearGradient(
        colors: [Color(0xFF7F00FF), Color(0xFFE100FF)], // deep violet → magenta
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

    } else {
      gradient = LinearGradient(
        colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.7)], // Default
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🌈 Gradient Icon Container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),

            const SizedBox(width: 14),

            // 📊 Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildListings(List data) {
    if (data.isEmpty) return _emptyMessage("No listings available.");

    return Column(
      children: data.map((p) {
        final title = p['title'] ?? "Untitled Property";
        final price = double.tryParse(p['price'] ?? '0') ?? 0;
        final formattedPrice = price >= 1000
            ? "AED ${(price / 1000)}K"
            : "AED $price";
        final category = p['category'] ?? "N/A";
        final type = p['transactionType'] ?? "N/A";
        final image = (p['images'] != null && p['images'].isNotEmpty)
            ? p['images'][0]
            : null;

        final gradient = category.toUpperCase() == "RESIDENTIAL"
            ? const LinearGradient(
          colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : const LinearGradient(
          colors: [Color(0xFFFFA751), Color(0xFFFF5F6D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),

            border: Border.all(color: Colors.grey.shade200.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🏙️ Image section
              if (image != null)
                ClipRRect(
                borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
                child: image != null && image.isNotEmpty
                ? Image.network(
                image,
                height: 140,
                width: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                // 🧩 fallback to app logo if image fails to load
                return Image.asset(
                'assets/collabrix_logo.png', // your app logo
                height: 140,
                width: 180,
                fit: BoxFit.contain,
                );
                },
                )
                    : Image.asset(
                'assets/collabrix_logo.png', // fallback if no image key
                height: 140,
                width: 180,
                fit: BoxFit.contain,
                ),
                )

            else
                Container(
                  height: 140,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16)),
                  ),
                  child: Icon(Icons.image_not_supported_outlined,
                      size: 40, color: Colors.grey.shade400),
                ),

              // 📄 Info section
              Expanded(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🏷️ Title
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // 💰 Price
                      Text(
                        formattedPrice,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 🧩 Category and Type chips
                      Wrap(
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: gradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              category,
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              type,
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal.shade700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


  Widget _buildRequirements(List data) {
    if (data.isEmpty) return _emptyMessage("No requirements found.");

    final formatter = NumberFormat.decimalPattern(); // for 1,000 style formatting

    return LayoutBuilder(
      builder: (context, constraints) {

        final isWide = constraints.maxWidth > 800;
        return Wrap(
          spacing: 20,
          runSpacing: 8,
          children: data.map<Widget>((req) {
            final title = req['title'] ?? "Untitled Requirement";
            final category = req['category'] ?? "N/A";
            final transaction = req['transactionType'] ?? "N/A";

            final minRaw = num.tryParse(req['minPrice'] ?? '') ?? 0;
            final maxRaw = num.tryParse(req['maxPrice'] ?? '') ?? 0;

            final minPrice = minRaw > 0 ? formatter.format(minRaw) : "—";
            final maxPrice = maxRaw > 0 ? formatter.format(maxRaw) : "—";

            return Container(
              width: isWide ? (constraints.maxWidth / 2) - 24 : double.infinity,
              padding: const EdgeInsets.only(left: 22,right:22, top: 12,bottom:12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),

              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌈 Gradient Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF0072FF).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.assignment_outlined,
                        color: Colors.white, size: 22),
                  ),

                  const SizedBox(width: 16),

                  // 📋 Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Meta line
                        Row(
                          children: [
                            Icon(Icons.layers_outlined,
                                size: 15, color: Colors.grey.shade600),
                            const SizedBox(width: 5),
                            Text(
                              category,
                              style: GoogleFonts.poppins(
                                fontSize: 13.2,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.swap_horiz_rounded,
                                size: 15, color: Colors.grey.shade600),
                            const SizedBox(width: 5),
                            Text(
                              transaction,
                              style: GoogleFonts.poppins(
                                fontSize: 13.2,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Divider(color: Colors.grey.shade200, height: 10),

                        const SizedBox(height: 8),

                        // Price range
                        Row(
                          children: [
                            Icon(Icons.monetization_on_outlined,
                                size: 16, color: Colors.teal.shade700),
                            const SizedBox(width: 5),
                            Text(
                              "AED $minPrice - AED $maxPrice",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.teal.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildReviews(List data) {
    // 🔹 Keep only approved reviews
    final approvedReviews =
    data.where((r) => (r['status'] ?? '').toString().toUpperCase() == 'APPROVED').toList();

    if (approvedReviews.isEmpty) return _emptyMessage("No reviews available yet.");

    return Column(
      children: approvedReviews.map((r) {
        final reviewer = r['reviewer']?['displayName'] ?? "Anonymous";
        final avatar = r['reviewer']?['user']?['avatar'];
        final rating = r['rating'] ?? 0;
        final comment = r['comment'] ?? '';

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                backgroundColor: Colors.white,
                child: avatar == null
                    ? Text(
                  _getInitials(reviewer),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewer,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        rating,
                            (index) => const Icon(Icons.star,
                            color: Colors.amber, size: 16),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comment,
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

// helper for initials
  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }


  Widget _emptyMessage(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(text,
            style:
            GoogleFonts.poppins(color: Colors.black54, fontSize: 14.5)),
      ),
    );
  }


  Widget _contactButton(IconData icon, String label, String url, {String? phone}) {
    final Color baseColor = label == "WhatsApp"
        ? Colors.green
        : (label == "Email" ? Colors.orange.shade700 : kPrimaryColor);

    return Builder(
      builder: (context) {
        OverlayEntry? tooltipEntry;
        bool isVisible = false;

        void toggleTooltip(BuildContext context, String number) {
          if (isVisible) {
            tooltipEntry?.remove();
            tooltipEntry = null;
            isVisible = false;
            return;
          }

          final renderBox = context.findRenderObject() as RenderBox;
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          final overlaySize = MediaQuery.of(context).size;

          // 🧭 Decide where to show (above or below)
          final showAbove = position.dy > overlaySize.height / 2;

          tooltipEntry = OverlayEntry(
            builder: (context) => Positioned(
              left: position.dx - 70,
              top: showAbove
                  ? position.dy - 85
                  : position.dy + size.height + 10,
              child: Material(
                color: Colors.transparent,
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: kPrimaryColor.withOpacity(0.3),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.phone,
                                  color: kPrimaryColor, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Broker Contact",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                fontSize: 13.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          number,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          // Auto remove after 3 seconds or tap outside
          /* Future.delayed(const Duration(seconds: 3)).then((_) {
            tooltipEntry?.remove();
            tooltipEntry = null;
          });*/
          Overlay.of(context).insert(tooltipEntry!);
          isVisible = true;
        }

        return SizedBox(
          width: 180,
          child: ElevatedButton.icon(
            onPressed: () async {
              if (label == "Call" && phone != null && phone.isNotEmpty) {
                toggleTooltip(context, phone); // ✅ Tooltip only — no dialing
              } else if (label != "Call") {
                // ✅ WhatsApp & Email only
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                }
              }
            },
            icon: Icon(icon, size: 16, color: Colors.white),
            label: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: baseColor,
              shadowColor: baseColor.withOpacity(0.25),
              elevation: 3,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      },
    );
  }


}
