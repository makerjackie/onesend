import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/transfer_store.dart';

const Color oneSendInk = Color(0xff10130f);
const Color oneSendLime = Color(0xffd9f866);
const Color oneSendPaper = Color(0xfff5f6f0);
const Color oneSendMuted = Color(0xff737970);

class OneSendApp extends StatelessWidget {
  const OneSendApp({required this.store, super.key});

  final TransferStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: oneSendLime,
      brightness: Brightness.light,
      surface: oneSendPaper,
      primary: oneSendInk,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OneSend · 一传',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: oneSendPaper,
        appBarTheme: const AppBarTheme(
          backgroundColor: oneSendPaper,
          foregroundColor: oneSendInk,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: oneSendInk,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 54),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: oneSendInk,
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            side: const BorderSide(color: Color(0xffd9ddd3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xffe2e5de)),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: oneSendInk,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
          titleLarge: TextStyle(
            color: oneSendInk,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleMedium: TextStyle(
            color: oneSendInk,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: oneSendInk, height: 1.45),
          bodyMedium: TextStyle(color: oneSendMuted, height: 1.45),
        ),
      ),
      home: HomeScreen(store: store),
    );
  }
}
