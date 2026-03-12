import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// ── Philips Hue Bluetooth UUIDs ──
const String kHueService      = '932c32bd-0000-47a2-835a-a8d455b859dd';
const String kCharPower       = '932c32bd-0002-47a2-835a-a8d455b859dd';
const String kCharBrightness  = '932c32bd-0003-47a2-835a-a8d455b859dd';
const String kCharColorTemp   = '932c32bd-0004-47a2-835a-a8d455b859dd';
const String kCharColorXY     = '932c32bd-0005-47a2-835a-a8d455b859dd';

enum HueEffect { none, gyrophare, sound, veilleuse, party, aurora, strobe, candle }

class HueService extends ChangeNotifier {
  BluetoothDevice?         _device;
  BluetoothCharacteristic? _charPower;
  BluetoothCharacteristic? _charBri;
  BluetoothCharacteristic? _charCT;
  BluetoothCharacteristic? _charXY;

  bool        _connected  = false;
  bool        _isOn       = true;
  int         _brightness = 200;
  int         _colorTemp  = 300;
  Color       _color      = const Color(0xFFFFCC88);
  HueEffect   _effect     = HueEffect.none;
  String      _statusMsg  = 'Non connecté';

  Timer?  _effectTimer;
  int     _effectStep = 0;

  bool      get connected  => _connected;
  bool      get isOn       => _isOn;
  int       get brightness => _brightness;
  int       get colorTemp  => _colorTemp;
  Color     get color      => _color;
  HueEffect get effect     => _effect;
  String    get statusMsg  => _statusMsg;

