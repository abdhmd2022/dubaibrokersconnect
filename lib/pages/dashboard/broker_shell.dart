import 'package:flutter/material.dart';
import '../../constants.dart';
import 'UnverifiedBrokerDashboard.dart';
import 'brokerdashboard.dart';
import '../listings/listings_screen.dart';
import '../requirements/requirements_screen.dart';
import '../directory/broker_directory_screen.dart';
import '../profile/profile_screen.dart';
import '../transactions/transactions_screen.dart';
import '../a2aforms/a2aforms_screen.dart';
import 'sidebar_broker.dart';

class BrokerShell extends StatefulWidget {
  final Map<String, dynamic> userData;
  const BrokerShell({super.key, required this.userData});

  @override
  State<BrokerShell> createState() => _BrokerShellState();
}

class _BrokerShellState extends State<BrokerShell> {
  int _selectedIndex = 0;



  @override
  Widget build(BuildContext context) {
    final userData = widget.userData;
    final bool isVerified = userData['isVerified'] == true;
    final List<Widget> _pages = [
      isVerified
          ? BrokerDashboardContent(userData: userData,
        onNavigateToListings: () => setState(() => _selectedIndex = 1),
        onNavigateToRequirements: () => setState(() => _selectedIndex = 2),
        onNavigateToTransactions: () => setState(() => _selectedIndex = 5),
        onNavigateToBrokers: () => setState(() => _selectedIndex = 3),
        onNavigateToProfile: () => setState(() => _selectedIndex = 4),
        onNavigateToA2aForms: () => setState(() => _selectedIndex = 6),)
          :  UnverifiedBrokerDashboard(userData: userData,
        onNavigateToBrokers: () {
          setState(() => _selectedIndex = 3);
        },),
      ListingsScreen(userData: userData,),
      RequirementsScreen(userData: userData,),
      BrokerDirectoryScreen(),
      ProfileScreen(),
      TransactionsScreen(),
      A2aformsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        children: [
          BrokerSidebar(
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
