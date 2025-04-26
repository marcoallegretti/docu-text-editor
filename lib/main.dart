import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'screens/editor_screen.dart';
import 'screens/settings_screen.dart';
import 'models/document_model.dart';
import 'services/platform_service.dart';
import 'providers/theme_provider.dart';
import 'providers/auto_save_provider.dart';

import 'utils/web_context_menu.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable browser context menu for web platform
  WebContextMenuUtil.disableBrowserContextMenu();

  // Enable all orientations except portrait down for mobile
  // Desktop platforms are not affected by this setting
  if (!PlatformService.isDesktopPlatform()) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Set system overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AutoSaveProvider()),
      ],
      child: const TextEditorApp(),
    ),
  );
}

class TextEditorApp extends StatelessWidget {
  const TextEditorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Text Editor',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              themeProvider.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          initialRoute: '/editor',
          onGenerateRoute: (settings) {
            // Different transitions based on platform
            final isDesktop = PlatformService.isDesktopPlatform();

            switch (settings.name) {
              case '/editor':
                final args = settings.arguments as DocumentModel?;
                return _buildRoute(
                  settings,
                  EditorScreen(initialDocument: args),
                  isDesktop,
                );

              case '/settings':
                final args = settings.arguments as Map<String, dynamic>?;
                return _buildRoute(
                  settings,
                  SettingsScreen(arguments: args),
                  isDesktop,
                );

              default:
                return _buildRoute(
                  settings,
                  const EditorScreen(),
                  isDesktop,
                );
            }
          },
          builder: (context, child) {
            // Apply app-wide text scaling factor limitation
            final mediaQuery = MediaQuery.of(context);
            final constrainedTextScaleFactor =
                mediaQuery.textScaleFactor.clamp(0.9, 1.2);

            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(constrainedTextScaleFactor),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }

  // Helper method to create platform-specific route transitions
  PageRoute _buildRoute(RouteSettings settings, Widget page, bool isDesktop) {
    if (isDesktop) {
      // Desktop platforms use fade transition
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: AppTheme.shortAnimationDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    } else {
      // Mobile platforms use material page route with slide transition
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => page,
      );
    }
  }
}
