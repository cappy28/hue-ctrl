import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class SoundVisualizerWidget extends StatelessWidget {
  final SoundService sound;
  const SoundVisualizerWidget({super.key, required this.sound});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sound,
      builder: (_, __) {
        return SizedBox(
          height: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(sound.bars.length, (i) {
              final h = (sound.bars[i] * 38).clamp(3.0, 38.0);
              final hue = (i / sound.bars.length) * 280 + 180;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
