import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  const DashboardPage({super.key, required this.username});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  int _baptismalCertCount = 0;
  int _marriageCertCount = 0;
  int _confirmationCertCount = 0;
  int _deathCertCount = 0;

  bool _isLoadingCounts = true;
  String _countsErrorMessage = '';

  int touchedIndex = -1;

  final Color baptismalColor = const Color(0xFF42A5F5); // Lighter Blue
  final Color marriageColor = const Color(0xFFEC407A); // Lighter Pink
  final Color confirmationColor = const Color(0xFF66BB6A); // Lighter Green
  final Color deathColor = const Color(0xFFEF5350); // Lighter Red

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchCertificateCounts();
  }

  Future<void> _fetchCertificateCounts() async {
    setState(() {
      _isLoadingCounts = true;
      _countsErrorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final parishId = prefs.getInt('parish_id');

      if (parishId == null) {
        setState(() {
          _countsErrorMessage = 'Parish ID not found. Please log in again.';
          _isLoadingCounts = false;
        });
        return;
      }

      final url = Uri.parse(
        'https://dioceseofcalbayog.com/home/api/all_certificate_counts?parish_id=$parishId',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            _baptismalCertCount = data['data']['baptismal'] ?? 0;
            _marriageCertCount = data['data']['marriage'] ?? 0;
            _confirmationCertCount = data['data']['confirmation'] ?? 0;
            _deathCertCount = data['data']['death'] ?? 0;
          });
        } else {
          _countsErrorMessage =
              data['message'] ?? 'Failed to parse certificate counts.';
        }
      } else {
        _countsErrorMessage = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      _countsErrorMessage = 'Network error: $e';
    } finally {
      setState(() {
        _isLoadingCounts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: _isLoadingCounts
          ? const Center(child: CircularProgressIndicator())
          : _countsErrorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _countsErrorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    context,
                    'Certificate Overview',
                    Icons.dashboard,
                  ),
                  const SizedBox(height: 20), // Slightly reduced spacing
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - 16) / 2;
                      final itemHeight = 160.0;
                      final aspectRatio = itemWidth / itemHeight;

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: aspectRatio,
                        children: [
                          _buildCertificateCard(
                            title: 'Baptismal',
                            count: _baptismalCertCount,
                            gradient: LinearGradient(
                              colors: [
                                baptismalColor,
                                baptismalColor.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            icon: Icons.water_drop,
                          ),
                          _buildCertificateCard(
                            title: 'Marriage',
                            count: _marriageCertCount,
                            gradient: LinearGradient(
                              colors: [
                                marriageColor,
                                marriageColor.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            icon: Icons.favorite,
                          ),
                          _buildCertificateCard(
                            title: 'Confirmation',
                            count: _confirmationCertCount,
                            gradient: LinearGradient(
                              colors: [
                                confirmationColor,
                                confirmationColor.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            icon: Icons.verified,
                          ),
                          _buildCertificateCard(
                            title: 'Death',
                            count: _deathCertCount,
                            gradient: LinearGradient(
                              colors: [deathColor, deathColor.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            icon: Icons.sick,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  _buildSectionTitle(
                    context,
                    'Certificate Distribution',
                    Icons.pie_chart,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          SizedBox(height: 280, child: _buildPieChart()),
                          const SizedBox(height: 20),
                          _buildLegend(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildSectionTitle(
                    context,
                    'Detailed Cert Totals',
                    Icons.list_alt,
                  ),
                  const SizedBox(height: 16),
                  _buildDataTable(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // --- MODIFIED WIDGET FOR SECTION TITLES ---
  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 6.0,
        top: 12.0,
      ), // Reduced vertical padding
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Align items vertically in center
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24, // Reduced icon size
          ),
          const SizedBox(width: 8), // Reduced spacing
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                // Changed to titleLarge
                fontWeight: FontWeight.bold,
                color: Colors.grey[850],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6), // Reduced spacing
          Container(
            width: 30, // Reduced divider width
            height: 2.5, // Slightly reduced divider height
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
  // --- END MODIFIED WIDGET ---

  Widget _buildCertificateCard({
    required String title,
    required int count,
    required LinearGradient gradient,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$title tapped. Count: $count')));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors[0].withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 36),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final total =
        _baptismalCertCount +
        _marriageCertCount +
        _confirmationCertCount +
        _deathCertCount;

    if (total == 0) {
      return const Center(
        child: Text(
          'No data to display in the chart.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback:
                (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 4,
          centerSpaceRadius: 70,
          sections: _buildChartSections(total),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections(int total) {
    return [
      _buildPieChartSection(
        value: _baptismalCertCount.toDouble(),
        title: 'Baptismal',
        color: baptismalColor,
        index: 0,
        total: total,
      ),
      _buildPieChartSection(
        value: _marriageCertCount.toDouble(),
        title: 'Marriage',
        color: marriageColor,
        index: 1,
        total: total,
      ),
      _buildPieChartSection(
        value: _confirmationCertCount.toDouble(),
        title: 'Confirmation',
        color: confirmationColor,
        index: 2,
        total: total,
      ),
      _buildPieChartSection(
        value: _deathCertCount.toDouble(),
        title: 'Death',
        color: deathColor,
        index: 3,
        total: total,
      ),
    ];
  }

  PieChartSectionData _buildPieChartSection({
    required double value,
    required String title,
    required Color color,
    required int index,
    required int total,
  }) {
    final isTouched = index == touchedIndex;
    final double radius = isTouched ? 75 : 70;
    final double fontSize = isTouched ? 17 : 15;
    final FontWeight fontWeight = isTouched
        ? FontWeight.bold
        : FontWeight.normal;

    final double percentage = total > 0 ? (value / total) * 100 : 0.0;
    final String sectionTitle = value > 0
        ? '${percentage.toStringAsFixed(1)}%'
        : '';

    return PieChartSectionData(
      color: color,
      value: value,
      title: sectionTitle,
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      borderSide: isTouched
          ? BorderSide(color: Colors.white.withOpacity(0.9), width: 3)
          : BorderSide(color: Colors.transparent, width: 0),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendItem(baptismalColor, 'Baptismal', _baptismalCertCount),
        _buildLegendItem(marriageColor, 'Marriage', _marriageCertCount),
        _buildLegendItem(
          confirmationColor,
          'Confirmation',
          _confirmationCertCount,
        ),
        _buildLegendItem(deathColor, 'Death', _deathCertCount),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$text ($count)',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Table(
          border: TableBorder.all(
            color: Colors.grey.shade200,
            width: 1,
            borderRadius: BorderRadius.circular(12),
          ),
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.15),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              children: const [
                Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Certificate Type',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Count',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            _buildDataTableRow('Baptismal', _baptismalCertCount),
            _buildDataTableRow('Marriage', _marriageCertCount),
            _buildDataTableRow('Confirmation', _confirmationCertCount),
            _buildDataTableRow('Death', _deathCertCount),
            TableRow(
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              children: [
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Total Certificates',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    '${_baptismalCertCount + _marriageCertCount + _confirmationCertCount + _deathCertCount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildDataTableRow(String type, int count) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(type, style: const TextStyle(fontSize: 14)),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
