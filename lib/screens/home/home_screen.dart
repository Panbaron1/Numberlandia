import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/num_block.dart';
import '../../widgets/settings_sheet.dart';
import '../build_a_million/build_a_million_screen.dart';
import '../number_line/number_line_screen.dart';
import '../times_tables/times_tables_screen.dart';
import '../number_machine/number_machine_screen.dart';
import '../doubling/doubling_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cols = gridColumns(width);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.md, Gap.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: NColors.brandGradient,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: const Text(
                            'Numberlandia',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white, // masked by shader
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Explore numbers',
                          style: TextStyle(
                            fontSize: 14,
                            color: NColors.inkSoft,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    iconSize: 26,
                    icon: const Icon(Icons.tune_rounded, color: NColors.inkSoft),
                    tooltip: 'Settings',
                    onPressed: () => showSettingsSheet(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.sm),
            // ── Grid ─────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                child: GridView.count(
                  crossAxisCount: cols,
                  mainAxisSpacing: Gap.md,
                  crossAxisSpacing: Gap.md,
                  childAspectRatio: 0.8,
                  children: [
                    ActivityCard(
                      title: 'Build a Million',
                      emoji: '🏗️',
                      color: NColors.million,
                      live: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const BuildAMillionScreen())),
                    ),
                    ActivityCard(
                      title: 'Number Line',
                      emoji: '📏',
                      color: NColors.numberLine,
                      live: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const NumberLineScreen())),
                    ),
                    ActivityCard(
                      title: 'Times Tables',
                      emoji: '✖️',
                      color: NColors.timesTables,
                      live: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const TimesTablesScreen())),
                    ),
                    ActivityCard(
                      title: 'Number Machine',
                      emoji: '⚙️',
                      color: NColors.machine,
                      live: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const NumberMachineScreen())),
                    ),
                    ActivityCard(
                      title: 'Doubling',
                      emoji: '✌️',
                      color: NColors.doubling,
                      live: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const DoublingScreen())),
                    ),
                  ],
                ),
              ),
            ),
            // ── Buddies band — a shelf of number characters ──────────
            const _BuddiesBand(),
          ],
        ),
      ),
    );
  }
}

/// A friendly row of NumBlock characters standing on a shelf at the bottom
/// of the home screen. Purely decorative — gives the app its mascots.
class _BuddiesBand extends StatelessWidget {
  const _BuddiesBand();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            NColors.bg,
            NColors.million.withAlpha(16),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Shelf line
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: Gap.lg),
              decoration: BoxDecoration(
                color: NColors.inkSoft.withAlpha(40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Characters 1..5 standing on the shelf
          Padding(
            padding: const EdgeInsets.only(bottom: 17),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 1; i <= 5; i++)
                  BouncyNumBlock(value: i, unit: 11, showSign: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
