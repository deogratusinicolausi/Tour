import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/memory_model.dart';
import '../utils/colors.dart';

class MemoryTimelineCard extends StatelessWidget {
  final MemoryModel memory;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const MemoryTimelineCard({
    super.key,
    required this.memory,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLocked = memory.isCapsuleLocked;
    final thumb = memory.mediaUrls.isNotEmpty
        ? memory.mediaUrls.first
        : memory.thumbnailUrl;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: width * 0.035),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ Timeline line + dot ═══
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: memory.favorite
                        ? AppColors.accentGold
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentGold,
                      width: 2,
                    ),
                    boxShadow: memory.favorite
                        ? [
                      BoxShadow(
                        color: AppColors.accentGold.withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                        : [],
                  ),
                ),
                Container(
                  width: 2,
                  height: width * 0.32,
                  color: Colors.white.withOpacity(0.2),
                ),
              ],
            ),
            SizedBox(width: width * 0.03),

            // ═══ Memory Card ═══
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        if (thumb.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: width * 0.35,
                                  width: double.infinity,
                                  child: isLocked
                                      ? Container(
                                    color: Colors.black
                                        .withOpacity(0.7),
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.lock,
                                            color: AppColors
                                                .accentGold,
                                            size: width * 0.1),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Opens ${memory.capsuleOpenDate?.year ?? ''}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                            FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                      : Image.network(
                                    thumb,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Container(
                                          color: Colors.white
                                              .withOpacity(0.1),
                                          child: const Icon(
                                              Icons.broken_image,
                                              color: Colors.white54),
                                        ),
                                  ),
                                ),
                                // Memory type badge
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black
                                          .withOpacity(0.75),
                                      borderRadius:
                                      BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.accentGold
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _typeIcon(memory.memoryType),
                                          style: const TextStyle(
                                              fontSize: 11),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          memory.memoryType.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // ⭐ Capsule badge (Locked)
                                if (memory.capsuleOpenDate != null && isLocked)
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.goldGradient,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.accentGold.withOpacity(0.6),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.lock, size: 12, color: Colors.black),
                                          const SizedBox(width: 4),
                                          Text(
                                            'OPENS ${memory.capsuleOpenDate!.year}',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                // ⭐ Unlocked badge
                                if (memory.capsuleOpenDate != null && !isLocked)
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.lock_open, size: 12, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text('UNLOCKED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                // Favorite button
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: onFavorite,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withOpacity(0.6),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: memory.favorite
                                              ? Colors.red
                                              : Colors.white
                                              .withOpacity(0.4),
                                        ),
                                      ),
                                      child: Icon(
                                        memory.favorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: memory.favorite
                                            ? Colors.red
                                            : Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Content
                        Padding(
                          padding: EdgeInsets.all(width * 0.035),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                memory.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.04,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (memory.location.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: Colors.white70,
                                        size: width * 0.035),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        memory.location,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: width * 0.028,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (memory.description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  memory.description,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: width * 0.03,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      color: AppColors.accentGold,
                                      size: width * 0.03),
                                  const SizedBox(width: 4),
                                  Text(
                                    memory.formattedDate,
                                    style: TextStyle(
                                      color: AppColors.accentGold,
                                      fontSize: width * 0.028,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeIcon(String type) {
    switch (type) {
      case 'photo':
        return '📸';
      case 'video':
        return '🎥';
      case 'journal':
        return '✍️';
      case 'location':
        return '📍';
      default:
        return '📸';
    }
  }
}