import 'package:a2abrokerapp/pages/brokermanagement/broker_management_screen.dart';
import 'package:a2abrokerapp/pages/locations/locations_screen.dart';
import 'package:a2abrokerapp/pages/propertytypes/property_types_screen.dart';
import 'package:a2abrokerapp/pages/tagmanagement/tag_management_screen.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../brokermanagement/broker_profile_screen.dart';
import '../import/import_from_bayut_screen.dart';
import '../import/import_from_propertyfinder_screen.dart';
import 'admindashboard.dart';
import '../listings/listings_screen.dart';
import '../requirements/requirements_screen.dart';
import '../directory/broker_directory_screen.dart';
import '../profile/profile_screen.dart';
import '../transactions/transactions_screen.dart';
import '../a2aforms/a2aforms_screen.dart';
import 'sidebar_admin.dart';

class AdminShell extends StatelessWidget {
  final Map<String, dynamic> userData;
  final Widget child;

  const AdminShell({
    super.key,
    required this.userData,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        children: [
          AdminSidebar(userData: userData),
          Expanded(child: child),
        ],
      ),
    );
  }
}

