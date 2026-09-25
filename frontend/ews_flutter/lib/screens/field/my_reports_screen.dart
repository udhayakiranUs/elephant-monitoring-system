import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../models/report_model.dart';
import '../../services/api_service.dart';
import '../../widgets/report_card.dart';
import 'report_details_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  int _selectedTab = 0;

  List<ReportModel> _myReports = [];
  List<ReportModel> _allReports = [];

  bool _loading = true;

  final TextEditingController _searchController = TextEditingController();

  DateTime? _selectedDate;

  String _searchText = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyReports();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // LOAD MY REPORTS
  // ---------------------------------------------------------
  Future<void> _loadMyReports() async {
    final api = context.read<ApiService>();

    setState(() {
      _loading = true;
    });

    final data = await api.loadMyReports();

    if (!mounted) return;

    setState(() {
      _myReports = data;
      _loading = false;
    });
  }

  // ---------------------------------------------------------
  // LOAD ALL REPORTS
  // ---------------------------------------------------------
  Future<void> _loadAllReports() async {
    final api = context.read<ApiService>();

    setState(() {
      _loading = true;
    });

    await api.loadAll(force: true);

    if (!mounted) return;

    setState(() {
      _allReports = List<ReportModel>.from(
        api.reports,
      );

      _loading = false;
    });
  }

  // ---------------------------------------------------------
  // CHANGE TAB
  // ---------------------------------------------------------
  Future<void> _changeTab(int index) async {
    if (_selectedTab == index) return;

    setState(() {
      _selectedTab = index;
      _selectedDate = null;
      _searchController.clear();
    });

    if (index == 0) {
      await _loadMyReports();
    } else {
      await _loadAllReports();
    }
  }

  // ---------------------------------------------------------
  // REFRESH
  // ---------------------------------------------------------
  Future<void> _refresh() async {
    if (_selectedTab == 0) {
      await _loadMyReports();
    } else {
      await _loadAllReports();
    }
  }

  // ---------------------------------------------------------
  // SELECT DATE
  // ---------------------------------------------------------
  Future<void> _selectDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select report date',
      cancelText: 'Cancel',
      confirmText: 'Search',
    );

    if (!mounted || picked == null) return;

    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
    });
  }

  // ---------------------------------------------------------
  // CLEAR DATE
  // ---------------------------------------------------------
  void _clearDate() {
    setState(() {
      _selectedDate = null;
    });
  }

  // ---------------------------------------------------------
  // FILTER REPORTS
  // ---------------------------------------------------------
  List<ReportModel> _filteredReports(
    List<ReportModel> reports,
  ) {
    return reports.where((report) {
      // ---------------------------------------------
      // DATE FILTER
      // ---------------------------------------------
      if (_selectedDate != null) {
        final reportDate = report.dateTime;

        final sameDate = reportDate.year == _selectedDate!.year &&
            reportDate.month == _selectedDate!.month &&
            reportDate.day == _selectedDate!.day;

        if (!sameDate) {
          return false;
        }
      }

      // ---------------------------------------------
      // SEARCH FILTER
      // ---------------------------------------------
      if (_searchText.isEmpty) {
        return true;
      }

      final searchableText = [
        report.id,
        report.range,
        report.beat,
        report.officer,
        report.designation,
        report.locationDescription,
        report.remarks,
      ].join(' ').toLowerCase();

      return searchableText.contains(_searchText);
    }).toList();
  }

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final sourceReports = _selectedTab == 0 ? _myReports : _allReports;

    final reports = _filteredReports(
      sourceReports,
    );

    return Column(
      children: [
        // ---------------------------------------------------
        // TABS
        // ---------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            8,
          ),
          child: Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _tabButton(
                    title: 'My Reports',
                    selected: _selectedTab == 0,
                    onTap: () => _changeTab(0),
                  ),
                ),
                Expanded(
                  child: _tabButton(
                    title: 'All Reports',
                    selected: _selectedTab == 1,
                    onTap: () => _changeTab(1),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ---------------------------------------------------
        // SEARCH BOX
        // ---------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            8,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search reports...',
              prefixIcon: const Icon(
                Icons.search,
              ),
              suffixIcon: _searchText.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                      ),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.green,
                ),
              ),
            ),
          ),
        ),

        // ---------------------------------------------------
        // DATE SEARCH
        // ---------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            8,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(
                    Icons.calendar_month,
                  ),
                  label: Text(
                    _selectedDate == null
                        ? 'Select Report Date'
                        : _formatDate(
                            _selectedDate!,
                          ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green,
                    side: BorderSide(
                      color: AppColors.border,
                    ),
                    minimumSize: const Size(
                      0,
                      48,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ),
              if (_selectedDate != null) const SizedBox(width: 8),
              if (_selectedDate != null)
                IconButton(
                  tooltip: 'Clear date',
                  onPressed: _clearDate,
                  icon: const Icon(
                    Icons.clear,
                  ),
                  color: AppColors.text3,
                ),
            ],
          ),
        ),

        // ---------------------------------------------------
        // RESULT COUNT
        // ---------------------------------------------------
        if (!_loading)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              2,
              16,
              4,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${reports.length} report${reports.length == 1 ? '' : 's'} found',
                style: AppText.body(
                  size: 12,
                  color: AppColors.text3,
                ),
              ),
            ),
          ),

        // ---------------------------------------------------
        // REPORT LIST
        // ---------------------------------------------------
        Expanded(
          child: RefreshIndicator(
            color: AppColors.green,
            backgroundColor: AppColors.card,
            onRefresh: _refresh,
            child: _loading
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  )
                : reports.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(
                            height: 100,
                          ),
                          Center(
                            child: Icon(
                              Icons.search_off,
                              size: 48,
                              color: AppColors.text3,
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Center(
                            child: Text(
                              _selectedDate != null || _searchText.isNotEmpty
                                  ? 'No reports found'
                                  : _selectedTab == 0
                                      ? 'No reports yet'
                                      : 'No reports available',
                              style: AppText.body(
                                size: 13,
                                color: AppColors.text3,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          16,
                        ),
                        itemCount: reports.length,
                        itemBuilder: (context, i) {
                          final report = reports[i];

                          return ReportCard(
                            report: report,
                            onTap: () {
                              Navigator.of(
                                context,
                              ).push(
                                MaterialPageRoute(
                                  builder: (_) => ReportDetailsScreen(
                                    report: report,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // TAB BUTTON
  // ---------------------------------------------------------
  Widget _tabButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          title,
          style: AppText.body(
            size: 13,
            color: selected ? Colors.white : AppColors.text3,
          ).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // DATE FORMAT
  // ---------------------------------------------------------
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}
