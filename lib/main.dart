import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/filters_provider.dart';
import 'providers/anonymity_provider.dart';
import 'screens/home_screen.dart';
import 'screens/add_contact_screen.dart';
import 'screens/contact_detail_screen.dart';
import 'screens/filters_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => FiltersProvider()),
        ChangeNotifierProvider(create: (_) => AnonymityProvider()),
      ],
      child: MaterialApp(
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
