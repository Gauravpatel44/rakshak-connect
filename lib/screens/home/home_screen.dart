import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_strings.dart';
import '../../localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contact_provider.dart';
import '../../providers/alert_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/offline_queue_service.dart';
import '../../services/widget_service.dart';
import '../../widgets/sos_button.dart';
import '../../widgets/emergency_card.dart';
import '../contacts/contacts_screen.dart';
import '../government/government_services_screen.dart';
import '../history/alert_history_screen.dart';
import '../profile/profile_screen.dart';

/// Main home screen with SOS button, quick cards, and bottom navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Pages are const-constructed once; IndexedStack keeps them alive
  static const List<Widget> _pages = [
    _HomePage(),
    ContactsScreen(),
    GovernmentServicesScreen(),
    AlertHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load data once on home init — not on every build
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final auth = context.read<AppAuthProvider>();
    if (auth.user != null) {
      context.read<ContactProvider>().loadContacts(auth.user!.uid);
      context.read<AlertProvider>().loadAlerts(auth.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i != _currentIndex) setState(() => _currentIndex = i);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: l10n.t('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.contacts_rounded),
            label: l10n.t('contacts'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_hospital_rounded),
            label: l10n.t('govServices'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_rounded),
            label: l10n.t('history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: l10n.t('profile'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// Home Tab — heavily optimised for minimal rebuilds
// ══════════════════════════════════════════════════════════

class _HomePage extends StatelessWidget {
  const _HomePage();

  void _onSosTap(BuildContext context) {
    // Read providers without watching — avoids triggering rebuild on read
    final contacts = context.read<ContactProvider>().contacts;
    final auth = context.read<AppAuthProvider>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 8),
            Text(AppStrings.sosConfirmTitle),
          ],
        ),
        content: const Text(
          AppStrings.sosConfirmMessage,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.sosCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(
                AppRoutes.sosAlert,
                arguments: {
                  'userId': auth.user?.uid ?? '',
                  'userName': auth.user?.name ?? 'User',
                  'contacts': contacts,
                },
              );
            },
            child: const Text(AppStrings.sosConfirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Selector instead of watch — only rebuilds when isSending changes
    final isSending = context.select<AlertProvider, bool>((p) => p.isSending);
    // Only read the name — don't watch the entire auth provider
    final firstName = context.select<AppAuthProvider, String>(
      (p) => p.user?.name.split(' ').first ?? 'User',
    );

    Future<void> handleRefresh() async {
      final auth = context.read<AppAuthProvider>();
      final contactProvider = context.read<ContactProvider>();
      final alertProvider = context.read<AlertProvider>();
      if (auth.user != null) {
        final userId = auth.user!.uid;
        contactProvider.loadContacts(userId);
        alertProvider.loadAlerts(userId);
        await OfflineQueueService.syncPendingAlerts(FirestoreService());
        await WidgetService().updateWidgetData(contactCount: contactProvider.count);
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Theme.of(context).cardColor,
        onRefresh: handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
          // ── App Bar ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              // collapseMode: pin avoids parallax repaints
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $firstName 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          AppStrings.staySafe,
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ── SOS Button — already has RepaintBoundary inside ──
                SosButton(
                  onTap: () => _onSosTap(context),
                  isSending: isSending,
                ),

                // ── Panic Siren Quick Alarm Bar ───────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _PanicSirenBanner(
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.siren),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Quick Action Cards ──────────────────────────
                // No flutter_animate here — cards are static after first render
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _QuickCards(),
                ),

                const SizedBox(height: 24),

                // ── Government Services Teaser ──────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _GovServiceTeaser(
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.governmentServices),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}

// ── Static Quick Cards Grid — extracted to prevent rebuild ──────────────

class _QuickCards extends StatelessWidget {
  const _QuickCards();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        EmergencyCard(
          title: l10n.t('myContacts'),
          icon: Icons.contacts_rounded,
          color: const Color(0xFF9C27B0),
          // Bug #12 fix: actually navigate to contacts screen
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.contacts),
        ),
        EmergencyCard(
          title: l10n.t('liveLocation'),
          icon: Icons.location_on_rounded,
          color: const Color(0xFF4CAF50),
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.liveLocation),
        ),
        EmergencyCard(
          title: l10n.t('emergencyCall'),
          icon: Icons.phone_rounded,
          color: AppColors.accent,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.emergencyCall),
        ),
        EmergencyCard(
          title: l10n.t('alertHistory'),
          icon: Icons.history_rounded,
          color: const Color(0xFFFF9800),
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.alertHistory),
        ),
        EmergencyCard(
          title: l10n.t('fakeCall'),
          icon: Icons.phone_callback_rounded,
          color: const Color(0xFF00897B),
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.fakeCallSetup),
        ),
        EmergencyCard(
          title: l10n.t('safetyTips'),
          icon: Icons.lightbulb_outline_rounded,
          color: const Color(0xFFE91E63),
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.emergencyTips),
        ),
      ],
    );
  }
}

// ── Government Services Teaser — extracted to prevent rebuild ───────────

class _GovServiceTeaser extends StatelessWidget {
  final VoidCallback onTap;
  const _GovServiceTeaser({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.local_police_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.governmentServices,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Quick-access to important services',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Panic Siren Banner ──────────────────────────────────────────────────

class _PanicSirenBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PanicSirenBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE65100), Color(0xFFD84315)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE65100).withAlpha(80),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panic Siren & Strobe',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Loud audio alarm & flashing strobe light',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

