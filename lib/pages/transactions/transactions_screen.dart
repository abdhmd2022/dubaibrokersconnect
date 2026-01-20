import 'dart:convert';

import 'package:a2abrokerapp/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../widgets/animated_logo_loader.dart';

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

        // 🟢 Pending My Confirmation → transactions I created
        final myPending = txList.where((tx) {
          final status = tx["status"]?.toString().toUpperCase();
          final createdBy = tx["createdByBrokerId"];
          return status == "PENDING" && createdBy == currentBrokerId;
        }).toList();

        // 🟣 Pending Others → transactions others created for me
        final othersPending = txList.where((tx) {
          final status = tx["status"]?.toString().toUpperCase();
          final brokerId =
              tx["brokerId"] ?? (tx["broker"] is Map ? tx["broker"]["id"] : null);
          final createdBy = tx["createdByBrokerId"];
          return status == "PENDING" &&
              brokerId == currentBrokerId &&
              createdBy != currentBrokerId;
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
                    _buildTransactionList(pendingMyConfirmations, true),
                    _buildTransactionList(pendingOthersList, false),
                    _buildTransactionList(completedTransactions, false, completed: true),

                  ],
                ),
              ),


            ],
          ),
        )),
      ),
    );
  }

  Widget _buildTransactionList(
      List<Map<String, dynamic>> items,
      bool showConfirmButton, {
        bool completed = false,
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
                          if (!completed && !showConfirmButton) ...[
                            const SizedBox(height: 6),
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
    final result = await showDialog(
      context: context,
      builder: (_) => RecordTransactionDialog(userData: widget.userData),
    );

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
    _fetchVerifiedBrokers();
  }

  // 🔹 Fetch verified brokers
  Future<void> _fetchVerifiedBrokers() async {
    try {
      final token = await AuthService.getToken();
      final currentBrokerId = widget.userData["broker"]["id"];

      final response = await http.get(
        Uri.parse("$baseURL/api/brokers"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List allBrokers = json["data"] ?? [];

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
      } else {
        setState(() => _fetchingBrokers = false);
      }
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
                    final company = b["user"]?["companyName"];
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