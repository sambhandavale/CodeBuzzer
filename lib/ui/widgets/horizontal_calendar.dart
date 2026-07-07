import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/contest_provider.dart';

class HorizontalCalendar extends StatefulWidget {
  const HorizontalCalendar({super.key});

  @override
  State<HorizontalCalendar> createState() => _HorizontalCalendarState();
}

class _HorizontalCalendarState extends State<HorizontalCalendar> {
  DateTime _focusedMonth = DateTime.now();
  final ScrollController _calendarScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContestProvider>();
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
                            "$contestCount",
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
}
