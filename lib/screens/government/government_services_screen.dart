import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/government_service_model.dart';
import '../../widgets/government_service_card.dart';

/// Government emergency services directory screen
class GovernmentServicesScreen extends StatelessWidget {
  const GovernmentServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.governmentServices)),
      body: Column(
        children: [
          // ── Subtitle ─────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.govServicesSubtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  AppStrings.tapToCall,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ── Service Cards List ────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              itemCount: GovernmentServices.all.length,
              itemBuilder: (_, i) =>
                  GovernmentServiceCard(service: GovernmentServices.all[i]),
            ),
          ),
        ],
      ),
    );
  }
}
