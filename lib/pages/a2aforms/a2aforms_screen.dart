import 'dart:convert';
import 'dart:ui';
import 'package:data_table_2/data_table_2.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_logo_loader.dart';

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

  List<Map<String, dynamic>> _forms = [];
  int _page = 1;
  int _totalPages = 1;
  final int _limit = 9;


  @override
  void initState() {
    super.initState();

    fetchA2AForms(page: 1);
  }

  Widget _buildDeleteConfirmationDialog() {
    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24), // margin from edges
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: Colors.white.withOpacity(0.9),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400), // ✅ prevent full width
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.96), Colors.grey.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 58,
                color: Color(0xFFD32F2F),
              ),
              const SizedBox(height: 16),
              Text(
                "Delete A2A Form?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "This action cannot be undone. Are you sure you want to delete this form?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        "Delete",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _deleteA2AForm(String formId) async {

    print('id -> $formId');
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
        builder: (context) => _buildDeleteConfirmationDialog(),
    );

    if (confirmed != true) return;

    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse("${baseURL}/api/a2a/$formId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "A2A form deleted successfully",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        // Refresh list after deletion
        await fetchA2AForms();
      } else {
        _showError("Failed to delete form (${response.body})");
      }
    } catch (e) {
      _showError("Error deleting form: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case "APPROVED":
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case "REJECTED":
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      case "PENDING":
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF9A825);
        break;
      case "DRAFT":
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // =======================================================
// 📄 Fetch A2A Forms (API Integration)
// =======================================================

  Future<void> fetchA2AForms({int page = 1}) async {
    setState(() => _loading = true);

    try {
      final token = await AuthService.getToken();
      final role = widget.userData["role"];
      String? currentBrokerId;

      // ✅ Determine brokerId based on role
      if (role == "ADMIN") {
        currentBrokerId = widget.userData["broker"]?["id"];
      } else if (role == "BROKER") {
        currentBrokerId = widget.userData["broker"]["id"];
      }

      print('current broker id - > $currentBrokerId');


      final response = await http.get(
        Uri.parse('${baseURL}/api/a2a?page=$page&limit=$_limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json["data"] ?? [];
        final pagination = json["pagination"] ?? {};

        setState(() {
          _page = pagination["page"] ?? page;
          _totalPages = pagination["totalPages"] ?? 1;

          _forms = data.map((f) {
            final date = f["agreementDate"] != null
                ? DateFormat('dd-MMM-yyyy')
                .format(DateTime.parse(f["agreementDate"]))
                : "-";
            final price = f["listedPrice"] != null
                ? "AED ${NumberFormat('#,##0').format(double.tryParse(f["listedPrice"]) ?? 0)}"
                : "-";

            return {
              "id": f["id"],
              "brokerId": f["brokerId"],
              "title": f["formTitle"] ?? "-",
              "date": date,
              "address": f["propertyAddress"] ?? "-",
              "buyer": f["buyerName"] ?? "-",
              "status": f["status"] ?? "-",
              "price": price,
            };
          }).toList();
        });
      } else {
        debugPrint("⚠️ Failed to fetch A2A forms (${response.statusCode})");
      }
    } catch (e) {
      debugPrint("❌ Error fetching A2A forms: $e");
    } finally {
      setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Container(
        color: const Color(0xFFF8FAFB),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            SizedBox(height: 24,),
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
                      builder: (_) => CreateA2AFormDialog(
                        userData: widget.userData,
                        onFormCreated: () => fetchA2AForms(page: 1), // 👈 callback
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔹 Table/List Card
            Expanded(
              child: _loading
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    AnimatedLogoLoader(assetPath: 'assets/collabrix_logo.png'),
                  ],
                ),
              )
                  : Container(

                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: // Inside your Container where you currently build the DataTable:
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white,
                                  Colors.grey.shade50,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: DataTable2(
                              fixedTopRows: 1, // ✅ Keeps header fixed
                              showCheckboxColumn: false,
                              headingRowColor: WidgetStateProperty.all(
                                Colors.blueGrey.shade50.withOpacity(0.95),
                              ),
                              headingRowDecoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                              ),
                              headingTextStyle: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                color: Colors.black87,
                                letterSpacing: 0.2,
                              ),
                              dataTextStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                              columnSpacing: 30,
                              horizontalMargin: 12,
                              dataRowHeight: 54,
                              dividerThickness: 0.4,
                              border: TableBorder.symmetric(
                                inside: BorderSide(color: Colors.grey.shade200, width: 0.6),
                              ),
                              minWidth: 1100,
                              columns: const [
                                DataColumn2(
                                  label: Center(child:
                                  Text("Form Title")),
                                  size: ColumnSize.M,
                                  numeric: false,
                                  tooltip: "Form Title",



                                ),
                                DataColumn2(
                                  label: Center(child: Text("Agreement Date")),
                                  size: ColumnSize.S,
                                ),
                                DataColumn2(
                                  label: Center(child: Text("Property Address")),
                                  size: ColumnSize.L,
                                ),
                                DataColumn2(
                                  label: Center(child: Text("Buyer Name")),
                                  size: ColumnSize.M,
                                ),
                                DataColumn2(
                                  label: Center(child: Text("Status")),
                                  size: ColumnSize.S,
                                ),
                                DataColumn2(
                                  label: Center(child: Text("Actions")),
                                  size: ColumnSize.S,
                                ),
                              ],
                              rows: _forms.map((f) {
                                final role = widget.userData["role"];
                                final currentBrokerId  = widget.userData['broker']["id"];


                                final isOwnForm = f["brokerId"] == currentBrokerId.toString().trim();
                                return DataRow(
                                  color: WidgetStateProperty.resolveWith<Color?>(
                                        (Set<WidgetState> states) {
                                      if (states.contains(WidgetState.hovered)) {
                                        return Colors.blue.shade50.withOpacity(0.4);
                                      }
                                      return Colors.transparent;
                                    },
                                  ),
                                  cells: [

                                    DataCell(Center(
                                      child: Text(
                                        f["title"] ?? "-",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                          fontSize: 13,
                                        ),
                                      ),
                                    )),
                                    DataCell(Center(
                                      child: Text(
                                        f["date"] ?? "-",
                                        textAlign: TextAlign.center,

                                        style: GoogleFonts.poppins(color: Colors.grey.shade700),
                                      ),
                                    )),
                                    DataCell(Center(
                                      child: Text(
                                        f["address"] ?? "-",
                                        textAlign: TextAlign.center,

                                        style: GoogleFonts.poppins(color: Colors.grey.shade700),
                                      ),
                                    )),
                                    DataCell(Center(
                                      child: Text(
                                        f["buyer"] ?? "-",
                                        textAlign: TextAlign.center,

                                        style: GoogleFonts.poppins(color: Colors.grey.shade700),
                                      ),
                                    )),
                                    DataCell(Center(child: _buildStatusChip(f["status"] ?? "-"))),
                                DataCell(
                                Center(
                                child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                // 👁 View button (always visible)
                                _buildActionButton(
                                Icons.visibility_rounded,
                                  currentBrokerId.toString(),
                                color: const Color(0xFF1976D2),
                                ),
                                  if (isOwnForm) const SizedBox(width: 8),

                                // ✏️ Edit button (only visible for owned forms)
                                if (isOwnForm)
                                _buildActionButton(
                                Icons.edit_rounded,
                                "Edit",
                                color: Colors.orangeAccent,
                                ),
                                if (isOwnForm) const SizedBox(width: 8),

                                // 🗑 Delete button (only visible for owned forms)
                                if (isOwnForm)
                                _buildActionButton(
                                Icons.delete_rounded,
                                "Delete",
                                color: Colors.redAccent,
                                onTap: () => _deleteA2AForm(f["id"]),
                                ),
                                ],
                                ),
                                ),
                                ),                                  ],
                                );
                              }).toList(),
                            ),
                          );
                        },
                      )


                    ),

                    // Pagination bar
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _page > 1
                                ? () => fetchA2AForms(page: _page - 1)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade100,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Previous",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            "Page $_page of $_totalPages",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _page < _totalPages
                                ? () => fetchA2AForms(page: _page + 1)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade100,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Next",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )







          ],
        ),
      ),
    );
  }


  // 🔹 Action Button (small)
  Widget _buildActionButton(
      IconData icon,
      String tooltip, {
        Color color = const Color(0xFF1976D2),
        VoidCallback? onTap,
      }) {
    return Tooltip(
      message: tooltip,
      textStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: color.withOpacity(0.2),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.15), width: 1),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
      ),
    );
  }

}

