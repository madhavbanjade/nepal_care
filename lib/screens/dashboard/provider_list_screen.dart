import 'package:flutter/material.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/core/theme/app_text_theme.dart';
import 'package:nepal_care/models/provider_prrofile.dart';
import 'package:nepal_care/repositories/user_repository.dart';
import 'package:nepal_care/widgets/booking_request_dialog.dart';

/// The full, searchable list of Firestore-verified provider profiles.
class ProviderListScreen extends StatefulWidget {
  const ProviderListScreen({
    super.key,
    this.initialCategory,
    this.repository,
  });

  final String? initialCategory;
  final UserRepository? repository;

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  static const _allCategories = <String>[
    'All',
    'Baby Care',
    'Adult Care',
    'Senior Care',
    'Pet Care',
    'Special Needs Care',
    'Housekeeping',
  ];

  late final UserRepository _repository = widget.repository ?? UserRepository();
  late String _category = widget.initialCategory ?? 'All';
  final _searchController = TextEditingController();
  String _query = '';
  _ProviderSort _sort = _ProviderSort.experience;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(ProviderProfile profile) {
    final categoryMatches = _category == 'All' ||
        profile.serviceCategory.toLowerCase() == _category.toLowerCase();
    final terms = '${profile.fullName} ${profile.serviceCategory} ${profile.bio}'
        .toLowerCase();
    return categoryMatches && terms.contains(_query.toLowerCase());
  }

  List<ProviderProfile> _sorted(List<ProviderProfile> profiles) {
    final result = profiles.where(_matches).toList();
    result.sort((a, b) {
      switch (_sort) {
        case _ProviderSort.name:
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
        case _ProviderSort.category:
          return a.serviceCategory.toLowerCase().compareTo(b.serviceCategory.toLowerCase());
        case _ProviderSort.experience:
          return _experienceYears(b).compareTo(_experienceYears(a));
      }
    });
    return result;
  }

  int _experienceYears(ProviderProfile profile) {
    final value = RegExp(r'\d+').firstMatch(profile.yearsOfExperience)?.group(0);
    return int.tryParse(value ?? '') ?? 0;
  }

  Future<void> _showSortSheet() async {
    final choice = await showModalBottomSheet<_ProviderSort>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Sort providers', style: AppTextTheme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            ..._ProviderSort.values.map(
              (sort) => RadioListTile<_ProviderSort>(
                contentPadding: EdgeInsets.zero,
                value: sort,
                groupValue: _sort,
                title: Text(sort.label),
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ),
          ]),
        ),
      ),
    );
    if (choice != null && mounted) setState(() => _sort = choice);
  }

  Future<void> _showFilterSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Filter by category', style: AppTextTheme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allCategories
                  .map((category) => ChoiceChip(
                        label: Text(category),
                        selected: category == _category,
                        onSelected: (_) => Navigator.pop(context, category),
                      ))
                  .toList(),
            ),
          ]),
        ),
      ),
    );
    if (choice != null && mounted) setState(() => _category = choice);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          titleSpacing: 0,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CATEGORY', style: AppTextTheme.textTheme.bodySmall?.copyWith(letterSpacing: 1.1)),
            Text(_category == 'All' ? 'Care providers' : _category, style: AppTextTheme.textTheme.headlineSmall),
          ]),
        ),
        body: StreamBuilder<List<ProviderProfile>>(
          stream: _repository.streamVerifiedProviderProfiles(),
          builder: (context, snapshot) {
            final providers = _sorted(snapshot.data ?? const <ProviderProfile>[]);
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search providers or services...',
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  OutlinedButton.icon(onPressed: _showSortSheet, icon: const Icon(Icons.swap_vert_rounded, size: 18), label: const Text('Sort')),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(onPressed: _showFilterSheet, icon: const Icon(Icons.tune_rounded, size: 18), label: const Text('Filter')),
                  const Spacer(),
                  _CountPill(count: providers.length),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Sorted by: ${_sort.label}', style: AppTextTheme.textTheme.bodySmall),
                ),
              ),
              Expanded(
                child: snapshot.hasError
                    ? const _ListMessage(icon: Icons.cloud_off_outlined, text: 'Unable to load providers right now.')
                    : snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : providers.isEmpty
                            ? const _ListMessage(icon: Icons.search_off_outlined, text: 'No verified providers match these filters.')
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                                itemCount: providers.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 14),
                                itemBuilder: (context, index) => _ProviderListCard(profile: providers[index]),
                              ),
              ),
            ]);
          },
        ),
      );
}

enum _ProviderSort {
  experience('Most experience'),
  name('Name A-Z'),
  category('Service category');

  const _ProviderSort(this.label);
  final String label;
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFE0F6E5), border: Border.all(color: const Color(0xFF8BDB9D)), borderRadius: BorderRadius.circular(18)),
        child: Text('$count ${count == 1 ? 'provider' : 'providers'}', style: const TextStyle(color: Color(0xFF25843B), fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class _ProviderListCard extends StatelessWidget {
  const _ProviderListCard({required this.profile});
  final ProviderProfile profile;

  String get _initials => profile.fullName.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).take(2).map((word) => word[0].toUpperCase()).join();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border(top: const BorderSide(color: Color(0xFFE4CBF5), width: 5)),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFE9D4F6), borderRadius: BorderRadius.circular(15)),
            child: Text(_initials.isEmpty ? 'CP' : _initials, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(profile.fullName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              const SizedBox(width: 5),
              const _VerifiedPill(),
            ]),
            const SizedBox(height: 3),
            Text(profile.serviceCategory, style: AppTextTheme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.work_outline_rounded, size: 15, color: Color(0xFF67AEDD)),
              const SizedBox(width: 4),
              Text(profile.yearsOfExperience, style: AppTextTheme.textTheme.bodySmall),
            ]),
            const SizedBox(height: 9),
            const _AvailablePill(),
            const SizedBox(height: 11),
            OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => BookingRequestDialog(provider: profile),
              ),
              icon: const Icon(Icons.calendar_month_outlined, size: 16),
              label: const Text('Book provider'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 10), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ])),
          IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border_rounded, color: Color(0xFFB5B5B5))),
        ]),
      );
}

class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFFE1F3FF), border: Border.all(color: const Color(0xFF74B9E6)), borderRadius: BorderRadius.circular(10)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.verified_rounded, size: 11, color: Color(0xFF338CC6)),
          SizedBox(width: 3),
          Text('Verified', style: TextStyle(fontSize: 9, color: Color(0xFF276C9A), fontWeight: FontWeight.w700)),
        ]),
      );
}

class _AvailablePill extends StatelessWidget {
  const _AvailablePill();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFFE1F5E6), borderRadius: BorderRadius.circular(10)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle, size: 7, color: Color(0xFF46A85C)),
          SizedBox(width: 4),
          Text('Available', style: TextStyle(fontSize: 10, color: Color(0xFF287A40), fontWeight: FontWeight.w700)),
        ]),
      );
}

class _ListMessage extends StatelessWidget {
  const _ListMessage({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 38, color: AppColors.textMuted),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center, style: AppTextTheme.textTheme.bodyMedium),
      ]));
}
