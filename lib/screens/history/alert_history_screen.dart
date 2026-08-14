import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/alert_model.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/offline_queue_service.dart';
import '../../widgets/alert_history_tile.dart';

/// Alert history screen showing all past SOS alerts with status and date filtering
class AlertHistoryScreen extends StatelessWidget {
  const AlertHistoryScreen({super.key});

  void _showFilterBottomSheet(BuildContext context) {
    final alertProvider = context.read<AlertProvider>();
    AlertStatusFilter tempStatus = alertProvider.statusFilter;
    AlertDateFilter tempDate = alertProvider.dateFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Handle bar ───────────────────────────
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Title & Reset Button ─────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Alerts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempStatus = AlertStatusFilter.all;
                            tempDate = AlertDateFilter.allTime;
                          });
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),

                  // ── Status Filter Section ────────────────
                  const Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AlertStatusFilter.values.map((status) {
                      final isSelected = tempStatus == status;
                      return ChoiceChip(
                        label: Text(status.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => tempStatus = status);
                          }
                        },
                        selectedColor: AppColors.primary.withAlpha(40),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // ── Date Range Section ───────────────────
                  const Text(
                    'DATE RANGE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AlertDateFilter.values.map((date) {
                      final isSelected = tempDate == date;
                      return ChoiceChip(
                        label: Text(date.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => tempDate = date);
                          }
                        },
                        selectedColor: AppColors.primary.withAlpha(40),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // ── Apply Button ─────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        alertProvider.setFilters(
                          status: tempStatus,
                          date: tempDate,
                        );
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final allAlerts = alertProvider.alerts;
    final filteredAlerts = alertProvider.filteredAlerts;
    final hasActiveFilter = alertProvider.hasActiveFilter;

    Future<void> handleRefresh() async {
      final user = context.read<AppAuthProvider>().user;
      if (user != null) {
        alertProvider.loadAlerts(user.uid);
        await OfflineQueueService.syncPendingAlerts(FirestoreService());
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.alertHistory),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                tooltip: 'Filter Alerts',
                onPressed: () => _showFilterBottomSheet(context),
              ),
              if (hasActiveFilter)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Quick Filter Horizontal Bar ────────────────────
          if (allAlerts.isNotEmpty)
            _QuickFilterBar(
              alertProvider: alertProvider,
              onOpenFilterModal: () => _showFilterBottomSheet(context),
            ),

          // ── List View / Empty States with Pull-to-Refresh ─
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Theme.of(context).cardColor,
              onRefresh: handleRefresh,
              child: allAlerts.isEmpty
                  ? _EmptyHistory()
                  : filteredAlerts.isEmpty
                      ? _FilteredEmptyHistory(
                          onClear: () => alertProvider.clearFilters(),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: false,
                          itemCount: filteredAlerts.length,
                          itemBuilder: (_, i) =>
                              AlertHistoryTile(alert: filteredAlerts[i]),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scrolling quick-filter bar
class _QuickFilterBar extends StatelessWidget {
  final AlertProvider alertProvider;
  final VoidCallback onOpenFilterModal;

  const _QuickFilterBar({
    required this.alertProvider,
    required this.onOpenFilterModal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All
          _FilterChipItem(
            label: 'All',
            isSelected: alertProvider.statusFilter == AlertStatusFilter.all &&
                alertProvider.dateFilter == AlertDateFilter.allTime,
            onTap: () => alertProvider.clearFilters(),
          ),
          const SizedBox(width: 8),
          // Success
          _FilterChipItem(
            label: 'Success',
            icon: Icons.check_circle_outline_rounded,
            isSelected:
                alertProvider.statusFilter == AlertStatusFilter.success,
            onTap: () {
              if (alertProvider.statusFilter == AlertStatusFilter.success) {
                alertProvider.setStatusFilter(AlertStatusFilter.all);
              } else {
                alertProvider.setStatusFilter(AlertStatusFilter.success);
              }
            },
          ),
          const SizedBox(width: 8),
          // Failed
          _FilterChipItem(
            label: 'Failed',
            icon: Icons.error_outline_rounded,
            isSelected: alertProvider.statusFilter == AlertStatusFilter.failed,
            onTap: () {
              if (alertProvider.statusFilter == AlertStatusFilter.failed) {
                alertProvider.setStatusFilter(AlertStatusFilter.all);
              } else {
                alertProvider.setStatusFilter(AlertStatusFilter.failed);
              }
            },
          ),
          const SizedBox(width: 8),
          // Today
          _FilterChipItem(
            label: 'Today',
            icon: Icons.today_rounded,
            isSelected: alertProvider.dateFilter == AlertDateFilter.today,
            onTap: () {
              if (alertProvider.dateFilter == AlertDateFilter.today) {
                alertProvider.setDateFilter(AlertDateFilter.allTime);
              } else {
                alertProvider.setDateFilter(AlertDateFilter.today);
              }
            },
          ),
          const SizedBox(width: 8),
          // This Week
          _FilterChipItem(
            label: 'This Week',
            icon: Icons.calendar_view_week_rounded,
            isSelected: alertProvider.dateFilter == AlertDateFilter.thisWeek,
            onTap: () {
              if (alertProvider.dateFilter == AlertDateFilter.thisWeek) {
                alertProvider.setDateFilter(AlertDateFilter.allTime);
              } else {
                alertProvider.setDateFilter(AlertDateFilter.thisWeek);
              }
            },
          ),
          const SizedBox(width: 8),
          // Custom / More Filter Chip
          ActionChip(
            avatar: Icon(
              Icons.tune_rounded,
              size: 16,
              color: alertProvider.hasActiveFilter
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            label: const Text('More'),
            onPressed: onOpenFilterModal,
            backgroundColor: Theme.of(context).cardColor,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: alertProvider.hasActiveFilter
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: alertProvider.hasActiveFilter
                    ? AppColors.primary
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: isSelected,
      avatar: icon != null
          ? Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            )
          : null,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withAlpha(35),
      checkmarkColor: AppColors.primary,
      backgroundColor: Theme.of(context).cardColor,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected
            ? AppColors.primary
            : Theme.of(context).colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).colorScheme.onSurface.withAlpha(30),
        ),
      ),
    );
  }
}

/// Empty state when no alerts match active filter
class _FilteredEmptyHistory extends StatelessWidget {
  final VoidCallback onClear;

  const _FilteredEmptyHistory({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.filter_alt_off_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'No Alerts Found',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No emergency alerts match the selected filter criteria.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset Filters'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state when no alerts exist in Firestore
class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.noHistory,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.noHistorySubtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
