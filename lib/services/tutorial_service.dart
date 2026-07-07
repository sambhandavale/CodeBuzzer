import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static Future<bool> hasSeenHomeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seen_home_tutorial_v3') ?? false;
  }

  static Future<void> markHomeTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_home_tutorial_v3', true);
  }

  static Future<bool> hasSeenSettingsTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seen_settings_tutorial_v3') ?? false;
  }

  static Future<void> markSettingsTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_settings_tutorial_v3', true);
  }

  static Future<bool> hasSeenPopupTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seen_popup_tutorial_v3') ?? false;
  }

  static Future<void> markPopupTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_popup_tutorial_v3', true);
  }

  static void showPopupTutorial({
    required BuildContext context,
    required GlobalKey formKey,
  }) {
    List<TargetFocus> targets = [
      TargetFocus(
        identify: "TargetForm",
        keyTarget: formKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1CD065).withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Schedule Your Alarm",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        "Fill in the title, pick a date and time in the future, and hit SCHEDULE. We will wake you up right on time!",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF111214),
      textSkip: "GOT IT",
      paddingFocus: 10,
      opacityShadow: 0.9,
      onFinish: () {
        markPopupTutorialSeen();
      },
      onSkip: () {
        markPopupTutorialSeen();
        return true;
      },
    ).show(context: context);
  }

  static void showHomeTutorial({
    required BuildContext context,
    required GlobalKey headerKey,
    required GlobalKey calendarKey,
    required GlobalKey filterKey,
    required GlobalKey addNavKey,
    required GlobalKey settingsNavKey,
  }) {
    List<TargetFocus> targets = [
      TargetFocus(
        identify: "TargetHeader",
        keyTarget: headerKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1CD065).withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Welcome to CodeBuzzer!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        "Here you'll see the current date. Note that all times in this app are automatically shown in your local timezone.",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
      TargetFocus(
        identify: "TargetCalendar",
        keyTarget: calendarKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1CD065).withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Contest Calendar",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        "Swipe horizontally to select different dates. Dates with a small green dot indicate there is at least one contest scheduled.",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
      TargetFocus(
        identify: "TargetFilter",
        keyTarget: filterKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1CD065).withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Platform Filters",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        "Tap these chips to quickly filter the list below by platform. Tap 'All' to see everything.",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
      TargetFocus(
        identify: "TargetAddAlarm",
        keyTarget: addNavKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1CD065).withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Manual Reminders",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        "Tap here to create a custom alarm for any contest not listed, or just a personal reminder!",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
      TargetFocus(
        identify: "TargetSettings",
        keyTarget: settingsNavKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1CD065).withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Configure Platforms",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        "Tap here to go to Settings. You can completely disable platforms you don't use, so they never show up in your feed.",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF111214),
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.9,
      onFinish: () {
        markHomeTutorialSeen();
      },
      onClickTarget: (target) {
        // do nothing
      },
      onSkip: () {
        markHomeTutorialSeen();
        return true;
      },
    ).show(context: context);
  }

  static void showSettingsTutorial({
    required BuildContext context,
    required GlobalKey platformsKey,
  }) {
    List<TargetFocus> targets = [
      TargetFocus(
        identify: "TargetPlatforms",
        keyTarget: platformsKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1CD065).withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Active Platforms",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        "Turn off platforms you don't care about here. They will be hidden from the calendar and alarms won't be set for them.",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF111214),
      textSkip: "GOT IT",
      paddingFocus: 10,
      opacityShadow: 0.9,
      onFinish: () {
        markSettingsTutorialSeen();
      },
      onSkip: () {
        markSettingsTutorialSeen();
        return true;
      },
    ).show(context: context);
  }
}
