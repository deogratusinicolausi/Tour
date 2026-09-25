import 'package:flutter/material.dart';
import '../services/hand_cursor_service.dart';

class AirCursor extends StatelessWidget {
  const AirCursor({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cursorService = HandCursorService.instance;

    return Positioned.fill(
      child: ValueListenableBuilder<Offset?>(
        valueListenable: cursorService.cursorPosition,
        builder: (context, position, child) {
          if (position == null) {
            return const SizedBox.shrink();
          }

          return Stack(
            children: [
              Positioned(
                left: position.dx - 30,
                top: position.dy - 30,
                child: IgnorePointer(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber,
                      border: Border.all(
                        color: Colors.red,
                        width: 5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.ads_click,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 50,
                left: 20,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    color: Colors.black,
                    child: Text(
                      'AIR CURSOR: '
                          '${position.dx.toStringAsFixed(0)} , '
                          '${position.dy.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}