import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/hue_service.dart';
import '../services/sound_service.dart';
import '../models/app_theme.dart';
import '../widgets/bulb_widget.dart';
import '../widgets/sound_viz.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SoundService _sound = SoundService();

  static const _palette = [
    Color(0xFFFF0000), Color(0xFFFF4500), Color(0xFFFF8C00), Color(0xFFFFD700),
    Color(0xFFFFFFFF), Color(0xFFE0F0FF), Color(0xFF00E5FF), Color(0xFF0080FF),
    Color(0xFF8000FF), Color(0xFFFF00FF), Color(0xFFFF1493), Color(0xFF00FF88),
    Color(0xFF00FF00), Color(0xFF39FF14), Color(0xFFFF6600), Color(0xFFFF69B4),
  ];

  @override
  void initState() {
    super.initState();
    _sound.onLevel = (level) {
      context.read<HueService>().onSoundLevel(level);
    };
  }

  @override
  void dispose() { _sound.stop(); super.dispose(); }

  void _toggleSound(HueService hue) async {
    if (hue.effect == HueEffect.sound) {
      _sound.stop();
      hue.stopEffect();
    } else {
      final ok = await _sound.start();
      if (ok) {
        hue.toggleEffect(HueEffect.sound);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission micro refusée', style: GoogleFonts.rajdhani())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hue = context.watch<HueService>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // Grid bg
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // Gyrophare flash overlay
          if (hue.effect == HueEffect.gyrophare)
            _GyrophareOverlay(color: hue.color),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(hue),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    child: Column(
                      children: [
                        _buildBulbs(hue),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: _buildControlPanel(hue)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildColorPanel(hue)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _buildEffectsPanel(hue)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildScenesPanel(hue)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status bar bottom
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildStatusBar(hue),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(HueService hue) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RichText(text: TextSpan(children: [
              TextSpan(text: 'HUE', style: GoogleFonts.orbitron(
                fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white,
                shadows: [Shadow(color: AppTheme.accent.withOpacity(0.6), blurRadius: 20)],
              )),
              TextSpan(text: 'CTRL', style: GoogleFonts.orbitron(
                fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.accent,
                shadows: [const Shadow(color: AppTheme.accent, blurRadius: 30)],
              )),
            ])),
            Text('9.27 BLUETOOTH', style: GoogleFonts.orbitron(fontSize: 8, color: AppTheme.textDim, letterSpacing: 3)),
          ]),
          const Spacer(),
          GestureDetector(
            onTap: () {
              hue.disconnect();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ScanScreen()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: hue.connected ? const Color(0xFF00FF88) : AppTheme.textDim),
                color: hue.connected ? const Color(0xFF00FF88).withOpacity(0.08) : Colors.transparent,
              ),
              child: Text(
                hue.connected ? '✓ CONNECTÉ' : 'DÉCONNECTÉ',
                style: GoogleFonts.orbitron(
                  fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w700,
                  color: hue.connected ? const Color(0xFF00FF88) : AppTheme.textDim,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulbs(HueService hue) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BulbWidget(color: hue.color, isOn: hue.isOn, brightness: hue.brightness / 254, label: 'AMPOULE 1'),
          const SizedBox(width: 48),
          BulbWidget(color: hue.color, isOn: hue.isOn, brightness: hue.brightness / 254, label: 'AMPOULE 2'),
        ],
      ),
    );
  }

  Widget _buildControlPanel(HueService hue) {
    return _Panel(
      accentColor: const Color(0xFF00FF88),
      title: '⚡ CONTRÔLE',
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _NeonButton(
              label: 'ON', color: const Color(0xFF00FF88),
              onTap: () => hue.setPower(true),
            )),
            const SizedBox(width: 8),
            Expanded(child: _NeonButton(
              label: 'OFF', color: AppTheme.accentR,
              onTap: () => hue.setPower(false),
            )),
          ]),
          const SizedBox(height: 14),
          _SliderRow(
            label: 'Luminosité',
            value: hue.brightness.toDouble(),
            min: 1, max: 254,
            display: '${(hue.brightness / 254 * 100).round()}%',
            color: AppTheme.accent,
            onChanged: (v) => hue.setBrightness(v.round()),
          ),
          const SizedBox(height: 10),
          _SliderRow(
            label: 'Température',
            value: hue.colorTemp.toDouble(),
            min: 153, max: 500,
            display: _ctLabel(hue.colorTemp),
            color: const Color(0xFFFF8C00),
            onChanged: (v) => hue.setColorTemp(v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPanel(HueService hue) {
    return _Panel(
      accentColor: AppTheme.accentR,
      title: '🎨 COULEUR',
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, crossAxisSpacing: 5, mainAxisSpacing: 5,
            ),
            itemCount: _palette.length,
            itemBuilder: (_, i) {
              final c = _palette[i];
              final sel = hue.color == c;
              return GestureDetector(
                onTap: () => hue.setColor(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: c, borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: sel ? Colors.white : Colors.transparent,
                      width: sel ? 2 : 0,
                    ),
                    boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.6), blurRadius: 8)] : [],
                  ),
                  transform: sel ? (Matrix4.identity()..scale(1.15)) : Matrix4.identity(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _showColorPicker(hue),
            child: Container(
              height: 36, width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0xFFFF0000), const Color(0xFFFFFF00),
                  const Color(0xFF00FF00), const Color(0xFF00FFFF),
                  const Color(0xFF0000FF), const Color(0xFFFF00FF),
                ]),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(child: Text('COULEUR PERSO',
                style: GoogleFonts.orbitron(fontSize: 9, color: Colors.white, letterSpacing: 2,
                  shadows: [const Shadow(color: Colors.black, blurRadius: 6)]))),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(HueService hue) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.panel,
        title: Text('Couleur personnalisée', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14)),
        content: ColorPicker(
          pickerColor: hue.color,
          onColorChanged: hue.setColor,
          labelTypes: const [],
          pickerAreaHeightPercent: 0.7,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.orbitron(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildEffectsPanel(HueService hue) {
    return _Panel(
      accentColor: AppTheme.accentP,
      title: '✨ EFFETS',
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, childAspectRatio: 2.2,
            crossAxisSpacing: 6, mainAxisSpacing: 6,
            children: [
              _EffectBtn(icon: '🚨', label: 'Gyrophare', effect: HueEffect.gyrophare,
                activeColor: AppTheme.accentR, current: hue.effect,
                onTap: () => hue.toggleEffect(HueEffect.gyrophare)),
              _EffectBtn(icon: '🎵', label: 'Réactif son', effect: HueEffect.sound,
                activeColor: const Color(0xFFA855F7), current: hue.effect,
                onTap: () => _toggleSound(hue)),
              _EffectBtn(icon: '🌙', label: 'Veilleuse', effect: HueEffect.veilleuse,
                activeColor: const Color(0xFFF97316), current: hue.effect,
                onTap: () => hue.toggleEffect(HueEffect.veilleuse)),
              _EffectBtn(icon: '🎉', label: 'Party', effect: HueEffect.party,
                activeColor: const Color(0xFF22C55E), current: hue.effect,
                onTap: () => hue.toggleEffect(HueEffect.party)),
              _EffectBtn(icon: '🌈', label: 'Aurora', effect: HueEffect.aurora,
                activeColor: const Color(0xFF06B6D4), current: hue.effect,
                onTap: () => hue.toggleEffect(HueEffect.aurora)),
              _EffectBtn(icon: '⚡', label: 'Strobe', effect: HueEffect.strobe,
                activeColor: const Color(0xFFEAB308), current: hue.effect,
                onTap: () => hue.toggleEffect(HueEffect.strobe)),
              _EffectBtn(icon: '🕯️', label: 'Bougie', effect: HueEffect.candle,
                activeColor: const Color(0xFFFF8C00), current: hue.effect,
                onTap: () => hue.toggleEffect(HueEffect.candle)),
              _EffectBtn(icon: '⏹', label: 'Arrêter', effect: HueEffect.none,
                activeColor: AppTheme.textDim, current: HueEffect.none,
                onTap: hue.stopEffect),
            ],
          ),
          if (hue.effect == HueEffect.sound) ...[
            const SizedBox(height: 10),
            SoundVisualizerWidget(sound: _sound),
          ],
        ],
      ),
    );
  }

  Widget _buildScenesPanel(HueService hue) {
    return _Panel(
      accentColor: const Color(0xFF06B6D4),
      title: '🌟 SCÈNES',
      child: GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2, childAspectRatio: 1.6,
        crossAxisSpacing: 6, mainAxisSpacing: 6,
        children: kScenes.map((s) => GestureDetector(
          onTap: () => hue.applyScene(s),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              color: Colors.transparent,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(s.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 3),
              Text(s.label, style: GoogleFonts.rajdhani(
                color: AppTheme.textDim, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1,
              ), textAlign: TextAlign.center),
            ]),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildStatusBar(HueService hue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xF0050508),
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hue.connected ? const Color(0xFF00FF88) : const Color(0xFF444444),
            boxShadow: hue.connected ? [const BoxShadow(color: Color(0xFF00FF88), blurRadius: 8)] : [],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(hue.statusMsg.toUpperCase(),
          style: GoogleFonts.orbitron(fontSize: 9, color: AppTheme.textDim, letterSpacing: 2))),
      ]),
    );
  }

  String _ctLabel(int ct) {
    if (ct < 180) return 'Lumière du jour';
    if (ct < 250) return 'Blanc froid';
    if (ct < 350) return 'Blanc neutre';
    if (ct < 430) return 'Blanc chaud';
    return 'Très chaud';
  }
}

