import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/settings_store.dart';
import 'screens/home/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await SettingsStore.instance.load();

  runApp(const NumberlandiaApp());
}

class NumberlandiaApp extends StatelessWidget {
  const NumberlandiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Numberlandia',
      theme: buildNumberlandiaTheme(),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      // Cap the OS font scale: huge accessibility fonts are the single worst
      // real-device overflow trigger. Never shrink below 1.0; cap at 1.3.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler
                .clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3),
          ),
          child: child!,
        );
      },
    );
  }
}