class CreateA2AFormDialog extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onFormCreated; // 👈 new

  const CreateA2AFormDialog({
    super.key,
    required this.userData,
    this.onFormCreated,
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
  final formTitleC = TextEditingController();

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

  final TextEditingController _searchController = TextEditingController();

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
    final broker = user['broker']?? {};

    print('broker -> $broker');


    // 🧩 Safely map values to text fields
    buyerAgentNameC.text = broker?['displayName'] ?? '${user['firstName']} ${user['lastName']}';
    buyerEstablishmentNameC.text = user['companyName'] ?? broker?['user']?['companyName'] ?? '';
    buyerOfficeAddressC.text = broker?['address'] ?? '';
    buyerPhoneC.text = broker?['phone'] ?? broker['mobile'] ?? '';
    buyerFaxC.text = '';
    buyerEmailC.text = broker?['email'] ?? user['email'] ?? '';
    buyerDedLicenseC.text = broker?['licenseNumber'] ?? '';
    buyerPoBoxC.text = broker?['postalCode'] ?? '';
    buyerOrnC.text = broker?['reraNumber'] ?? '';
    buyerBrnC.text = broker?['brnNumber'] ?? '';
    buyerBrnIssueDateC.text = broker?['brnIssuesDate'] != null
        ? DateFormat('dd-MMM-yyyy').format(DateTime.parse(broker!['brnIssuesDate']))
        : '';
    buyerMobileC.text = broker?['mobile'] ?? user['phone'] ?? '';
    buyerFormBStrC.text = '';
    setState(() {});
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
          // 🧩 Get current broker ID from userData
          final currentUser = widget.userData;
          final currentBrokerId = currentUser['broker']?['id'];

          // 🧩 Add only verified brokers other than current broker
          all.addAll(brokers.where((b) =>
          b["isVerified"] == true &&
              b["id"].toString() != currentBrokerId.toString()));

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

  Future<void> createA2AForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _loadingBrokers = true);
      final token = await AuthService.getToken();
      final user = widget.userData;

      // 🔹 Determine broker and company IDs
      final role = user["role"];
      final brokerId = user["broker"]?["id"];

      // For now, we’ll reuse broker ID as company until your API gives a2a_company_id explicitly
      final companyId = "550e8400-e29b-41d4-a716-446655440012";

      // 🧾 Prepare body
      final body = {
        "broker_id": brokerId,
        "form_title": formTitleC.text.trim().isEmpty
            ? "A2A Form - Untitled"
            : formTitleC.text.trim(),
        "agreement_date": DateTime.now().toIso8601String(),
        "status": "draft",
        "a2a_company_id": companyId,

        // 🟣 SELLER’S AGENT (Part 1A)
        "seller_agent_establishment": sellerEstablishmentC.text.trim(),
        "seller_agent_address": sellerOfficeAddressC.text.trim(),
        "seller_agent_phone": sellerOfficePhoneC.text.trim(),
        "seller_agent_fax": sellerFaxC.text.trim(),
        "seller_agent_email": sellerEmailC.text.trim(),
        "seller_agent_orn": sellerOrnC.text.trim(),
        "seller_agent_ded_license": sellerDedLicenseC.text.trim(),
        "seller_agent_po_box": sellerPoBoxC.text.trim(),
        "seller_agent_name": sellerAgentC.text.trim(),
        "seller_agent_brn": sellerBrnC.text.trim(),
        "seller_agent_brn_date": sellerBrnIssueDateC.text.isNotEmpty
            ? DateFormat('dd-MMM-yyyy')
            .parse(sellerBrnIssueDateC.text)
            .toIso8601String()
            : null,
        "seller_agent_mobile": sellerMobileC.text.trim(),
        "seller_form_a_str": sellerFormAStrC.text.trim(),

        // 🟣 BUYER’S AGENT (Part 1B)
        "buyer_agent_establishment": buyerEstablishmentNameC.text.trim(),
        "buyer_agent_address": buyerOfficeAddressC.text.trim(),
        "buyer_agent_phone": buyerPhoneC.text.trim(),
        "buyer_agent_fax": buyerFaxC.text.trim(),
        "buyer_agent_email": buyerEmailC.text.trim(),
        "buyer_agent_orn": buyerOrnC.text.trim(),
        "buyer_agent_ded_license": buyerDedLicenseC.text.trim(),
        "buyer_agent_po_box": buyerPoBoxC.text.trim(),
        "buyer_agent_name": buyerAgentNameC.text.trim(),
        "buyer_agent_brn": buyerBrnC.text.trim(),
        "buyer_agent_brn_date": buyerBrnIssueDateC.text.isNotEmpty
            ? DateFormat('dd-MMM-yyyy')
            .parse(buyerBrnIssueDateC.text)
            .toIso8601String()

            : null,
        "buyer_agent_mobile": buyerMobileC.text.trim(),
        "buyer_form_b_str": buyerFormBStrC.text.trim(),

        // 🟣 PROPERTY DETAILS (Part 2)
        "property_address": propertyAddressC.text.trim(),
        "master_developer": masterDeveloperC.text.trim(),
        "master_project_name": masterProjectNameC.text.trim(),
        "building_name": buildingNameC.text.trim(),
        "listed_price": listedPriceC.text.trim(),
        "property_description": propertyDescriptionC.text.trim(),
        "maintenance_fee": maintenanceFeeC.text.trim(),

        // 🟣 COMMISSION & BUYER DETAILS (Part 3)
        "seller_commission_percentage": sellerCommissionC.text.trim(),
        "buyer_commission_percentage": buyerCommissionC.text.trim(),
        "buyer_name": buyerNameC.text.trim(),
        "budget": buyerBudgetC.text.trim(),
        "transfer_fee_paid_by": transferFeeBy?.toLowerCase() ?? "buyer",
        "has_pre_finance_approval": buyerHasFinanceApproval,
        "mou_exists": buyerHasMOU,
        "buyer_contacted_listing_agent": buyerContactedListing,
        "is_property_tenanted": propertyIsTenanted,
      };

      // 🌐 API Call
      final response = await http.post(
        Uri.parse("$baseURL/api/a2a"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );


      if (response.statusCode == 201 || response.statusCode == 200) {
        widget.onFormCreated?.call(); // 🔥 triggers refresh in parent

        Navigator.pop(context); // close dialog

      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(
              "Failed: ${err["message"] ?? "Unable to create form."}",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error creating A2A Form: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            "Error: ${e.toString()}",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      );
    } finally {
      setState(() => _loadingBrokers = false);
    }
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

                // 🧾 Form Title + Company Profile (Equal Width Layout)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🧾 Form Title / Reference
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Form Title / Reference",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: formTitleC,
                              decoration: InputDecoration(
                                hintText: "e.g. Villa 123 - Marina",
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide(color: Color(0xFF1976D2), width: 1),
                                ),
                              ),
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // 🏢 Company Profile Dropdown
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your Company Profile",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300, width: 1),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: widget.userData["companyName"],
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                      color: Colors.black54),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: widget.userData["companyName"],
                                      child: Text(
                                          '${widget.userData["companyName"]} (ORN: ${widget.userData['broker']["reraNumber"]})' ?? "No Company Found",
                                        style: GoogleFonts.poppins(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                  onChanged: (_) {},
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),


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
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await createA2AForm();
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
        double step = 0.5, // default step allows decimal increments
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
            // ✅ allow digits + optional decimal up to 2 places
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
          ],
          onChanged: (value) {
            if (value.isEmpty) return;
            final val = double.tryParse(value) ?? min;
            // ✅ auto-correct if user enters < min or > max
            if (val < min) controller.text = min.toStringAsFixed(2);
            if (val > max) controller.text = max.toStringAsFixed(2);
          },
          decoration: InputDecoration(
            hintText: hint ?? "0",
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
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Colors.black87, width: 1),
            ),

            // 🔼🔽 arrows inside suffix
            suffixIcon: SizedBox(
              width: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      double current = double.tryParse(controller.text) ?? min;
                      if (current < max) {
                        current += step;
                        if (current > max) current = max;
                        controller.text = current.toStringAsFixed(2);
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
                      if (current > min) {
                        current -= step;
                        if (current < min) current = min;
                        controller.text = current.toStringAsFixed(2);
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
              : DropdownButtonFormField2<String>(
            decoration: InputDecoration(
              labelText: "Select Seller's Agent",
              labelStyle: GoogleFonts.poppins(fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            isExpanded: true,
            dropdownStyleData: DropdownStyleData(
              maxHeight: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            menuItemStyleData: const MenuItemStyleData(
              height: 42,
              padding: EdgeInsets.symmetric(horizontal: 12),
            ),
            dropdownSearchData: DropdownSearchData(
              searchController: _searchController,
              searchInnerWidgetHeight: 50,
              searchInnerWidget: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search broker...',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              searchMatchFn: (item, searchValue) {
                return item.value
                    .toString()
                    .toLowerCase()
                    .contains(searchValue.toLowerCase()) ||
                    (item.child is Text &&
                        (item.child as Text)
                            .data!
                            .toLowerCase()
                            .contains(searchValue.toLowerCase()));
              },
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
                sellerAgentC.text = broker["displayName"] ?? '';
                sellerEstablishmentC.text = broker["user"]?["companyName"] ?? '';
                sellerOrnC.text = broker["reraNumber"] ?? '';
                sellerBrnC.text = broker["brnNumber"] ?? '';
                sellerMobileC.text = broker["mobile"] ?? '';
                sellerEmailC.text = broker["email"] ?? '';
                sellerOfficeAddressC.text = broker["address"] ?? '';
                sellerOfficePhoneC.text = broker['user']["phone"] ?? broker["mobile"];
                sellerDedLicenseC.text = broker["licenseNumber"] ?? '';
                sellerBrnIssueDateC.text = broker?['brnIssuesDate'] != null
                    ? DateFormat('dd-MMM-yyyy').format(DateTime.parse(broker!['brnIssuesDate']))
                    : '';
                sellerPoBoxC.text = broker["postalCode"] ?? '';
                _searchController.clear();
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
