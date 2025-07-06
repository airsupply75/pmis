import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// --- Profile Model ---
class Profile {
  final int id;
  final String firstname;
  final String lastname;
  final String phone;
  final String email;
  final String avatar;
  final String role;

  Profile({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.phone,
    required this.email,
    required this.avatar,
    required this.role,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: int.parse(json['id'].toString()),
      firstname: json['firstname'],
      lastname: json['lastname'],
      phone: json['phone'],
      email: json['email'],
      role: json['role'],
      avatar:
          'https://dioceseofcalbayog.com/home/public/uploads/${json['avatar']}',
    );
  }
}

// --- Profile Page Widget ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Profile? _profile;
  bool _isLoading = true;
  String? _errorMessage; // To store and display error messages

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear any previous error messages
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        setState(() {
          _errorMessage = 'User ID not found. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://dioceseofcalbayog.com/home/api/profile/$userId'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == true) {
          setState(() {
            _profile = Profile.fromJson(jsonData['data']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                jsonData['message'] ?? 'Failed to load profile data.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Server error: ${response.statusCode}. Please try again later.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: fetchProfile,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _profile == null
          ? const Center(
              child: Text('No profile data available. Pull to refresh.'),
            )
          : RefreshIndicator(
              onRefresh: fetchProfile,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(), // Allows pull to refresh even if content is small
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(_profile!.avatar),
                        radius: 80,
                        backgroundColor: Colors.grey.shade200,
                        onBackgroundImageError: (exception, stackTrace) {
                          // Fallback for image loading errors
                          print('Error loading avatar: $exception');
                        },
                        child: _profile!.avatar.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey.shade600,
                              )
                            : null,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.baseline, // Align text baselines
                        textBaseline: TextBaseline
                            .alphabetic, // Required for crossAxisAlignment: TextBaseline.alphabetic
                        children: [
                          Text(
                            _profile!.firstname,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ), // Adds 8 pixels of horizontal space
                          Text(
                            _profile!.lastname,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _profile!.email,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // You can add more profile details here
                      _buildProfileInfoCard(
                        icon: Icons.person,
                        title: 'Role',
                        value: _profile!.role,
                      ),
                      const SizedBox(height: 16),
                      _buildProfileInfoCard(
                        icon: Icons.phone,
                        title: 'Phone No',
                        value: _profile!.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildProfileInfoCard(
                        icon: Icons.email_outlined,
                        title: 'Email Address',
                        value: _profile!.email,
                      ),
                      // Add more fields as needed, e.g., phone, address etc.
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Helper widget to build consistent info cards
  Widget _buildProfileInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 28),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
