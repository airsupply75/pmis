import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String _reportType = 'Monthly';
  String? _selectedYear;
  String? _selectedMonth;

  List<String> _years = [];
  final List<String> _months = [
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
    '07',
    '08',
    '09',
    '10',
    '11',
    '12',
  ];

  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _reportData = [];

  @override
  void initState() {
    super.initState();
    _generateYearOptions();
    _fetchReport();
  }

  void _generateYearOptions() {
    final currentYear = DateTime.now().year;
    _years = List.generate(10, (i) => (currentYear - i).toString());
    _selectedYear = _years.first;
    _selectedMonth = _months.first;
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _reportData = [];
    });

    Uri url;

    switch (_reportType) {
      case 'Weekly':
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');
        url = Uri.parse(
          'https://dioceseofcalbayog.com/home/api/weekly_report?user_id=$userId',
        );
        break;
      case 'Yearly':
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');
        url = Uri.parse(
          'https://dioceseofcalbayog.com/home/api/yearly_report?user_id=$userId&year=$_selectedYear',
        );
        break;
      default: // Monthly
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');
        url = Uri.parse(
          'https://dioceseofcalbayog.com/home/api/monthly_report?user_id=$userId&year=$_selectedYear&month=$_selectedMonth',
        );
        break;
    }

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == true && jsonData['data'] is List) {
          setState(() {
            _reportData = jsonData['data'];
          });
        } else {
          setState(() {
            _errorMessage = 'No report data found.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDropdowns() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors
                    .deepPurple[50], // Light purple background for dropdown
              ),
              child: DropdownButtonFormField<String>(
                value: _reportType,
                decoration: InputDecoration(
                  labelText: 'Report Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Weekly',
                    child: Text(
                      'Weekly Report',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Monthly',
                    child: Text(
                      'Monthly Report',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Yearly',
                    child: Text(
                      'Yearly Report',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _reportType = value!;
                    _selectedYear = _years.first;
                    _selectedMonth = _months.first;
                    _fetchReport();
                  });
                },
              ),
            ),
            if (_reportType == 'Monthly' || _reportType == 'Yearly') ...[
              const SizedBox(height: 16),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(canvasColor: Colors.deepPurple[50]),
                child: DropdownButtonFormField<String>(
                  value: _selectedYear,
                  decoration: InputDecoration(
                    labelText: 'Select Year',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                    ),
                  ),
                  items: _years
                      .map(
                        (year) =>
                            DropdownMenuItem(value: year, child: Text(year)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value!;
                      _fetchReport();
                    });
                  },
                ),
              ),
            ],
            if (_reportType == 'Monthly') ...[
              const SizedBox(height: 16),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(canvasColor: Colors.deepPurple[50]),
                child: DropdownButtonFormField<String>(
                  value: _selectedMonth,
                  decoration: InputDecoration(
                    labelText: 'Select Month',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                    ),
                  ),
                  items: _months
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(_monthName(m)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value!;
                      _fetchReport();
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _monthName(String month) {
    final date = DateTime(0, int.parse(month));
    return date.month == 0
        ? ''
        : '${date.month.toString().padLeft(2, '0')} - ${['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][date.month]}';
  }

  Widget _buildReportList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    } else if (_reportData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No reports to show for the selected criteria.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _reportData.length,
      itemBuilder: (context, index) {
        final item = _reportData[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            title: Text(
              item['document_name'] ?? 'Unknown Document',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Prints',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  item['total_prints'].toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Reports', style: TextStyle(color: Colors.white)),
      //   backgroundColor: Colors.deepPurple,
      //   iconTheme: const IconThemeData(
      //     color: Colors.white,
      //   ), // Ensures back arrow is white
      // ),
      body: Column(
        children: [
          _buildDropdowns(),
          const SizedBox(height: 12),
          Expanded(child: _buildReportList()),
        ],
      ),
    );
  }
}
