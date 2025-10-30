import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/animated_logo_loader.dart';
import '../brokermanagement/broker_profile_screen.dart';

class BrokerDirectoryScreen extends StatefulWidget {
  const BrokerDirectoryScreen({super.key});

  @override
  State<BrokerDirectoryScreen> createState() => _BrokerDirectoryScreenState();
}

class _BrokerDirectoryScreenState extends State<BrokerDirectoryScreen> {
  List<dynamic> brokers = [];
  bool loading = true;
  bool verifiedOnly = false;
  int currentPage = 1;
  int totalPages = 1;
  final int limit = 10;
  String searchQuery = '';
  bool isFetching = false;
  String selectedCategory = "All";
  int totalBrokers = 0;


  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBrokers();
  }

  Future<void> fetchBrokers({int page = 1}) async {
    setState(() => loading = true);
    try {
      final token = await AuthService.getToken();
      final url =
      Uri.parse('$baseURL/api/brokers?page=$page&limit=$limit&all=true');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          brokers = List.from(data['data']);
          totalPages = data['pagination']['totalPages'] ?? 1;
          currentPage = data['pagination']['page'] ?? 1;
          totalBrokers = data['pagination']['total'] ?? brokers.length;
          loading = false;
        });

      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      debugPrint('Error fetching brokers: $e');
      setState(() => loading = false);
    }
  }

  List<dynamic> get filteredBrokers {
    return brokers.where((b) {
      final matchSearch = searchQuery.isEmpty ||
          b['displayName']
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          b['companyName']
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase());

      final matchVerified = !verifiedOnly || (b['isVerified']?.toString() == 'true');

      // 🏢 Category filter
      final categories = List<String>.from(b['categories'] ?? []);
      final matchCategory = selectedCategory == "All" ||
          categories.any((cat) =>
          cat.toString().toLowerCase() == selectedCategory.toLowerCase());

      return matchSearch && matchVerified && matchCategory;
    }).toList();
  }

  Widget _buildBrokerCard(Map<String, dynamic> b) {
    final avatar = b['user']?['avatar'];
    final name = b['displayName'] ?? 'N/A';
    final company = b['companyName'] ?? '';
    final verified = b['isVerified'] == true;
    final rating = b['rating']?.toString() ?? 'N/A';
    final email = b['email'];
    final phone = b['phone'];
    final whatsapp = b['mobile'];
    final categories = List<String>.from(b['categories'] ?? []);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BrokerProfileScreen(brokerId: b['id'])),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 👤 Avatar with gradient ring
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor.withOpacity(0.8),
                      kPrimaryColor.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(2.5),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: avatar != null && avatar.isNotEmpty
                        ? Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) {
                        // 🧩 Fallback if image fails to load
                        return Image.asset(
                          'assets/collabrix_logo.png', // your app logo
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                        );
                      },
                    )
                        : Image.asset(
                      'assets/collabrix_logo.png', // fallback if avatar null or empty
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

              ),

              const SizedBox(width: 18),

              // 🧾 Broker Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Verified Badge
                    Row(
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(width: 8),
                        if (verified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.shade300,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.verified,
                                    color: Colors.green.shade700, size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  "Verified",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.2,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!verified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.redAccent.shade400,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.cancel_outlined,
                                    color: Colors.redAccent.shade700, size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  "Not Verified",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.2,
                                    color: Colors.redAccent.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 16,
                          color: Colors.teal.shade500,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            company.isNotEmpty ? company : "Company not specified",
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ⭐ Rating
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: Colors.amber.shade600, size: 18),
                        const SizedBox(width: 5),
                        Text(
                          rating != 'N/A' ? "$rating ★" : "No Rating",
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      children: categories.map((cat) {
                        final isResidential = cat.toUpperCase() == "RESIDENTIAL";
                        final gradient = isResidential
                            ? const LinearGradient(
                            colors: [Color(0xFF43CEA2), Color(0xFF185A9D)]) // Green-Blue
                            : const LinearGradient(
                            colors: [Color(0xFFFFA751), Color(0xFFFF5F6D)]); // Orange-Red

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(10),
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
                ),
              ),

              // 📞 Contact Buttons (modern rounded icons)
              Wrap(
                spacing: 10,
                children: [
                  _roundIconButton(
                    Icons.call,
                    "tel:$phone",
                    kPrimaryColor,
                    Colors.white,
                    phone: phone,
                  ),


                  _roundIconButton(FontAwesomeIcons.whatsapp,
                      "https://wa.me/${phone.toString().replaceAll('+', '')}",
                      Colors.green.shade600, Colors.white),
                  _roundIconButton(Icons.email_outlined, "mailto:$email",
                      Colors.orange.shade700, Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _roundIconButton(
      IconData icon,
      String url,
      Color bg,
      Color iconColor, {
        String? phone,
      }) {
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

        return InkWell(
          onTap: () async {
            if (icon == Icons.call && phone != null && phone.isNotEmpty) {
              toggleTooltip(context, phone);
            } else {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
            }
          },
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: bg.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
        );
      },
    );
  }






  Widget _modernChoiceChip(String label) {
    final isSelected = selectedCategory == label;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isSelected ? kPrimaryColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          if (!isSelected)
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
        border: Border.all(
          color: isSelected
              ? kPrimaryColor.withOpacity(0.6)
              : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => selectedCategory = label),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                const Icon(Icons.check, color: Colors.white, size: 16)
              else
                const Icon(Icons.circle_outlined,
                    color: Colors.grey, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷️ Modern 2025 Header with Icon
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🌐 Gradient Icon Container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          backgroundColor,
                          backgroundColor
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: backgroundColor,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.people,
                      color: kPrimaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 🧾 Title Text
                  Text(
                    "Broker Directory",
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "Discover trusted and verified real estate professionals across Dubai",
              style: GoogleFonts.poppins(
                color: Colors.black54,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),

            // 🌐 Frosted Filters Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  // 🔍 Search Field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => searchQuery = val),
                      style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                        hintText: "Search by name, company, or area...",
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: 14.5,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: kPrimaryColor, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 🧩 Filters Row - Left & Right Split
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 🔹 LEFT: Category Chips
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            _modernChoiceChip("All"),
                            _modernChoiceChip("Residential"),
                            _modernChoiceChip("Commercial"),
                          ],
                        ),
                      ),

                      // 🔸 RIGHT: Verified & Reset
                      Wrap(
                        spacing: 14,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilterChip(
                            label: Row(
                              children: [
                                Icon(Icons.verified,
                                    size: 16,
                                    color: verifiedOnly
                                        ? Colors.green.shade700
                                        : Colors.grey.shade500),
                                const SizedBox(width: 6),
                                const Text("Verified Only"),
                              ],
                            ),
                            showCheckmark: false,
                            selected: verifiedOnly,
                            selectedColor: Colors.green.withOpacity(0.12),
                            onSelected: (v) => setState(() => verifiedOnly = v),
                            labelStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: verifiedOnly
                                  ? Colors.green.shade700
                                  : Colors.grey.shade700,
                            ),
                            backgroundColor: verifiedOnly
                                ? Colors.green.shade100
                                : Colors.grey.shade100,
                            elevation: verifiedOnly ? 2 : 0,
                            pressElevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: verifiedOnly
                                    ? Colors.green.shade700.withOpacity(0.4)
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = '';
                                verifiedOnly = false;
                                selectedCategory = "All";
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text("Reset",
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600, fontSize: 13.5)),
                            style: ElevatedButton.styleFrom(
                              elevation: 1,
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 8,),
                  // 📊 Brokers Count Info Bar
                  if (!loading && brokers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 6,right:6,top:6, ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people_outline, size: 18, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                    () {
                                  final filteredCount = filteredBrokers.length;
                                  final total = totalBrokers;
                                  final filterText = [
                                    if (selectedCategory != "All") selectedCategory,
                                    if (verifiedOnly) "Verified",
                                    if (searchQuery.isNotEmpty) "Search applied",
                                  ].join(" • ");

                                  // Construct base message
                                  String message =
                                      "Showing $filteredCount of $total brokers";

                                  // Append active filters if any
                                  if (filterText.isNotEmpty) {
                                    message += " ($filterText)";
                                  }

                                  return message;
                                }(),
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          Container(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.layers_outlined,
                                    color: kPrimaryColor, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  "Page $currentPage of $totalPages",
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height:20),

            // List or loading
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: loading
                    ? Center(
                  key: const ValueKey('loader'),
                  child: AnimatedLogoLoader(assetPath: 'assets/collabrix_logo.png'),
                )
                    : filteredBrokers.isEmpty
                    ? Center(
                  key: const ValueKey('empty'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          color: Colors.grey.shade400, size: 60),
                      const SizedBox(height: 14),
                      Text(
                        "No brokers found",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Try adjusting filters or search again.",
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
                    : Container(
                  key: const ValueKey('list'),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ScrollConfiguration(
                    behavior:
                    const ScrollBehavior().copyWith(overscroll: false),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 40),
                      itemCount: filteredBrokers.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (ctx, i) {
                        return TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 400),
                          tween: Tween(begin: 0, end: 1),
                          curve: Curves.easeOut,
                          builder: (context, value, child) =>
                              Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              ),
                          child: _buildBrokerCard(filteredBrokers[i]),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),


            // Pagination footer
            if (!loading)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed:
                    currentPage > 1 ? () => fetchBrokers(page: currentPage - 1) : null,
                    child: const Text("Previous"),
                  ),
                  Text("Page $currentPage of $totalPages",
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.black54)),
                  TextButton(
                    onPressed: currentPage < totalPages
                        ? () => fetchBrokers(page: currentPage + 1)
                        : null,
                    child: const Text("Next"),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}
