import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/core/theme/app_text_theme.dart';
import 'package:nepal_care/models/provider_prrofile.dart';
import 'package:nepal_care/repositories/user_repository.dart';
import 'package:nepal_care/screens/dashboard/provider_detail_screen.dart';
import 'package:nepal_care/screens/dashboard/provider_list_screen.dart';
import 'package:nepal_care/screens/bookings/my_bookings_screen.dart';
import 'package:nepal_care/screens/chat/message_list_screen.dart';
import 'package:nepal_care/screens/profile/profile_screen.dart';
import 'package:nepal_care/core/enum/user_role.dart';
import 'package:nepal_care/widgets/booking_request_dialog.dart';

/// Customer home screen. Only providers verified in Firestore are displayed. ihiwhbihwr
class UserDashboard extends StatefulWidget {
  const UserDashboard({
    super.key,
    this.userName = 'Aarav',
    this.locationLabel = 'Kathmandu, Ward 10',
    this.repository,
  });

  final String userName;
  final String locationLabel;
  final UserRepository? repository;

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  late final UserRepository _repository = widget.repository ?? UserRepository();
  final _searchController = TextEditingController();
  String _query = '';
  int _selectedCategory = 0;
  int _selectedNavIndex = 0;

  static const _categories = <_Category>[
    _Category('All', Icons.apps_rounded, Color(0xFFE1F1FB)),
    _Category('Baby Care', Icons.child_care_outlined, Color(0xFFFFD9DA)),
    _Category('Adult Care', Icons.volunteer_activism_outlined, Color(0xFFFFE7A8)),
    _Category('Senior Care', Icons.elderly_outlined, Color(0xFFFFE1A9)),
    _Category('Pet Care', Icons.pets_outlined, Color(0xFFD9D7E8)),
    _Category('Housekeeping', Icons.home_outlined, Color(0xFFDFF0DF)),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilters(ProviderProfile profile) {
    final selectedLabel = _categories[_selectedCategory].label;
    final matchesCategory = selectedLabel == 'All' ||
        profile.serviceCategory.toLowerCase() == selectedLabel.toLowerCase();
    return matchesCategory &&
        '${profile.fullName} ${profile.serviceCategory}'
            .toLowerCase()
            .contains(_query.toLowerCase());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: _selectedNavIndex == 3
            ? const ProfileScreen(role: UserRole.customer)
            : _selectedNavIndex == 2
                ? MessagesListScreen(currentUserId: FirebaseAuth.instance.currentUser!.uid)
            : _selectedNavIndex == 1
                ? const MyBookingsScreen()
                : SafeArea(
          child: StreamBuilder<List<ProviderProfile>>(
            stream: _repository.streamVerifiedProviderProfiles(),
            builder: (context, snapshot) {
              final profiles = snapshot.data ?? const <ProviderProfile>[];
              final visibleProfiles = profiles.where(_matchesFilters).toList();
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _Header(
                          userName: widget.userName,
                          locationLabel: widget.locationLabel,
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value.trim()),
                          decoration: InputDecoration(
                            hintText: 'Search services or providers...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _OfferBanner(),
                        const SizedBox(height: 22),
                        _SectionTitle(
                          'Browse categories',
                          onPressed: () => _openProviderList(),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 86,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (context, index) => _CategoryItem(
                              category: _categories[index],
                              selected: _selectedCategory == index,
                              onTap: () => setState(() => _selectedCategory = index),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _SectionTitle(
                          'Recommended near you',
                          onPressed: () => _openProviderList(),
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.hasError)
                          const _ProviderMessage(
                            icon: Icons.cloud_off_outlined,
                            text: 'Unable to load providers right now.',
                          )
                        else if (snapshot.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 34),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (visibleProfiles.isEmpty)
                          _ProviderMessage(
                            icon: Icons.search_off_outlined,
                            text: _query.isNotEmpty || _selectedCategory != 0
                                ? 'No verified providers match your search.'
                                : 'No verified providers are available yet.',
                          )
                        else
                          ...visibleProfiles.map(
                            (profile) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ProviderCard(profile: profile),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: NavigationBar(
          height: 64,
          selectedIndex: _selectedNavIndex,
          onDestinationSelected: (index) => setState(() => _selectedNavIndex = index),
          indicatorColor: const Color(0xFFD7ECFC),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.calendar_today_outlined), label: 'Bookings'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Messages'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      );

  void _openProviderList() {
    final category = _categories[_selectedCategory].label;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderListScreen(
          initialCategory: category == 'All' ? null : category,
          repository: _repository,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.userName, required this.locationLabel});

  final String userName;
  final String locationLabel;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.accentRed),
                  const SizedBox(width: 3),
                  Flexible(child: Text(locationLabel, overflow: TextOverflow.ellipsis, style: AppTextTheme.textTheme.bodySmall)),
                ]),
                const SizedBox(height: 4),
                Text('Good morning, $userName 👋', style: AppTextTheme.textTheme.headlineSmall),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Badge(smallSize: 7, child: const Icon(Icons.notifications_none_rounded, size: 25)),
            style: IconButton.styleFrom(backgroundColor: AppColors.surface, foregroundColor: AppColors.textDark),
          ),
        ],
      );
}

class _OfferBanner extends StatelessWidget {
  const _OfferBanner();

  @override
  Widget build(BuildContext context) => Container(
        height: 115,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: const Color(0xFF78B9E4), borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('LIMITED OFFER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: Color(0xFF174968))),
              const SizedBox(height: 5),
              const Text('First booking\n20% off', style: TextStyle(fontSize: 17, height: 1.1, fontWeight: FontWeight.w700)),
              const Spacer(),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(minimumSize: const Size(0, 27), padding: const EdgeInsets.symmetric(horizontal: 13), backgroundColor: const Color(0xFF183858), textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                child: const Text('Claim now'),
              ),
            ]),
          ),
          Container(
            width: 48,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0x6699D6F3), shape: BoxShape.circle),
            child: const Text('🎉', style: TextStyle(fontSize: 25)),
          ),
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.onPressed});
  final String title;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        TextButton(onPressed: onPressed, child: const Text('See all ›')),
      ]);
}

