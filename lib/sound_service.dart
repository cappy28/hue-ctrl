import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

class SoundService extends ChangeNotifier {
  NoiseMeter?           _noiseMeter;
  StreamSubscription?   _sub;
  double                _level    = 0;
  bool                  _active   = false;
  final List<double>    _bars     = List.filled(24, 0);
  Function(double)?     onLevel;

  bool         get active => _active;
  double       get level  => _level;
  List<double> get bars   => _bars;

  Future<bool> start() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return false;
    _noiseMeter = NoiseMeter();
    _sub = _noiseMeter!.noise.listen((NoiseReading reading) {
      final db = reading.meanDecibel.clamp(30.0, 100.0);
      _level = (db - 30) / 70.0; // normalize 0..1
      // Fake frequency bars based on level with variation
      for (int i = 0; i < _bars.length; i++) {
        final freq = _level * (0.5 + 0.5 * (i / _bars.length));
        _bars[i] = (freq + (i % 3 == 0 ? _level * 0.3 : 0)).clamp(0.0, 1.0);
      }
      onLevel?.call(_level);
      notifyListeners();
    });
    _active = true;
    notifyListeners();
    return true;
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _active = false;
    _level = 0;
    for (int i = 0; i < _bars.length; i++) { _bars[i] = 0; }
    notifyListeners();
  }
}
