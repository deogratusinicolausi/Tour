import 'package:flutter/material.dart';

import '../services/airtrip_service.dart';
import '../utils/colors.dart';

class AirTripExploreScreen extends StatefulWidget {
  const AirTripExploreScreen({super.key});

  @override
  State<AirTripExploreScreen> createState() =>
      _AirTripExploreScreenState();
}

class _AirTripExploreScreenState
    extends State<AirTripExploreScreen> {
  final AirTripService _airTrip =
      AirTripService.instance;

  final List<Map<String, String>> destinations = [
    {
      'id': 'serengeti',
      'name': 'Serengeti',
      'subtitle': 'Wildlife & Safari',
      'emoji': '🦁',
    },
    {
      'id': 'kilimanjaro',
      'name': 'Kilimanjaro',
      'subtitle': 'Mountain Adventure',
      'emoji': '🏔️',
    },
    {
      'id': 'zanzibar',
      'name': 'Zanzibar',
      'subtitle': 'Beach & Island',
      'emoji': '🏝️',
    },
    {
      'id': 'tarangire',
      'name': 'Tarangire',
      'subtitle': 'Elephants & Nature',
      'emoji': '🐘',
    },
  ];

  @override
  void dispose() {
    _airTrip.clearFocus();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackground(),

            Column(
              children: [
                _buildHeader(),

                Expanded(
                  child: _buildDestinationGrid(),
                ),
              ],
            ),

            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            Colors.black,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        12,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 8),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'AIRTRIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'Explore Tanzania hands-free',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          ValueListenableBuilder<AirTripIntent>(
            valueListenable: _airTrip.intent,
            builder: (
              context,
              intent,
              child,
            ) {
              return _IntentIndicator(
                intent: intent,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        150,
      ),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: destinations.length,
      itemBuilder: (context, index) {
        final destination =
            destinations[index];

        return ValueListenableBuilder<String?>(
          valueListenable:
              _airTrip.focusedItem,
          builder: (
            context,
            focused,
            child,
          ) {
            final isFocused =
                focused == destination['id'];

            return GestureDetector(
              onTap: () {
                _airTrip.focus(
                  destination['id']!,
                );

                Navigator.pushNamed(
                  context,
                  '/home',
                );
              },
              child: AnimatedContainer(
                duration:
                    const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(24),
                  border: Border.all(
                    color: isFocused
                        ? AppColors.accentGold
                        : Colors.white24,
                    width: isFocused ? 2.5 : 1,
                  ),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color:
                                AppColors.accentGold
                                    .withValues(
                                      alpha: 0.35,
                                    ),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(
                        alpha: 0.12,
                      ),
                      Colors.white.withValues(
                        alpha: 0.04,
                      ),
                    ],
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        destination['emoji']!,
                        style:
                            const TextStyle(
                          fontSize: 54,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        destination['name']!,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        destination['subtitle']!,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),

                      if (isFocused) ...[
                        const SizedBox(
                          height: 12,
                        ),
                        const Text(
                          'PINCH TO EXPLORE',
                          style: TextStyle(
                            color:
                                AppColors.accentGold,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(
            alpha: 0.75,
          ),
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white24,
          ),
        ),
        child: const Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround,
          children: [
            _Instruction(
              icon: '☝️',
              text: 'Point',
            ),
            _Instruction(
              icon: '🤏',
              text: 'Select',
            ),
            _Instruction(
              icon: '✋',
              text: 'Scroll',
            ),
            _Instruction(
              icon: '✊',
              text: 'Back',
            ),
          ],
        ),
      ),
    );
  }
}

class _Instruction extends StatelessWidget {
  const _Instruction({
    required this.icon,
    required this.text,
  });

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _IntentIndicator extends StatelessWidget {
  const _IntentIndicator({
    required this.intent,
  });

  final AirTripIntent intent;

  @override
  Widget build(BuildContext context) {
    if (intent == AirTripIntent.none) {
      return const SizedBox.shrink();
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentGold
            .withValues(alpha: 0.15),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentGold,
        ),
      ),
      child: Text(
        intent.name.toUpperCase(),
        style: const TextStyle(
          color: AppColors.accentGold,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
