import 'package:flutter/material.dart';
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
      await AlarmService.init();

      final contests = await ApiService.fetchContests();
      final prefs = await SharedPreferences.getInstance();
      
      List<String> enabledSites =
          prefs.getStringList('enabled_sites') ??
          ['CodeForces', 'LeetCode', 'CodeChef', 'AtCoder', 'CodingNinjas', 'Manual'];

      for (var contest in contests) {
        if (enabledSites.contains(contest.site)) {
          if (contest.isAlarmActive) {
            await AlarmService.scheduleContestAlarm(contest);
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

  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  Workmanager().registerPeriodicTask(
    "contest_sync_task",
    "syncContests",
    frequency: const Duration(hours: 48),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
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
      title: 'CP Reminders',
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
