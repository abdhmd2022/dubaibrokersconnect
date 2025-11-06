import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';

class A2AFormsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const A2AFormsScreen({
    super.key,
    required this.userData,

  });
  @override
  State<A2AFormsScreen> createState() => _A2AFormsScreenState();
}

class _A2AFormsScreenState extends State<A2AFormsScreen> {
  bool _loading = false;

  final List<Map<String, String>> _forms = [
    {
      "title": "Form #21",
      "date": "03-Nov-2025",
      "address": "JVC Villa 12",
      "buyer": "Ahmed Ali",
      "status": "Draft",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: const Color(0xFFF8FAFB),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "A2A Forms",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Manage your Agent-to-Agent agreements.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18,color: Colors.white,),
                  label: Text(
                    "Create New Form",
                    style: GoogleFonts.poppins(fontSize: 13,
                    color: Colors.white),

                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.4),
                      builder: (_) =>  CreateA2AFormDialog(userData: widget.userData,),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔹 Table/List Card
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 40,
                    headingRowColor:
                    WidgetStateProperty.all(Colors.grey.shade100),
                    headingTextStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    dataTextStyle: GoogleFonts.poppins(fontSize: 13),
                    columns: const [
                      DataColumn(label: Text("Form Title")),
                      DataColumn(label: Text("Agreement Date")),
                      DataColumn(label: Text("Property Address")),
                      DataColumn(label: Text("Buyer Name")),
                      DataColumn(label: Text("Status")),
                      DataColumn(label: Text("Actions")),
                    ],
                    rows: _forms
                        .map(
                          (f) => DataRow(cells: [
                        DataCell(Text(f["title"]!)),
                        DataCell(Text(f["date"]!)),
                        DataCell(Text(f["address"]!)),
                        DataCell(Text(f["buyer"]!)),
                        DataCell(_buildStatusChip(f["status"]!)),
                        DataCell(Row(
                          children: [
                            _buildActionButton(Icons.visibility, "View"),
                            const SizedBox(width: 8),
                            _buildActionButton(Icons.edit, "Edit"),
                            const SizedBox(width: 8),
                            _buildActionButton(Icons.delete, "Delete",
                                color: Colors.redAccent),
                          ],
                        )),
                      ]),
                    )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Status chip
  static Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case "draft":
        color = Colors.orange.shade100;
        break;
      case "approved":
        color = Colors.green.shade100;
        break;
      case "rejected":
        color = Colors.red.shade100;
        break;
      default:
        color = Colors.grey.shade200;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
      ),
    );
  }

  // 🔹 Action Button (small)
  Widget _buildActionButton(IconData icon, String tooltip,
      {Color color = const Color(0xFF1976D2)}) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class CreateA2AFormDialog extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CreateA2AFormDialog({
    super.key,
    required this.userData,

  });
  @override
  State<CreateA2AFormDialog> createState() => _CreateA2AFormDialogState();
}

