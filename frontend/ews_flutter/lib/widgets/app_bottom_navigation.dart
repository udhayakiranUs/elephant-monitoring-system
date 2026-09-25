import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text.dart';

class NavItem {
  final IconData icon;
  final String label;
  final int badge;
  const NavItem(this.icon, this.label, {this.badge = 0});
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.green,
        unselectedItemColor: AppColors.text3,
        selectedLabelStyle: AppText.heading(size: 12, weight: FontWeight.w600),
        unselectedLabelStyle: AppText.heading(size: 12, weight: FontWeight.w600),
        items: [
          for (final i in items)
            BottomNavigationBarItem(
              label: i.label,
              icon: Badge(
                isLabelVisible: i.badge > 0,
                backgroundColor: AppColors.red,
                label: Text('${i.badge}'),
                child: Icon(i.icon),
              ),
            ),
        ],
      ),
    );
  }
}
