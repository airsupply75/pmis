import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Baptismal {
  final int id;
  final String bap_fullname;
  final String bap_birthdate;
  final String bap_mother;
  bool approved;

  Baptismal({
    required this.id,
    required this.bap_fullname,
    required this.bap_birthdate,
    required this.bap_mother,
    required this.approved,
  });

  factory Baptismal.fromJson(Map<String, dynamic> json) {
    return Baptismal(
      id: int.parse(json['id'].toString()),
      bap_fullname: json['bap_fullname'] ?? '',
      bap_birthdate: json['bap_birthdate'] ?? '',
      bap_mother: json['bap_mother'] ?? '',
      approved: json['approved'].toString() == '1',
    );
  }
}

class PendingPage extends StatefulWidget {
  const PendingPage({super.key});

  @override
  State<PendingPage> createState() => _PendingPageState();
}

class _PendingPageState extends State<PendingPage> {
  bool _isLoading = true;
  List<Baptismal> _baptismalRecords = [];
  List<Baptismal> _filteredRecords = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPendingBaptismals();
    _searchController.addListener(() {
      _filterSearchResults(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPendingBaptismals() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final parishId = prefs.getInt('parish_id');

    final url = Uri.parse(
      'https://dioceseofcalbayog.com/home/api/baptismal/pending?parish_id=$parishId',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        final List data = jsonData['data'];
        final records = data.map((json) => Baptismal.fromJson(json)).toList();

        setState(() {
          _baptismalRecords = records;
          _filteredRecords = records;
          _isLoading = false;
        });
      } else {
        setState(() {
          _baptismalRecords = [];
          _filteredRecords = [];
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _baptismalRecords = [];
        _filteredRecords = [];
        _isLoading = false;
      });
    }
  }

  void _filterSearchResults(String query) {
    setState(() {
      _filteredRecords = query.isEmpty
          ? _baptismalRecords
          : _baptismalRecords
                .where(
                  (record) => record.bap_fullname.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
                )
                .toList();
    });
  }

  Future<void> toggleApprovalStatus(Baptismal record) async {
    final newStatus = record.approved ? '0' : '1';

    final response = await http.post(
      Uri.parse(
        'https://dioceseofcalbayog.com/home/api/baptismal/toggle_approval/${record.id}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'approved': newStatus}),
    );

    if (response.statusCode == 200) {
      setState(() => record.approved = !record.approved);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Approval status updated!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by full name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _filteredRecords.isEmpty
              ? Center(child: Text('No matching pending records.'))
              : ListView.builder(
                  itemCount: _filteredRecords.length,
                  itemBuilder: (context, index) {
                    final b = _filteredRecords[index];
                    final formattedDate = b.bap_birthdate.isNotEmpty
                        ? DateFormat(
                            'MMMM d, y',
                          ).format(DateTime.parse(b.bap_birthdate))
                        : 'N/A';

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            b.bap_fullname[0].toUpperCase(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(b.bap_fullname),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Birthdate: $formattedDate'),
                            Text('Mother: ${b.bap_mother}'),
                          ],
                        ),
                        trailing: Switch(
                          value: b.approved,
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                          onChanged: (_) => toggleApprovalStatus(b),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