  // ── SCAN & CONNECT ──
  Future<List<ScanResult>> scan() async {
    List<ScanResult> results = [];
    await FlutterBluePlus.startScan(
      withServices: [Guid(kHueService)],
      timeout: const Duration(seconds: 8),
    );
    await for (final r in FlutterBluePlus.scanResults) {
      results = r;
      notifyListeners();
    }
    return results;
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      _statusMsg = 'Connexion à ${device.platformName}...';
      notifyListeners();
      await device.connect(autoConnect: false);
      _device = device;

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connected = false;
          _statusMsg = 'Déconnecté';
          notifyListeners();
        }
      });

      final services = await device.discoverServices();
      for (final s in services) {
        if (s.uuid.toString().startsWith('932c32bd-0000')) {
          for (final c in s.characteristics) {
            final u = c.uuid.toString();
            if (u.contains('0002')) _charPower = c;
            if (u.contains('0003')) _charBri   = c;
            if (u.contains('0004')) _charCT    = c;
            if (u.contains('0005')) _charXY    = c;
          }
        }
      }
      _connected = true;
      _statusMsg = 'Connecté · ${device.platformName}';
      notifyListeners();
      return true;
    } catch (e) {
      _statusMsg = 'Erreur: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    stopEffect();
    await _device?.disconnect();
    _connected = false;
    _statusMsg = 'Déconnecté';
    notifyListeners();
  }

  // ── WRITE HELPERS ──
  Future<void> _write(BluetoothCharacteristic? c, List<int> data) async {
    if (c == null) return;
    try { await c.write(data, withoutResponse: true); } catch (_) {}
  }

  // ── CONTROLS ──
  Future<void> setPower(bool on) async {
    _isOn = on;
    await _write(_charPower, [on ? 1 : 0]);
    _statusMsg = on ? 'Allumé' : 'Éteint';
    notifyListeners();
  }

  Future<void> setBrightness(int val) async {
    _brightness = val.clamp(1, 254);
    await _write(_charBri, [_brightness]);
    notifyListeners();
  }

  Future<void> setColorTemp(int mirek) async {
    _colorTemp = mirek.clamp(153, 500);
    final hi = _colorTemp >> 8;
    final lo = _colorTemp & 0xff;
    await _write(_charCT, [hi, lo]);
    // Visual color approximation
    final t = (_colorTemp - 153) / (500 - 153);
    final r = 255;
    final g = (200 + 55 * (1 - t)).round();
    final b = (255 * (1 - t * 0.8)).round();
    _color = Color.fromARGB(255, r, g, b);
    notifyListeners();
  }

  Future<void> setColor(Color c) async {
    _color = c;
    final xy = _rgbToXY(c.red, c.green, c.blue);
    final x16 = (xy[0] * 65535).round();
    final y16 = (xy[1] * 65535).round();
    await _write(_charXY, [
      (x16 >> 8) & 0xff, x16 & 0xff,
      (y16 >> 8) & 0xff, y16 & 0xff,
    ]);
    notifyListeners();
  }

  // ── EFFECTS ──
  void toggleEffect(HueEffect e) {
    if (_effect == e) { stopEffect(); return; }
    stopEffect();
    _effect = e;
    notifyListeners();
    switch (e) {
      case HueEffect.gyrophare: _startGyrophare(); break;
      case HueEffect.veilleuse: _startVeilleuse(); break;
      case HueEffect.party:     _startParty();     break;
      case HueEffect.aurora:    _startAurora();    break;
      case HueEffect.strobe:    _startStrobe();    break;
      case HueEffect.candle:    _startCandle();    break;
      default: break;
    }
  }

  void stopEffect() {
    _effectTimer?.cancel();
    _effectTimer = null;
    _effect = HueEffect.none;
    _effectStep = 0;
    notifyListeners();
  }

  void _startGyrophare() {
    setPower(true);
    _effectTimer = Timer.periodic(const Duration(milliseconds: 400), (_) async {
      final c = _effectStep % 2 == 0
          ? const Color(0xFFFF0000)
          : const Color(0xFF0044FF);
      _effectStep++;
      _color = c;
      notifyListeners();
      await setColor(c);
    });
  }

  void _startVeilleuse() {
    setPower(true);
    setBrightness(15);
    setColor(const Color(0xFFFF6600));
  }

  void _startParty() {
    final colors = [
      const Color(0xFFFF0000), const Color(0xFFFF8800),
      const Color(0xFFFFFF00), const Color(0xFF00FF00),
      const Color(0xFF0088FF), const Color(0xFFFF00FF),
      const Color(0xFF00FFFF), const Color(0xFFFF0088),
    ];
    setPower(true);
    _effectTimer = Timer.periodic(const Duration(milliseconds: 280), (_) async {
      final c = colors[_effectStep % colors.length];
      _effectStep++;
      _color = c;
      notifyListeners();
      await setColor(c);
    });
  }

  void _startAurora() {
    final steps = [
      [const Color(0xFF00FFCC), 180],
      [const Color(0xFF0088FF), 200],
      [const Color(0xFF8800FF), 230],
      [const Color(0xFFFF00CC), 200],
      [const Color(0xFF00FFFF), 180],
      [const Color(0xFF0044FF), 220],
    ];
    setPower(true);
    _effectTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) async {
      final step = steps[_effectStep % steps.length];
      _effectStep++;
      final c   = step[0] as Color;
      final bri = step[1] as int;
      _color = c;
      notifyListeners();
      await setColor(c);
      await setBrightness(bri);
    });
  }

  void _startStrobe() {
    setPower(true);
    _effectTimer = Timer.periodic(const Duration(milliseconds: 80), (_) async {
      final on = _effectStep % 2 == 0;
      _effectStep++;
      await _write(_charPower, [on ? 1 : 0]);
    });
  }

  void _startCandle() {
    final rng = Random();
    setPower(true);
    setColor(const Color(0xFFFF8C00));
    _effectTimer = Timer.periodic(const Duration(milliseconds: 150), (_) async {
      final bri = 100 + rng.nextInt(100);
      await setBrightness(bri);
      final r = 255;
      final g = 100 + rng.nextInt(60);
      final b = rng.nextInt(20);
      final c = Color.fromARGB(255, r, g, b);
      _color = c;
      notifyListeners();
      await setColor(c);
    });
  }

  // ── SCENES ──
  Future<void> applyScene(HueScene scene) async {
    stopEffect();
    setPower(true);
    await Future.delayed(const Duration(milliseconds: 50));
    await setBrightness(scene.brightness);
    if (scene.colorTemp != null) {
      await setColorTemp(scene.colorTemp!);
    } else if (scene.color != null) {
      await setColor(scene.color!);
    }
    _statusMsg = scene.label;
    notifyListeners();
  }

  // ── COLOR MATH ──
  List<double> _rgbToXY(int r, int g, int b) {
    double rL = r / 255.0;
    double gL = g / 255.0;
    double bL = b / 255.0;
    rL = rL > 0.04045 ? pow((rL + 0.055) / 1.055, 2.4).toDouble() : rL / 12.92;
    gL = gL > 0.04045 ? pow((gL + 0.055) / 1.055, 2.4).toDouble() : gL / 12.92;
    bL = bL > 0.04045 ? pow((bL + 0.055) / 1.055, 2.4).toDouble() : bL / 12.92;
    final X = rL * 0.664511 + gL * 0.154324 + bL * 0.162028;
    final Y = rL * 0.283881 + gL * 0.668433 + bL * 0.047685;
    final Z = rL * 0.000088 + gL * 0.072310 + bL * 0.986039;
    final s = X + Y + Z;
    if (s == 0) return [0, 0];
    return [X / s, Y / s];
  }

  // ── SOUND REACTIVE (called externally with amplitude 0..1) ──
  void onSoundLevel(double level) {
    if (_effect != HueEffect.sound) return;
    final bri = (level * 254).clamp(10, 254).toInt();
    final hue = (_effectStep * 8) % 360;
    _effectStep++;
    final c = HSVColor.fromAHSV(1, hue.toDouble(), 1, 1).toColor();
    _color = c;
    notifyListeners();
    _write(_charBri, [bri]);
    final xy = _rgbToXY(c.red, c.green, c.blue);
    final x16 = (xy[0] * 65535).round();
    final y16 = (xy[1] * 65535).round();
    _write(_charXY, [(x16>>8)&0xff, x16&0xff, (y16>>8)&0xff, y16&0xff]);
  }
}

// ── SCENE MODEL ──
class HueScene {
  final String label;
  final String icon;
  final int    brightness;
  final int?   colorTemp;
  final Color? color;
  const HueScene({required this.label, required this.icon, required this.brightness, this.colorTemp, this.color});
}

const kScenes = [
  HueScene(label:'Cinéma',     icon:'🎬', brightness:30,  color:Color(0xFFFF2200)),
  HueScene(label:'Lecture',    icon:'📖', brightness:220, colorTemp:200),
  HueScene(label:'Focus',      icon:'🧠', brightness:254, colorTemp:160),
  HueScene(label:'Romantique', icon:'💖', brightness:60,  color:Color(0xFFFF6080)),
  HueScene(label:'Gaming',     icon:'🎮', brightness:180, color:Color(0xFF39FF14)),
  HueScene(label:'Réveil',     icon:'☀️', brightness:10,  colorTemp:220),
];
