import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:async';
import 'dart:math';

import '../../services/alarm_service.dart';
import '../../data/dsa_quotes.dart';
import '../../main.dart'; // for callbackDispatcher
import 'main_screen.dart';
import 'landing_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _currentQuote = "";
  String _displayedText = "";
  int _quoteCounter = 0;
  
  bool _isAppInitialized = false;
  bool _isQuoteFinishedTyping = false;
  bool _hasSeenLanding = false;

  Timer? _typingTimer;
  Timer? _gapTimer;

  @override
  void initState() {
    super.initState();
    _pickNextQuote();
    _startTyping();
    _initApp();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _gapTimer?.cancel();
    super.dispose();
  }

  void _pickNextQuote() {
    if (_quoteCounter == 0) {
      // First quote is the deterministic daily quote
      final now = DateTime.now();
      final dayOfYear = int.parse("${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}");
      final random = Random(dayOfYear);
      _currentQuote = DsaQuotes.quotes[random.nextInt(DsaQuotes.quotes.length)];
    } else {
      // Subsequent quotes are completely random if loading takes very long
      final random = Random();
      _currentQuote = DsaQuotes.quotes[random.nextInt(DsaQuotes.quotes.length)];
    }
    _quoteCounter++;
  }

  void _startTyping() {
    _displayedText = "";
    _isQuoteFinishedTyping = false;
    int charIndex = 0;
    
    // Typewriter effect speed: ~35ms per character
    _typingTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (charIndex < _currentQuote.length) {
        setState(() {
          _displayedText += _currentQuote[charIndex];
        });
        charIndex++;
      } else {
        timer.cancel();
        _onQuoteFinished();
      }
    });
  }

  void _onQuoteFinished() {
    _isQuoteFinishedTyping = true;
    
    // Always wait 3 seconds after a quote finishes typing so the user can read it.
    _gapTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      if (_isAppInitialized) {
        // If background init is done, navigate into the app
        _navigate();
      } else {
        // If background init is STILL running, show another quote
        _pickNextQuote();
        _startTyping();
      }
    });
  }

  Future<void> _initApp() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Failed to load .env file: $e");
    }

    try {
      Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      Workmanager().registerPeriodicTask(
        "contest_sync_task",
        "syncContests",
        frequency: const Duration(hours: 48),
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (e) {
      debugPrint("Failed to init Workmanager: $e");
    }

    try {
      await AlarmService.init();
    } catch (e) {
      debugPrint("Failed to init AlarmService: $e");
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _hasSeenLanding = prefs.getBool('has_seen_landing') ?? false;

    _isAppInitialized = true;
  }

  void _navigate() {
    _gapTimer?.cancel();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) =>
            _hasSeenLanding ? const MainScreen() : const LandingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111214),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // Logo
              Center(
                child: Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'CodeBuzzer',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1CD065),
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(flex: 2),
              
              // Loading Indicator
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Color(0xFF1CD065),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 40),

              // DSA Quote Container with Fixed Height to prevent jumping
              Container(
                height: 120,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1E22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2C2F36)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.lightbulb_outline, color: Color(0xFF1CD065), size: 16),
                        SizedBox(width: 8),
                        Text(
                          "DSA TIP OF THE DAY",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Color(0xFF1CD065),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      "$_displayedText${!_isQuoteFinishedTyping ? '|' : ''}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
