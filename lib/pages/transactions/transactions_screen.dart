import 'dart:convert';

import 'package:a2abrokerapp/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

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
                  labelColor: const Color(0xFF1976D2),
                  indicatorColor: const Color(0xFF1976D2),
                  tabs: const [
                    Tab(text: "Pending My Confirmation (2)"),
                    Tab(text: "Pending Others (0)"),
                    Tab(text: "Completed (1)"),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionList(pendingMyConfirmations, true),
                    _buildTransactionList([], false),
                    _buildTransactionList(completedTransactions, false,
                        completed: true),
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
    if (items.isEmpty) {
      return Center(
        child: Text(
          "No transactions found.",
          style: GoogleFonts.poppins(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.separated(
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
          child: Row(
            children: [
              // Transaction Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx["title"] ?? "-",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text("s ", style: GoogleFonts.poppins(fontSize: 13)),
                        Text(
                          tx["broker"],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "|  Value: ${tx["value"]}",
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "|  Date: ${tx["date"]}",
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      completed
                          ? "Your Review AI Score: ${tx["aiScore"]}/100   Partner Review AI Score: ${tx["partnerScore"]}/100"
                          : "Your Review AI Score: ${tx["aiScore"]}/100",
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              if (showConfirmButton)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
          ),
        );
      },
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
  final Map<String, dynamic> userData; // 👈 pass this when opening dialog

  const RecordTransactionDialog({Key? key, required this.userData})
      : super(key: key);

  @override
  State<RecordTransactionDialog> createState() =>
      _RecordTransactionDialogState();
}

class _RecordTransactionDialogState extends State<RecordTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleC = TextEditingController();
  final TextEditingController _descriptionC = TextEditingController();
  final TextEditingController _commissionAmountC = TextEditingController();
  final TextEditingController _commissionPercentageC = TextEditingController();

  String? _selectedBrokerId;
  String? _selectedPropertyId;
  bool _loading = false;
  bool _fetchingBrokers = true;

  List<dynamic> _brokers = [];

  @override
  void initState() {
    super.initState();
    _fetchVerifiedBrokers();
  }

  // =========================================================
  // 🔹 FETCH VERIFIED & APPROVED BROKERS (EXCLUDING SELF)
  // =========================================================
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

        // ✅ Filter verified & approved brokers, excluding current broker
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

        debugPrint("✅ Loaded ${_brokers.length} verified brokers (excluding self)");
      } else {
        setState(() => _fetchingBrokers = false);
        debugPrint("⚠️ Failed to fetch brokers (${response.statusCode})");
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
        width: 480,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        "Record a New Transaction",
                        style: GoogleFonts.poppins(
                            fontSize: 17, fontWeight: FontWeight.w600),
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
                const SizedBox(height: 16),

                // Broker dropdown
                // 🧩 Broker dropdown
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

                // Property dropdown (static for now)
                _buildDropdownField(
                  label: "Property *",
                  value: _selectedPropertyId,
                  items: const [
                    DropdownMenuItem(
                        value: "aa0e8400-e29b-41d4-a716-446655440001",
                        child: Text("Luxury Villa - Downtown")),
                    DropdownMenuItem(
                        value: "bb0e8400-e29b-41d4-a716-446655440002",
                        child: Text("Sky View Apartment - Marina")),
                  ],
                  onChanged: (v) => setState(() => _selectedPropertyId = v),
                ),
                const SizedBox(height: 12),

                _buildTextField("Transaction Title *", controller: _titleC),
                const SizedBox(height: 12),
                _buildMultilineField("Description *", controller: _descriptionC),
                const SizedBox(height: 12),

                _buildTextField(
                  "Commission Amount (AED)",
                  controller: _commissionAmountC,
                  inputType:
                  const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  "Commission Percentage (%)",
                  controller: _commissionPercentageC,
                  inputType:
                  const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 24),

                // Submit Button
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
                      : Text(
                    "Submit Transaction",
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // 🔹 SUBMIT TRANSACTION
  // =========================================================
  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBrokerId == null || _selectedPropertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select a broker and property first.")));
      return;
    }

    try {
      setState(() => _loading = true);
      final token = await AuthService.getToken();

      final body = {
        "broker_id": _selectedBrokerId,
        "property_id": _selectedPropertyId,
        "title": _titleC.text.trim(),
        "description": _descriptionC.text.trim(),
        "status": "pending",
        "commission_amount":
        double.tryParse(_commissionAmountC.text.trim()) ?? 0.0,
        "commission_percentage":
        double.tryParse(_commissionPercentageC.text.trim()) ?? 0.0,
      };

      final response = await http.post(
        Uri.parse("$baseURL/api/transactions"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Transaction recorded successfully!"),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
          Text("Failed: ${jsonDecode(response.body)['message'] ?? 'Error'}"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      debugPrint("❌ Error submitting transaction: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // =========================================================
  // 🔹 FORM FIELDS
  // =========================================================
  Widget _buildTextField(String label,
      {TextEditingController? controller,
        TextInputType? inputType,
        String? hint}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (v) =>
      (v == null || v.trim().isEmpty) ? "Required field" : null,
    );
  }

  Widget _buildMultilineField(String label,
      {TextEditingController? controller}) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: label,
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
