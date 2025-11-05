import 'package:a2abrokerapp/pages/brokermanagement/broker_management_screen.dart';
import 'package:a2abrokerapp/pages/locations/locations_screen.dart';
import 'package:a2abrokerapp/pages/propertytypes/property_types_screen.dart';
import 'package:a2abrokerapp/pages/tagmanagement/tag_management_screen.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../brokermanagement/broker_profile_screen.dart';
import 'admindashboard.dart';
import '../listings/listings_screen.dart';
import '../requirements/requirements_screen.dart';
import '../directory/broker_directory_screen.dart';
import '../profile/profile_screen.dart';
import '../transactions/transactions_screen.dart';
import '../a2aforms/a2aforms_screen.dart';
import 'sidebar_admin.dart';

class AdminShell extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AdminShell({super.key, required this.userData});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;


  @override
  Widget build(BuildContext context) {
    final userData = widget.userData;
    final List<Widget> _pages = [
      AdminDashboardContent(
        userData: userData,
        onNavigateToBrokers: () {
          setState(() => _selectedIndex = 3); // 👈 opens Broker Directory
        },
        onNavigateToBrokerManagement: () {
          setState(() => _selectedIndex = 7); // 👈 opens Broker Directory
        },
      ),
      ListingsScreen(userData: userData,),
      RequirementsScreen(userData: userData,),
      BrokerDirectoryScreen(userData: userData,),
      ProfileScreen(brokerId: userData['broker']['id'], userData: userData),
      TransactionsScreen(),
      A2aformsScreen(),
      BrokerManagementScreen(),
      TagManagementScreen(),
      PropertyTypesScreen(),
      LocationManagementScreen(),

    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        children: [
          AdminSidebar(
            userData: widget.userData,
            selectedIndex: _selectedIndex,
            onItemSelected: (i) => setState(() => _selectedIndex = i),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
