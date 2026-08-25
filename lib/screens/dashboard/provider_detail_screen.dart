import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nepal_care/core/utils/user_display_name.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/core/theme/app_text_theme.dart';
import 'package:nepal_care/models/provider_prrofile.dart';
import 'package:nepal_care/repositories/chat_repository.dart';
import 'package:nepal_care/screens/chat/chat_screen.dart';
import 'package:nepal_care/widgets/booking_request_dialog.dart';

/// Full profile a customer sees before booking. `fullName`, `serviceCategory`,
/// `yearsOfExperience`, `bio`, and `hourlyRate` are real — everything under
/// "DUMMY DATA" below (rating, review count, completed jobs, response time,
/// and the sample reviews list) is placeholder until the review/completed-
/// booking system exists. See the notes above [_DummyStats] and
/// [_dummyReviewsFor] for what needs to replace each piece, and don't ship
/// this to real users without swapping them out — showing fabricated ratings
/// to customers is a trust/honesty problem, not just a cosmetic one.
class ProviderDetailScreen extends StatelessWidget {
  const ProviderDetailScreen({super.key, required this.profile});

  final ProviderProfile profile;

  @override
  Widget build(BuildContext context) {
    final stats = _DummyStats.forProvider(profile);
    final reviews = _dummyReviewsFor(profile);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back_rounded)),
                  const Spacer(),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border_rounded)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  _ProfileHeader(profile: profile, stats: stats),
                  const SizedBox(height: 20),
                  _StatsRow(stats: stats),
                  const SizedBox(height: 24),
                  Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    profile.bio.isNotEmpty ? profile.bio : 'No description provided yet.',
                    style: AppTextTheme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reviews', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text('${stats.rating.toStringAsFixed(1)} ★ · ${stats.reviewCount} reviews', style: AppTextTheme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final review in reviews)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReviewTile(review: review),
                    ),
                ],
              ),
            ),
            _BookingBar(profile: profile),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.stats});

  final ProviderProfile profile;
  final _DummyStats stats;

  String get _initials => profile.fullName
      .split(RegExp(r'\s+'))
      .where((name) => name.isNotEmpty)
      .take(2)
      .map((name) => name[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFC8EAF8), borderRadius: BorderRadius.circular(18)),
            child: Text(_initials.isEmpty ? 'CP' : _initials, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(profile.fullName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, color: Color(0xFF4CA9E0), size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(profile.serviceCategory, style: AppTextTheme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF5A623)),
                    const SizedBox(width: 3),
                    Text('${stats.rating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(' (${stats.reviewCount})', style: AppTextTheme.textTheme.bodySmall),
                    const SizedBox(width: 10),
                    const Icon(Icons.work_outline_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Flexible(child: Text(profile.yearsOfExperience, overflow: TextOverflow.ellipsis, style: AppTextTheme.textTheme.bodySmall)),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final _DummyStats stats;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _StatChip(label: 'Completed jobs', value: '${stats.completedJobs}', color: const Color(0xFFD6ECFC)),
          const SizedBox(width: 10),
          _StatChip(label: 'Response time', value: stats.responseTime, color: const Color(0xFFDFF0DF)),
          const SizedBox(width: 10),
          _StatChip(label: 'Rating', value: stats.rating.toStringAsFixed(1), color: const Color(0xFFFFE7A8)),
        ],
      );
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 2),
              Text(label, textAlign: TextAlign.center, style: AppTextTheme.textTheme.bodySmall),
            ],
          ),
        ),
      );
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final _DummyReview review;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.w700))),
                Text(review.relativeDate, style: AppTextTheme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 15,
                  color: const Color(0xFFF5A623),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(review.comment, style: AppTextTheme.textTheme.bodyMedium),
          ],
        ),
      );
}

