import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants.dart';

class ImportFromBayutScreen extends StatefulWidget {
  const ImportFromBayutScreen({super.key});

  @override
  State<ImportFromBayutScreen> createState() => _ImportFromBayutScreenState();
}

class _ImportFromBayutScreenState extends State<ImportFromBayutScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 1;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Step 3 controllers
  final TextEditingController titleC = TextEditingController();
  final TextEditingController refNoC = TextEditingController();
  final TextEditingController locationC = TextEditingController();
  final TextEditingController sizeC = TextEditingController();
  final TextEditingController rentC = TextEditingController();
  final TextEditingController descriptionC = TextEditingController();

  String? propertyType = "Villa";
  String? rooms = "1 Room";
  String? status = "Ready to Move";
  String? furnishing = "Furnished";

  String lookingFor = "";
  String category = "";
  final TextEditingController bayutUrlC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _controller.forward(from: 0);
  }

  void _submitListing() {
    // TODO: implement API logic later
    debugPrint("Listing submitted: ${titleC.text}");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Listing created successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750,maxHeight: 500),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(

                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStepIndicator(),
                  const SizedBox(height: 30),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildCurrentStep(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.import_export_rounded, color: kPrimaryColor, size: 24),
        ),
        const SizedBox(width: 10),
        Text(
          "Import from Bayut",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    const double stepCircleSize = 80;
    const double stepSpacing = 135; // distance between circles

    return Center(
      child: SizedBox(
        width: (stepSpacing ) + (stepCircleSize * 3),
        height: stepCircleSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- Connecting Lines Between Circles
            Positioned(
              top: (stepCircleSize / 4) - 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Line between step 1 & 2
                  Container(
                    width: stepSpacing,
                    height: 4,
                    color: _currentStep > 1
                        ? kPrimaryColor
                        : Colors.grey.shade200,
                  ),
                  // Line between step 2 & 3
                  Container(
                    width: stepSpacing,
                    height: 4,
                    color: _currentStep > 2
                        ? kPrimaryColor
                        : Colors.grey.shade200,
                  ),
                ],
              ),
            ),

            // --- Step Circles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepCircle(1, "Select Type"),
                _buildStepCircle(2, "Import URL"),
                _buildStepCircle(3, "Review Data"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final bool isActive = _currentStep >= step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? kPrimaryColor : Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? kPrimaryColor : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildStepOne();
      case 2:
        return _buildStepTwo();
      case 3:
        return _buildStepThree();
      default:
        return Container();
    }
  }

  Widget _buildStepOne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What type of property are you importing? *",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟦 I'm Looking For Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "I'm looking to",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        _buildSegmentedButton(
                          "Rent",
                          lookingFor == "Rent",
                              () => setState(() => lookingFor = "Rent"),
                          Icons.sell_outlined,
                        ),
                        _buildSegmentedButton(
                          "Sell",
                          lookingFor == "Sell",
                              () => setState(() => lookingFor = "Sell"),
                          Icons.shopping_cart_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // 🟧 Property Category Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Property Category",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        _buildSegmentedButton(
                          "Residential",
                          category == "Residential",
                              () => setState(() => category = "Residential"),
                          Icons.home_outlined,
                        ),
                        _buildSegmentedButton(
                          "Commercial",
                          category == "Commercial",
                              () => setState(() => category = "Commercial"),
                          Icons.apartment_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const Spacer(),

        // ✅ Validation added here
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (lookingFor.isEmpty || category.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Please select both 'I'm looking to' and 'Property Category' before continuing.",
                            style: GoogleFonts.poppins(fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(
                      bottom: 20,   // distance from bottom
                      right: 20,    // distance from right edge
                      left: 100,    // limit from left so it doesn’t stretch full width
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }
              _goToStep(2);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "Next: Import Data",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.5,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ),

      ],
    );
  }

  Widget _buildStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: kPrimaryColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Selected: $category property for $lookingFor",
                  style: GoogleFonts.poppins(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 0),


        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // URL TextField (takes most width)
            Expanded(
              flex: 4,
              child: TextField(
                controller: bayutUrlC,
                decoration: InputDecoration(
                  labelText: "Bayut Property URL *",
                  prefixIcon: const Icon(Icons.link, color: kPrimaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 🟢 Import Data button
            ElevatedButton.icon(
              onPressed: () => _goToStep(3),
              icon: const Icon(Icons.cloud_download_rounded, size: 18),
              label: const Text(
                "Import Data",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
              ),
            ),
          ],
        ),


        const SizedBox(height: 8),

// 🧩 Helper text below field
        Text(
          "Paste the full URL of the Bayut property listing. The system will extract basic property details automatically.",
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 12.5,
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              label: const Text("Back"),
              onPressed: () => _goToStep(1),
            ),

          ],
        ),
      ],
    );
  }

  Widget _buildStepThree() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Step 3: Review Imported Data",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 24,
            runSpacing: 20,
            children: [
              _buildTextField("Property Title", titleC),
              _buildTextField("Reference Number", refNoC),
              _buildTextField("Location", locationC),
              _buildDropdown("Property Type", ["Villa", "Apartment", "Townhouse"], propertyType, (val) {
                setState(() => propertyType = val);
              }),
              _buildDropdown("Rooms", ["Studio", "1 Room", "2 Rooms", "3 Rooms", "4 Rooms"], rooms, (val) {
                setState(() => rooms = val);
              }),
              _buildTextField("Size (Sq Ft)", sizeC),
              _buildTextField("Annual Rent (AED)", rentC),
              _buildDropdown("Status", ["Ready to Move", "Under Construction"], status, (val) {
                setState(() => status = val);
              }),
              _buildDropdown("Furnished Status", ["Furnished", "Unfurnished", "Semi-Furnished"], furnishing, (val) {
                setState(() => furnishing = val);
              }),
              _buildTextField("Property Description", descriptionC, maxLines: 3),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                label: const Text("Back"),
                onPressed: () => _goToStep(2),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text("Create Listing"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _submitListing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: kPrimaryColor,
      labelStyle: GoogleFonts.poppins(
        color: selected ? Colors.white : Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildSegmentedButton(
      String label,
      bool selected,
      VoidCallback onTap,
      IconData icon,
      ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? kPrimaryColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? kPrimaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: selected ? Colors.white : Colors.grey.shade700,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return SizedBox(
      width: 450,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 13),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? value,
      Function(String?) onChanged) {
    return SizedBox(
      width: 450,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 13),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        value: value,
        items: options
            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }



}
