import 'dart:convert';

import 'package:a2abrokerapp/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../widgets/animated_logo_loader.dart';

class MyTransactionsScreen extends StatefulWidget {
  final Map<String, dynamic> userData; // 👈 pass this when opening dialog

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

  List<dynamic> _transactions = [];


  final List<Map<String, dynamic>> pendingMyConfirmations = [
    {
      "title": "studio sale",
      "broker": "saadan",
      "value": "3,500,000 AED",
      "date": "12 Sep 2025",
      "aiScore": 60,
    },
    {
      "title": "studio",
      "broker": "saadan",
      "value": "2,000,000 AED",
      "date": "12 Sep 2025",
      "aiScore": 20,
    },
  ];

  final List<Map<String, dynamic>> completedTransactions = [
    {
      "title": "abc",
      "broker": "saadan",
      "value": "2,000,000 AED",
      "date": "08 Sep 2025",
      "aiScore": 50,
      "partnerScore": 60,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final token = await AuthService.getToken();
      final currentBrokerId = widget.userData["broker"]["id"]; // 👈 your broker ID
      final response = await http.get(
        Uri.parse("$baseURL/api/transactions"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final List<dynamic> all = jsonBody["data"] ?? [];

        // Separate by status
        final pendingAll = all
            .where((tx) =>
        (tx["status"]?.toString().toUpperCase() ?? "") == "PENDING")
            .toList();

        final completed = all
            .where((tx) =>
        (tx["status"]?.toString().toUpperCase() ?? "") == "COMPLETED")
            .toList();

        // Split pending between "mine" and "others"
        final pendingMy = pendingAll
            .where((tx) => tx["brokerId"]?.toString() == currentBrokerId)
            .toList();

        final pendingOthers = pendingAll
            .where((tx) => tx["brokerId"]?.toString() != currentBrokerId)
            .toList();

        setState(() {
          _transactions = all;
          _loading = false;

          pendingMyConfirmations.clear();
          completedTransactions.clear();

          // ✅ Pending My Confirmation
          pendingMyConfirmations.addAll(
            pendingMy.map<Map<String, dynamic>>((t) {
              final valueNum =
                  double.tryParse(t["value"]?.toString() ?? "0") ?? 0;
              final formattedValue =
                  "AED ${NumberFormat('#,###').format(valueNum)}";
              final date = t["transactionDate"] != null
                  ? DateFormat('dd MMM yyyy')
                  .format(DateTime.parse(t["transactionDate"]).toLocal())
                  : "N/A";

              return {
                "title": t["title"] ?? "-",
                "broker": t["broker"]?["displayName"] ?? "-",
                "value": formattedValue,
                "date": date,
                "status": t["status"] ?? "PENDING",
                "type": t["transactionType"] ?? "-",
              };
            }).toList(),
          );

          // ✅ Pending Others (store separately)
          pendingOthersList = pendingOthers.map<Map<String, dynamic>>((t) {
            final valueNum =
                double.tryParse(t["value"]?.toString() ?? "0") ?? 0;
            final formattedValue =
                "AED ${NumberFormat('#,###').format(valueNum)}";
            final date = t["transactionDate"] != null
                ? DateFormat('dd MMM yyyy')
                .format(DateTime.parse(t["transactionDate"]).toLocal())
                : "N/A";

            return {
              "title": t["title"] ?? "-",
              "broker": t["broker"]?["displayName"] ?? "-",
              "value": formattedValue,
              "date": date,
              "status": t["status"] ?? "PENDING",
              "type": t["transactionType"] ?? "-",
            };
          }).toList();

          // ✅ Completed Transactions
          completedTransactions.addAll(
            completed.map<Map<String, dynamic>>((t) {
              final valueNum =
                  double.tryParse(t["value"]?.toString() ?? "0") ?? 0;
              final formattedValue =
                  "AED ${NumberFormat('#,###').format(valueNum)}";
              final date = t["transactionDate"] != null
                  ? DateFormat('dd MMM yyyy')
                  .format(DateTime.parse(t["transactionDate"]).toLocal())
                  : "N/A";

              return {
                "title": t["title"] ?? "-",
                "broker": t["broker"]?["displayName"] ?? "-",
                "value": formattedValue,
                "date": date,
                "status": t["status"] ?? "COMPLETED",
                "type": t["transactionType"] ?? "-",
              };
            }).toList(),
          );
        });
      } else {
        setState(() => _loading = false);
        debugPrint("⚠️ Failed to fetch transactions: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching transactions: $e");
      setState(() => _loading = false);
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
              const SizedBox(height: 16),

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
              const SizedBox(height: 16),

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

  Widget _buildTransactionList(List<Map<String, dynamic>> items,
      bool showConfirmButton,
      {bool completed = false}) {


    if (_loading) {
      return   Center(
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
                    "No transaction found",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, curve: Curves.easeOutCubic),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTransactions,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tx = items[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
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
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: completed
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tx["status"] ?? "",
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: completed
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Value & Type
                Text(
                  "${tx["value"]}  •  ${tx["type"] ?? '-'}",
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),

                // Broker & Date
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      tx["broker"] ?? "-",
                      style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today_rounded,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      tx["date"] ?? "N/A",
                      style: GoogleFonts.poppins(
                          fontSize: 12.5, color: Colors.grey.shade700),
                    ),
                  ],
                ),

                if (showConfirmButton) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _openConfirmDialog(tx),
                    child: Text(
                      "Confirm",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }



  void _openNewTransactionDialog() {
    showDialog(
      context: context,
      builder: (_) =>  RecordTransactionDialog(userData: widget.userData,),
    );
  }

  void _openConfirmDialog(Map<String, dynamic> tx) {
    showDialog(
      context: context,
      builder: (_) => ConfirmTransactionDialog(brokerName: tx["broker"]),
    );
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
                      onPressed: () => Navigator.pop(context),
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
      final reviewerId = widget.userData["broker"]["id"];

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

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Transaction recorded successfully!"),
          backgroundColor: Colors.green,
        ));
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

  const ConfirmTransactionDialog({Key? key, required this.brokerName})
      : super(key: key);

  @override
  State<ConfirmTransactionDialog> createState() =>
      _ConfirmTransactionDialogState();
}

class _ConfirmTransactionDialogState extends State<ConfirmTransactionDialog> {
  double _rating = 0;
  final TextEditingController _reviewC = TextEditingController();

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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
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
                    onPressed: () {
                      setState(() => _rating = index + 1);
                    },
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
                  "Describe your experience working with this broker. Be detailed and professional.",
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
                  border:
                  Border.all(color: const Color(0xFF1976D2).withOpacity(0.3)),
                ),
                child: Text(
                  "Note: Your review quality affects both brokers' reputation scores. Our AI analyzes reviews for professionalism, detail, and helpfulness. Write thoughtfully!",
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

                onPressed: () => Navigator.pop(context),
                child: Text("Confirm & Complete Transaction",
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
