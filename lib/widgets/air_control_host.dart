import 'package:flutter/material.dart';

import '../services/air_control_engine.dart';

class AirControlHost extends StatefulWidget {
  const AirControlHost({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AirControlHost> createState() => _AirControlHostState();
}

class _AirControlHostState extends State<AirControlHost> {
  final AirControlEngine _engine =
      AirControlEngine.instance;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _engine.start();
    });
  }

  @override
  void dispose() {
    _engine.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}