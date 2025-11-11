import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';

class BrokerManagementScreen extends StatefulWidget {

  const BrokerManagementScreen({super.key,
    });

  @override
  State<BrokerManagementScreen> createState() => _BrokerManagementScreenState();
}

class _BrokerManagementScreenState extends State<BrokerManagementScreen> {
  bool _loadingStats = true;
  bool _loadingBrokers = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  Map<String, dynamic>? stats;
  List<dynamic> brokers = [];
  List<dynamic> filteredBrokers = [];

  int _page = 1;
  final int _limit = 10;


  String activeFilter = 'Pending';
  String searchQuery = '';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchOverviewStats();
    _fetchBrokers();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _fetchOverviewStats() async {
    setState(() => _loadingStats = true);
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$baseURL/api/brokers/stats/overview'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      setState(() {
        stats = jsonDecode(response.body)['data'];
        _loadingStats = false;
      });
    } else {
      setState(() => _loadingStats = false);
    }
  }

  Future<void> _fetchBrokers({bool refresh = true}) async {
    if (refresh) {
      setState(() {
        _loadingBrokers = true;
        _page = 1;
        _hasMore = true;
      });
    }
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$baseURL/api/brokers?page=$_page&limit=$_limit'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> newData = data['data'];
      setState(() {
        if (refresh) {
          brokers = newData;

        } else {
          brokers.addAll(newData);
        }
        // 🟡 Apply default filter
        if (_page == 1 && activeFilter == 'Pending') {
          filteredBrokers = brokers
              .where((b) =>
          (b['approvalStatus'] ?? '').toString().toUpperCase() == 'PENDING')
              .toList();
        } else {
          filteredBrokers = brokers;
        }

        _hasMore = _page < (data['pagination']?['totalPages'] ?? 1);
      });
    }
    setState(() => _loadingBrokers = false);
  }

  Future<void> _loadMore() async {
    if (!_hasMore) return;
    setState(() => _isLoadingMore = true);
    _page++;
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$baseURL/api/brokers?page=$_page&limit=$_limit'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> newData = data['data'];
      setState(() {
        brokers.addAll(newData);
        _hasMore = _page < (data['pagination']?['totalPages'] ?? 1);
      });
      _applyFilters();
    }
    setState(() => _isLoadingMore = false);
  }

  void _applyFilters() {
    List<dynamic> list = brokers;

    // 🧩 Handle filters (including Disabled & All)
    if (activeFilter != 'All') {
      list = list.where((b) {
        final approvalStatus = (b['approvalStatus'] ?? '').toString().toUpperCase();
        final isActive = b['user']?['isActive'] == true;

        switch (activeFilter.toUpperCase()) {
          case 'DISABLED':
            return !isActive; // show inactive ones
          case 'PENDING':
          case 'APPROVED':
          case 'REJECTED':
            return isActive && approvalStatus == activeFilter.toUpperCase();
          default:
            return true; // fallback
        }
      }).toList();
    }

    // 🔍 Handle search query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((b) {
        final displayName = (b['displayName'] ?? '').toString().toLowerCase();
        final company = (b['user']?['companyName'] ?? '').toString().toLowerCase();
        final email = (b['email'] ?? '').toString().toLowerCase();
        return displayName.contains(q) || company.contains(q) || email.contains(q);
      }).toList();
    }

    setState(() => filteredBrokers = list);
  }

  Widget _buildShimmerCard(int index) {
    // 🎨 Different color accents for each card
    final colorSets = [
      [Color(0xFF3A8EF6), Color(0xFF6F3AFF)], // Blue-Purple (All)
      [Color(0xFFFFB300), Color(0xFFFF7043)], // Amber-Orange (Pending)
      [Color(0xFF43A047), Color(0xFF66BB6A)], // Green (Approved)
      [Color(0xFFE53935), Color(0xFFEF5350)], // Red (Rejected)
      [Color(0xFF607D8B), Color(0xFF90A4AE)], // Grey-Blue (Disabled)
    ];


    final icons = [
      Icons.people_alt_rounded,
      Icons.access_time_filled_rounded,
      Icons.verified_rounded,
      Icons.cancel_rounded,
      Icons.block_flipped,
    ];

    final colors = colorSets[index % colorSets.length];
    final gradient = LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Shimmer.fromColors(
      baseColor: Colors.grey.withOpacity(0.25),
      highlightColor: Colors.grey.withOpacity(0.45),
      child: Container(
        height: 110,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.first.withOpacity(0.25),
              colors.last.withOpacity(0.35),
              Colors.white.withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 6),

            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🌀 Animated icon placeholder circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(

                shape: BoxShape.circle,
                gradient: gradient,
              ),
              child: Icon(
                icons[index % icons.length],
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 12,
                    width: MediaQuery.of(context).size.width * 0.3,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
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

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 10,
              spreadRadius: -6,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Stack(
          children: [
           /* // 🔹 faint diagonal highlight lines for background texture
            Positioned.fill(
              child: CustomPaint(painter: _LinePatternPainter(color)),
            ),*/

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
                // ✳️ Glowing icon badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.9),
                        color.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
              ],
            ),
          ],
        ),
      ).animate().fade(duration: 500.ms, curve: Curves.easeOut),
    );
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All', 'icon': FontAwesomeIcons.layerGroup, 'color': kPrimaryColor},
      {'label': 'Pending', 'icon': Icons.access_time_filled_rounded, 'color': Colors.amber},
      {'label': 'Approved', 'icon': Icons.verified, 'color': Colors.green},
      {'label': 'Rejected', 'icon': FontAwesomeIcons.circleXmark, 'color': Colors.redAccent},
      //{'label': 'Disabled', 'icon': FontAwesomeIcons.ban, 'color': Colors.grey},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: filters.map((f) {
          final bool selected = activeFilter == f['label'];
          final Color color = f['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                  colors: [
                    color.withOpacity(0.9),
                    color.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.grey.shade100,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () {
                  setState(() {
                    activeFilter = f['label'] as String;
                    _applyFilters();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Row(
                    children: [
                      FaIcon(
                        f['icon'] as IconData,
                        size: 16,
                        color: selected ? Colors.white : color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        f['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? Colors.white : Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 350.ms).scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
              duration: 250.ms,
              curve: Curves.easeOutBack,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Card(
          elevation: 20,
          color: Colors.white,
          shadowColor: Colors.black12.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 260),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 📦 Icon
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Icon(
                    FontAwesomeIcons.userTie,
                    color: kPrimaryColor.withOpacity(0.7),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 24),

                // 📝 Title
                Text(
                  "No brokers found",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),

                // 💬 Subtitle
                Text(
                  "Try adjusting your filters or search keywords.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 500.ms, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = stats?['brokers']?['total'] ?? 0;
    final pending = stats?['brokers']?['pending'] ?? 0;
    final approved = stats?['brokers']?['approved'] ?? 0;
    return Scaffold(
        backgroundColor: backgroundColor,
        floatingActionButton: FloatingActionButton(
          backgroundColor: kPrimaryColor,
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
            child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 18,),
                      Text("Broker Management",
                    style: GoogleFonts.poppins(
                        fontSize: 24, fontWeight: FontWeight.w700))
                    .animate()
                    .fade(duration: 400.ms),
                Text("Review and manage broker profile approvals",
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey.shade600))
                    .animate()
                    .fade(duration: 400.ms, delay: 100.ms),
                const SizedBox(height: 20),
                if (_loadingStats)
            Row(
            children: List.generate(
            4, (index) => Expanded(child: _buildShimmerCard(index))))
    else
    Row(
    children: [
    _buildStatCard("All", total, Colors.blueAccent, Icons.people),
    _buildStatCard("Pending", pending, Colors.amber,
    Icons.access_time_rounded),
    _buildStatCard("Approved", approved, Colors.green,
        Icons.verified),
    _buildStatCard("Rejected", 0, Colors.red, FontAwesomeIcons.circleXmark),

    ],
    ),
    const SizedBox(height: 24),
                      Card(
                        elevation: 6,
                        color: Colors.white,
                        shadowColor: Colors.black12.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 Filter Chips
                              _buildFilterChips(),
                              const SizedBox(height: 16),

                              // 🔹 Search Bar
                              TextField(
                                decoration: InputDecoration(
                                  hintText: "Search by name, company, or email...",
                                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                    BorderSide(color: kPrimaryColor.withOpacity(0.6), width: 1.2),
                                  ),
                                ),
                                style: GoogleFonts.poppins(fontSize: 14.5),
                                onChanged: (val) {
                                  setState(() => searchQuery = val.trim().toLowerCase());
                                  _applyFilters();
                                },
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms).scale(
                        begin: const Offset(0.98, 0.98),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack,
                        duration: 350.ms,
                      ),

                      const SizedBox(height: 0),
                      if (_loadingBrokers)
                        Column(
                          children: List.generate(
                            5,
                                (index) => _buildShimmerCard(index),
                          ),
                        )
                      else if (filteredBrokers.isEmpty)
                      _buildEmptyState()

                        else
                        Column(
                          children: [
                            ...filteredBrokers
                                .map((b) => _buildBrokerCard(b)
                                .animate()
                                .fade(duration: 500.ms, curve: Curves.easeOut))
                                .toList(),
                            if (_isLoadingMore)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: kPrimaryColor)),
                              ),
                          ],
                        ),
                    ],
                ),
            ),
        ),
    );
  }

  // --- Broker Card ---
  Widget _buildBrokerCard(Map<String, dynamic> b) {
    final user = b['user'] ?? {};
    final role = b['brokerTitle'] ?? 'Broker';
    final categories = (b['categories'] as List?)?.cast<String>() ?? [];
    final status = (b['approvalStatus'] ?? '').toString().toUpperCase();
    final created = DateTime.tryParse(b['createdAt'] ?? '');
    final formattedDate = created != null
        ? "Registered on ${DateFormat('dd-MMM-yyyy').format(created)}"
        : '-';

    final bool isActive = user['isActive'] == true;
    final bool isDisabled = !isActive;

    final Color baseColor = Colors.white;
    final Color sideColor = isDisabled
        ? Colors.grey
        : status == 'APPROVED'
        ? Colors.green
        : status == 'PENDING'
        ? Colors.amber
        : status == 'REJECTED'
        ? Colors.redAccent
        : Colors.grey;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [

            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 6,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
        child: Opacity(
          opacity: isDisabled ? 0.7 : 1,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 👤 Avatar + Lock for disabled
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: kPrimaryColor.withOpacity(0.1),
                      backgroundImage: user['avatar'] != null
                          ? NetworkImage(user['avatar'])
                          : null,
                      child: user['avatar'] == null
                          ? Text(
                        (b['displayName'] ?? 'B')[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: kPrimaryColor,
                        ),
                      )
                          : null,
                    ),
                    if (isDisabled)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            FontAwesomeIcons.lock,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // 📋 Broker Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Status Chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Text(
                              "${b['displayName'] ?? 'N/A'}",
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 8,),
                            _statusChip(b['approvalStatus'] ?? '', isVerified: b['isVerified'] == true,isActive: isActive),


                          ],),


                        ],
                      ),
                      const SizedBox(height: 6),

                      // Role and Category Badges
                      Row(
                        children: [
                          Text(role,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600)),

                        ],
                      ),

                      const SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          // 🏢 Company
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(FontAwesomeIcons.building, size: 13, color: Colors.grey),
                              const SizedBox(width: 5),
                              Text(
                                user['companyName'] ?? 'Freelancer',
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                              ),
                            ],
                          ),

                          // Divider Dot
                          Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),

                          // ✉️ Email
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.mail_outline, size: 14, color: Colors.grey),
                              const SizedBox(width: 5),
                              Text(
                                user['email'] ?? b['email'] ?? 'N/A',
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                              ),
                            ],
                          ),

                          // Divider Dot
                          Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),

                          // 📞 Phone
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 5),
                              Text(
                                user['phone'] ?? b['mobile'] ?? 'N/A',
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: categories.map((cat) {
                          final bool isResidential = cat.toUpperCase() == 'RESIDENTIAL';
                          final gradientColors = isResidential
                              ? [Colors.orange.withOpacity(0.8), Colors.orange.withOpacity(0.8)]
                              : [Colors.orange.withOpacity(0.8), Colors.orange.withOpacity(0.8)];

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: gradientColors.first.withOpacity(0.3),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isResidential
                                      ? FontAwesomeIcons.houseChimney
                                      : FontAwesomeIcons.building,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),




                      const SizedBox(height: 10),
                      Text(
                        formattedDate,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: IconButton(
                          icon: const Icon(Icons.info_outline_rounded,
                              color: Colors.blueAccent, size: 22),
                          tooltip: "View Company & BRN Details",
                          onPressed: () => _showBrokerDetailsDialog(context, b),
                        ),
                      ),

                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // ✅ Approve / Reject Buttons (hide if disabled)
                if (!isDisabled) _buildActionButtons(b, status),



              ],
            ),
          ),
        ),
      ).animate().fade(duration: 400.ms, curve: Curves.easeOut),
    );
  }



  void _showBrokerDetailsDialog(BuildContext context, Map<String, dynamic> broker) {
    final user = broker['user'] ?? {};
    final company = user['companyName'];
    final brnNumber = broker['brnNumber'];
    final brnIssueDate = broker['brnIssuesDate'];
    final brnExpiryDate = broker['brnExpiryDate'];
    final rawAttachment = broker['brnAttachment'] ?? broker['brn_attachment'];
    final brnAttachment = (rawAttachment != null && rawAttachment.toString().isNotEmpty)
        ? (rawAttachment.toString().startsWith('http')
        ? rawAttachment
        : '$baseURL/$rawAttachment')
        : null;

    print('✅ brnAttachment URL: $brnAttachment');



    final hasDetails = (company != null && company.toString().trim().isNotEmpty) ||
        (brnNumber != null && brnNumber.toString().trim().isNotEmpty) ||
        (brnIssueDate != null && brnIssueDate.toString().trim().isNotEmpty);

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final double dialogWidth = isMobile ? screenWidth * 0.9 : 440;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              minWidth: isMobile ? screenWidth * 0.85 : 360,
            ),
            child: Dialog(
              elevation: 0,
              backgroundColor: Colors.white,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 24 : 40,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Header Row ---
                          Row(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF4FC3F7), Color(0xFF1976D2)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.info_outline_rounded,
                                    color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Broker Details",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.black54, size: 22),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // --- Details Section ---
                          if (hasDetails)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  "🏢 Company Name",
                                  company?.toString().isNotEmpty == true
                                      ? company
                                      : "N/A",
                                ),
                                const SizedBox(height: 10),
                                _buildDetailRow(
                                  "🆔 BRN Number",
                                  brnNumber?.toString().isNotEmpty == true
                                      ? brnNumber
                                      : "N/A",
                                ),
                                const SizedBox(height: 10),
                                _buildDetailRow(
                                  "📅 BRN Issue Date",
                                  brnIssueDate != null
                                      ? DateFormat('dd-MMM-yyyy').format(
                                      DateTime.tryParse(brnIssueDate) ??
                                          DateTime.now())
                                      : "N/A",
                                ),
                                const SizedBox(height: 10),
                                _buildDetailRow(
                                  "⏳ BRN Expiry Date",
                                  brnExpiryDate != null
                                      ? DateFormat('dd-MMM-yyyy').format(
                                      DateTime.tryParse(brnExpiryDate) ?? DateTime.now())
                                      : "N/A",
                                ),


                                // --- BRN Attachment ---
                                if (brnAttachment != null && brnAttachment.toString().isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    "📎 BRN Attachment",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (brnAttachment.toString().toLowerCase().endsWith(".pdf"))
                                    GestureDetector(
                                      onTap: () async {
                                        // open in browser
                                        if (await canLaunchUrl(Uri.parse(brnAttachment))) {
                                          await launchUrl(Uri.parse(brnAttachment),
                                              mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                "Open PDF",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.blueAccent,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const Icon(Icons.open_in_new, color: Colors.blueAccent, size: 18),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),

                                      child: Image.network(
                                        brnAttachment,
                                        fit: BoxFit.cover,
                                        height: 160,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stack) {
                                          print('❌ Image load error: $error');
                                          return Text("Failed to load image", style: TextStyle(color: Colors.red));
                                        },
                                      ),
                                    ),
                                ],

                              ],
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.info_outline_rounded,
                                        size: 38,
                                        color: Colors.blueAccent.withOpacity(0.7)),
                                    const SizedBox(height: 12),
                                    Text(
                                      "No Company/BRN details available for this broker.",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(

                                        fontSize: 14,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().fade(duration: 300.ms).scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
              duration: 250.ms,
              curve: Curves.easeOutBack,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87)),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.blueGrey.shade700,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }


  Widget _statusChip(String status, {bool isVerified = false, bool isActive = true}) {
    status = status.toUpperCase();
    if (!isActive) status = 'DISABLED';


    // 🔹 Helper to build your existing chip style
    Widget buildChip(String text, Color color, IconData icon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(
              text.isNotEmpty
                  ? '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}'
                  : text,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),

          ],
        ),
      );
    }

    // 🧩 Define chips list
    List<Widget> chips = [];

    // 🟢 Approved + Verified → show both chips
    if (status == 'APPROVED' && isVerified) {
      chips.add(buildChip('APPROVED', Colors.green.shade500, Icons.check_circle_rounded));
      chips.add(buildChip('VERIFIED', Colors.teal.shade600, Icons.verified_rounded));
    } else {
      Color color;
      IconData icon;

      switch (status) {
        case 'APPROVED':
          color = Colors.green.shade500;
          icon = Icons.verified;
          break;
        case 'PENDING':
          color = Colors.orange;
          icon = Icons.access_time_rounded;
          break;
        case 'REJECTED':
          color = Colors.redAccent.shade400;
          icon = FontAwesomeIcons.circleXmark;
          break;
        case 'DISABLED':
          color = Colors.grey.shade600;
          icon = FontAwesomeIcons.ban;
          break;
        default:
          color = Colors.blueGrey.shade400;
          icon = FontAwesomeIcons.circleInfo;
      }

      chips.add(buildChip(status, color, icon));
    }

    return Row(children: chips)
        .animate()
        .fadeIn(duration: 350.ms, curve: Curves.easeOut);
  }

  Widget _buildActionButtons(Map<String, dynamic> b, String status) {
    if (status != 'PENDING') return const SizedBox.shrink();

    final user = b['user'] ?? {};
    final company = user['companyName'];
    final brnNumber = b['brnNumber'];

    // both required to enable approve
    final bool canApprove = company != null &&
        company.toString().trim().isNotEmpty &&
        brnNumber != null &&
        brnNumber.toString().trim().isNotEmpty;

    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ✅ Approve Button
          ElevatedButton.icon(
            onPressed: canApprove
                ? () => _confirmApprove(b)
                : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Company and BRN details are required before approval.",
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const FaIcon(FontAwesomeIcons.circleCheck, size: 14),
            label: const Text("Approve"),
            style: ElevatedButton.styleFrom(
              elevation: 4,
              shadowColor: Colors.green.withOpacity(0.3),
              backgroundColor:
              canApprove ? Colors.green.shade600 : Colors.grey.shade400,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut).scale(
            begin: const Offset(0.98, 0.98),
            end: const Offset(1, 1),
            duration: 300.ms,
            curve: Curves.easeOutCubic,
          ),

          const SizedBox(width: 10),

          // ❌ Reject Button
          ElevatedButton.icon(
            onPressed: () => _confirmReject(b),
            icon: const FaIcon(FontAwesomeIcons.circleXmark, size: 14),
            label: const Text("Reject"),
            style: ElevatedButton.styleFrom(
              elevation: 4,
              shadowColor: Colors.redAccent.withOpacity(0.3),
              backgroundColor: Colors.redAccent.shade400,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ).animate().fadeIn(duration: 350.ms, curve: Curves.easeOut).scale(
            begin: const Offset(0.98, 0.98),
            end: const Offset(1, 1),
            duration: 350.ms,
            curve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmApprove(Map<String, dynamic> b) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          title: Row(
            children: [
              const Icon(FontAwesomeIcons.circleCheck, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Text(
                "Approve Broker",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400), // same fixed width
            child: Text(
              "Are you sure you want to approve this broker?",
              style: GoogleFonts.poppins(fontSize: 13.5),
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 10),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text("Approve"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _approveBroker(b);
    }
  }

  Future<void> _confirmReject(Map<String, dynamic> broker) async {
    final brokerId = broker['id'];
    final url = "$baseURL/api/brokers/$brokerId/reject";

    final reasonController = TextEditingController();
    String? rejectionReason;

    // 🧩 Step 1: Show dialog for reason input
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(FontAwesomeIcons.circleXmark, color: Colors.redAccent, size: 18),
              const SizedBox(width: 8),
              Text("Reject Broker", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ],
          ),
          content: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), // ✅ fixed width

            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Please provide a reason for rejection:",
                style: GoogleFonts.poppins(fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Enter rejection reason...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: kPrimaryColor),
                  ),
                ),
              ),
            ],
          ),),


          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                rejectionReason = reasonController.text.trim();
                if (rejectionReason!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a reason for rejection."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text("Reject"),
            ),
          ],
        );
      },
    );

    // 🧩 Step 2: If canceled, stop
    if (confirmed != true || rejectionReason == null || rejectionReason!.isEmpty) return;

    try {
      final token = await AuthService.getToken();

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "approvalStatus": "REJECTED",
          "rejection_reason": rejectionReason,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          broker['approvalStatus'] = 'REJECTED';
        });

        _fetchBrokers(refresh: true);

        /*ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Broker rejected: $rejectionReason'),
            backgroundColor: Colors.redAccent,
          ),
        );*/
      } else {
        throw Exception("Failed to reject broker");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _approveBroker(Map<String, dynamic> b) async {
    final token = await AuthService.getToken();
    final id = b['id'];
    final res = await http.post(
      Uri.parse('$baseURL/api/brokers/$id/approve'),
      headers: {'Authorization': 'Bearer $token'},
      body: jsonEncode({
        "approvalStatus": "APPROVED",
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      await http.post(
        Uri.parse('$baseURL/api/brokers/$id/verify'),
        headers: {'Authorization': 'Bearer $token'},
      );
      /*ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Broker approved & verified successfully"))


      );*/
      _fetchBrokers(refresh: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to approve broker"),
          backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _rejectBroker(Map<String, dynamic> b) async {
    final token = await AuthService.getToken();
    final id = b['id'].toString().trim();
    print('broker id -> $id');
    final res = await http.post(
      Uri.parse('$baseURL/api/brokers/$id/reject'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      /*ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Broker rejected successfully")));*/
      _fetchBrokers(refresh: true);
    } else {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to reject broker"),
          backgroundColor: Colors.redAccent));
    }
  }
}
// 🔸 Custom background painter for faint diagonal lines
class _LinePatternPainter extends CustomPainter {
  final Color color;
  _LinePatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.06)
      ..strokeWidth = 1;

    const spacing = 12;
    for (double i = -size.height; i < size.width * 2; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
