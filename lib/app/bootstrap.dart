import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/firebase/database_seeder.dart';
import '../firebase_options.dart';
import '../features/auth/screens/auth_gate.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? initializationError;
  StackTrace? initializationStackTrace;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Database seeding disabled - uncomment to enable mock data insertion
    // await DatabaseSeeder.seedDummyData();
  } catch (error, stackTrace) {
    initializationError = error;
    initializationStackTrace = stackTrace;
  }

  runApp(
    ProviderScope(
      child: ExamPrepMvpApp(
        initializationError: initializationError,
        initializationStackTrace: initializationStackTrace,
      ),
    ),
  );
}

class ExamPrepMvpApp extends StatelessWidget {
  const ExamPrepMvpApp({
    super.key,
    this.initializationError,
    this.initializationStackTrace,
  });

  final Object? initializationError;
  final StackTrace? initializationStackTrace;

  @override
  Widget build(BuildContext context) {
    if (initializationError != null) {
      return MaterialApp(
        title: 'Exam Prep MVP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: _StartupErrorScreen(
          error: initializationError!,
          stackTrace: initializationStackTrace,
        ),
      );
    }

    return MaterialApp(
      title: 'Exam Prep MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({
    required this.error,
    this.stackTrace,
  });

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Startup Error')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Firebase failed to initialize.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Most likely, Firebase platform options are not configured yet. '
                'For Flutter web, this is required before auth works.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Run these commands from project root:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SelectableText(
                  'dart pub global activate flutterfire_cli\n'
                  'flutterfire configure',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
              ),
              if (stackTrace != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Stack trace:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  '$stackTrace',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
