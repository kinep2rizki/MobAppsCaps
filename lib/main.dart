import 'package:flutter/material.dart';
import 'package:my_app/Services/NotificationService.dart';
import 'package:my_app/pages/HomePage.dart';
import 'package:my_app/pages/ProfilePages/PopupNotif.dart';
import 'package:my_app/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Ensure that plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Check login status
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn, navigatorKey: _rootNavigatorKey));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Login UI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Show HomePage if logged in, otherwise show LoginPage
      home: NotificationLaunchHandler(
        child: isLoggedIn ? const HomePage() : const LoginPage(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NotificationLaunchHandler extends StatefulWidget {
  final Widget child;

  const NotificationLaunchHandler({super.key, required this.child});

  @override
  State<NotificationLaunchHandler> createState() =>
      _NotificationLaunchHandlerState();
}

class _NotificationLaunchHandlerState extends State<NotificationLaunchHandler> {
  bool _initializationStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapNotifications());
  }

  Future<void> _bootstrapNotifications() async {
    if (_initializationStarted) {
      return;
    }

    _initializationStarted = true;

    try {
      await NotificationPopupManager.initialize(
        onNotificationTap: () async {
          final navigator = _rootNavigatorKey.currentState;
          if (navigator == null) {
            return;
          }

          navigator.push(
            MaterialPageRoute(builder: (_) => const PopupNotifPage()),
          );
        },
      );

      await NotificationPopupManager.handleLaunchNotificationTap();
    } catch (_) {
      _initializationStarted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
