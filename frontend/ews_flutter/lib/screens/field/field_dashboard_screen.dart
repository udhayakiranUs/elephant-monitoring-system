import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';

class FieldDashboardScreen extends StatelessWidget {
  const FieldDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================================
              // WELCOME
              // =====================================================

              const Text(
                'Welcome, Field Staff',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Elephant Warning System',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text2,
                ),
              ),

              const SizedBox(height: 18),

              // =====================================================
              // ELEPHANT / FOREST IMAGE CARD
              // =====================================================

              Container(
                width: double.infinity,
                height: 210,
                decoration: BoxDecoration(
                  color: AppColors.green3,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.green3,
                              AppColors.green2,
                              AppColors.green,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      bottom: 15,
                      child: Icon(
                        Icons.forest,
                        size: 105,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    const Positioned(
                      left: 22,
                      top: 24,
                      child: Icon(
                        Icons.pets,
                        size: 58,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      left: 22,
                      bottom: 25,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ELEPHANT MONITORING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            AppText.divisionTitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // =====================================================
              // QUICK STATUS
              // =====================================================

              const Text(
                'Today\'s Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),

              const SizedBox(height: 12),

              const Row(
                children: [
                  Expanded(
                    child: _StatusCard(
                      icon: Icons.pets,
                      title: 'Elephants',
                      value: '12',
                      color: AppColors.green,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatusCard(
                      icon: Icons.warning_amber_rounded,
                      title: 'Active Alerts',
                      value: '03',
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const Row(
                children: [
                  Expanded(
                    child: _StatusCard(
                      icon: Icons.location_on_outlined,
                      title: 'Reports',
                      value: '08',
                      color: AppColors.blue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatusCard(
                      icon: Icons.check_circle_outline,
                      title: 'Resolved',
                      value: '05',
                      color: AppColors.green2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // =====================================================
              // QUICK ACTIONS
              // =====================================================

              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),

              const SizedBox(height: 12),

              const _ActionCard(
                icon: Icons.warning_amber_rounded,
                title: 'Raise Alert',
                subtitle: 'Report an immediate elephant sighting',
                color: AppColors.red,
              ),

              const SizedBox(height: 10),

              const _ActionCard(
                icon: Icons.edit_note,
                title: 'Create Report',
                subtitle: 'Submit a detailed field report',
                color: AppColors.green,
              ),

              const SizedBox(height: 10),

              const _ActionCard(
                icon: Icons.map_outlined,
                title: 'View Range Map',
                subtitle: 'Check elephant locations and ranges',
                color: AppColors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// STATUS CARD
// ===============================================================

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.text2,
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// ACTION CARD
// ===============================================================

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.text2,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.text3,
          ),
        ],
      ),
    );
  }
}
