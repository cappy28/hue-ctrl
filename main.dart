import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/app_theme.dart';
import 'services/hue_service.dart';
import 'screens/scan_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.bg,
  ));
  runApp(const HueCtrlApp());
}

class HueCtrlApp extends StatelessWidget {
  const HueCtrlApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HueService(),
      child: MaterialApp(
        title: 'HUE CTRL',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const ScanScreen(),
      ),
    );
  }
}
