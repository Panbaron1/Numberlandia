// Overflow guard: build every screen in cramped viewports at the maximum
// clamped text scale (1.3) and assert no RenderFlex/RenderBox overflow.
// In debug, an overflow throws a FlutterError during layout, which
// tester.takeException() surfaces — so any fixed-pixel layout that can't
// scale/wrap/scroll fails this test deterministically, on any "device".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:numberlandia/screens/home/home_screen.dart';
import 'package:numberlandia/screens/add_up/add_up_screen.dart';
import 'package:numberlandia/screens/take_away/take_away_screen.dart';
import 'package:numberlandia/screens/number_machine/number_machine_screen.dart';
import 'package:numberlandia/screens/number_line/number_line_screen.dart';
import 'package:numberlandia/screens/doubling/doubling_screen.dart';
import 'package:numberlandia/screens/times_tables/times_tables_screen.dart';
import 'package:numberlandia/screens/build_a_million/build_a_million_screen.dart';
import 'package:numberlandia/screens/clock/clock_screen.dart';
import 'package:numberlandia/screens/pop/pop_screen.dart';

// The worst real-device shapes: tiny-narrow portrait, short landscape, small square.
const _viewports = <Size>[
  Size(320, 640),
  Size(360, 800),
  Size(640, 360),
  Size(300, 300),
];

final _screens = <String, Widget Function()>{
  'Home': () => const HomeScreen(),
  'Add Up': () => const AddUpScreen(),
  'Take Away': () => const TakeAwayScreen(),
  'Numberblocks': () => const NumberMachineScreen(),
  'Number Line': () => const NumberLineScreen(),
  'Doubling': () => const DoublingScreen(),
  'Times Tables': () => const TimesTablesScreen(),
  'Build a Million': () => const BuildAMillionScreen(),
  'Clock': () => const ClockScreen(),
  'Pop': () => const PopScreen(),
};

Future<void> _pumpAt(WidgetTester tester, Size size, Widget screen) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      // Mirror the app's max clamped text scale (worst case after the clamp).
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
      home: screen,
    ),
  );
  // Don't settle (Clock runs a periodic Timer); a couple of pumps is enough
  // for layout to run and any overflow to throw.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  for (final entry in _screens.entries) {
    for (final size in _viewports) {
      testWidgets('${entry.key} does not overflow at ${size.width.toInt()}x'
          '${size.height.toInt()} @1.3x', (tester) async {
        await _pumpAt(tester, size, entry.value());
        expect(tester.takeException(), isNull,
            reason: '${entry.key} overflowed at $size');
        // Tear down any State (e.g. Clock's timer) before the test ends.
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