class _Category {
  const _Category(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({required this.category, required this.selected, required this.onTap});
  final _Category category;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: 52, child: Column(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: category.color, borderRadius: BorderRadius.circular(13), border: selected ? Border.all(color: AppColors.textDark, width: 1.4) : null),
            child: Icon(category.icon, size: 23, color: AppColors.textDark),
          ),
          const SizedBox(height: 5),
          Text(category.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600)),
        ])),
      );
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.profile});
  final ProviderProfile profile;

  String get _initials => profile.fullName.split(RegExp(r'\s+')).where((name) => name.isNotEmpty).take(2).map((name) => name[0].toUpperCase()).join();

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProviderDetailScreen(profile: profile)),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Row(children: [
            Container(
              width: 47,
              height: 47,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFC8EAF8), borderRadius: BorderRadius.circular(12)),
              child: Text(_initials.isEmpty ? 'CP' : _initials, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(profile.fullName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                const SizedBox(width: 3),
                const Icon(Icons.verified_rounded, color: Color(0xFF4CA9E0), size: 14),
              ]),
              const SizedBox(height: 2),
              Text(profile.serviceCategory, style: AppTextTheme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.work_outline_rounded, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Flexible(child: Text(profile.yearsOfExperience, overflow: TextOverflow.ellipsis, style: AppTextTheme.textTheme.bodySmall)),
              ]),
              const SizedBox(height: 5),
              const _AvailabilityChip(),
            ])),
            const SizedBox(width: 6),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border_rounded, size: 18), visualDensity: VisualDensity.compact),
              const SizedBox(height: 6),
              SizedBox(
                height: 29,
                child: FilledButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => BookingRequestDialog(provider: profile),
                  ),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), backgroundColor: const Color(0xFF70B9E8), foregroundColor: AppColors.textDark, textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  child: const Text('Book'),
                ),
              ),
            ]),
          ]),
        ),
      );
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xFFE2F5E6), borderRadius: BorderRadius.circular(8)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle, size: 6, color: Color(0xFF43A85F)),
          SizedBox(width: 3),
          Text('Available', style: TextStyle(fontSize: 8, color: Color(0xFF287A40), fontWeight: FontWeight.w600)),
        ]),
      );
}

class _ProviderMessage extends StatelessWidget {
  const _ProviderMessage({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(children: [
          Icon(icon, size: 36, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center, style: AppTextTheme.textTheme.bodyMedium),
        ]),
      );
}
