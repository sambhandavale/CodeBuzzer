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
                            color: const Color(0xFF1CD065).withValues(alpha: 
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
                        color: const Color(0xFF1CD065).withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1CD065).withValues(alpha: 0.2),
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
                  color: const Color(0xFF1CD065).withValues(alpha: 0.8),
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
              // Actions (Swipe to action)
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: SwipeActionSlider(
                  onDismiss: () async {
                    if (contest != null) {
                      await provider.dismissAlarm(contest);
                    } else {
                      await Alarm.stop(widget.alarmSettings.id);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  onSnooze: () async {
                    if (contest != null) {
                      await provider.snoozeAlarm(contest);
                    } else {
                      final now = DateTime.now();
                      final snoozeTime = now.add(const Duration(minutes: 5));
                      final newSettings =
                          widget.alarmSettings.copyWith(dateTime: snoozeTime);
                      await Alarm.stop(widget.alarmSettings.id);
                      await Alarm.set(alarmSettings: newSettings);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SwipeActionSlider extends StatefulWidget {
  final VoidCallback onDismiss;
  final VoidCallback onSnooze;

  const SwipeActionSlider({
    super.key,
    required this.onDismiss,
    required this.onSnooze,
  });

  @override
  State<SwipeActionSlider> createState() => _SwipeActionSliderState();
}

class _SwipeActionSliderState extends State<SwipeActionSlider> {
  double _dragPosition = 0.0;
  final double _maxDrag = 110.0;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPosition += details.delta.dx;
      if (_dragPosition > _maxDrag) _dragPosition = _maxDrag;
      if (_dragPosition < -_maxDrag) _dragPosition = -_maxDrag;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragPosition > _maxDrag * 0.8) {
      widget.onSnooze();
    } else if (_dragPosition < -_maxDrag * 0.8) {
      widget.onDismiss();
    } else {
      setState(() {
        _dragPosition = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: widget.onDismiss,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, color: Colors.redAccent.withValues(alpha: 0.7), size: 24),
                      Text('Dismiss', style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onSnooze,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.snooze, color: Colors.amber.withValues(alpha: 0.7), size: 24),
                      Text('Snooze', style: TextStyle(color: Colors.amber.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Transform.translate(
            offset: Offset(_dragPosition, 0),
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF1CD065),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1CD065).withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.alarm, color: Colors.black87, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
