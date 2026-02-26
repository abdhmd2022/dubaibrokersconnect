import 'dart:convert';

import 'package:a2abrokerapp/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_logo_loader.dart';
import '../../widgets/web_image_widget.dart';

class MyTransactionsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MyTransactionsScreen({Key? key, required this.userData})
      : super(key: key);

  @override
  State<MyTransactionsScreen> createState() => _MyTransactionsScreenState();
}

class _MyTransactionsScreenState extends State<MyTransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> pendingOthersList = [];
  late ScrollController _scrollController;

  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 10; // or whatever your API default is
  bool _loadingMore = false;

  List<Map<String, dynamic>> pendingMyConfirmations = [];
  List<Map<String, dynamic>> completedTransactions = [
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fetchTransactions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _currentPage < _totalPages) {
      _fetchTransactions(page: _currentPage + 1);
    }
  }

  Future<void> _fetchTransactions({int page = 1}) async {
    try {
      if (page == 1) setState(() => _loading = true);
      else setState(() => _loadingMore = true);

      final token = await AuthService.getToken();
      final currentBrokerId = widget.userData["broker"]["id"];
      final currentUserId = widget.userData["id"];

      final response = await http.get(
        Uri.parse("$baseURL/api/transactions?page=$page&limit=$_limit"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded["data"] ?? [];
        final pagination = decoded["pagination"] ?? {};

        // Update total pages
        _totalPages = pagination["totalPages"] ?? 1;
        _currentPage = pagination["page"] ?? page;

        final List<Map<String, dynamic>> txList =
        data.map((e) => Map<String, dynamic>.from(e)).toList();

        // 🟢 Pending My Confirmation → transactions created by OTHER broker, but assigned to ME
        final myPending = txList.where((tx) {
          final status = (tx["status"] ?? "").toString().toUpperCase();
          final createdBy = tx["createdByBrokerId"];
          final brokerId = tx["brokerId"]; // the broker who needs to confirm / transaction belongs to

          return status == "PENDING" &&
              brokerId == currentBrokerId &&
              createdBy != currentBrokerId;
        }).toList();

        // 🟣 Pending Others Confirmation → created by ME, waiting for OTHER broker
        final othersPending = txList.where((tx) {
          final status = (tx["status"] ?? "").toString().toUpperCase();
          final createdBy = tx["createdByBrokerId"];
          final brokerId =
              tx["brokerId"] ?? (tx["broker"] is Map ? tx["broker"]["id"] : null);

          return status == "PENDING" &&
              createdBy == currentBrokerId &&
              brokerId != currentBrokerId;
        }).toList();

        // 🟢 Completed Transactions — mine or assigned to me
        final completed = txList.where((tx) {
          final status = tx["status"]?.toString().toUpperCase();
          final brokerId = tx["brokerId"] ?? (tx["broker"] is Map ? tx["broker"]["id"] : null);
          final createdBy = tx["createdByBrokerId"];

          final isCompleted = status == "COMPLETED";
          final isMine = createdBy == currentBrokerId;
          final isAssignedToMe = brokerId == currentBrokerId;

          return isCompleted && (isMine || isAssignedToMe);
        }).toList();



        setState(() {
          if (page == 1) {
            pendingMyConfirmations = myPending;
            pendingOthersList = othersPending;
            completedTransactions = completed;
          } else {
            // Append more pages
            pendingMyConfirmations.addAll(myPending);
            pendingOthersList.addAll(othersPending);
            completedTransactions.addAll(completed);
          }
        });
      } else {
        debugPrint("⚠️ Failed to fetch transactions: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching transactions: $e");
    } finally {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBrokerId = widget.userData["broker"]["id"];
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewTransactionDialog,
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add, size: 26, color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.maxWidth(context)),

        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.isMobile(context) ? 16 : 32,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24,),

              Text(
                "My Transactions",
                style: GoogleFonts.poppins(
                  fontSize: Responsive.isMobile(context) ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),


              // Top bar button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded,
                      size: 18, color: Colors.white),
                  label: Text(
                    "Record New Transaction",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                  onPressed: _openNewTransactionDialog,
                ),
              ),
              const SizedBox(height: 24),

              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelStyle: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelColor: Colors.black54,
                  labelColor: kPrimaryColor,
                  indicatorColor: kPrimaryColor,
                  tabs: [
                    Tab(text: "Pending My Confirmation (${pendingMyConfirmations.length})"),
                     Tab(text: "Pending Others (${pendingOthersList.length})"),
                    Tab(text: "Completed (${completedTransactions.length})"),
                  ],

                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [


                _buildTransactionList(pendingMyConfirmations, true, currentBrokerId: currentBrokerId),
                _buildTransactionList(pendingOthersList, false, currentBrokerId: currentBrokerId),
                _buildTransactionList(completedTransactions, false, completed: true, currentBrokerId: currentBrokerId),

                  ],
                ),
              ),


            ],
          ),
        )),
      ),
    );
  }

  void _showInitiatorDetailsDialog(Map<String, dynamic>? user) {
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// 🔹 Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Initiator Details",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.pop(),
                    )
                  ],
                ),

                const SizedBox(height: 12),

                _infoTile("Name", user["display_name"]),
                _infoTile("Email", user["email"]),
                _infoTile("Phone", user["phone"]),
                _infoTile("Company", user["company_name"]),
                _infoTile("Role", user["role"]),
                _infoTile("Broker ID", user["broker_id"]),

              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoTile(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? "-",
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchBrokerById(String brokerId) async {
    final token = await AuthService.getToken();

    final res = await http.get(
      Uri.parse("$baseURL/api/brokers/$brokerId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body)["data"] ?? {};
    } else {
      throw Exception("Broker fetch failed");
    }
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
      }  else if (label.contains("WhatsApp")) {
        final whatsapp = brokerData['user']?['whatsappno'] ?? '';

        if (whatsapp.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("WhatsApp number not available")),
          );
          return;
        }

        final Uri whatsappUri = Uri.parse("https://wa.me/$whatsapp?text=Hello%20$name!");

        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      }
      else if (label.contains("Email")) {
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
                  dynamic avatarUrl = data['avatar'];

                  // Determine the full image URL - handle both absolute and relative paths
                  final String? imageUrl = (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                      ? (avatarUrl.toString().startsWith('http://') || avatarUrl.toString().startsWith('https://'))
                      ? avatarUrl.toString()
                      : '$baseURL/$avatarUrl'
                      : null;

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
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  child: imageUrl != null

                                      ? ClipOval(
                                    child: WebCompatibleImage(
                                      imageUrl: imageUrl,
                                      width: 80,
                                      height: 80,
                                      fallback: Text(
                                        (data['displayName'] ?? 'A')[0].toUpperCase(),
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 24,
                                            color: Colors.white),
                                      ),
                                    ),
                                  )
                                      : Text(
                                    (data['displayName'] ?? 'A')[0].toUpperCase(),
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 24,
                                        color: Colors.white),
                                  ),
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
                              onPressed: () => context.pop(),
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


  Widget _buildTransactionList(
      List<Map<String, dynamic>> items,
      bool showConfirmButton, {
        bool completed = false,
        required String currentBrokerId,

      }) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            AnimatedLogoLoader(assetPath: 'assets/collabrix_logo.png'),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_rounded, size: 48, color: kPrimaryColor.withOpacity(0.8)),
              const SizedBox(height: 20),
              Text(
                "No Transactions Found",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Once transactions are added, they’ll appear here.",
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTransactions,
      child: SingleChildScrollView(
        controller: _scrollController, // 👈 ADD THIS

        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          children: [
            ...items.map((tx) {
              final isCompleted =
              (tx["status"]?.toString().toUpperCase() == "COMPLETED");
              final color = isCompleted
                  ? Colors.green
                  : (tx["status"]?.toString().toUpperCase() == "PENDING"
                  ? Colors.orange
                  : Colors.blue);

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Title & status badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  tx["transactionType"] == "SALE"
                                      ? Icons.home_work_rounded
                                      : tx["transactionType"] == "RENT"
                                      ? Icons.apartment_rounded
                                      : Icons.handshake_rounded,
                                  color: kPrimaryColor.withOpacity(0.9),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    tx["title"] ?? "-",
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.9),
                                  color.withOpacity(0.7)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Text(
                              tx["status"]?.toString().toUpperCase() ?? "-",
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 💰 Value & Type
                      Row(
                        children: [
                          Icon(Icons.payments_rounded,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            "AED ${NumberFormat('#,###').format(num.tryParse(tx['value']?.toString() ?? '0') ?? 0)}",
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.category_rounded,
                              size: 15, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            tx["transactionType"]?.toString().toUpperCase() ?? "-",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 🧑‍💼 Broker + 📅 Date
                      // 🧑‍💼 Broker + 👤 Created By + 📅 Date
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  size: 15, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                tx["broker"] is Map
                                    ? (tx["broker"]["displayName"] ?? "-")
                                    : (tx["broker"]?.toString() ?? "-"),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.calendar_month_rounded,
                                  size: 15, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                tx["transactionDate"] != null
                                    ? DateFormat('dd MMM yyyy').format(
                                  DateTime.parse(tx["transactionDate"]),
                                )
                                    : "N/A",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          /// ================= PENDING MY CONFIRMATION =================
                          /// Others initiated → You confirm
                          if (showConfirmButton) ...[
                            Row(
                              children: [
                                Icon(Icons.account_circle_outlined,
                                    size: 15, color: Colors.grey.shade600),
                                const SizedBox(width: 4),

                                Text(
                                  "Initiated by: ${tx["created_by"]?["display_name"] ?? "Unknown"}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),

                                SizedBox(width: 8,),

                                if (tx["createdByBrokerId"] != currentBrokerId)
                                  InkWell(
                                    onTap: () {
                                      _showBrokerProfilePopup(
                                        context,
                                        tx["createdByBrokerId"],
                                      );
                                    },
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                              ],
                            ),
                          ],

                          /// ================= PENDING OTHERS =================
                          /// You initiated → Others confirm
                          if (!showConfirmButton && !completed) ...[
                            const SizedBox(height: 4),

                            Row(
                              children: [
                                Icon(Icons.hourglass_top_rounded,
                                    size: 15, color: Colors.orange),
                                const SizedBox(width: 4),

                                Text(
                                  "Pending with: ${
                                      tx["broker"] is Map
                                          ? (tx["broker"]["displayName"] ?? "Unknown")
                                          : (tx["broker"]?.toString() ?? "Unknown")
                                  }",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: Colors.orange.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                SizedBox(width: 8,),
                                if (tx["brokerId"] != currentBrokerId)
                                  InkWell(
                                    onTap: () {
                                      _showBrokerProfilePopup(
                                        context,
                                        tx["brokerId"],
                                      );
                                    },
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                              ],
                            ),
                          ],

                          /// ================= COMPLETED =================
                          if (completed) ...[
                            const SizedBox(height: 4),

                            /// Initiator
                            Row(
                              children: [
                                Icon(Icons.account_circle_outlined,
                                    size: 15, color: Colors.grey.shade600),
                                const SizedBox(width: 4),

                                Text(
                                  "Initiated by: ${tx["created_by"]?["display_name"] ?? "Unknown"}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                SizedBox(width: 8,),
                                if (tx["createdByBrokerId"] != currentBrokerId)
                                  InkWell(
                                    onTap: () {
                                      _showBrokerProfilePopup(
                                        context,
                                        tx["createdByBrokerId"],
                                      );
                                    },
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            /// Confirmee
                            Row(
                              children: [
                                Icon(Icons.verified_user_outlined,
                                    size: 15, color: Colors.green),
                                const SizedBox(width: 4),

                                Text(
                                  "Confirmed by: ${
                                      tx["broker"] is Map
                                          ? (tx["broker"]["displayName"] ?? "Unknown")
                                          : (tx["broker"]?.toString() ?? "Unknown")
                                  }",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: Colors.green.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                SizedBox(width: 8,),
                                if (tx["brokerId"] != currentBrokerId)
                                  InkWell(
                                    onTap: () {
                                      _showBrokerProfilePopup(
                                        context,
                                        tx["brokerId"],
                                      );
                                    },
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                              ],
                            ),
                          ],


                        ],
                      ),


                      // 🔘 Confirm button (if applicable)
                      if (showConfirmButton) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              elevation: 3,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              "Confirm",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: () => _openConfirmDialog(tx),
                          ),
                        ),

                      ],
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
              );
            }),

          ],
        ),
      ),
    );
  }





  void _openNewTransactionDialog() async {
    final TextEditingController _amountController = TextEditingController();
    final result = await showDialog(
      context: context,
      builder: (_) => RecordTransactionDialog(userData: widget.userData),
    );
    void _formatAmount(String value) {
      if (value.isEmpty) return;

      String newValue = value.replaceAll(',', '');

      final number = int.tryParse(newValue);
      if (number == null) return;

      final formatted = NumberFormat('#,###').format(number);

      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // ✅ When dialog closes with success, refresh list
    if (result == true) {
      debugPrint("🔄 Refreshing after new transaction...");

      _fetchTransactions();
    }
  }

  void _openConfirmDialog(Map<String, dynamic> tx) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmTransactionDialog(
        brokerName: tx["broker"] is Map
            ? (tx["broker"]["displayName"] ?? "-")
            : (tx["broker"]?.toString() ?? "-"),
        transactionId: tx["id"], // 👈 pass the transaction id
      ),
    );

    // ✅ If confirmed successfully, refresh list
    if (result == true) {
      _fetchTransactions(page: _currentPage);
    }
  }

}

class RecordTransactionDialog extends StatefulWidget {
  final Map<String, dynamic> userData;

  const RecordTransactionDialog({Key? key, required this.userData})
      : super(key: key);

  @override
  State<RecordTransactionDialog> createState() =>
      _RecordTransactionDialogState();
}

class _RecordTransactionDialogState extends State<RecordTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleC = TextEditingController();
  final TextEditingController _valueC = TextEditingController();
  final TextEditingController _commentC = TextEditingController();
  final TextEditingController _dateC = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedBrokerId;
  String _selectedType = "sale";
  double _rating = 0;
  bool _loading = false;
  bool _fetchingBrokers = true;

  List<dynamic> _brokers = [];

  @override
  void initState() {
    super.initState();
    // ✅ AUTO SELECT CURRENT DATE
    _selectedDate = DateTime.now();

    // ✅ SHOW IT IN FIELD
    _dateC.text = DateFormat('dd-MMM-yyyy')
        .format(_selectedDate!);

    _fetchVerifiedBrokers();
  }

  // 🔹 Fetch verified brokers
  Future<void> _fetchVerifiedBrokers() async {
    try {
      final token = await AuthService.getToken();
      final currentBrokerId = widget.userData["broker"]["id"];

      int page = 1;
      int totalPages = 1;
      List<dynamic> allBrokers = [];

      do {
        final response = await http.get(
          Uri.parse("$baseURL/api/brokers?page=$page&limit=50"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final List brokers = json["data"] ?? [];
          final pagination = json["pagination"] ?? {};

          totalPages = pagination["totalPages"] ?? 1;

          allBrokers.addAll(brokers);
          page++;
        } else {
          break;
        }
      } while (page <= totalPages);

      // 🔹 Now Apply Filter AFTER fetching ALL pages
      final filtered = allBrokers.where((b) {
        final isVerified = b["isVerified"] == true;
        final isApproved = b["approvalStatus"] == "APPROVED";
        final isNotSelf = b["id"] != currentBrokerId;
        return isVerified && isApproved && isNotSelf;
      }).toList();

      setState(() {
        _brokers = filtered;
        _fetchingBrokers = false;
      });
    } catch (e) {
      setState(() => _fetchingBrokers = false);
      debugPrint("❌ Error fetching brokers: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Record a New Transaction",
                        style: GoogleFonts.poppins(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField("Transaction Title *", controller: _titleC),
                const SizedBox(height: 12),
                // Broker dropdown
                _fetchingBrokers
                    ? const Center(child: CircularProgressIndicator())
                    : _buildDropdownField(
                  label: "Select Broker *",
                  value: _selectedBrokerId,
                  items: _brokers.map<DropdownMenuItem<String>>((b) {
                    final name = b["displayName"] ?? "Unnamed Broker";
                    final company = b["companyName"];
                    final formattedCompany =
                    (company != null && company.toString().trim().isNotEmpty)
                        ? company
                        : "Freelancer";

                    return DropdownMenuItem<String>(
                      value: b["id"],
                      child: Text(
                        "$name – $formattedCompany",
                        style: GoogleFonts.poppins(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedBrokerId = v),
                ),
                const SizedBox(height: 12),



                // Type dropdown (sale / rent)
                Row(
                  children: [
                    // Transaction Type dropdown (takes ~40% width)
                    Expanded(
                      flex: 2,
                      child: _buildDropdownField(
                        label: "Type *",
                        value: _selectedType,
                        items: const [
                          DropdownMenuItem(value: "sale", child: Text("Sale")),
                          DropdownMenuItem(value: "rent", child: Text("Rent")),
                          DropdownMenuItem(value: "referral", child: Text("Referral")),
                        ],
                        onChanged: (v) => setState(() => _selectedType = v ?? "sale"),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Transaction Value (takes ~60% width)
                    Expanded(
                      flex: 2,
                      child: _buildTextField(


                        "Transaction Value *",
                        controller: _valueC,
                        inputType: TextInputType.number,
                        prefixText: "AED ",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Date picker
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dateC,
                      decoration: InputDecoration(
                        labelText: "Transaction Date *",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
                      ),
                      validator: (_) =>
                      _selectedDate == null ? "Please select a date" : null,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ⭐ Rating
                Text("Your Rating for this Broker",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () => setState(() => _rating = index + 1),
                      icon: Icon(
                        Icons.star_rounded,
                        color: index < _rating
                            ? const Color(0xFF1976D2)
                            : Colors.grey.shade400,
                        size: 28,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // 💬 Comment field
                TextFormField(
                  controller: _commentC,
                  maxLines: 3,

                  decoration: InputDecoration(
                    hint: Text("Describe your experience working with this broker. Be detailed and professional",
                      style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),),

                    labelText: "Your Review",
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2851),
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _loading ? null : _submitTransaction,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Submit Transaction",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 📅 Pick Date
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateC.text = DateFormat('dd-MMM-yyyy').format(picked);
      });
    }
  }


  // 🚀 Submit Transaction then Review
  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _loading = true);
      // final token = await AuthService.getToken();
      final token = await AuthService.getToken();
      print('token -> $token');
      // Step 1: Create Transaction
      final transactionBody = {
        "broker_id": _selectedBrokerId,
        "title": _titleC.text.trim(),
        "status": "pending",
        "type": _selectedType,
        "currency": "AED",
        "value": double.tryParse(_valueC.text.trim()) ?? 0.0,
        "transaction_date":
        _selectedDate?.toUtc().toIso8601String() ??
            DateTime.now().toUtc().toIso8601String(),
      };

      print('submit body -> $transactionBody');

      final transactionRes = await http.post(
        Uri.parse("$baseURL/api/transactions"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(transactionBody),
      );

      if (transactionRes.statusCode == 201 || transactionRes.statusCode == 200) {
        final data = jsonDecode(transactionRes.body);
        final transactionId = data["data"]?["id"] ?? data["id"];

        // Step 2: Submit Review (if rating given)
        if (_rating > 0) {
          final reviewBody = {
            "broker_id": _selectedBrokerId,
            "transaction_id": transactionId,
            "rating": _rating.toInt(),
            "comment": _commentC.text.trim(),
            "status": "APPROVED",
            //"reviewerId": reviewerId,
          };

          await http.post(
            Uri.parse("$baseURL/api/reviews"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
            body: jsonEncode(reviewBody),
          );
        }

        Navigator.of(context).pop(true);
       /* ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Transaction recorded successfully!"),
          backgroundColor: Colors.green,
        ));*/


      } else {
        final msg = jsonDecode(transactionRes.body)['message'] ?? 'Error';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed: $msg"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildTextField(
      String label, {
        TextEditingController? controller,
        TextInputType? inputType,
        String? prefixText,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: inputType == TextInputType.number
          ? [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
      ]
          : [],
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixStyle: GoogleFonts.poppins(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (v) =>
      (v == null || v.trim().isEmpty) ? "Required field" : null,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: items,
      onChanged: onChanged,
      validator: (v) => v == null ? "Required field" : null,
    );
  }
}

class ConfirmTransactionDialog extends StatefulWidget {
  final String brokerName;
  final String transactionId;

  const ConfirmTransactionDialog({
    Key? key,
    required this.brokerName,
    required this.transactionId,
  }) : super(key: key);

  @override
  State<ConfirmTransactionDialog> createState() =>
      _ConfirmTransactionDialogState();
}

class _ConfirmTransactionDialogState extends State<ConfirmTransactionDialog> {
  double _rating = 0;
  final TextEditingController _reviewC = TextEditingController();
  bool _loading = false;

  Future<void> _confirmTransaction() async {
    try {
      setState(() => _loading = true);
      final token = await AuthService.getToken();

      // 🔹 1. Complete the transaction
      final res = await http.post(
        Uri.parse("$baseURL/api/transactions/${widget.transactionId}/complete"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        // 🔹 2. Optionally submit review if rating given
        if (_rating > 0) {
          final reviewBody = {
            "transaction_id": widget.transactionId,
            "rating": _rating.toInt(),
            "comment": _reviewC.text.trim(),
            "status": "APPROVED",
          };

          await http.post(
            Uri.parse("$baseURL/api/reviews"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
            body: jsonEncode(reviewBody),
          );
        }

        // ✅ Close dialog and refresh parent
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Transaction confirmed successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final msg = jsonDecode(res.body)['message'] ?? 'Failed to confirm';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $msg"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Confirm transaction error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      "Confirm Transaction & Review Broker",
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      softWrap: true,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => context.pop(),
                  )],
              ),

              const SizedBox(height: 10),
              Text(
                "Please confirm the details of this transaction and provide your review for ${widget.brokerName}.",
                style: GoogleFonts.poppins(fontSize: 13.5),
              ),
              const SizedBox(height: 16),

              Text("Your Rating",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => _rating = index + 1),
                    icon: Icon(
                      Icons.star_rounded,
                      color: index < _rating
                          ? const Color(0xFF1976D2)
                          : Colors.grey.shade400,
                      size: 26,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _reviewC,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Your Review",
                  hintText:
                  "Describe your experience working with this broker.",
                  border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.3)),
                ),
                child: Text(
                  "Note: Your review impacts both brokers' reputation. Write professionally.",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: const Color(0xFF1976D2)),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _loading ? null : _confirmTransaction,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "Confirm & Complete Transaction",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  )))]),
        ),
      ),
    );
  }
}