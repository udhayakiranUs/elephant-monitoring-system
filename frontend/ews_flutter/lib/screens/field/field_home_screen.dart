import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/gps_service.dart';
import '../../services/sync_service.dart';

import '../profile/profile_screen.dart';
import '../command/live_map_screen.dart';
import 'my_reports_screen.dart';
import 'new_report_screen.dart';
import 'field_dashboard_screen.dart';

class FieldHomeScreen extends StatefulWidget {
  const FieldHomeScreen({super.key});

  @override
  State<FieldHomeScreen> createState() => _FieldHomeScreenState();
}

class _FieldHomeScreenState extends State<FieldHomeScreen> {
  int _index = 0;

  static const List<String> _titles = [
    '🏠 HOME',
    '📜 MY REPORTS',
    '➕ ADD REPORT',
    '🗺️ RANGE MAP',
    '👤 PROFILE',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<ApiService>().loadAll();
      context.read<GpsService>().refresh();
      context.read<SyncService>().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = context.select<ApiService, int>(
      (api) => api.pendingCount,
    );

    final auth = context.watch<AuthService>();
    final user = auth.user;

    final userName =
        user?.name.trim().isNotEmpty == true ? user!.name.trim() : 'User';

    final designation = user?.designation.trim().isNotEmpty == true
        ? user!.designation.trim()
        : 'Field Officer';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Phones use bottom navigation.
        // Tablets, desktop and web use the vertical sidebar.
        final bool isMobile = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: AppColors.bg,

          // ============================================================
          // TOP BAR
          // ============================================================

          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.text,
            toolbarHeight: 68,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Text(
                  _titles[_index],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  height: 22,
                  width: 1,
                  color: AppColors.border,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Early Warning System · ${AppText.divisionTitle}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.text2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              if (!isMobile)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _welcomeUser(
                    userName,
                    pending,
                  ),
                ),
              if (isMobile)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.green.withValues(alpha: 0.10),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.green,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),

          // ============================================================
          // MAIN BODY
          // ============================================================

          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ========================================================
              // DESKTOP / TABLET SIDEBAR
              // ========================================================

              if (!isMobile)
                _buildSidebar(
                  userName: userName,
                  designation: designation,
                  pending: pending,
                ),

              // ========================================================
              // CURRENT SCREEN
              // ========================================================

              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: const [
                    FieldDashboardScreen(),
                    MyReportsScreen(),
                    NewReportScreen(),
                    LiveMapScreen(),
                    ProfileScreen(
                      embedded: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ============================================================
          // MOBILE BOTTOM NAVIGATION
          // ============================================================

          bottomNavigationBar: isMobile ? _buildBottomNavigation() : null,
        );
      },
    );
  }

  // ==================================================================
  // WELCOME USER
  // ==================================================================

  Widget _welcomeUser(
    String userName,
    int pending,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Welcome, $userName',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        if (pending > 0) ...[
          const SizedBox(width: 14),
          Chip(
            backgroundColor: AppColors.amber.withValues(alpha: 0.10),
            side: const BorderSide(
              color: AppColors.amber,
            ),
            label: Text(
              '$pending queued',
              style: const TextStyle(
                color: AppColors.amber2,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(width: 4),
      ],
    );
  }

  // ==================================================================
  // SIDEBAR
  // ==================================================================

  Widget _buildSidebar({
    required String userName,
    required String designation,
    required int pending,
  }) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Column(
        children: [
          // ------------------------------------------------------------
          // USER INFORMATION
          // ------------------------------------------------------------

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              18,
              22,
              18,
              18,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        designation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------------------
          // NAVIGATION ITEMS
          // ------------------------------------------------------------

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              children: [
                _sideItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  title: 'Home',
                ),
                _sideItem(
                  index: 1,
                  icon: Icons.history,
                  selectedIcon: Icons.history,
                  title: 'Reports',
                ),
                _sideItem(
                  index: 2,
                  icon: Icons.add_circle_outline,
                  selectedIcon: Icons.add_circle,
                  title: 'Add Report',
                ),
                _sideItem(
                  index: 3,
                  icon: Icons.map_outlined,
                  selectedIcon: Icons.map,
                  title: 'Map',
                ),
                _sideItem(
                  index: 4,
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  title: 'Profile',
                ),
              ],
            ),
          ),

          // ------------------------------------------------------------
          // QUEUED REPORT STATUS
          // ------------------------------------------------------------

          if (pending > 0)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sync_problem_outlined,
                    size: 18,
                    color: AppColors.amber2,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$pending report${pending == 1 ? '' : 's'} queued',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.amber2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              4,
              18,
              16,
            ),
            child: Text(
              'Early Warning System',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.text3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // SIDEBAR ITEM
  // ==================================================================

  Widget _sideItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
  }) {
    final bool selected = _index == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _index = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 48,
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.green.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: selected
                  ? Border.all(
                      color: AppColors.green.withValues(alpha: 0.18),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 21,
                  color: selected ? AppColors.green : AppColors.text2,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.green : AppColors.text,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================================================================
  // MOBILE BOTTOM NAVIGATION
  // ==================================================================

  Widget _buildBottomNavigation() {
    final items = [
      (
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        title: 'Home',
      ),
      (
        icon: Icons.history,
        selectedIcon: Icons.history,
        title: 'Reports',
      ),
      (
        icon: Icons.add_circle_outline,
        selectedIcon: Icons.add_circle,
        title: 'Add Report',
      ),
      (
        icon: Icons.map_outlined,
        selectedIcon: Icons.map,
        title: 'Map',
      ),
      (
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        title: 'Profile',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _mobileNavItem(
                    index: i,
                    icon: items[i].icon,
                    selectedIcon: items[i].selectedIcon,
                    title: items[i].title,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================================
  // MOBILE NAVIGATION ITEM
  // ==================================================================

  Widget _mobileNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
  }) {
    final bool selected = _index == index;

    return InkWell(
      onTap: () {
        setState(() {
          _index = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(
          horizontal: 3,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              size: 21,
              color: selected ? AppColors.green : AppColors.text2,
            ),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.green : AppColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
