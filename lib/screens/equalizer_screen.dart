import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  static const _channel = MethodChannel('kr.ssing.catsong/media');
  static const _accent = AppTheme.fixedAccent;

  bool _isLoading = true;
  int _numBands = 0;
  int _minLevel = -1500;
  int _maxLevel = 1500;
  List<Map<String, dynamic>> _bands = [];
  List<String> _presets = [];
  int _selectedPreset = -1;
  double _bassBoostStrength = 0;
  double _virtualizerStrength = 0;

  @override
  void initState() {
    super.initState();
    _initEqualizer();
  }

  Future<void> _initEqualizer() async {
    try {
      final playerProvider = context.read<PlayerProvider>();
      final audioSessionId = await playerProvider.player.androidAudioSessionId;

      final result = await _channel.invokeMethod('initEqualizer', {
        'audioSessionId': audioSessionId ?? 0,
      });

      int bassStrength = 0;
      int virtStrength = 0;
      try {
        bassStrength = await _channel.invokeMethod('initBassBoost', {
          'audioSessionId': audioSessionId ?? 0,
        });
      } catch (e) {}
      try {
        virtStrength = await _channel.invokeMethod('initVirtualizer', {
          'audioSessionId': audioSessionId ?? 0,
        });
      } catch (e) {}

      setState(() {
        _numBands = result['numBands'] as int;
        _minLevel = result['minLevel'] as int;
        _maxLevel = result['maxLevel'] as int;
        _bands = (result['bands'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _presets = (result['presets'] as List).map((e) => e.toString()).toList();
        _bassBoostStrength = (bassStrength as int).toDouble();
        _virtualizerStrength = (virtStrength as int).toDouble();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatFreq(int hz) {
    if (hz >= 1000000) return '${(hz / 1000000).toStringAsFixed(0)}kHz';
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(0)}Hz';
    return '${hz}Hz';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.equalizer,
            style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: _accent, size: 20),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : SingleChildScrollView(
        child: Column(
          children: [
            // Preset selection
            if (_presets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.preset,
                        style: const TextStyle(
                            color: _accent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_presets.length, (index) {
                          final isSelected = _selectedPreset == index;
                          return GestureDetector(
                            onTap: () async {
                              await _channel.invokeMethod(
                                  'setEqualizerPreset', {'preset': index});
                              setState(() => _selectedPreset = index);
                              try {
                                for (int i = 0; i < _bands.length; i++) {
                                  final result = await _channel.invokeMethod(
                                      'getEqualizerBandLevel', {'band': i});
                                  setState(() {
                                    _bands[i]['level'] = result as int;
                                  });
                                }
                              } catch (e) {
                                await _initEqualizer();
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _accent
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? _accent
                                      : const Color(0xFFE5E5E5),
                                ),
                              ),
                              child: Text(
                                _presets[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black54,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(color: Color(0xFFE5E5E5)),

            // Band sliders
            SizedBox(
              height: 280,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(_bands.length, (index) {
                    final band = _bands[index];
                    final level = band['level'] as int;
                    final freq = band['freq'] as int;

                    return Column(
                      children: [
                        Text(
                          '${level > 0 ? '+' : ''}${(level / 100).toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: _accent, fontSize: 11),
                        ),
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: _accent,
                                inactiveTrackColor: _accent.withOpacity(0.15),
                                thumbColor: _accent,
                                overlayColor: _accent.withOpacity(0.1),
                              ),
                              child: Slider(
                                value: level.toDouble(),
                                min: _minLevel.toDouble(),
                                max: _maxLevel.toDouble(),
                                onChanged: (value) async {
                                  setState(() {
                                    _bands[index]['level'] = value.toInt();
                                    _selectedPreset = -1;
                                  });
                                  await _channel.invokeMethod(
                                      'setEqualizerBand', {
                                    'band': index,
                                    'level': value.toInt(),
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        Text(
                          _formatFreq(freq),
                          style: const TextStyle(
                              color: Colors.black45, fontSize: 10),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),

            const Divider(color: Color(0xFFE5E5E5)),

            // Bass Booster
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speaker, color: _accent, size: 16),
                      const SizedBox(width: 6),
                      Text(AppLocalizations.of(context)!.bassBooster,
                          style: const TextStyle(
                              color: _accent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(
                        '${(_bassBoostStrength / 10).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: _accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(AppLocalizations.of(context)!.enhancesBass,
                      style: const TextStyle(
                          color: Colors.black45, fontSize: 11)),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _accent,
                      inactiveTrackColor: _accent.withOpacity(0.15),
                      thumbColor: _accent,
                      overlayColor: _accent.withOpacity(0.1),
                    ),
                    child: Slider(
                      value: _bassBoostStrength,
                      min: 0,
                      max: 1000,
                      onChanged: (value) async {
                        setState(() => _bassBoostStrength = value);
                        await _channel.invokeMethod('setBassBoost', {
                          'strength': value.toInt(),
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Virtualizer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.surround_sound, color: _accent, size: 16),
                      const SizedBox(width: 6),
                      Text(AppLocalizations.of(context)!.virtualizer,
                          style: const TextStyle(
                              color: _accent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(
                        '${(_virtualizerStrength / 10).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: _accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(AppLocalizations.of(context)!.surroundEffect,
                      style: const TextStyle(
                          color: Colors.black45, fontSize: 11)),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _accent,
                      inactiveTrackColor: _accent.withOpacity(0.15),
                      thumbColor: _accent,
                      overlayColor: _accent.withOpacity(0.1),
                    ),
                    child: Slider(
                      value: _virtualizerStrength,
                      min: 0,
                      max: 1000,
                      onChanged: (value) async {
                        setState(() => _virtualizerStrength = value);
                        await _channel.invokeMethod('setVirtualizer', {
                          'strength': value.toInt(),
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Reset button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  for (int i = 0; i < _bands.length; i++) {
                    await _channel.invokeMethod('setEqualizerBand', {
                      'band': i,
                      'level': 0,
                    });
                  }
                  await _channel.invokeMethod('setBassBoost', {'strength': 0});
                  await _channel.invokeMethod('setVirtualizer', {'strength': 0});
                  setState(() {
                    for (var band in _bands) {
                      band['level'] = 0;
                    }
                    _selectedPreset = -1;
                    _bassBoostStrength = 0;
                    _virtualizerStrength = 0;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(AppLocalizations.of(context)!.reset,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel.invokeMethod('releaseEqualizer');
    _channel.invokeMethod('releaseAudioEffects');
    super.dispose();
  }
}