class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.profile});

  final ProviderProfile profile;

  Future<void> _startChat(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to message this provider.')),
      );
      return;
    }
    if (profile.uid.isEmpty || profile.uid == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This conversation is not available.')),
      );
      return;
    }

    try {
      final conversationId = await ChatRepository().getOrCreateConversation(
        userAId: user.uid,
        userAName: userDisplayName(
          displayName: user.displayName,
          email: user.email,
          fallback: 'Care-Nepal member',
        ),
        userARole: 'Customer',
        userBId: profile.uid,
        userBName: profile.fullName,
        userBRole: profile.serviceCategory,
      );
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            currentUserId: user.uid,
            otherUserId: profile.uid,
            otherUserName: profile.fullName,
            otherUserRole: profile.serviceCategory,
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start this conversation. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _startChat(context),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Message'),
              ),
              const SizedBox(width: 10),
              if (profile.hourlyRate > 0)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rate', style: AppTextTheme.textTheme.bodySmall),
                      Text('Rs ${profile.hourlyRate}/hr', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.accentRed)),
                    ],
                  ),
                ),
              SizedBox(
                width: profile.hourlyRate > 0 ? 130 : 150,
                child: FilledButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => BookingRequestDialog(provider: profile),
                  ),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Book now', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
}

// ============================================================
// DUMMY DATA — replace once the real systems exist.
// ============================================================

/// Placeholder stats. Real replacements, in order of what to build first:
///  - completedJobs: count of that provider's bookings with a `completed`
///    status (status doesn't exist yet — see BookingStatus, only has
///    pending/accepted/declined today).
///  - rating / reviewCount: aggregate off a `reviews` collection, written by
///    customers after a completed booking. Compute this with a Cloud
///    Function on write, not client-side on every screen load.
///  - responseTime: average delta between a booking's `createdAt` and
///    whenever the provider first set it to accepted/declined.
///
/// Values are derived from a hash of the provider's uid/name so the same
/// provider shows the same numbers on every visit instead of jumping around
/// — makes it obvious this is a stand-in, not real backend flakiness.
class _DummyStats {
  const _DummyStats({
    required this.rating,
    required this.reviewCount,
    required this.completedJobs,
    required this.responseTime,
  });

  final double rating;
  final int reviewCount;
  final int completedJobs;
  final String responseTime;

  factory _DummyStats.forProvider(ProviderProfile profile) {
    final seed = (profile.uid.isNotEmpty ? profile.uid : profile.fullName).hashCode.abs();
    final rating = 4.5 + (seed % 5) / 10; // 4.5–4.9
    final reviewCount = 18 + (seed % 160);
    final completedJobs = reviewCount + 6 + (seed % 40);
    const responseTimes = ['Under 15 min', 'Under 30 min', 'Under 1 hour', 'Same day'];
    final responseTime = responseTimes[seed % responseTimes.length];
    return _DummyStats(rating: rating, reviewCount: reviewCount, completedJobs: completedJobs, responseTime: responseTime);
  }
}

class _DummyReview {
  const _DummyReview({
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.relativeDate,
  });

  final String customerName;
  final int rating;
  final String comment;
  final String relativeDate;
}

/// Same 3 canned reviews for every provider right now — fine as a UI
/// placeholder, not fine to ship. Replace with a real query against a
/// `reviews` collection filtered by `providerId`, ordered by `createdAt`.
List<_DummyReview> _dummyReviewsFor(ProviderProfile profile) => const [
      _DummyReview(
        customerName: 'Sanjita K.',
        rating: 5,
        comment: 'Very punctual and caring. Would book again without hesitation.',
        relativeDate: '2 weeks ago',
      ),
      _DummyReview(
        customerName: 'Bikash R.',
        rating: 5,
        comment: 'Professional and communicated clearly throughout the booking.',
        relativeDate: '1 month ago',
      ),
      _DummyReview(
        customerName: 'Prabin S.',
        rating: 4,
        comment: 'Good experience overall, arrived a little later than scheduled.',
        relativeDate: '2 months ago',
      ),
    ];
