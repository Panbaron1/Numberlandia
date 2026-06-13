import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/settings_sheet.dart';
import '../build_a_million/build_a_million_screen.dart';
import '../number_line/number_line_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cols = gridColumns(width);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Numberlandia',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: NColors.ink,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Gap.md),
            child: IconButton(
              iconSize: 28,
              icon: const Icon(Icons.tune_rounded, color: NColors.inkSoft),
              tooltip: 'Settings',
              onPressed: () => showSettingsSheet(context),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, Gap.md),
          child: GridView.count(
            crossAxisCount: cols,
            mainAxisSpacing: Gap.md,
            crossAxisSpacing: Gap.md,
            childAspectRatio: 0.85,
            children: [
              ActivityCard(
                title: 'Build a Million',
                emoji: '🏗️',
                color: NColors.million,
                live: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BuildAMillionScreen()),
                ),
              ),
              ActivityCard(
                title: 'Number Line',
                emoji: '📏',
                color: NColors.numberLine,
                live: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NumberLineScreen()),
                ),
              ),
              const ActivityCard(
                title: 'Times Tables',
                emoji: '✖️',
                color: NColors.timesTables,
                live: false,
              ),
              const ActivityCard(
                title: 'Number Machine',
                emoji: '⚙️',
                color: NColors.machine,
                live: false,
              ),
              const ActivityCard(
                title: 'Doubling',
                emoji: '✌️',
                color: NColors.doubling,
                live: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
