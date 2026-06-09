import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contest.dart';

class ApiService {
  static const String apiUrl = 'https://kontests.net/api/v1/all';
  static const String modificationsKey = 'contest_modifications';
  static const String manualAlarmsKey = 'manual_alarms';

  static Future<List<Contest>> fetchContests() async {
    List<Contest> allContests = [];

    // 1. Fetch from Codeforces API
    try {
      final cfContests = await _fetchCodeForces();
      allContests.addAll(cfContests);
    } catch (e) {
      print('CF Error: $e');
    }

    // 2. Manual LeetCode Generation (Hardcoded as requested)
    allContests.addAll(_generateManualLeetCodeContests());

    // 3. Manual CodeChef Generation
    allContests.addAll(_generateManualCodeChefContests());

    // 4. Load stored manual alarms
    try {
      final manualAlarms = await _loadManualAlarms();
      allContests.addAll(manualAlarms);
    } catch (e) {
      print('Manual Alarms Load Error: $e');
    }

    if (allContests.isEmpty) {
      throw Exception('Failed to load any contests or none upcoming.');
    }

    // 5. Apply local modifications (Dismissed/Snoozed status)
    allContests = await _applyModifications(allContests);

    // Sort globally by start time
    allContests.sort((a, b) => a.startTime.compareTo(b.startTime));
    return allContests;
  }

