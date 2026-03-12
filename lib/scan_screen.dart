import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/hue_service.dart';
import '../models/app_theme.dart';
import 'home_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  List<ScanResult> _results = [];
  bool             _scanning = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  Future<void> _startScan() async {
    // Request permissions
    await [Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();

    setState(() { _scanning = true; _results = []; });

    FlutterBluePlus.startScan(
      withServices: [Guid('932c32bd-0000-47a2-835a-a8d455b859dd')],
      timeout: const Duration(seconds: 8),
    );

    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) setState(() => _results = results);
    });

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _scanning = false);
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    final svc = context.read<HueService>();
    final ok = await svc.connect(device);
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Logo
              Text('HUE', style: GoogleFonts.orbitron(
                fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white,
                shadows: [Shadow(color: AppTheme.accent.withOpacity(0.8), blurRadius: 30)],
              )),
              Text('CTRL', style: GoogleFonts.orbitron(
                fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.accent,
                shadows: [Shadow(color: AppTheme.accent, blurRadius: 40)],
              )),
              const SizedBox(height: 4),
              Text('PHILIPS HUE BLUETOOTH · 9.27',
                style: GoogleFonts.orbitron(fontSize: 9, color: AppTheme.textDim, letterSpacing: 3)),

              const SizedBox(height: 48),

              // Scan button
              GestureDetector(
                onTap: _scanning ? null : _startScan,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) {
                    return Container(
                      width: double.infinity, height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _scanning
                            ? AppTheme.accent.withOpacity(0.5 + 0.5 * _pulse.value)
                            : AppTheme.accent,
                        ),
                        color: _scanning ? AppTheme.accent.withOpacity(0.08) : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          _scanning ? 'RECHERCHE EN COURS...' : 'SCANNER LES AMPOULES',
                          style: GoogleFonts.orbitron(
                            color: AppTheme.accent, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              if (_scanning)
                LinearProgressIndicator(
                  color: AppTheme.accent,
                  backgroundColor: AppTheme.border,
                ),

              const SizedBox(height: 16),

              // Results
              Expanded(
                child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _scanning ? 'Recherche des ampoules Philips Hue...' : 'Appuie sur SCANNER pour détecter tes ampoules',
                        style: GoogleFonts.rajdhani(color: AppTheme.textDim, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = _results[i];
                        return GestureDetector(
                          onTap: () => _connect(r.device),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.panel,
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Text('💡', style: TextStyle(fontSize: 24)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.device.platformName.isNotEmpty ? r.device.platformName : 'Hue Bulb',
                                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 13, letterSpacing: 2),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(r.device.remoteId.toString(),
                                        style: GoogleFonts.rajdhani(color: AppTheme.textDim, fontSize: 11, letterSpacing: 1)),
                                    ],
                                  ),
                                ),
                                Column(children: [
                                  Text('${r.rssi} dBm', style: GoogleFonts.orbitron(color: AppTheme.accent, fontSize: 10)),
                                  const Icon(Icons.chevron_right, color: AppTheme.accent),
                                ]),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
