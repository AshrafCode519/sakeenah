import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.getInstance();
  final isDark = storage.isDarkMode;

  runApp(SakeenahApp(initialIsDark: isDark));
}

class SakeenahApp extends StatefulWidget {
  final bool initialIsDark;

  const SakeenahApp({super.key, required this.initialIsDark});

  @override
  State<SakeenahApp> createState() => _SakeenahAppState();
}

class _SakeenahAppState extends State<SakeenahApp> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.initialIsDark;
  }

  void _updateTheme(bool isDark) {
    setState(() {
      _isDark = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سَكينة - القرآن الكريم والأذكار',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: HomeScreen(
          onThemeChanged: _updateTheme,
        ),
      ),
    );
  }
}
