import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Screen displayed on first run if Firebase credentials are not yet configured.
/// Guides the developer on how to connect Firebase to Rakshak Connect.
class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Center(
                child: Icon(Icons.shield_rounded, color: Colors.white, size: 80),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Rakshak Connect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.settings_rounded,
                            color: AppColors.primary, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Firebase Setup Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    for (final step in const [
                      '1️⃣  Go to console.firebase.google.com',
                      '2️⃣  Create project → Add Android app',
                      '      Package: com.gaurav.rakshak_connect',
                      '3️⃣  Download google-services.json',
                      '4️⃣  Place it in: android/app/',
                      '5️⃣  Enable Email/Password Auth',
                      '6️⃣  Create Firestore Database',
                      '7️⃣  Update firebase_options.dart',
                      '8️⃣  Hot restart the app ✅',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          step,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF424242),
                            height: 1.4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'UI is fully built & ready!\nConnect Firebase to unlock all features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