  static Future<void> saveModifications(Contest contest) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> mods = json.decode(prefs.getString(modificationsKey) ?? '{}');
    mods[contest.id] = {
      'is_alarm_active': contest.isAlarmActive,
      'snooze_count': contest.snoozeCount,
      'start_time': contest.startTime.toIso8601String(),
    };
    await prefs.setString(modificationsKey, json.encode(mods));
  }

  static Future<List<Contest>> _applyModifications(List<Contest> contests) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> mods = json.decode(prefs.getString(modificationsKey) ?? '{}');
    
    return contests.map((c) {
      if (mods.containsKey(c.id)) {
        final mod = mods[c.id];
        return c.copyWith(
          isAlarmActive: mod['is_alarm_active'],
          snoozeCount: mod['snooze_count'],
          startTime: DateTime.tryParse(mod['start_time'] ?? ''),
        );
      }
      return c;
    }).toList();
  }

  static Future<void> saveManualAlarm(Contest contest) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> stored = prefs.getStringList(manualAlarmsKey) ?? [];
    
    // Check if it already exists (updating)
    int index = -1;
    for (int i = 0; i < stored.length; i++) {
      final Map<String, dynamic> data = json.decode(stored[i]);
      if (data['id'] == contest.id) {
        index = i;
        break;
      }
    }

    if (index != -1) {
      stored[index] = json.encode(contest.toJson());
    } else {
      stored.add(json.encode(contest.toJson()));
    }
    
    await prefs.setStringList(manualAlarmsKey, stored);
  }

  static Future<void> deleteManualAlarm(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> stored = prefs.getStringList(manualAlarmsKey) ?? [];
    stored.removeWhere((s) => json.decode(s)['id'] == id);
    await prefs.setStringList(manualAlarmsKey, stored);
  }

  static Future<List<Contest>> _loadManualAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> stored = prefs.getStringList(manualAlarmsKey) ?? [];
    List<Contest> alarms = [];
    List<String> updatedStored = [];
    DateTime now = DateTime.now();

    for (String s in stored) {
      try {
        final Map<String, dynamic> data = json.decode(s);
        final contest = Contest.fromJson(data);
        
        // Keep alarms that haven't ended yet (or ended within the last 24h)
        if (contest.endTime.isAfter(now.subtract(const Duration(hours: 24)))) {
          alarms.add(contest);
          updatedStored.add(s);
        }
      } catch (e) {
        // Skip corrupted data
      }
    }

    // Clean up expired alarms in background
    if (updatedStored.length != stored.length) {
      await prefs.setStringList(manualAlarmsKey, updatedStored);
    }
    
    return alarms;
  }

  static Future<List<Contest>> _fetchCodeForces() async {
    final response = await http
        .get(Uri.parse('https://codeforces.com/api/contest.list'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        List<dynamic> results = data['result'];
        List<Contest> contests = [];

        for (var c in results) {
          if (c['phase'] == 'BEFORE') {
            final start = DateTime.fromMillisecondsSinceEpoch(
              c['startTimeSeconds'] * 1000,
            );
            contests.add(
              Contest(
                id: 'cf_${c['id']}',
                name: c['name'],
                url: 'https://codeforces.com/contests/${c['id']}',
                startTime: start,
                endTime: start.add(Duration(seconds: c['durationSeconds'])),
                duration: c['durationSeconds'].toString(),
                site: 'CodeForces',
                status: c['phase'],
              ),
            );
          }
        }
        return contests;
      }
    }
    throw Exception('CF Failed');
  }

  static Future<List<Contest>> _fetchLeetCode() async {
    final response = await http
        .post(
          Uri.parse('https://leetcode.com/graphql'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            "query": "{ allContests { title titleSlug startTime duration } }",
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> results = data['data']['allContests'];
      List<Contest> contests = [];

      for (var c in results) {
        final start = DateTime.fromMillisecondsSinceEpoch(c['startTime'] * 1000);
        // Only include upcoming contests
        if (start.isAfter(DateTime.now())) {
          contests.add(
            Contest(
              id: 'lc_${c['titleSlug']}',
              name: c['title'],
              url: 'https://leetcode.com/contest/${c['titleSlug']}',
              startTime: start,
              endTime: start.add(Duration(seconds: c['duration'])),
              duration: c['duration'].toString(),
              site: 'LeetCode',
              status: 'BEFORE',
            ),
          );
        }
      }
      return contests;
    }
    throw Exception('LC Failed');
  }

  static List<Contest> _generateManualLeetCodeContests() {
    List<Contest> contests = [];
    DateTime now = DateTime.now();
    // Anchor for Biweekly: June 6, 2026 at 8:00 PM
    DateTime biweeklyAnchor = DateTime(2026, 6, 6, 20, 0);
    
    for (int i = 0; i < 30; i++) {
      DateTime day = now.add(Duration(days: i));
      
      // Weekly Contest (Every Sunday 8:00 AM)
      if (day.weekday == DateTime.sunday) {
        DateTime contestStart = DateTime(day.year, day.month, day.day, 8, 0);
        if (contestStart.isAfter(now)) {
          contests.add(Contest(
            id: 'lc_weekly_${day.year}_${day.month}_${day.day}',
            name: "LeetCode Weekly Contest",
            url: "https://leetcode.com/contest/",
            startTime: contestStart,
            endTime: contestStart.add(const Duration(minutes: 90)),
            duration: "5400",
            site: "LeetCode",
            status: "BEFORE",
          ));
        }
      }

      // Biweekly Contest (Every other Saturday 8:00 PM)
      if (day.weekday == DateTime.saturday) {
        DateTime contestStart = DateTime(day.year, day.month, day.day, 20, 0);
        int daysDifference = contestStart.difference(biweeklyAnchor).inDays;
        
        if (daysDifference % 14 == 0) {
          if (contestStart.isAfter(now)) {
            contests.add(Contest(
              id: 'lc_biweekly_${day.year}_${day.month}_${day.day}',
              name: "LeetCode Biweekly Contest",
              url: "https://leetcode.com/contest/",
              startTime: contestStart,
              endTime: contestStart.add(const Duration(minutes: 90)),
              duration: "5400",
              site: "LeetCode",
              status: "BEFORE",
            ));
          }
        }
      }
    }
    return contests;
  }

  static List<Contest> _generateManualCodeChefContests() {
    List<Contest> contests = [];
    DateTime now = DateTime.now();
    
    // Find the next 4 Wednesdays
    for (int i = 0; i < 30; i++) {
      DateTime day = now.add(Duration(days: i));
      if (day.weekday == DateTime.wednesday) {
        // Wednesday at 8:00 PM IST (20:00 IST = 14:30 UTC)
        DateTime contestStart = DateTime(day.year, day.month, day.day, 20, 0);
        
        if (contestStart.isAfter(now)) {
          contests.add(Contest(
            id: 'cc_${day.year}_${day.month}_${day.day}', // Deterministic ID
            name: "CodeChef Weekly Contest",
            url: "https://www.codechef.com/contests",
            startTime: contestStart,
            endTime: contestStart.add(const Duration(hours: 3)),
            duration: "10800",
            site: "CodeChef",
            status: "BEFORE",
          ));
        }
        
        if (contests.length >= 4) break;
      }
    }
    return contests;
  }
}
