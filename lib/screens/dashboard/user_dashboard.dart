import 'package:flutter/material.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/core/theme/app_text_theme.dart';
import 'package:nepal_care/models/provider_prrofile.dart';
import 'package:nepal_care/repositories/user_repository.dart';

/// A provider that has completed [ProfileSubmittedScreen] and been verified,
/// with their service category, pricing, and availability set. This is what
/// populates "Recommended near you" once their form data is approved.
class ProviderListing {
  const ProviderListing({
    required this.id,
    required this.name,
    required this.category,
    required this.initials,
    required this.avatarColor,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.price,
    required this.isAvailable,
    this.isVerified = true,
  });

  final String id;
  final String name;
  final String category;
  final String initials;
  final Color avatarColor;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final int price;
  final bool isAvailable;
  final bool isVerified;
}

class ServiceCategory {
  const ServiceCategory({
    required this.label,
    required this.icon,
    required this.iconBackground,
  });

  final String label;
  final IconData icon;
  final Color iconBackground;
}

class UserDashboard extends StatefulWidget {
  const UserDashboard({
    super.key,
    this.userName = 'Customer',
    this.locationLabel = 'Kathmandu, Nepal',
    this.categories = const [],
    this.providers = const [],
    this.notificationCount = 0,
  });

  final String userName;
  final String locationLabel;
  final List<ServiceCategory> categories;
  final List<ProviderListing> providers;
  final int notificationCount;

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final _userRepository = UserRepository();
  int _selectedCategoryIndex = 0;
  int _bottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            _Header(
              locationLabel: widget.locationLabel,
              userName: widget.userName,
              notificationCount: widget.notificationCount,
            ),
            const SizedBox(height: 18),
            const _SearchBar(),
            const SizedBox(height: 18),
            const _PromoBanner(),
            const SizedBox(height: 24),

            _SectionHeader(title: 'Browse categories', onSeeAll: () {}),
            const SizedBox(height: 12),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final category = widget.categories[index];
                  return _CategoryChip(
                    category: category,
                    selected: index == _selectedCategoryIndex,
                    onTap: () => setState(() => _selectedCategoryIndex = index),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            _SectionHeader(title: 'Recommended near you', onSeeAll: () {}),
            const SizedBox(height: 12),

            StreamBuilder<List<ProviderProfile>>(
              stream: _userRepository.streamVerifiedProviderProfiles(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _EmptyProvidersState(
                    message: 'Could not load verified providers: ${snapshot.error}',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(),
                  ));
                }

                final providers = snapshot.data!;
                if (providers.isEmpty) return const _EmptyProvidersState();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: providers
                      .map(
                        (profile) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ProviderCard(
                            provider: _listingFromProfile(profile),
                            onBook: () {},
                            onFavorite: () {},
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
      ),
    );
  }

  ProviderListing _listingFromProfile(ProviderProfile profile) {
    final initials = profile.fullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return ProviderListing(
      id: profile.phone,
      name: profile.fullName,
      category: profile.serviceCategory,
      initials: initials.isEmpty ? 'CP' : initials,
      avatarColor: const Color(0xFFDCEBFA),
      rating: 0,
      reviewCount: 0,
      distanceKm: 0,
      price: 0,
      isAvailable: true,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.locationLabel,
    required this.userName,
    required this.notificationCount,
  });

  final String locationLabel;
  final String userName;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    locationLabel,
                    style: AppTextTheme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Good morning, $userName',
                      style: AppTextTheme.textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
        _NotificationBell(count: notificationCount),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
            ],
          ),
          child: const Icon(Icons.notifications_none_rounded, size: 22),
        ),
        if (count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Text(
            'Search services or providers...',
            style: AppTextTheme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6FB3E0), Color(0xFF3E8FD6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LIMITED OFFER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'First booking\n20% off',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15294A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Claim now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text('⚡', style: TextStyle(fontSize: 36)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextTheme.textTheme.titleMedium),
        GestureDetector(
          onTap: onSeeAll,
          child: Row(
            children: [
              Text(
                'See all',
                style: AppTextTheme.textTheme.bodySmall?.copyWith(color: AppColors.primary),
              ),
              Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ServiceCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: category.iconBackground,
              shape: BoxShape.circle,
              border: selected ? Border.all(color: Colors.black87, width: 2) : null,
            ),
            child: Icon(category.icon, color: Colors.black87, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            category.label,
            style: AppTextTheme.textTheme.bodySmall?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.onBook,
    required this.onFavorite,
  });

  final ProviderListing provider;
  final VoidCallback onBook;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: provider.avatarColor,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              provider.initials,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        provider.name,
                        style: AppTextTheme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (provider.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 14, color: Color(0xFF3E8FD6)),
                    ],
                  ],
                ),
                Text(
                  provider.category,
                  style: AppTextTheme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Color(0xFFF5A623)),
                    const SizedBox(width: 2),
                    Text(
                      '${provider.rating} (${provider.reviewCount})',
                      style: AppTextTheme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                    Text(
                      '${provider.distanceKm} km',
                      style: AppTextTheme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: provider.isAvailable ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      provider.isAvailable ? 'Available' : 'Busy',
                      style: AppTextTheme.textTheme.bodySmall?.copyWith(
                        color: provider.isAvailable ? Colors.green.shade700 : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onFavorite,
                    child: const Icon(Icons.favorite_border, size: 18, color: Colors.black45),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Rs ${provider.price}',
                style: AppTextTheme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFE05656),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Book', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyProvidersState extends StatelessWidget {
  const _EmptyProvidersState({
    this.message = 'No verified providers nearby yet',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.search_off, size: 32, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextTheme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.black38,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Bookings'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}
