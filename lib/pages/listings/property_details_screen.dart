import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher_web/url_launcher_web.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_logo_loader.dart';
import '../brokermanagement/broker_profile_screen.dart'; // 👈 import your profile screen
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
class PropertyDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> propertyData;

  const PropertyDetailsScreen({Key? key, required this.propertyData})
      : super(key: key);

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final propertyData = widget.propertyData;
    final bool isActive =
        propertyData['listingStatus']?.toString().toUpperCase() == 'ACTIVE';
    final brokerData = propertyData['broker'] ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Back to Listings + Share
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: Colors.blueAccent),
                      const SizedBox(width: 6),
                      Text("Back to Listings",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Colors.blueAccent,
                            fontSize: 13,
                          )),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.ios_share_rounded,
                      color: Colors.grey, size: 22),
                )
              ],
            ),
            const SizedBox(height: 20),

            /// 🔹 Title + Location
            Text(
              propertyData['title'] ?? 'N/A',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 26,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Text(
                  propertyData['location'] ?? 'Unknown',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            /// 🔹 Chips Row (Residential, Inactive, For Rent)
            Wrap(
              spacing: 8,
              children: [
                _buildChip(propertyData['category'] ?? 'Residential',
                    Colors.blue.shade600,
                    icon: Icons.apartment_rounded),
                _buildChip(
                  isActive ? 'Active' : 'Inactive',
                  isActive ? Colors.green : Colors.grey,
                  icon: isActive
                      ? Icons.verified_rounded
                      : Icons.block_rounded,
                ),
                _buildChip(
                  'For ${(propertyData['transactionType'] ?? 'Unknown').toString()}',
                  Colors.indigo,
                  icon: Icons.swap_horiz_rounded,
                ),
              ],
            ),
            const SizedBox(height: 30),

            /// 🔹 Main Content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// --- Left: Property Details ---
                Expanded(
                  flex: 2,
                  child: _propertyDetailsCard(propertyData),
                ),

                /// --- Right: Contact Agent ---
                Expanded(
                  flex: 1,
                  child: _contactAgentCard(context, brokerData, propertyData),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 🔹 Property Details Card
  // ------------------------------------------------------------
  Widget _propertyDetailsCard(Map<String, dynamic> propertyData) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            children: [
              const Icon(Icons.home_work_outlined, color: Colors.black54),
              const SizedBox(width: 8),
              Text("Property Details",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 18),

          /// --- Details Grid ---
          Wrap(
            runSpacing: 18,
            spacing: 50,
            children: [
              _detailItem(
                icon: Icons.currency_exchange_rounded,
                label: "Price",
                value:
                "${propertyData['currency'] ?? 'AED'} ${propertyData['price'] ?? '0'}",
                highlight: true,
              ),
              _detailItem(
                  icon: Icons.bed_outlined,
                  label: "Bedrooms",
                  value: "${propertyData['rooms'] ?? '0'} rooms"),
              _detailItem(
                  icon: Icons.bathtub_outlined,
                  label: "Bathrooms",
                  value: "${propertyData['bathrooms'] ?? '0'} baths"),
              _detailItem(
                  icon: Icons.local_parking_rounded,
                  label: "Parking",
                  value: "${propertyData['parkingSpaces'] ?? '0'} spots"),
              _detailItem(
                  icon: Icons.apartment_rounded,
                  label: "Property Type",
                  value: propertyData['type'] ?? 'Apartment'),
              _detailItem(
                  icon: Icons.chair_alt_outlined,
                  label: "Furnishing Status",
                  value: propertyData['furnished'] ?? 'Unfurnished'),
              _detailItem(
                  icon: Icons.square_foot,
                  label: "Size",
                  value: propertyData['size'] ?? '0 sqft'),
              _detailItem(
                  icon: Icons.task_alt_rounded,
                  label: "Status",
                  value: propertyData['status'] ?? 'Ready to Move'),
            ],
          ),

          const SizedBox(height: 25),

          /// --- Amenities ---
          if (propertyData['amenitiesTagIds'] != null &&
              (propertyData['amenitiesTagIds'] as List).isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.star_border_rounded,
                        color: Colors.black54),
                    const SizedBox(width: 8),
                    Text("Amenities",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                  (propertyData['amenitiesTagIds'] as List).map<Widget>(
                        (a) {
                      final tagColor = Colors
                          .primaries[(a.hashCode % Colors.primaries.length)];
                      return _buildChip(
                        a.toString().replaceAll('-', ' ').toUpperCase(),
                        tagColor,
                        icon: Icons.check_circle_outline,
                      );
                    },
                  ).toList(),
                ),
              ],
            ),

          const SizedBox(height: 25),

          /// --- Description ---
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Colors.black54),
              const SizedBox(width: 8),
              Text("Description",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            propertyData['description'] ?? "No description available.",
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // 🔹 Contact Agent Card
  // ------------------------------------------------------------
  Widget _contactAgentCard(BuildContext context,
      Map<String, dynamic> brokerData, Map<String, dynamic> propertyData) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.black54),
              const SizedBox(width: 8),
              Text("Contact Agent",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),

          /// Broker Info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  (brokerData['displayName'] ?? 'A')[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(brokerData['displayName'] ?? 'Agent',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text("Broker",
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          _verifiedBadge(brokerData['isVerified'] == true),

          /// 🔹 Social Links
          /// 🔹 Social Links
          if (brokerData['socialLinks'] != null &&
              (brokerData['socialLinks'] as Map).isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                for (final entry
                in (brokerData['socialLinks'] as Map<String, dynamic>).entries)
                  if (entry.value != null && entry.value.toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () async {
                          final Uri uri = Uri.parse(entry.value);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Builder(builder: (_) {
                          final social = _getSocialIcon(entry.key);
                          return CircleAvatar(
                            radius: 18,
                            backgroundColor: social['color'],
                            child: Icon(
                              social['icon'],
                              size: 16,
                              color: Colors.white,
                            ),
                          );
                        }),
                      ),
                    ),
              ],
            ),
          ],


          const SizedBox(height: 20),

          _contactButton(Icons.call, "Call ${brokerData['phone'] ?? ''}",
              Colors.blue.shade700, Colors.white,
              brokerData: brokerData),
          const SizedBox(height: 10),
          _contactButton(FontAwesomeIcons.whatsapp, "WhatsApp",
              Colors.green.shade600, Colors.white,
              brokerData: brokerData),
          const SizedBox(height: 10),
          _contactButton(Icons.email_outlined, "Send Email",
              Colors.white, Colors.grey.shade800,
              outlined: true, brokerData: brokerData),
          const SizedBox(height: 10),
          _contactButton(Icons.person_2_outlined, "View Profile",
              Colors.white, Colors.grey.shade800,
              outlined: true, brokerData: brokerData),

          const SizedBox(height: 25),
          Divider(color: Colors.grey.shade300, height: 1),
          const SizedBox(height: 16),

          Text(
            "Reference Number",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(propertyData['ref'] ?? '-',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  /// 🔹 Helper to get correct social icon
  Map<String, dynamic> _getSocialIcon(String key) {
    switch (key.toLowerCase()) {
      case 'facebook':
        return {
          'icon': FontAwesomeIcons.facebookF,
          'color': const Color(0xFF1877F2),
        };
      case 'instagram':
        return {
          'icon': FontAwesomeIcons.instagram,
          'color': const Color(0xFFE1306C),
        };
      case 'linkedin':
        return {
          'icon': FontAwesomeIcons.linkedinIn,
          'color': const Color(0xFF0A66C2),
        };
      case 'twitter':
      case 'x':
        return {
          'icon': FontAwesomeIcons.xTwitter,
          'color': Colors.black,
        };
      case 'youtube':
        return {
          'icon': FontAwesomeIcons.youtube,
          'color': const Color(0xFFFF0000),
        };
      case 'tiktok':
        return {
          'icon': FontAwesomeIcons.tiktok,
          'color': const Color(0xFF010101),
        };
      case 'whatsapp':
        return {
          'icon': FontAwesomeIcons.whatsapp,
          'color': const Color(0xFF25D366),
        };
      default:
        return {
          'icon': FontAwesomeIcons.globe,
          'color': Colors.grey.shade600,
        };
    }
  }



  // ------------------------------------------------------------
  // 🔹 Contact Button + Launcher
  // ------------------------------------------------------------
  Widget _contactButton(IconData icon, String label, Color bgColor,
      Color textColor,
      {bool outlined = false, required Map<String, dynamic> brokerData}) {
    return InkWell(
      onTap: () => _handleContactTap(context, label, brokerData),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : bgColor,
          borderRadius: BorderRadius.circular(10),
          border: outlined ? Border.all(color: Colors.grey.shade400) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.poppins(
                    color: textColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContactTap(BuildContext context, String label,
      Map<String, dynamic> brokerData) async {
    final phone = brokerData['phone'] ?? '';
    final email = brokerData['email'] ?? '';
    final name = brokerData['displayName'] ?? 'Broker';

    try {
      if (label.contains("Call")) {
        final Uri callUri = Uri(scheme: 'tel', path: phone);
        await launchUrl(callUri, mode: LaunchMode.externalApplication);
      } else if (label.contains("WhatsApp")) {
        final Uri whatsappUri = Uri.parse("https://wa.me/$phone?text=Hello%20$name!");
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else if (label.contains("Email")) {
        final Uri emailUri = Uri(
          scheme: 'mailto',
          path: email,
          query: Uri.encodeFull('subject=Property Inquiry&body=Hello $name,'),
        );
        await launchUrl(emailUri);
      } else if (label.contains("Profile")) {
        _showBrokerProfilePopup(context, brokerData['id']);
      }

    } catch (e) {
      debugPrint('Error launching contact action: $e');
    }
  }
  Future<Map<String, dynamic>> _fetchBrokerProfile(dynamic brokerId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$baseURL/api/brokers/$brokerId"); // 👈 replace with actual endpoint
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token', // add if required
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] ?? {};
    } else {
      throw Exception('Failed to load broker profile');
    }
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _showBrokerProfilePopup(BuildContext context, dynamic brokerId) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 120,  // 👈 smaller padding from edges
            vertical: 100,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,   // 👈 limits popup width
                maxHeight: 650,  // 👈 limits popup height
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _fetchBrokerProfile(brokerId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 80),
                            AnimatedLogoLoader(assetPath: 'assets/collabrix_logo.png'),
                          ],
                        ),
                      );
                  } else if (snapshot.hasError) {

                    return _errorDialog("Failed to load profile");
                  }

                  final data = snapshot.data ?? {};
                  final user = data['user'] ?? {};
                  final properties = data['properties'] ?? [];
                  final reviews = data['reviews'] ?? [];

                  return Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 🔹 Gradient Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  kPrimaryColor.withOpacity(0.85),
                                  Colors.teal.shade400.withOpacity(0.85)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: user['avatar'] != null
                                      ? NetworkImage(user['avatar'])
                                      : null,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  child: user['avatar'] == null
                                      ? Text(
                                    (data['displayName'] ?? 'A')[0].toUpperCase(),
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 24,
                                        color: Colors.white),
                                  )
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  data['displayName'] ?? 'Broker Name',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18),
                                ),
                                Text(
                                  data['companyName'] ?? '',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _badge("Verified", Colors.greenAccent, Icons.verified),
                                    const SizedBox(width: 6),
                                    _badge("${data['rating'] ?? '4.8'} ★",
                                        Colors.amberAccent, Icons.star_rounded),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                          _sectionHeader("Contact Details"),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (data['phone'] != null)
                                _actionChip(
                                  icon: Icons.phone,
                                  label: data['phone'],
                                  color: Colors.blue.shade700,
                                  onTap: () async {
                                    final Uri callUri = Uri(scheme: 'tel', path: data['phone']);
                                    if (await canLaunchUrl(callUri)) {
                                      await launchUrl(callUri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                ),

                              if (data['email'] != null)
                                _actionChip(
                                  icon: Icons.email_outlined,
                                  label: data['email'],
                                  color: Colors.orange.shade700,
                                  onTap: () async {
                                    final Uri emailUri = Uri(
                                      scheme: 'mailto',
                                      path: data['email'],
                                      query: Uri.encodeFull('subject=Property Inquiry&body=Hello ${data['displayName'] ?? ''},'),
                                    );
                                    if (await canLaunchUrl(emailUri)) {
                                      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                ),

                              if (data['website'] != null)
                                _actionChip(
                                  icon: Icons.language,
                                  label: data['website']
                                      .toString()
                                      .replaceAll(RegExp(r'https?://'), ''), // remove protocol
                                  color: Colors.teal.shade700,
                                  onTap: () async {
                                    final Uri webUri = Uri.parse(data['website']);
                                    if (await canLaunchUrl(webUri)) {
                                      await launchUrl(webUri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                ),
                            ],
                          ),


                          const SizedBox(height: 18),
                          _sectionHeader("About"),
                          Text(
                            data['bio'] ??
                                "Experienced agent with a strong portfolio in UAE’s luxury property market.",
                            textAlign: TextAlign.start,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              color: Colors.grey.shade700,
                            ),
                          ),

                          const SizedBox(height: 18),
                          if (data['specializations'] != null &&
                              (data['specializations'] as List).isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionHeader("Specializations"),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (data['specializations'] as List)
                                      .map((s) => _modernChip(s, Colors.blue.shade700))
                                      .toList(),
                                ),
                              ],
                            ),

                          const SizedBox(height: 16),
                          if (data['languages'] != null &&
                              (data['languages'] as List).isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionHeader("Languages"),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.start,
                                  children: (data['languages'] as List)
                                      .map((lang) => _modernChip(lang, Colors.teal.shade700))
                                      .toList(),
                                ),
                              ],
                            ),

                          const SizedBox(height: 20),
                          if (data['socialLinks'] != null &&
                              (data['socialLinks'] as Map).isNotEmpty) ...[
                            _sectionHeader("Social Links"),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              children: [
                                for (final entry
                                in (data['socialLinks'] as Map<String, dynamic>).entries)
                                  if (entry.value != null &&
                                      entry.value.toString().isNotEmpty)
                                    Builder(builder: (_) {
                                      final social = _getSocialIcon(entry.key);
                                      return InkWell(
                                        onTap: () async {
                                          final url = entry.value.toString().startsWith('@')
                                              ? "https://instagram.com/${entry.value.toString().replaceAll('@', '')}"
                                              : entry.value.toString();
                                          final uri = Uri.parse(url);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri,
                                                mode: LaunchMode.externalApplication);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: CircleAvatar(
                                          backgroundColor:
                                          social['color'].withOpacity(0.1),
                                          radius: 18,
                                          child: Icon(social['icon'],
                                              color: social['color'], size: 18),
                                        ),
                                      );
                                    }),
                              ],
                            ),
                          ],

                         /* const SizedBox(height: 22),

                          if (properties.isNotEmpty) ...[
                            _sectionHeader("Recent Listings"),
                            const SizedBox(height: 10),

                            SizedBox(
                              height: 220,
                              child: ListView.separated(
                                scrollDirection: Axis.vertical,
                                physics: const BouncingScrollPhysics(),
                                separatorBuilder: (_, __) => const SizedBox(width: 14),
                                itemCount: properties.length,
                                itemBuilder: (context, index) {
                                  final property = properties[index];
                                  final imageList = (property['images'] ?? []) as List;
                                  final imageUrl = imageList.isNotEmpty
                                      ? "$baseURL/${imageList.first}"
                                      : 'https://via.placeholder.com/300';
                                  final price = property['price'] != null
                                      ? "AED ${property['price']}"
                                      : 'Price not available';
                                  final category = property['category'] ?? '';
                                  final type = property['transactionType'] ?? '';
                                  final createdAt = property['createdAt'] != null
                                      ? DateTime.tryParse(property['createdAt'])
                                      : null;

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 230,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12.withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        /// Property image
                                        ClipRRect(
                                          borderRadius:
                                          const BorderRadius.vertical(top: Radius.circular(16)),
                                          child:  Image.asset(
                                            'assets/collabrix_logo.png',
                                            fit: BoxFit.cover,
                                          ),*//*Image.network(
                                            imageUrl,
                                            height: 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              height: 120,
                                              color: Colors.grey.shade100,
                                              child: const Icon(Icons.image_not_supported_outlined,
                                                  color: Colors.grey),
                                            ),
                                          ),*//*
                                        ),

                                        /// Property info
                                        Padding(
                                          padding:
                                          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              /// Title
                                              Text(
                                                property['title'] ?? 'Untitled Property',
                                                softWrap: true,
                                                overflow: TextOverflow.visible,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13.5,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 6),

                                              /// Price
                                              Row(
                                                children: [
                                                  const Icon(Icons.currency_exchange_rounded,
                                                      size: 14, color: Colors.green),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      price,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.green.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),

                                              /// Category + Type
                                              Row(
                                                children: [
                                                  const Icon(Icons.home_work_outlined,
                                                      size: 14, color: Colors.blueGrey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "$category • $type",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.blueGrey.shade600,
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
                                },
                              ),
                            ),
                          ],*/


                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text("Close"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// 🔹 Compact badge
  Widget _badge(String text, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: GoogleFonts.poppins(
                color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    ),
  );

  /// 🔹 Modern minimal chip
  Widget _modernChip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text,
        style: GoogleFonts.poppins(
            color: color, fontWeight: FontWeight.w600, fontSize: 12)),
  );

  /// 🔹 Contact chip
  Widget _contactChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blueGrey, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12.5, color: Colors.blueGrey.shade700)),
      ],
    ),
  );

  /// 🔹 Section title with small accent line
  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 4),
    child: Row(
      children: [
        Container(width: 3, height: 18, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text(text,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    ),
  );

  /// 🔹 Error display
  Widget _errorDialog(String message) => Container(
    width: 300,
    height: 160,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
            color: Colors.black12.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6))
      ],
    ),
    child: Center(
      child: Text(message,
          style: GoogleFonts.poppins(
              color: Colors.redAccent, fontWeight: FontWeight.w600)),
    ),
  );



  Widget _buildChip(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: GoogleFonts.poppins(
                  color: color, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _detailItem(
      {required IconData icon,
        required String label,
        required String value,
        bool highlight = false}) {
    return SizedBox(
      width: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: highlight ? Colors.green : Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: highlight
                            ? Colors.green.shade700
                            : Colors.black87,
                        fontWeight:
                        highlight ? FontWeight.w700 : FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifiedBadge(bool isVerified) {
    final color = isVerified ? Colors.green : Colors.redAccent;
    final bgColor = isVerified ? Colors.green.withOpacity(0.12) : Colors.redAccent.withOpacity(0.12);
    final icon = isVerified ? Icons.verified_rounded : Icons.error_outline_rounded;
    final label = isVerified ? "Verified" : "Not Verified";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

}
