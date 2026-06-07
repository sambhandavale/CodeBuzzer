import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:provider/provider.dart';
import '../../providers/contest_provider.dart';
import '../../models/contest.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({super.key, required this.alarmSettings});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ContestProvider>();
    Contest? contest;
    try {
      contest = provider.contests
          .firstWhere((c) => c.alarmId == widget.alarmSettings.id);
    } catch (e) {
      // Fallback if not found
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E2125),
              Color(0xFF111214),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              // App Logo with Pulsing Ripple (WhatsApp style)
              Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        double waveValue = (_controller.value + index / 3) % 1;
                        return Container(
                          width: 120 + (waveValue * 150),
                          height: 120 + (waveValue * 150),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1CD065).withOpacity(
                              (1 - waveValue).clamp(0.0, 0.2),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  Container(
                    width: 130,
                    height: 130,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1E22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1CD065).withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1CD065).withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Text(
                'CODEBUZZER REMINDER',
                style: TextStyle(
                  color: const Color(0xFF1CD065).withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  widget.alarmSettings.notificationSettings.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Starting soon',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white54,
                ),
              ),
              const Spacer(),
              // Actions (WhatsApp style)
              Padding(
                padding: const EdgeInsets.only(bottom: 60, left: 40, right: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Stop / Decline Action
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCallButton(
                          icon: Icons.close,
                          color: Colors.redAccent,
                          onTap: () async {
                            if (contest != null) {
                              await provider.dismissAlarm(contest);
                            } else {
                              await Alarm.stop(widget.alarmSettings.id);
                            }
                            if (mounted) Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Dismiss',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    // Snooze / Accept Action
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCallButton(
                          icon: Icons.snooze,
                          color: Colors.amber,
                          onTap: () async {
                            if (contest != null) {
                              await provider.snoozeAlarm(contest);
                            } else {
                              final now = DateTime.now();
                              final snoozeTime =
                                  now.add(const Duration(minutes: 5));
                              final newSettings =
                                  widget.alarmSettings.copyWith(dateTime: snoozeTime);
                              await Alarm.stop(widget.alarmSettings.id);
                              await Alarm.set(alarmSettings: newSettings);
                            }
                            if (mounted) Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Snooze (5m)',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 35),
      ),
    );
  }
}
