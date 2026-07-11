import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'services/alarm_service.dart';
import 'services/api_service.dart';
import 'ui/screens/landing_screen.dart';
import 'ui/screens/main_screen.dart';
import 'ui/screens/alarm_ring_screen.dart';
import 'providers/contest_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: ".env");
      await AlarmService.init();

      final contests = await ApiService.fetchContests();
      final prefs = await SharedPreferences.getInstance();

      List<String> disabledSites = prefs.getStringList('disabled_sites') ?? [];

      final now = DateTime.now();
      final scheduleLimit = now.add(const Duration(days: 5));

      for (var contest in contests) {
        if (contest.site == 'Manual') continue;

        bool isDisabled = disabledSites.contains(contest.site);
        bool isUpcoming =
            contest.startTime.isAfter(now) &&
            contest.startTime.isBefore(scheduleLimit);

        if (!isDisabled && contest.isAlarmActive && isUpcoming) {
          try {
            await AlarmService.scheduleContestAlarm(contest);
          } catch (e) {
            // Ignore alarm scheduling errors in background sync
          }
        } else if (isDisabled || contest.startTime.isAfter(scheduleLimit)) {
          try {
            await AlarmService.stopAlarm(contest.alarmId);
          } catch (e) {
            // Ignore
          }
        }
      }
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher Error: $error');
    return true;
  };

  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  Workmanager().registerPeriodicTask(
    "contest_sync_task",
    "syncContests",
    frequency: const Duration(hours: 48),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  // Set system UI style for immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF111214),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await AlarmService.init();

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenLanding = prefs.getBool('has_seen_landing') ?? false;

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ContestProvider())],
      child: MyApp(hasSeenLanding: hasSeenLanding),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool hasSeenLanding;
  const MyApp({super.key, required this.hasSeenLanding});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Listen for alarm ring events to navigate to the ring screen
    Alarm.ringStream.stream.listen((alarmSettings) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => AlarmRingScreen(alarmSettings: alarmSettings),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodeBuzzer',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111214),
        fontFamily: 'GoogleSans',
        primaryColor: const Color(0xFF1CD065),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1CD065),
          primary: const Color(0xFF1CD065),
          onPrimary: Colors.black,
          surface: const Color(0xFF1C1E22),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: widget.hasSeenLanding ? const MainScreen() : const LandingScreen(),
    );
  }
}
