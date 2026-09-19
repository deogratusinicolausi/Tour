import 'package:flutter/material.dart';
import '../utils/colors.dart';

// ⭐️ Hover Wrapper
class HoverDealCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const HoverDealCard({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<HoverDealCard> createState() => _HoverDealCardState();
}

class _HoverDealCardState extends State<HoverDealCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..scale(_isHovered ? 1.03 : 1.0)
            ..translate(0.0, _isHovered ? -5.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: _isHovered
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ⭐️ Countdown Timer Widget
class CountdownTimer extends StatefulWidget {
  final DateTime? endDate;

  const CountdownTimer({super.key, this.endDate});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _updateRemaining();
        _startTimer();
      }
    });
  }

  void _updateRemaining() {
    if (widget.endDate == null) {
      _remaining = Duration.zero;
      return;
    }
    final diff = widget.endDate!.difference(DateTime.now());
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.endDate == null || _remaining == Duration.zero) {
      return const SizedBox();
    }

    final width = MediaQuery.of(context).size.width;
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            days > 0
                ? '${days}d ${hours}h'
                : hours > 0
                ? '${hours}h ${minutes}m'
                : '${minutes}m ${seconds}s',
            style: TextStyle(
              color: Colors.white,
              fontSize: width * 0.025,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ⭐️ Deal Grid Card
class DealGridCard extends StatelessWidget {
  final Map<String, dynamic> deal;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;

  const DealGridCard({
    super.key,
    required this.deal,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final discount = deal['discount'] ?? 0;
    final originalPrice = (deal['originalPrice'] ?? 0) as num;
    final salePrice = (deal['salePrice'] ?? 0) as num;
    final currency = deal['currency'] ?? 'USD';
    final savings = originalPrice - salePrice;

    return HoverDealCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  _buildImage(deal['imageUrl'], height * 0.11, width),

                  // Discount badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        '-$discount%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Featured
                  if (deal['featured'] == true)
                    Positioned(
                      top: 8,
                      right: 32,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.star,
                            size: 10, color: Colors.black),
                      ),
                    ),

                  // Countdown
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: CountdownTimer(
                      endDate: (deal['endDate'] != null)
                          ? (deal['endDate'] as dynamic).toDate()
                          : null,
                    ),
                  ),

                  // Like
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onLike,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color:
                          isLiked ? Colors.red : Colors.grey.shade700,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(width * 0.025),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal['title'] ?? 'Unnamed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.032,
                            color: Colors.grey.shade900,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((deal['itemName'] ?? '').toString().isNotEmpty) ...[
                          SizedBox(height: height * 0.003),
                          Text(
                            deal['itemName'],
                            style: TextStyle(
                              fontSize: width * 0.024,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$currency ${salePrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.038,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$currency ${originalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: width * 0.026,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        if (savings > 0) ...[
                          SizedBox(height: height * 0.003),
                          Text(
                            'Save $currency ${savings.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: width * 0.022,
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(dynamic url, double height, double width) {
    if (url == null || url.toString().isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade200, Colors.red.shade400],
          ),
        ),
        child: Center(
          child: Icon(Icons.local_offer, size: width * 0.1, color: Colors.white),
        ),
      );
    }

    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        color: Colors.grey.shade200,
        child: Icon(Icons.broken_image,
            size: width * 0.1, color: Colors.grey.shade400),
      ),
    );
  }
}

// ⭐️ Deal List Card
class DealListCard extends StatelessWidget {
  final Map<String, dynamic> deal;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;

  const DealListCard({
    super.key,
    required this.deal,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final discount = deal['discount'] ?? 0;
    final originalPrice = (deal['originalPrice'] ?? 0) as num;
    final salePrice = (deal['salePrice'] ?? 0) as num;
    final currency = deal['currency'] ?? 'USD';

    return HoverDealCard(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: height * 0.015),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
              const BorderRadius.horizontal(left: Radius.circular(18)),
              child: Stack(
                children: [
                  SizedBox(
                    width: width * 0.32,
                    height: width * 0.32,
                    child:
                    _buildImage(deal['imageUrl'], width * 0.32, width),
                  ),
                  // Discount badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-$discount%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(width * 0.035),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal['title'] ?? 'Unnamed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.038,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((deal['itemName'] ?? '').toString().isNotEmpty) ...[
                      SizedBox(height: height * 0.005),
                      Text(
                        deal['itemName'],
                        style: TextStyle(
                          fontSize: width * 0.028,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: height * 0.008),
                    Row(
                      children: [
                        Text(
                          '$currency ${salePrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.04,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$currency ${originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: width * 0.028,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.005),
                    CountdownTimer(
                      endDate: (deal['endDate'] != null)
                          ? (deal['endDate'] as dynamic).toDate()
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: width * 0.03),
              child: GestureDetector(
                onTap: onLike,
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey.shade400,
                  size: width * 0.06,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(dynamic url, double height, double width) {
    if (url == null || url.toString().isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade200, Colors.red.shade400],
          ),
        ),
        child: Icon(Icons.local_offer, size: width * 0.08, color: Colors.white),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.broken_image,
            size: width * 0.08, color: Colors.grey.shade400),
      ),
    );
  }
}