import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/contest.dart';
import '../../providers/contest_provider.dart';

class ContestCard extends StatelessWidget {
  final Contest contest;
  final bool isPrimary;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ContestCard({
    super.key,
    required this.contest,
    this.isPrimary = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    bool isManual = contest.site == 'Manual';
    final provider = context.watch<ContestProvider>();
    final bool isPlatformDisabled = provider.disabledSites.contains(contest.site);

    final bool isActive =
        contest.isAlarmActive && !isPlatformDisabled && contest.startTime.isAfter(DateTime.now());

    final now = DateTime.now();
    final bool isPast = contest.endTime.isBefore(now);
    final bool isOngoing = contest.startTime.isBefore(now) && contest.endTime.isAfter(now);
    final semanticLabel = '${contest.name} on ${contest.site}. '
        'Starts ${DateFormat('MMM d, h:mm a').format(contest.startTime)}. '
        '${isPast ? "Ended" : isOngoing ? "Ongoing" : "Upcoming"}. '
        'Alarm is ${contest.isAlarmActive ? "active" : "inactive"}. '
        'Double tap to toggle alarm.';

    return Semantics(
      label: semanticLabel,
      button: true,
      onTapHint: 'View details',
      child: Opacity(
        opacity: isActive ? 1.0 : 0.6,
        child: GestureDetector(
          onTap: () {
            _showContestInfoSheet(context, context.read<ContestProvider>());
          },
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1E22),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isActive
                  ? (isPrimary
                        ? const Color(0xFF1CD065)
                        : const Color(0xFF2C2F36))
                  : Colors.white10,
              width: isPrimary && isActive ? 2 : 1,
            ),
            boxShadow: isPrimary && isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF1CD065).withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Accent Bar for Platform
                  Container(
                    width: 6,
                    color: isActive
                        ? (isPrimary
                              ? const Color(0xFF1CD065)
                              : _getPlatformColor(contest.site))
                        : Colors.white12,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isPrimary
                                      ? const Color(0xFF1CD065).withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  contest.site.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                    color: isPrimary
                                        ? const Color(0xFF1CD065)
                                        : Colors.white54,
                                  ),
                                ),
                              ),
                              if (isManual)
                                Row(
                                  children: [
                                    _buildActionIcon(
                                      Icons.edit_outlined,
                                      onEdit,
                                      Colors.white38,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildActionIcon(
                                      Icons.delete_outline,
                                      onDelete,
                                      Colors.redAccent.withValues(alpha: 0.8),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            contest.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          if (contest.description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              contest.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_filled,
                                    size: 16,
                                    color: Color(0xFF1CD065),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat(
                                      'HH:mm',
                                    ).format(contest.startTime),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat(
                                      'MMM dd',
                                    ).format(contest.startTime),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  if (contest.snoozeCount > 0) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFBCA628,
                                        ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        'SNOOZED (+${contest.snoozeCount * 5}M)',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFBCA628),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(
                                              0xFF1CD065,
                                            ).withValues(alpha: 0.1)
                                          : Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isActive
                                              ? Icons.notifications_active
                                              : Icons.notifications_off,
                                          size: 12,
                                          color: isActive
                                              ? const Color(0xFF1CD065)
                                              : Colors.white38,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isActive ? 'ACTIVE' : 'DISMISSED',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: isActive
                                                ? const Color(0xFF1CD065)
                                                : Colors.white38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }

  void _showContestInfoSheet(BuildContext context, ContestProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1E22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final bool isPlatformDisabled = provider.disabledSites.contains(contest.site);
        // Need to re-evaluate isActive inside the builder to ensure it's fresh
        final bool isActive =
            contest.isAlarmActive && !isPlatformDisabled && contest.startTime.isAfter(DateTime.now());

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      contest.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getPlatformColor(contest.site).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      contest.site.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: _getPlatformColor(contest.site),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoRow(
                Icons.calendar_today,
                'Start Time',
                DateFormat(
                  'MMM dd, yyyy - HH:mm',
                ).format(contest.startTime.toLocal()),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.timer,
                'Duration',
                '${int.tryParse(contest.duration) != null ? (int.parse(contest.duration) ~/ 60) : 'Unknown'} minutes',
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.link, 'URL', contest.url),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? Colors.white10
                        : const Color(0xFF1CD065),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    if (isPlatformDisabled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Enable ${contest.site} in Settings to set alarms.')),
                      );
                      Navigator.pop(context);
                      return;
                    }
                    
                    try {
                      await provider.toggleAlarm(contest);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (e.toString().contains('AlarmPermissionException')) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1C1E22),
                              title: const Text('Permission Required'),
                              content: const Text(
                                  'Exact alarm permission is required. Please enable it in Settings.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel',
                                      style: TextStyle(color: Colors.white70)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    openAppSettings();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Open Settings',
                                      style: TextStyle(color: Color(0xFF1CD065))),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text(
                    isActive ? 'DEACTIVATE ALARM' : 'ACTIVATE ALARM',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isActive ? Colors.white : Colors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              if (contest.site == 'Manual') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onEdit != null)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            onEdit!();
                          },
                          child: const Text(
                            'EDIT',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    if (onEdit != null && onDelete != null)
                      const SizedBox(width: 12),
                    if (onDelete != null)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: Colors.redAccent.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete!();
                          },
                          child: const Text(
                            'DELETE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.redAccent,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.white38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white38,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPlatformColor(String site) {
    switch (site.toLowerCase()) {
      case 'codeforces':
        return const Color(0xFF3182CE);
      case 'leetcode':
        return const Color(0xFFED8936);
      case 'codechef':
        return const Color(0xFF975A16);
      case 'codingninjas':
        return const Color(0xFFF15A24);
      default:
        return const Color(0xFF1CD065);
    }
  }

  Widget _buildActionIcon(IconData icon, VoidCallback? onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
