import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TagManagementScreen extends StatelessWidget {
  const TagManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tag Management",
              style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Text("Coming Soon...",
                style:
                GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }
}
