import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/contest_provider.dart';

class ContestFilterChips extends StatelessWidget {
  const ContestFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContestProvider>();

    // We compute counts based on raw enabled sites, so they don't disappear when a filter is applied
    final rawVisible = provider.contests.toList();

    final allSites = rawVisible.map((c) => c.site).where((s) => s != 'Manual').toSet().toList();
    
    // Sort base sites to front, custom sites alphabetically
    final baseSites = ['CodeForces', 'LeetCode', 'CodeChef', 'AtCoder', 'CodingNinjas'];
    allSites.sort((a, b) {
      final aIsBase = baseSites.contains(a);
      final bIsBase = baseSites.contains(b);
      if (aIsBase && !bIsBase) return -1;
      if (!aIsBase && bIsBase) return 1;
      if (aIsBase && bIsBase) return baseSites.indexOf(a).compareTo(baseSites.indexOf(b));
      return a.compareTo(b);
    });

    int manualCount = rawVisible.where((c) => c.site == 'Manual').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var site in allSites) ...[
              _buildChip(site, rawVisible.where((c) => c.site == site).length, provider),
              const SizedBox(width: 8),
            ],
            _buildChip('Manual', manualCount, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, int count, ContestProvider provider) {
    final isSelected = provider.selectedPlatformFilter == label;
    return GestureDetector(
      onTap: () => provider.togglePlatformFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1CD065).withValues(alpha: 0.2)
              : const Color(0xFF1C1E22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1CD065) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFF1CD065) : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1CD065)
                      : const Color(
                          0xFFBCA628,
                        ), // Golden accent from screenshot
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
