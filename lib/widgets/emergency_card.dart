import 'package:flutter/material.dart';

/// Reusable home screen quick-action card.
/// Uses Material + Ink for hardware-accelerated ripple; no custom shadows.
class EmergencyCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const EmergencyCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // PhysicalModel uses hardware-accelerated elevation — cheaper than boxShadow
    return PhysicalModel(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      shadowColor: color.withAlpha(60),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Theme.of(context).cardColor,
          child: InkWell(
            onTap: onTap,
            splashColor: color.withAlpha(30),
            highlightColor: color.withAlpha(15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
