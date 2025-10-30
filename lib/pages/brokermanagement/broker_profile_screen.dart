import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants.dart';
import 'package:url_launcher/url_launcher.dart';

class BrokerProfileScreen extends StatelessWidget {
  final Map<String, dynamic> broker;
  const BrokerProfileScreen({super.key, required this.broker});

  Future<void> _launch(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = broker['displayName'] ?? '';
    final company = broker['companyName'] ?? '';
    final verified = broker['isVerified'] == true;
    final avatar = broker['user']?['avatar'];
    final rating = broker['rating'] ?? 'N/A';
    final email = broker['email'];
    final phone = broker['phone'];
    final whatsapp = broker['mobile'];
    final bio = broker['bio'] ?? '';
    final specializations = List<String>.from(broker['specializations'] ?? []);
    final languages = List<String>.from(broker['languages'] ?? []);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: kPrimaryColor.withOpacity(0.1),
                    backgroundImage:
                    avatar != null ? NetworkImage(avatar) : null,
                    child: avatar == null
                        ? Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                          color: kPrimaryColor),
                    )
                        : null,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(name,
                                style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700)),
                            if (verified)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.verified,
                                    color: Colors.green.shade600),
                              )
                          ],
                        ),
                        Text(company,
                            style: GoogleFonts.poppins(
                                color: Colors.black54, fontSize: 15)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _contactButton(Icons.call, "Call", "tel:$phone"),
                            const SizedBox(width: 8),
                            _contactButton(Icons.call, "WhatsApp",
                                "https://wa.me/${phone.toString().replaceAll('+', '')}"),
                            const SizedBox(width: 8),
                            _contactButton(
                                Icons.email_outlined, "Email", "mailto:$email"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Stats cards
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _statCard("Reputation Score", "0", Icons.bar_chart),
                _statCard("Average Rating", rating.toString(), Icons.star),
                _statCard("Completed Deals", "0", Icons.check_circle),
                _statCard("AI Review Score", "N/A", Icons.memory),
              ],
            ),
            const SizedBox(height: 30),

            // About section
            Text("About",
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12.withOpacity(0.05),
                        blurRadius: 8)
                  ]),
              child: Text(bio.isNotEmpty ? bio : "No description available.",
                  style: GoogleFonts.poppins(fontSize: 14.5)),
            ),
            const SizedBox(height: 20),

            // Specializations
            if (specializations.isNotEmpty) ...[
              Text("Specializations",
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: specializations
                    .map((e) => Chip(
                  label: Text(e),
                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                ))
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Languages
            if (languages.isNotEmpty) ...[
              Text("Languages",
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: languages
                    .map((e) => Chip(
                  label: Text(e),
                  backgroundColor: Colors.teal.shade50,
                ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kPrimaryColor, size: 24),
          const SizedBox(height: 10),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.black54)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _contactButton(IconData icon, String label, String url) {
    return ElevatedButton.icon(
      onPressed: () => _launch(url),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: label == "WhatsApp"
            ? Colors.green
            : (label == "Email" ? Colors.grey.shade700 : kPrimaryColor),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
