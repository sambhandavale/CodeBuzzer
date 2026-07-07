import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contest.dart';
import '../services/api_service.dart';
import '../services/alarm_service.dart';

class ContestProvider extends ChangeNotifier {
  List<Contest> _contests = [];
  bool _isLoading = false;
  String _error = '';
  DateTime _selectedDate = DateTime.now();
  List<String> _disabledSites = [];
  String? _selectedPlatformFilter;

  List<Contest> get contests => _contests;
  bool get isLoading => _isLoading;
  String get error => _error;
  DateTime get selectedDate => _selectedDate;
  List<String> get disabledSites => _disabledSites;
  String? get selectedPlatformFilter => _selectedPlatformFilter;

  List<Contest> get enabledContests {
    var raw = _contests.toList();

    if (_selectedPlatformFilter != null) {
      raw = raw.where((c) => c.site == _selectedPlatformFilter).toList();
    }
    return raw;
  }

  List<Contest> get filteredContests {
    return enabledContests.where((c) {
      return c.startTime.year == _selectedDate.year &&
          c.startTime.month == _selectedDate.month &&
          c.startTime.day == _selectedDate.day;
    }).toList();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void togglePlatformFilter(String platform) {
    if (_selectedPlatformFilter == platform) {
      _selectedPlatformFilter = null; // Toggle off
    } else {
      _selectedPlatformFilter = platform; // Toggle on
      
      // Auto-snap to the next available contest for this platform
      final platContests = _contests.where((c) => c.site == platform).toList();
      platContests.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (platContests.isNotEmpty) {
        try {
          final now = DateTime.now();
          final next = platContests.firstWhere((c) =>
              c.startTime.year > now.year ||
              (c.startTime.year == now.year && c.startTime.month > now.month) ||
              (c.startTime.year == now.year && c.startTime.month == now.month && c.startTime.day >= now.day)
          );
          _selectedDate = next.startTime;
        } catch (e) {
          _selectedDate = platContests.last.startTime;
        }
      }
    }
    notifyListeners();
  }

  Future<void> fetchContests({bool force = false}) async {
    // Only fetch if we don't have data, or if a manual refresh is requested.
    if (_contests.isNotEmpty && !force) return;

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _disabledSites = prefs.getStringList('disabled_sites') ?? [];

      final fetchedContests = await ApiService.fetchContests();
      _contests = fetchedContests;

      // Smart Date Snapping logic
      var now = DateTime.now();
      final visible = enabledContests;

      bool todayHasContest = visible.any(
        (c) =>
            c.startTime.year == now.year &&
            c.startTime.month == now.month &&
            c.startTime.day == now.day,
      );

      if (!todayHasContest && visible.isNotEmpty) {
        final nextContest = visible.firstWhere(
          (c) => c.startTime.isAfter(now),
          orElse: () => visible.first,
        );
        _selectedDate = nextContest.startTime;
      }

      _scheduleAutomatedAlarms(_contests);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _scheduleAutomatedAlarms(List<Contest> contests) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> disabledSites = prefs.getStringList('disabled_sites') ?? [];

    for (var contest in contests) {
      if (!disabledSites.contains(contest.site)) {
        try {
          if (contest.isAlarmActive) {
            await AlarmService.scheduleContestAlarm(contest);
          }
        } catch (e) {
          // ignore individual alarm errors
        }
      }
    }
  }

  Future<void> dismissAlarm(Contest contest) async {
    // 1. Stop the technical alarm
    await AlarmService.stopAlarm(contest.alarmId);

    // 2. Update state
    final index = _contests.indexWhere((c) => c.id == contest.id);
    if (index != -1) {
      final updatedContest = _contests[index].copyWith(isAlarmActive: false);
      _contests[index] = updatedContest;

      // 3. Persist
      await ApiService.saveModifications(updatedContest);
      notifyListeners();
    }
  }

  Future<void> toggleAlarm(Contest contest) async {
    final index = _contests.indexWhere((c) => c.id == contest.id);
    if (index != -1) {
      final oldContest = _contests[index];
      final newIsActive = !oldContest.isAlarmActive;
      final updatedContest = oldContest.copyWith(isAlarmActive: newIsActive);
      _contests[index] = updatedContest;

      try {
        if (newIsActive) {
          if (updatedContest.site == 'Manual') {
            await AlarmService.scheduleCustomAlarm(updatedContest);
          } else {
            await AlarmService.scheduleContestAlarm(updatedContest);
          }
        } else {
          await AlarmService.stopAlarm(updatedContest.alarmId);
        }

        await ApiService.saveModifications(updatedContest);
        notifyListeners();
      } catch (e) {
        // Revert UI state on failure
        _contests[index] = oldContest;
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> snoozeAlarm(Contest contest) async {
    // 1. Stop current ringing
    await AlarmService.stopAlarm(contest.alarmId);

    // 2. Update state (add 5 mins)
    final index = _contests.indexWhere((c) => c.id == contest.id);
    if (index != -1) {
      final oldContest = _contests[index];
      final newTime = DateTime.now().add(const Duration(minutes: 5));
      final updatedContest = oldContest.copyWith(
        startTime: newTime,
        snoozeCount: oldContest.snoozeCount + 1,
        isAlarmActive: true,
      );
      _contests[index] = updatedContest;

      // 3. Persist
      await ApiService.saveModifications(updatedContest);

      // 4. Reschedule
      if (updatedContest.site == 'Manual') {
        await AlarmService.scheduleCustomAlarm(updatedContest);
      } else {
        await AlarmService.scheduleContestAlarm(updatedContest);
      }

      notifyListeners();
    }
  }

  Future<void> rescheduleAllAlarms() async {
    // This force-updates all alarms by calling set again with the current shared preferences sound
    await _scheduleAutomatedAlarms(_contests);
    notifyListeners();
  }

  Future<void> updateDisabledSitesAndAlarms(List<String> newSites) async {
    _disabledSites = newSites;
    // cancel alarms for disabled sites and re-schedule for enabled
    for (var contest in _contests) {
      if (contest.site != 'Manual') {
        if (newSites.contains(contest.site)) {
          await AlarmService.stopAlarm(contest.alarmId);
        } else if (contest.isAlarmActive) {
          await AlarmService.scheduleContestAlarm(contest);
        }
      }
    }
    notifyListeners();
  }
}
