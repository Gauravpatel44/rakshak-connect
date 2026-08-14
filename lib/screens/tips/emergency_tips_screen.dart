import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';

/// Emergency tips screen — first aid, fire safety, and disaster guidance
class EmergencyTipsScreen extends StatelessWidget {
  const EmergencyTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.emergencyTips)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TipCategory(
            icon: Icons.medical_services_rounded,
            title: AppStrings.firstAid,
            color: AppColors.success,
            tips: const [
              '🩹 Call 108 immediately for any medical emergency.',
              '🫁 For unconscious person — check breathing, place in recovery position.',
              '🩸 Apply firm pressure on wounds to stop bleeding.',
              '🔥 For burns — cool with running water for 10 minutes.',
              '💊 Do NOT give food or water to unconscious person.',
              '🧠 For head injuries — keep still, avoid movement.',
              '🫀 Learn CPR — 30 chest compressions + 2 rescue breaths.',
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

          const SizedBox(height: 12),

          _TipCategory(
            icon: Icons.local_fire_department_rounded,
            title: AppStrings.fireSafety,
            color: AppColors.primary,
            tips: const [
              '🚪 Never use lifts during a fire — always use stairs.',
              '🚧 Stay low to avoid smoke — crawl if necessary.',
              '🔥 Never open a hot door — feel it first with the back of your hand.',
              '📞 Call 101 immediately on discovering fire.',
              '🧯 Use fire extinguisher: PASS — Pull, Aim, Squeeze, Sweep.',
              '🧱 Close doors behind you to slow fire spread.',
              '🏃 Escape first, then call for help — never go back for belongings.',
            ],
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

          const SizedBox(height: 12),

          _TipCategory(
            icon: Icons.crisis_alert_rounded,
            title: AppStrings.disasterGuidance,
            color: const Color(0xFF9C27B0),
            tips: const [
              '🌊 Earthquake: DROP, COVER, HOLD ON. Stay away from windows.',
              '🌪️ Flood: Move to higher ground immediately. Avoid floodwater.',
              '⛈️ Cyclone: Stay indoors, away from windows. Follow evacuation orders.',
              '🏔️ Landslide: Move away from the path. Call 1078.',
              '💧 Keep emergency kit: water, food, torch, first aid for 3 days.',
              '📱 Save emergency numbers: Police 112, Ambulance 108, NDRF 1078.',
              '🏠 Know your nearest evacuation shelter location.',
            ],
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

          const SizedBox(height: 24),

          // ── Important Numbers Card ──────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Emergency Numbers',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...[
                  ['Police', '112'],
                  ['Ambulance', '108'],
                  ['Fire Brigade', '101'],
                  ['Women Helpline', '1091'],
                  ['Child Helpline', '1098'],
                  ['Disaster Mgmt', '1078'],
                ].map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e[0],
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        Text(e[1],
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TipCategory extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<String> tips;

  const _TipCategory({
    required this.icon,
    required this.title,
    required this.color,
    required this.tips,
  });

  @override
  State<_TipCategory> createState() => _TipCategoryState();
}

class _TipCategoryState extends State<_TipCategory> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(widget.icon, color: widget.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // ── Tips List ─────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.tips
                    .map(
                      (tip) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          tip,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
