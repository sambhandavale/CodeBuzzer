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

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _focusedMonth;
  late ScrollController _calendarScrollController;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _calendarScrollController = ScrollController();

    // Fetch data only if needed (Provider handles check)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContestProvider>().fetchContests();
      final provider = context.read<ContestProvider>();
      double offset = (provider.selectedDate.day - 3).clamp(0, 31) * 70.0;
      if (_calendarScrollController.hasClients) {
        _calendarScrollController.jumpTo(offset);
      }
    });
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
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
                _buildHeader(),
                const SizedBox(height: 24),
                _buildCalendar(contestProvider),
                const SizedBox(height: 16),
                _buildFilterChips(contestProvider),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
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

  Widget _buildCalendar(ContestProvider provider) {
    // Generate days for the focused month
    final lastDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    );

    List<DateTime> days = [];
    if (provider.selectedPlatformFilter != null) {
      final contestDates = provider.enabledContests
          .map((c) => DateTime(c.startTime.year, c.startTime.month, c.startTime.day))
          .toSet()
          .toList();
      contestDates.sort((a, b) => a.compareTo(b));
      days = contestDates;
    } else {
      days = List.generate(
        lastDayOfMonth.day,
        (index) => DateTime(_focusedMonth.year, _focusedMonth.month, index + 1),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    provider.selectedPlatformFilter != null
                        ? "${provider.selectedPlatformFilter} Timeline"
                        : DateFormat('MMMM yyyy').format(_focusedMonth),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_focusedMonth.year != DateTime.now().year ||
                      _focusedMonth.month != DateTime.now().month)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _focusedMonth = DateTime.now();
                          provider.setSelectedDate(DateTime.now());
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1CD065).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            color: Color(0xFF1CD065),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  _buildNavButton(
                    Icons.chevron_left,
                    () => setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month - 1,
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  _buildNavButton(
                    Icons.chevron_right,
                    () => setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month + 1,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: provider.selectedPlatformFilter != null ? 100 : 85,
          child: ListView.builder(
            controller: _calendarScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final date = days[index];
              final isSelected =
                  provider.selectedDate.day == date.day &&
                  provider.selectedDate.month == date.month &&
                  provider.selectedDate.year == date.year;

              final now = DateTime.now();
              final isToday = now.day == date.day &&
                  now.month == date.month &&
                  now.year == date.year;

              // Check if there are contests on this day
              final contestCount = provider.enabledContests
                  .where(
                    (c) =>
                        c.startTime.day == date.day &&
                        c.startTime.month == date.month &&
                        c.startTime.year == date.year,
                  )
                  .length;

              return GestureDetector(
                onTap: () {
                  provider.setSelectedDate(date);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 58,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1CD065).withOpacity(0.15)
                        : const Color(0xFF1C1E22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1CD065)
                          : (isToday ? const Color(0xFF1CD065).withOpacity(0.5) : Colors.white.withOpacity(0.05)),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1CD065).withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isSelected
                              ? const Color(0xFF1CD065)
                              : Colors.white38,
                        ),
                      ),
                      if (provider.selectedPlatformFilter != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM').format(date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isSelected
                                ? const Color(0xFF1CD065).withOpacity(0.7)
                                : Colors.white24,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected || isToday ? Colors.white : Colors.white70,
                        ),
                      ),
                      if (contestCount > 0 && !isSelected) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1CD065).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$contestCount',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1CD065),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1E22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _buildFilterChips(ContestProvider provider) {
    // We compute counts based on raw enabled sites, so they don't disappear when a filter is applied
    final rawVisible = provider.contests
        .where(
          (c) => provider.enabledSites.contains(c.site) || c.site == 'Manual',
        )
        .toList();

    int cfCount = rawVisible.where((c) => c.site == 'CodeForces').length;
    int lcCount = rawVisible.where((c) => c.site == 'LeetCode').length;
    int atCount = rawVisible.where((c) => c.site == 'AtCoder').length;
    int ccCount = rawVisible.where((c) => c.site == 'CodeChef').length;
    int manualCount = rawVisible.where((c) => c.site == 'Manual').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip('CodeForces', cfCount, provider),
            if (lcCount > 0 || provider.enabledSites.contains('LeetCode')) ...[
              const SizedBox(width: 8),
              _buildChip('LeetCode', lcCount, provider),
            ],
            if (ccCount > 0 || provider.enabledSites.contains('CodeChef')) ...[
              const SizedBox(width: 8),
              _buildChip('CodeChef', ccCount, provider),
            ],
            if (atCount > 0 || provider.enabledSites.contains('AtCoder')) ...[
              const SizedBox(width: 8),
              _buildChip('AtCoder', atCount, provider),
            ],
            const SizedBox(width: 8),
            _buildChip('Manual', manualCount, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, int count, ContestProvider provider) {
    final isSelected = provider.selectedPlatformFilter == label;
    return GestureDetector(
      onTap: () => provider.togglePlatformFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1CD065).withOpacity(0.2)
              : const Color(0xFF1C1E22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1CD065) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFF1CD065) : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1CD065)
                      : const Color(
                          0xFFBCA628,
                        ), // Golden accent from screenshot
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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

    final bool isActive = contest.isAlarmActive;

    return Opacity(
      opacity: isActive ? 1.0 : 0.6,
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
                    color: const Color(0xFF1CD065).withOpacity(0.1),
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
                                    ? const Color(0xFF1CD065).withOpacity(0.1)
                                    : Colors.white.withOpacity(0.05),
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
                                    Colors.redAccent.withOpacity(0.8),
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
                                  DateFormat('HH:mm').format(contest.startTime),
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
                                      ).withOpacity(0.15),
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
                                          ).withOpacity(0.1)
                                        : Colors.white.withOpacity(0.05),
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
          color: Colors.white.withOpacity(0.03),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
