import '../widgets/contest_card.dart';
import '../widgets/horizontal_calendar.dart';
import '../widgets/contest_filter_chips.dart';
import 'package:codebuzzer/services/alarm_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../providers/contest_provider.dart';
import '../../models/contest.dart';
import '../../services/api_service.dart';
import '../widgets/add_alarm_popup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _permissionsGranted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();

    // Fetch data only if needed (Provider handles check)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContestProvider>().fetchContests();
      final provider = context.read<ContestProvider>();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final granted = await AlarmService.checkAllPermissions();
    if (mounted) {
      setState(() {
        _permissionsGranted = granted;
      });
    }
  }

  Future<void> _editContest(BuildContext context, Contest contest) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAlarmPopup(initialContest: contest),
    );
    if (result == true) {
      if (mounted) {
        context.read<ContestProvider>().fetchContests(force: true);
      }
    }
  }

  Future<void> _addCustomAlarmWithDate(
    BuildContext context,
    DateTime selectedDate,
  ) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAlarmPopup(initialDate: selectedDate),
    );
    if (result == true) {
      if (mounted) {
        context.read<ContestProvider>().fetchContests(force: true);
      }
    }
  }

  Future<void> _deleteContest(BuildContext context, Contest contest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1E22),
        title: const Text(
          'Delete Reminder',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this reminder?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: Color(0xFF1CD065)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AlarmService.stopAlarm(contest.alarmId);
      await ApiService.deleteManualAlarm(contest.id);
      if (mounted) {
        context.read<ContestProvider>().fetchContests(force: true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contestProvider = context.watch<ContestProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF111214),
      body: Stack(
        children: [
          // Background blobs for glassmorphism
          Positioned(
            top: -50,
            right: -50,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: 150,
                  height: 150,
                  color: const Color(0xFF1CD065).withOpacity(0.3),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_permissionsGranted)
                  GestureDetector(
                    onTap: () async {
                      await AlarmService.requestAllPermissions();
                      _checkPermissions();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 24, right: 24, top: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Permissions missing! Tap to grant.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                _buildHeader(),
                const SizedBox(height: 24),
                const HorizontalCalendar(),
                const SizedBox(height: 16),
                const ContestFilterChips(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Contests',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (!contestProvider.selectedDate.isBefore(
                        DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        ),
                      ))
                        GestureDetector(
                          onTap: () => _addCustomAlarmWithDate(
                            context,
                            contestProvider.selectedDate,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1CD065).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.add_alarm,
                                  size: 14,
                                  color: Color(0xFF1CD065),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Add Alarm',
                                  style: const TextStyle(
                                    color: Color(0xFF1CD065),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${contestProvider.filteredContests.length} Upcoming',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: contestProvider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1CD065),
                          ),
                        )
                      : contestProvider.error.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                contestProvider.error,
                                style: const TextStyle(color: Colors.redAccent),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => contestProvider.fetchContests(force: true),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1CD065).withOpacity(0.2),
                                  foregroundColor: const Color(0xFF1CD065),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF1CD065),
                          backgroundColor: const Color(0xFF1C1E22),
                          onRefresh: () =>
                              contestProvider.fetchContests(force: true),
                          child: contestProvider.filteredContests.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(top: 100),
                                  children: [
                                    Center(
                                      child: Text(
                                        'No contests on this date',
                                        style: TextStyle(
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(
                                    left: 24, right: 24, bottom: 120,
                                  ),
                                  itemCount:
                                      contestProvider.filteredContests.length,
                                  itemBuilder: (context, index) {
                                    final contest =
                                        contestProvider.filteredContests[index];
                                    return ContestCard(
                                      contest: contest,
                                      isPrimary: true,
                                      onEdit: () =>
                                          _editContest(context, contest),
                                      onDelete: () =>
                                          _deleteContest(context, contest),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String getOrdinal(int day) {
      if (day >= 11 && day <= 13) return 'th';
      switch (day % 10) {
        case 1:
          return 'st';
        case 2:
          return 'nd';
        case 3:
          return 'rd';
        default:
          return 'th';
      }
    }

    final now = DateTime.now();
    final formattedDate =
        "${DateFormat('EEEE, MMMM d').format(now)}${getOrdinal(now.day)}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/logo.png', fit: BoxFit.contain, width: 40),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'CodeBuzzer',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1CD065),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white54,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Search and Notif removed per request
        ],
      ),
    );
  }

}

