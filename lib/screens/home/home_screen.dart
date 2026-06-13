import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/num_block.dart';
import '../../widgets/settings_sheet.dart';
import '../add_up/add_up_screen.dart';
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
                  // Mascot cluster — a few number characters waving hello
                  if (width >= 500) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: Gap.md, top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (int i = 1; i <= 4; i++)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: BouncyNumBlock(
                                  value: i, unit: 14, showSign: false),
                            ),
                        ],
                      ),
                    ),
                  ],
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
            // Compute the child aspect ratio so all rows fit the available
            // height with no scrolling, on both phone (2 col) and tablet (3 col).
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                child: LayoutBuilder(
                  builder: (context, c) {
                    const spacing = Gap.md;
                    final rows = (5 / cols).ceil();
                    final cellW = (c.maxWidth - (cols - 1) * spacing) / cols;
                    final cellH =
                        (c.maxHeight - (rows - 1) * spacing) / rows;
                    final aspect =
                        (cellW / cellH).clamp(0.7, 1.6).toDouble();
                    return GridView.count(
                      crossAxisCount: cols,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: aspect,
                      children: [
                    ActivityCard(
                      title: 'Build a Million',
                      assetImage: 'assets/cards/million.png',
                      color: NColors.million,
                      live: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const BuildAMillionScreen())),
                    ),
                    ActivityCard(
                      title: 'Number Line',
                      assetImage: 'assets/cards/numberline.png',
                      color: NColors.numberLine,
                      live: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const NumberLineScreen())),
                    ),
                    ActivityCard(
                      title: 'Times Tables',
                      assetImage: 'assets/cards/timestables.png',
                      color: NColors.timesTables,
                      live: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const TimesTablesScreen())),
                    ),
                    ActivityCard(
                      title: 'Numberblocks',
                      assetImage: 'assets/cards/machine.png',
                      color: NColors.machine,
                      live: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const NumberMachineScreen())),
                    ),
                    ActivityCard(
                      title: 'Doubling',
                      assetImage: 'assets/cards/doubling.png',
                      color: NColors.doubling,
                      live: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const DoublingScreen())),
                    ),
                    ActivityCard(
                      title: 'Add Up',
                      assetImage: 'assets/cards/addup.png',
                      color: NColors.addUp,
                      live: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const AddUpScreen())),
                    ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: Gap.md),
          ],
        ),
      ),
    );
  }
}
