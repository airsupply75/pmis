import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pmis/pages/report_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badges/badges.dart' as badges;

import 'package:pmis/pages/auth/login_page.dart';
import 'package:pmis/pages/dashboard_page.dart';
import 'package:pmis/pages/pending_page.dart';
import 'package:pmis/pages/profile_page.dart';
import 'package:pmis/pages/settings_page.dart';

class MainAppScreen extends StatefulWidget {
  final String username;
  const MainAppScreen({super.key, required this.username});

  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  int _pendingCount = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(username: widget.username),
      const ProfilePage(),
      const SettingsPage(),
      const PendingPage(),
      const ReportPage(),
    ];

    fetchPendingCount();
  }

  Future<void> fetchPendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final parishId = prefs.getInt('parish_id');

      // Use a more robust check for parishId to prevent null issues in URL
      if (parishId == null) {
        print('Parish ID not found in SharedPreferences.');
        return;
      }

      final url = Uri.parse(
        'https://dioceseofcalbayog.com/home/api/baptismal/pending?parish_id=$parishId',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            _pendingCount = (data['data'] as List).length;
          });
        }
      } else {
        print('Failed to fetch pending count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching pending count: $e');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
    await prefs.remove('user_id');
    await prefs.remove('parish_id'); // Also clear parish_id on logout

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Profile';
      case 2:
        return 'Settings';
      case 3:
        return 'Pending Requests'; // More descriptive title
      case 4:
        return 'Reports'; // Plural for consistency
      default:
        return 'PMIS App'; // Default app name
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(_currentIndex),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold, // Make app bar title bold
          ),
        ),
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading:
            false, // Keep this false if you don't want a default back button
        leading: Builder(
          // Use Builder to get a context for Scaffold.of
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                // You can open a Drawer here if you add one to the Scaffold
                // Scaffold.of(context).openDrawer();
                // For now, it just shows a simple snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menu button pressed!')),
                );
              },
              tooltip: 'Menu',
            );
          },
        ),
        actions: [
          // Refresh button for pending count (optional but good for UX)
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => fetchPendingCount(),
            tooltip: 'Refresh Pending Count',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8), // Add a small space at the end
        ],
        elevation: 4.0, // Add a subtle shadow to the AppBar
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 3) {
            fetchPendingCount(); // Refresh badge count on visiting "Pending"
          }
        },
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        selectedItemColor: Theme.of(
          context,
        ).primaryColor, // Uses theme's primary color
        unselectedItemColor:
            Colors.grey.shade600, // Slightly darker grey for unselected
        selectedFontSize: 13, // Slightly smaller selected font
        unselectedFontSize: 11, // Slightly smaller unselected font
        showUnselectedLabels: true, // Always show labels for better clarity
        elevation: 8.0, // Add elevation to the bottom navigation bar
        backgroundColor: Colors.white, // Explicitly set background color
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), // Outlined icon for a modern look
            activeIcon: Icon(Icons.home), // Filled icon when active
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: badges.Badge(
              showBadge: _pendingCount > 0,
              badgeContent: Text(
                '$_pendingCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Colors.red,
                padding: EdgeInsets.all(
                  5,
                ), // Slightly smaller padding for badge
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ), // Rounded corners for badge
              ),
              child: const Icon(
                Icons.pending_actions_outlined,
              ), // More specific icon
            ),
            activeIcon: badges.Badge(
              showBadge: _pendingCount > 0,
              badgeContent: Text(
                '$_pendingCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Colors.red,
                padding: EdgeInsets.all(5),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: const Icon(
                Icons.pending_actions,
              ), // Filled icon when active
            ),
            label: 'Pending',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined), // Outlined chart icon
            activeIcon: Icon(Icons.bar_chart), // Filled chart icon
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