class _CreateA2AFormDialogState extends State<CreateA2AFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // ==========================================================
  // 🟩 SELLER'S AGENT STATE VARIABLES
  // ==========================================================
  String _sellerMode = 'directory'; // directory | manual
  List<dynamic> _brokers = [];
  Map<String, dynamic>? _selectedBroker;
  bool _loadingBrokers = false;
  bool _buyerFieldsReadOnly = true; // all fields except last are disabled

  // Text Controllers
  final sellerAgentC = TextEditingController();
  final sellerEstablishmentC = TextEditingController();
  final sellerOrnC = TextEditingController();
  final sellerBrnC = TextEditingController();
  final sellerMobileC = TextEditingController();
  final sellerEmailC = TextEditingController();
  final sellerOfficeAddressC = TextEditingController();
  final sellerOfficePhoneC = TextEditingController();
  final sellerFaxC = TextEditingController();
  final sellerDedLicenseC = TextEditingController();
  final sellerPoBoxC = TextEditingController();
  final sellerStrC = TextEditingController();
  final sellerBrnIssueDateC = TextEditingController();
  final sellerFormAStrC = TextEditingController();

  final buyerAgentNameC = TextEditingController();
  final buyerEstablishmentNameC = TextEditingController();
  final buyerOfficeAddressC = TextEditingController();
  final buyerPhoneC = TextEditingController();
  final buyerFaxC = TextEditingController();
  final buyerEmailC = TextEditingController();
  final buyerDedLicenseC = TextEditingController();
  final buyerPoBoxC = TextEditingController();
  final buyerOrnC = TextEditingController();
  final buyerBrnC = TextEditingController();
  final buyerBrnIssueDateC = TextEditingController();
  final buyerMobileC = TextEditingController();
  final buyerFormBStrC = TextEditingController();

  final propertyAddressC = TextEditingController();
  final masterDeveloperC = TextEditingController();
  final masterProjectNameC = TextEditingController();
  final buildingNameC = TextEditingController();
  final listedPriceC = TextEditingController();
  final maintenanceFeeC = TextEditingController();
  final propertyDescriptionC = TextEditingController();

  // Commission & Buyer
  final sellerCommissionC = TextEditingController();
  final buyerCommissionC = TextEditingController();
  final buyerNameC = TextEditingController();
  final buyerBudgetC = TextEditingController();

  String? transferFeeBy;
  bool buyerHasFinanceApproval = false;
  bool buyerHasMOU = false;
  bool buyerContactedListing = false;
  bool propertyIsTenanted = false;




  bool get isDirectoryMode => _sellerMode == 'directory';

  @override
  void initState() {
    super.initState();
    _prefillBuyerAgentDetails();
    _fetchVerifiedBrokers();
  }

  void _prefillBuyerAgentDetails() {
    final user = widget.userData;
    if (user == null) return;

    final role = user['role']?.toString().toUpperCase();
    final broker = role == 'ADMIN' ? user['broker'] : user;

    // 🧩 Safely map values to text fields
    buyerAgentNameC.text = broker?['displayName'] ?? '${user['firstName']} ${user['lastName']}';
    buyerEstablishmentNameC.text = user['companyName'] ?? broker?['user']?['companyName'] ?? '';
    buyerOfficeAddressC.text = broker?['address'] ?? '';
    buyerPhoneC.text = broker?['mobile'] ?? user['phone'] ?? '';
    buyerFaxC.text = '';
    buyerEmailC.text = broker?['email'] ?? user['email'] ?? '';
    buyerDedLicenseC.text = broker?['establishmentLicense'] ?? '';
    buyerPoBoxC.text = broker?['postalCode'] ?? '';
    buyerOrnC.text = broker?['reraNumber'] ?? '';
    buyerBrnC.text = broker?['licenseNumber'] ?? '';
    buyerBrnIssueDateC.text = '';
    buyerMobileC.text = broker?['mobile'] ?? user['phone'] ?? '';
    buyerFormBStrC.text = '';

  }


  // ==========================================================
  // 🔹 FETCH VERIFIED BROKERS (Dynamic Pagination)
  // ==========================================================
  Future<void> _fetchVerifiedBrokers() async {
    setState(() => _loadingBrokers = true);
    final token = await AuthService.getToken();
    int page = 1;
    bool hasMore = true;
    final List<dynamic> all = [];

    try {
      while (hasMore) {
        final res = await http.get(
          Uri.parse("$baseURL/api/brokers?page=$page&limit=50"),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final List<dynamic> brokers = data["data"] ?? [];
          final pagination = data["pagination"];
          all.addAll(brokers.where((b) => b["isVerified"] == true));
          page++;
          hasMore = pagination["page"] < pagination["totalPages"];
        } else {
          hasMore = false;
        }
      }
    } catch (e) {
      debugPrint("Error fetching brokers: $e");
    }

    setState(() {
      _brokers = all;
      _loadingBrokers = false;
    });
  }

  Widget _buildPropertySection() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE3B3), width: 1),


      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PART 2: THE PROPERTY",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB85C00),
            ),
          ),
          const SizedBox(height: 16),

          // 🏠 Property Details Section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(0xFFFFF5E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE3B3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Property Details",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),

                // Row 1

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "Full Property Address",
                        controller: propertyAddressC,
                        hint: "Enter full property address",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        "Master Developer",
                        controller: masterDeveloperC,
                        hint: "Enter developer name",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Row 2
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "Master Project Name",
                        controller: masterProjectNameC,
                        hint: "Enter master project name",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        "Building Name",
                        controller: buildingNameC,
                        hint: "Enter building name",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Row 3
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "Listed Price *",
                        controller: listedPriceC,
                        hint: "AED",
                        inputType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        "Maintenance Fee (per sq.ft.)",
                        controller: maintenanceFeeC,
                        hint: "AED/sq.ft.",
                        inputType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Description
                _buildMultilineField(
                  "Property Description",
                  controller: propertyDescriptionC,
                  hint: "Enter detailed property description...",
                  minLines: 3,
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultilineField(
      String label, {
        TextEditingController? controller,
        String? hint,
        int minLines = 3,
        int maxLines = 5,
        bool enabled = true,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          minLines: minLines,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint ?? '',
            hintStyle: GoogleFonts.poppins(fontSize: 12,
                color: Colors.grey),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade100,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
      ],
    );
  }

  // ==========================================================
  // 🔹 BUILD UI
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Create New A2A Form",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 🟩 Seller’s Agent (Dynamic Section)
                _buildSellerAgentSection(),

                // 🟦 Buyer’s Agent (Your Details)
                _buildBuyerAgentSection(),

                // 🟧 Property Details
                _buildPropertySection(),

                // 🟪 Commission & Buyer Details
                _buildCommissionAndBuyerSection(),

                SizedBox(height: 24),

                // 🔹 Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // TODO: implement API call to create A2A form
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        "Create Form",
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildNumericStepperField(
      String label, {
        required TextEditingController controller,
        String? hint,
        double step = 1.0,
        double min = 0,
        double max = 100,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: false),
          textAlign: TextAlign.left,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            // 🧩 Prevents typing minus or non-numeric chars
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) {
            // Prevent manually entering negative or empty
            if (value.isEmpty) return;
            final val = double.tryParse(value) ?? 0;
            if (val < min) controller.text = min.toStringAsFixed(0);
          },
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black87, width: 1),
            ),

            // 🔽🔼 suffix arrows inside field
            suffixIcon: SizedBox(
              width: 36,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      double current = double.tryParse(controller.text) ?? min;
                      if (current < max) {
                        current += step;
                        controller.text = current.toStringAsFixed(0);
                      }
                    },
                    child: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      double current = double.tryParse(controller.text) ?? min;
                      // 🧩 Block negative result
                      if (current > min) {
                        current -= step;
                        if (current < min) current = min;
                        controller.text = current.toStringAsFixed(0);
                      }
                    },
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
      ],
    );
  }



  Widget _buildCommissionAndBuyerSection() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8C8FF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PART 3: THE COMMISSION & BUYER DETAILS",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6A1B9A),
            ),
          ),
          const SizedBox(height: 16),

          // COMMISSION FIELDS
          Row(
            children: [
              Expanded(
                child: _buildNumericStepperField(
                  "Seller's Agent Commission (%)",
                  controller: sellerCommissionC,
                  hint: "e.g. 50",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumericStepperField(
                  "Buyer's Agent Commission (%)",
                  controller: buyerCommissionC,
                  hint: "e.g. 50",
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // BUYER DETAILS HEADER
          Text(
            "Buyer Details",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 10),

          // BUYER NAME + BUDGET
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  "Buyer Name (Family Name + Last 4 Digits of mobile) *",
                  controller: buyerNameC,
                  hint: "Mr Khan (+971 XX XXX 7558)",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: buyerBudgetC,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: false),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    label: Text('Budget'),
                    labelStyle: GoogleFonts.poppins(fontSize: 12),

                    prefixIcon: Container(
                      alignment: Alignment.center,
                      width: 55,
                      child: Text(
                        "AED",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: "0",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: Colors.black87, width: 1),
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // TRANSFER FEE DROPDOWN
          _buildDropdownField(
            label: "Transfer Fee Paid By",
            value: transferFeeBy,
            items: const ["Buyer", "Seller", "Negotiable"],
            onChanged: (val) => setState(() => transferFeeBy = val),
          ),
          const SizedBox(height: 16),

          // CHECKBOXES ROW 1
          Row(
            children: [
              Expanded(
                child: _buildCheckboxTile(
                  "Has the buyer had pre-finance approval?",
                  buyerHasFinanceApproval,
                      (v) => setState(() => buyerHasFinanceApproval = v!),
                ),
              ),
              Expanded(
                child: _buildCheckboxTile(
                  "Does a MOU exist on this property?",
                  buyerHasMOU,
                      (v) => setState(() => buyerHasMOU = v!),
                ),
              ),
            ],
          ),

          // CHECKBOXES ROW 2
          Row(
            children: [
              Expanded(
                child: _buildCheckboxTile(
                  "Has this buyer contacted the listing agent?",
                  buyerContactedListing,
                      (v) => setState(() => buyerContactedListing = v!),
                ),
              ),
              Expanded(
                child: _buildCheckboxTile(
                  "Is the property tenanted?",
                  propertyIsTenanted,
                      (v) => setState(() => propertyIsTenanted = v!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text("Select",
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey.shade500)),
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e, style: GoogleFonts.poppins(fontSize: 13)),
              ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(String label, bool value, Function(bool?) onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.scale(
          scale: 1.0, // make it a bit larger for better tap area
          child: Checkbox(
            value: value,
            activeColor: kPrimaryColor,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6), // ✅ rounded corners
            ),
            side: BorderSide(
              color: value
                  ? const Color(0xFF6A1B9A)
                  : Colors.grey.shade400,
              width: 1.4,
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // 🔹 SELLER MODE CHIPS
  // ==========================================================
  Widget _buildSellerModeChips() {
    return Row(
      children: [
        _buildModeCircle("Select from Directory", "directory"),
        const SizedBox(width: 20),
        _buildModeCircle("Manual/Blank", "manual"),
      ],
    );
  }

  Widget _buildModeCircle(String label, String mode) {
    final bool active = _sellerMode == mode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _sellerMode = mode;

          // 🧹 Clear fields when switching to Manual Entry
          if (mode == 'manual') {
            _selectedBroker = null;
            sellerAgentC.clear();
            sellerEstablishmentC.clear();
            sellerOrnC.clear();
            sellerBrnC.clear();
            sellerMobileC.clear();
            sellerEmailC.clear();
            sellerOfficeAddressC.clear();
            sellerOfficePhoneC.clear();
            sellerFaxC.clear();
            sellerDedLicenseC.clear();
            sellerPoBoxC.clear();
            sellerStrC.clear();
            sellerBrnIssueDateC.clear();
            sellerFormAStrC.clear();
          }
        });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? Colors.black : Colors.black,
                width: 1,
              ),
              color: active ?  Colors.transparent : Colors.transparent,
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: active ? 12 : 0,
                height: active ? 12 : 0,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🔹 SELLER AGENT SECTION
  // ==========================================================
  Widget _buildSellerAgentSection() {
    return _buildSection(
      title: "PART 1A: SELLER’S AGENT",
      color: const Color(0xFFE8F5E9),
      children: [
        _buildSellerModeChips(),
        const SizedBox(height: 16),

        // Directory Dropdown / Shimmer
        if (_sellerMode == 'directory')
          _loadingBrokers
              ? _buildShimmerPlaceholder()
              : DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "Select Seller's Agent",
              labelStyle: GoogleFonts.poppins(fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            items: _brokers
                .map((b) => DropdownMenuItem<String>(
              value: b["id"],
              child: Text(
                b["displayName"] ?? 'Unnamed Broker',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ))
                .toList(),
            onChanged: (id) {
              final broker = _brokers.firstWhere((b) => b["id"] == id);
              setState(() {
                _selectedBroker = broker;
                // Autofill (future-safe)
                sellerAgentC.text = broker["displayName"] ?? '';
                sellerEstablishmentC.text =
                    broker["user"]?["companyName"] ?? '';
                sellerOrnC.text = broker["reraNumber"] ?? '';
                sellerBrnC.text = broker["licenseNumber"] ?? '';
                sellerMobileC.text = broker["mobile"] ?? '';
                sellerEmailC.text = broker["email"] ?? '';
                sellerOfficeAddressC.text = broker["address"] ?? '';
                sellerDedLicenseC.text =
                    broker["establishmentLicense"] ?? '';
                sellerPoBoxC.text = broker["postalCode"] ?? '';
              });
            },
            value: _selectedBroker?["id"],
          ),

        if(_sellerMode == 'directory')...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF1976D2), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Please select a verified agent from the directory above to auto-fill their details.",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF1976D2),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),


        // Compact Grid Layout (Optimized)
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    "Agent Name *",
                    controller: sellerAgentC,
                    enabled: !isDirectoryMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    "Establishment Name *",
                    controller: sellerEstablishmentC,
                    enabled: !isDirectoryMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    "ORN *",
                    controller: sellerOrnC,
                    enabled: !isDirectoryMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    "BRN Number *",
                    controller: sellerBrnC,
                    enabled: !isDirectoryMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    "Mobile *",
                    controller: sellerMobileC,
                    enabled: !isDirectoryMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    "Email *",
                    controller: sellerEmailC,
                    enabled: !isDirectoryMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 🏢 Office & Contact Details
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    "Office Address",
                    controller: sellerOfficeAddressC,
                    enabled: !isDirectoryMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    "Office Phone",
                    controller: sellerOfficePhoneC,
                    enabled: !isDirectoryMode,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    "Fax",
                    controller: sellerFaxC,
                    enabled: !isDirectoryMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    "DED Licence *",
                    controller: sellerDedLicenseC,
                    enabled: !isDirectoryMode,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    "PO Box",
                    controller: sellerPoBoxC,
                    enabled: !isDirectoryMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    "STR# (optional)",
                    controller: sellerStrC,
                    enabled: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                Expanded(
                  child: _buildDatePickerField(
                    "BRN Issue Date",
                    controller: sellerBrnIssueDateC,
                    enabled: !isDirectoryMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    "Seller Agent Form A STR# (optional)",
                    controller: sellerFormAStrC,
                    enabled: true,
                  ),
                ),
              ],
            ),

          ],
        ),
      ],
    );
  }

  Widget _buildBuyerAgentSection() {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB3D2FF), width: 1),

      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PART 1B: BUYER’S AGENT (Your Details)",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 16),

          // Row 1
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  "Agent Name",
                  controller: buyerAgentNameC,
                  enabled: !_buyerFieldsReadOnly ? true : false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  "Establishment Name",
                  controller: buyerEstablishmentNameC,
                  enabled: !_buyerFieldsReadOnly ? true : false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),


          // Row 2
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  "Office Address",
                  controller: buyerOfficeAddressC,
                  enabled: !_buyerFieldsReadOnly ? true : false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  "Phone",
                  controller: buyerPhoneC,
                  enabled: !_buyerFieldsReadOnly ? true : false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 3
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  "Fax",
                  controller: buyerFaxC,
                  enabled: !_buyerFieldsReadOnly ? true : false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  "Email",
                  controller: buyerEmailC,
                  enabled: !_buyerFieldsReadOnly ? true : false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 4
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  "DED Licence",
                  controller: buyerDedLicenseC,
                  enabled: !_buyerFieldsReadOnly ? true : false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  "PO Box",
                  controller: buyerPoBoxC,
                  enabled: !_buyerFieldsReadOnly ? true : false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 5
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  "ORN",
                  controller: buyerOrnC,
                  enabled: !_buyerFieldsReadOnly ? true : false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  "BRN",
                  controller: buyerBrnC,
                  enabled: !_buyerFieldsReadOnly ? true : false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 6
          Row(
            children: [
              Expanded(
                child: _buildDatePickerField(
                  "BRN Date Issued",
                  controller: buyerBrnIssueDateC,
                  enabled: !_buyerFieldsReadOnly ? true : false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  "Mobile",
                  controller: buyerMobileC,
                  enabled: !_buyerFieldsReadOnly ? true : false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 7 (editable)
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  "Buyer’s Agent Form B STR#",
                  controller: buyerFormBStrC,
                  enabled: true, // ✅ only editable field
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }


  // ==========================================================
// 🔹 SECTION WRAPPER (Reusable for each part)
// ==========================================================
  Widget _buildSection({
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color:  Color(0xFFB2DFDB), width: 1),

      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }


  Widget _buildTextField(
      String label, {
        TextEditingController? controller,
        int maxLines = 1,
        bool enabled = true,  String? hint,
        TextInputType inputType = TextInputType.text,

      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        keyboardType: inputType,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
            hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 12,
          color: Colors.grey),

          labelStyle: GoogleFonts.poppins(fontSize: 12),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String label,
      {required TextEditingController controller,
      bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        enabled: enabled,
        onTap: !enabled
            ? null
            : () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            controller.text =
            "${picked.day}-${_monthName(picked.month)}-${picked.year}";
          }
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 13),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade50,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        style: GoogleFonts.poppins(fontSize: 13),
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[m - 1];
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
