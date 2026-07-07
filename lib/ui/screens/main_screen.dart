import 'package:codebuzzer/providers/contest_provider.dart';
import 'package:codebuzzer/services/alarm_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import '../widgets/add_alarm_popup.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

final GlobalKey settingsNavKey = GlobalKey();
final GlobalKey addNavKey = GlobalKey();

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _permissionsGranted = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await AlarmService.checkAllPermissions();
    setState(() {
      _permissionsGranted = granted;
    });
  }

  final List<Widget> _pages = [const HomeScreen(), const SettingsScreen()];

  void _showAddAlarmPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddAlarmPopup(),
    ).then((value) {
      if (value == true) {
        // If alarm was scheduled, refresh the list immediately
        Provider.of<ContestProvider>(
          context,
          listen: false,
        ).fetchContests(force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111214), // Dark base
      extendBody: true, // Allows body to extend behind the floating navbar
      body: Stack(
        children: [
          _pages[_currentIndex],

          // Custom Floating Navbar
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF444444),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavIcon(0, Icons.home_filled, isAction: false),
                    const SizedBox(width: 8),
                    _buildNavIcon(1, Icons.add, isAction: true),
                    const SizedBox(width: 8),
                    _buildNavIcon(2, Icons.person_outline, isAction: false),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon, {required bool isAction}) {
    // Mapping UI index to Page index
    // UI: 0 (Home), 1 (Add), 2 (Settings)
    // Page: 0 (Home), 1 (Settings)
    int pageIndex = index == 2 ? 1 : 0;
    final isSelected = !isAction && _currentIndex == pageIndex;
    final iconColor = isSelected ? const Color(0xFF1CD065) : Colors.white;

    return GestureDetector(
      key: index == 1 ? addNavKey : (index == 2 ? settingsNavKey : null),
      onTap: () {
        if (isAction) {
          _showAddAlarmPopup(context);
        } else {
          setState(() {
            _currentIndex = pageIndex;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 26),
      ),
    );
  }
}
