import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/memory_model.dart';
import '../../services/memory_service.dart';
import '../../utils/colors.dart';

class TravelPassportScreen extends StatefulWidget {
  const TravelPassportScreen({super.key});

  @override
  State<TravelPassportScreen> createState() =>
      _TravelPassportScreenState();
}

class _TravelPassportScreenState extends State<TravelPassportScreen> {
  final _service = MemoryService();
  List<MemoryModel> _memories = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final memories = await _service.getUserMemories().first;
    final stats = await _service.getPassportStats();
    if (mounted) {
      setState(() {
        _memories = memories;
        _stats = stats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGold),
      );
    }

    return ListView(
      padding: EdgeInsets.all(width * 0.05),
      children: [
        _buildPassportHeader(width),
        SizedBox(height: width * 0.05),
        _buildStatsGrid(width),
        SizedBox(height: width * 0.05),
        _buildStampsSection(width),
      ],
    );
  }

  // ============================================================
  // PASSPORT HEADER
  // ============================================================
  Widget _buildPassportHeader(double width) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.all(width * 0.06),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentGold.withOpacity(0.3),
                AppColors.accentGold.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.accentGold.withOpacity(0.5),
                width: 1.5),
          ),
          child: Column(
            children: [
              Icon(Icons.card_membership,
                  color: AppColors.accentGold, size: width * 0.15),
              const SizedBox(height: 12),
              const Text(
                'TRAVEL PASSPORT',
                style: TextStyle(
                  color: AppColors.accentGold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your journey at a glance',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATS GRID
  // ============================================================
  Widget _buildStatsGrid(double width) {
    final stats = [
      {'icon': '📸', 'label': 'Memories', 'value': _stats['total'] ?? 0},
      {'icon': '🌍', 'label': 'Countries', 'value': _stats['countries'] ?? 0},
      {'icon': '📍', 'label': 'Locations', 'value': _stats['locations'] ?? 0},
      {'icon': '❤️', 'label': 'Favorites', 'value': _stats['favorites'] ?? 0},
      {'icon': '🖼️', 'label': 'Photos', 'value': _stats['photos'] ?? 0},
      {'icon': '🎥', 'label': 'Videos', 'value': _stats['videos'] ?? 0},
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: width * 0.03,
      mainAxisSpacing: width * 0.03,
      childAspectRatio: 1.1,
      children: stats.map((s) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.13),
                borderRadius: BorderRadius.circular(16),
                border:
                Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    child: Text(s['icon']!,
                        style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${s['value']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      s['label']!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // STAMPS SECTION
  // ============================================================
  Widget _buildStampsSection(double width) {
    final countries = <String, int>{};
    for (var m in _memories) {
      if (m.location.isNotEmpty) {
        final parts = m.location.split(',');
        if (parts.length > 1) {
          final country = parts.last.trim();
          if (country.isNotEmpty) {
            countries[country] =
                (countries[country] ?? 0) + 1;
          }
        }
      }
    }

    if (countries.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.all(width * 0.08),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border:
              Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(Icons.public,
                    color: Colors.white.withOpacity(0.3),
                    size: width * 0.2),
                const SizedBox(height: 16),
                const Text(
                  'No stamps yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add memories with locations to collect stamps',
                  textAlign: TextAlign.center,
                  style:
                  TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Sort by count
    final sorted = countries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🎫 Country Stamps',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentGold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${sorted.length}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sorted
              .map((e) => _buildStamp(e.key, e.value, width))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStamp(String country, int count, double width) {
    final flag = _countryFlag(country);
    final size = (width - 80) / 2;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accentGold.withOpacity(0.15),
              AppColors.accentGold.withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.accentGold.withOpacity(0.7),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGold.withOpacity(0.3),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              flag,
              style: TextStyle(fontSize: size * 0.3),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                country,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.09,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count ${count == 1 ? 'visit' : 'visits'}',
              style: TextStyle(
                color: AppColors.accentGold,
                fontSize: size * 0.075,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FLAG EMOJI
  // ============================================================
  String _countryFlag(String country) {
    final c = country.toLowerCase().trim();
    if (c.contains('tanzania')) return '🇹🇿';
    if (c.contains('kenya')) return '🇰🇪';
    if (c.contains('uganda')) return '🇺🇬';
    if (c.contains('rwanda')) return '🇷🇼';
    if (c.contains('south africa')) return '🇿🇦';
    if (c.contains('egypt')) return '🇪🇬';
    if (c.contains('morocco')) return '🇲🇦';
    if (c.contains('ghana')) return '🇬🇭';
    if (c.contains('nigeria')) return '🇳🇬';
    if (c.contains('ethiopia')) return '🇪🇹';
    if (c.contains('namibia')) return '🇳🇦';
    if (c.contains('botswana')) return '🇧🇼';
    if (c.contains('zambia')) return '🇿🇲';
    if (c.contains('mozambique')) return '🇲🇿';
    if (c.contains('usa') || c.contains('united states')) return '🇺🇸';
    if (c.contains('italy')) return '🇮🇹';
    if (c.contains('japan')) return '🇯🇵';
    if (c.contains('france')) return '🇫🇷';
    if (c.contains('germany')) return '🇩🇪';
    if (c.contains('spain')) return '🇪🇸';
    if (c.contains('india')) return '🇮🇳';
    if (c.contains('china')) return '🇨🇳';
    if (c.contains('dubai') || c.contains('uae')) return '🇦🇪';
    if (c.contains('singapore')) return '🇸🇬';
    return '🌍';
  }
}