// ── REUSABLE WIDGETS ──

class _Panel extends StatelessWidget {
  final Color  accentColor;
  final String title;
  final Widget child;
  const _Panel({required this.accentColor, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 2, decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.transparent, accentColor, Colors.transparent]),
        )),
        const SizedBox(height: 12),
        Text(title, style: GoogleFonts.orbitron(fontSize: 9, color: AppTheme.textDim, letterSpacing: 3)),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class _NeonButton extends StatelessWidget {
  final String label;
  final Color  color;
  final VoidCallback onTap;
  const _NeonButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44, alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: color)),
        child: Text(label, style: GoogleFonts.orbitron(
          color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 3,
        )),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String   label;
  final double   value, min, max;
  final String   display;
  final Color    color;
  final Function(double) onChanged;
  const _SliderRow({required this.label, required this.value, required this.min, required this.max,
    required this.display, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.rajdhani(color: AppTheme.textDim, fontSize: 12, fontWeight: FontWeight.w600)),
        Text(display, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 10)),
      ]),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          thumbColor: color, activeTrackColor: color,
          inactiveTrackColor: AppTheme.border, trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          overlayShape: SliderComponentShape.noOverlay,
        ),
        child: Slider(value: value, min: min, max: max, onChanged: onChanged),
      ),
    ]);
  }
}

class _EffectBtn extends StatelessWidget {
  final String     icon, label;
  final HueEffect  effect, current;
  final Color      activeColor;
  final VoidCallback onTap;
  const _EffectBtn({required this.icon, required this.label, required this.effect,
    required this.current, required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = current == effect && effect != HueEffect.none;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(color: active ? activeColor : AppTheme.border),
          color: active ? activeColor.withOpacity(0.08) : Colors.transparent,
          boxShadow: active ? [BoxShadow(color: activeColor.withOpacity(0.2), blurRadius: 12)] : [],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.rajdhani(
            color: active ? activeColor : AppTheme.textDim,
            fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1,
          )),
        ]),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x07FFFFFF)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _GyrophareOverlay extends StatefulWidget {
  final Color color;
  const _GyrophareOverlay({required this.color});
  @override State<_GyrophareOverlay> createState() => _GyrophareOverlayState();
}
class _GyrophareOverlayState extends State<_GyrophareOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..repeat(reverse: true);
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Positioned.fill(
        child: IgnorePointer(
          child: Container(
            color: (_c.value > 0.5 ? const Color(0xFFFF0000) : const Color(0xFF0044FF))
              .withOpacity(0.07),
          ),
        ),
      ),
    );
  }
}
