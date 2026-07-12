import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static Future<bool> hasSeenHomeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seen_home_tutorial_v5') ?? false;
  }

  static Future<void> markHomeTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_home_tutorial_v5', true);
  }

  static Future<bool> hasSeenSettingsTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seen_settings_tutorial_v6') ?? false;
  }

  static Future<void> markSettingsTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_settings_tutorial_v6', true);
  }

  static Future<bool> hasSeenPopupTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seen_popup_tutorial_v4') ?? false;
  }

  static Future<void> markPopupTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_popup_tutorial_v4', true);
  }

  static Widget _buildGlassContainer({
    required BuildContext context,
    required TutorialCoachMarkController controller,
    required String title,
    required String description,
    String buttonText = "Next",
    VoidCallback? onNext,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111214).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1CD065).withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  description,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CD065),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (onNext != null) {
                      onNext();
                    } else {
                      controller.next();
                    }
                  },
                  child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showPopupTutorial({
    required BuildContext context,
    required GlobalKey formKey,
  }) {
    List<TargetFocus> targets = [
      TargetFocus(
        identify: "TargetForm",
        keyTarget: formKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildGlassContainer(
                context: context,
                controller: controller,
                title: "Schedule Your Alarm",
                description: "Fill in the title, pick a date and time in the future, and hit SCHEDULE. We will wake you up right on time!",
                buttonText: "Got It",
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
      opacityShadow: 0.8,
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
    VoidCallback? onFinish,
  }) {
    List<TargetFocus> targets = [
      TargetFocus(
        identify: "TargetHeader",
        keyTarget: headerKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildGlassContainer(
                context: context,
                controller: controller,
                title: "Welcome to CodeBuzzer!",
                description: "Here you'll see the current date. Note that all times in this app are automatically shown in your local timezone.",
              );
            },
          )
        ],
      ),
      TargetFocus(
        identify: "TargetCalendar",
        keyTarget: calendarKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildGlassContainer(
                context: context,
                controller: controller,
                title: "Contest Calendar",
                description: "Swipe horizontally to select different dates. Dates with a small green dot indicate there is at least one contest scheduled.",
              );
            },
          )
        ],
      ),
      TargetFocus(
        identify: "TargetFilter",
        keyTarget: filterKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildGlassContainer(
                context: context,
                controller: controller,
                title: "Platform Filters",
                description: "Tap these chips to quickly filter the list below by platform. Tap 'All' to see everything.",
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
              return _buildGlassContainer(
                context: context,
                controller: controller,
                title: "Manual Reminders",
                description: "Tap here to create a custom alarm for any contest not listed, or just a personal reminder!",
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
              return _buildGlassContainer(
                context: context,
                controller: controller,
                title: "Configure App Settings",
                description: "Tap here to go to Settings. You can disable reminders for contest platforms you don't use, and change your reminder alarm music!",
                buttonText: "Got It",
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
      opacityShadow: 0.8,
      onFinish: () {
        markHomeTutorialSeen();
        if (onFinish != null) onFinish();
      },
      onClickTarget: (target) {
        // do nothing
      },
      onSkip: () {
        markHomeTutorialSeen();
        if (onFinish != null) onFinish();
        return true;
      },
    ).show(context: context);
  }

  static void showSettingsTutorial({
    required BuildContext context,
    required GlobalKey platformsKey,
    required GlobalKey permissionsKey,
    required GlobalKey alarmSoundKey,
  }) {
    List<TargetFocus> targets = [
      TargetFocus(
        identify: "TargetPlatforms",
        keyTarget: platformsKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildGlassContainer(
                context: context,
                controller: controller,
                title: "Auto Alarms",
                description: "Toggle which platforms automatically schedule a 5-minute reminder. Tap the header above to expand/collapse this list!",
              );
            },
          )
        ],
      ),
      TargetFocus(
        identify: "TargetPermissions",
        keyTarget: permissionsKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildGlassContainer(
                context: context,
                controller: controller,
                title: "Permissions",
                description: "Ensure these are granted so your alarms fire accurately even when the app is completely closed.",
              );
            },
          )
        ],
      ),
      TargetFocus(
        identify: "TargetAlarmSound",
        keyTarget: alarmSoundKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildGlassContainer(
                context: context,
                controller: controller,
                title: "Custom Sound",
                description: "Pick your own loud MP3 or WAV file to make sure you never sleep through a contest again!",
                buttonText: "Got It",
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
      opacityShadow: 0.8,
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
