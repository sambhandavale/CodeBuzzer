import 'package:codebuzzer/providers/contest_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey _platformsKey = GlobalKey();
  bool _tutorialShown = false;
  List<String> _disabledSites = [];
  String? _customAlarmPath;
  String? _customAlarmName;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _disabledSites = prefs.getStringList('disabled_sites') ?? [];
      _customAlarmPath = prefs.getString('custom_alarm_path');
      _customAlarmName = prefs.getString('custom_alarm_name');

      // Fallback: If we have path but no name, derive it
      if (_customAlarmPath != null && _customAlarmName == null) {
        _customAlarmName = _customAlarmPath!.split(Platform.pathSeparator).last;
      }
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('disabled_sites', _disabledSites);

    if (mounted) {
      context.read<ContestProvider>().updateDisabledSitesAndAlarms(_disabledSites);
    }
  }

  Future<void> _pickAlarmSound() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final directory = await getApplicationDocumentsDirectory();
      final newPath =
          '${directory.path}/alarm_sound${file.path.substring(file.path.lastIndexOf('.'))}';

      // Save locally to avoid temp path issues
      await file.copy(newPath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_alarm_path', newPath);
      await prefs.setString('custom_alarm_name', result.files.single.name);

      setState(() {
        _customAlarmPath = newPath;
        _customAlarmName = result.files.single.name;
      });

      // KEY: Immediately reschedule all currently active alarms with the new sound
      if (mounted) {
        context.read<ContestProvider>().rescheduleAllAlarms();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alarm sound updated for all reminders!'),
          ),
        );
      }
    }
  }

  Future<void> _resetAlarmSound() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_alarm_path');
    setState(() {
      _customAlarmPath = null;
      _customAlarmName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final contestProvider = context.watch<ContestProvider>();
    final basePlatforms = ['CodeForces', 'LeetCode', 'CodeChef', 'AtCoder', 'CodingNinjas'];
    final allPlatforms = (basePlatforms + contestProvider.contests.map((c) => c.site).toList())
        .toSet()
        .where((s) => s != 'Manual')
        .toList();
    allPlatforms.sort();
    return Scaffold(
      backgroundColor: const Color(0xFF111214),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -50,
            left: -50,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: 150,
                  height: 150,
                  color: const Color(0xFF1CD065).withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 20.0,
                    ),
                    child: Row(
                      children: [
                        /* IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                        ), */
                        // Hidden because this is accessed via BottomNavBar now
                        const SizedBox(width: 8),
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'AUTO ALARMS',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Choose which platforms automatically trigger an alarm 5 minutes before the contest starts.',
                      style: TextStyle(fontSize: 14, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    key: _platformsKey,
                    child: Column(
                      children: [
                        for (final site in allPlatforms)
                          _buildToggle(
                            site, 
                            !_disabledSites.contains(site), 
                            (val) {
                              setState(() {
                                if (val) {
                                  _disabledSites.remove(site);
                                } else {
                                  _disabledSites.add(site);
                                }
                              });
                              _savePrefs();
                            }
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'ALARM PERMISSIONS',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'For 100% reliability even when the app is closed, please ensure all permissions are granted.',
                      style: TextStyle(fontSize: 14, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        _buildPermissionButton(
                          'EXACT ALARM',
                          Icons.timer,
                          () async {
                            final status =
                                await Permission.scheduleExactAlarm.status;
                            if (status.isDenied) {
                              await Permission.scheduleExactAlarm.request();
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    status.isGranted
                                        ? 'Granted!'
                                        : 'Requested or already active.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildPermissionButton(
                          'NOTIFICATIONS',
                          Icons.notifications,
                          () async {
                            final status = await Permission.notification.status;
                            if (status.isDenied) {
                              await Permission.notification.request();
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    status.isGranted
                                        ? 'Granted!'
                                        : 'Requested or already active.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1CD065).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1CD065).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color(0xFF1CD065),
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'TIP: Set "Battery Usage" to "Unrestricted" in App Info for best results.',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF1CD065),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'ALARM SOUND',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Customize the sound that wakes you up. Currently using: ${_customAlarmName ?? "Default (alarm.wav)"}',
                      style: TextStyle(fontSize: 14, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickAlarmSound,
                            icon: Icon(Icons.audiotrack, size: 18),
                            label: Text('CHOOSE FILE'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1CD065),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        if (_customAlarmPath != null) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: _resetAlarmSound,
                            icon: Icon(Icons.refresh, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white10,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 120,
                  ), // Final spacing for floating navbar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionButton(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(
    String title,
    bool value,
    Function(bool) onChanged, {
    bool isComingSoon = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isComingSoon ? Colors.white10 : const Color(0xFF2C2F36),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isComingSoon ? Colors.white38 : Colors.white,
                  ),
                ),
                if (isComingSoon)
                  Text(
                    'COMING SOON',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1CD065),
                      letterSpacing: 1.2,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: isComingSoon ? false : value,
            activeThumbColor: Colors.black,
            activeTrackColor: const Color(0xFF1CD065),
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
            onChanged: isComingSoon ? null : onChanged,
          ),
        ],
      ),
    );
  }
}
