import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/filters_provider.dart';
import 'providers/anonymity_provider.dart';
import 'providers/events_provider.dart';
import 'providers/weekly_summary_provider.dart';
import 'screens/home_screen.dart';
import 'screens/add_contact_screen.dart';
import 'screens/contact_detail_screen.dart';
import 'screens/filters_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/share_receiver_screen.dart';
import 'screens/events_screen.dart';
import 'screens/add_event_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/edit_event_screen.dart';
import 'screens/weekly_summary_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static const platform = MethodChannel('com.example.calllog/share');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForSharedText();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForSharedText();
    }
  }

  Future<void> _checkForSharedText() async {
    try {
      final String? sharedText = await platform.invokeMethod('getSharedText');
      if (sharedText != null && sharedText.isNotEmpty) {
        _handleSharedText(sharedText);
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du texte partagé: $e');
    }
  }

  void _handleSharedText(String text) {
    // Navigation vers l'écran de sélection de contact
    Future.delayed(const Duration(milliseconds: 500), () {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ShareReceiverScreen(sharedText: text),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => FiltersProvider()),
        ChangeNotifierProvider(create: (_) => AnonymityProvider()),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
        ChangeNotifierProvider(create: (_) => WeeklySummaryProvider()),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'CallLog',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Localisation française
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'),
        ],
        locale: const Locale('fr', 'FR'),
        // Routes
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              );

            case '/add-contact':
              return MaterialPageRoute(
                builder: (_) => const AddContactScreen(),
              );

            case '/contact-detail':
              final contactId = settings.arguments as int;
              return MaterialPageRoute(
                builder: (_) => ContactDetailScreen(contactId: contactId),
              );

            case '/filters':
              return MaterialPageRoute(
                builder: (_) => const FiltersScreen(),
              );

            case '/settings':
              return MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              );

            case '/events':
              return MaterialPageRoute(
                builder: (_) => const EventsScreen(),
              );

            case '/add-event':
              return MaterialPageRoute(
                builder: (_) => const AddEventScreen(),
              );

            case '/event-detail':
              final eventId = settings.arguments as int;
              return MaterialPageRoute(
                builder: (_) => EventDetailScreen(eventId: eventId),
              );

            case '/edit-event':
              final eventId = settings.arguments as int;
              return MaterialPageRoute(
                builder: (_) => EditEventScreen(eventId: eventId),
              );

            case '/weekly-summary':
              return MaterialPageRoute(
                builder: (_) => const WeeklySummaryScreen(),
              );

            default:
              return MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              );
          }
        },
      ),
    );
  }
}
