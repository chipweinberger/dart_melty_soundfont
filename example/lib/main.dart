// ignore_for_file: avoid_print

import 'dart:typed_data'; // for Uint8List

import 'package:dart_melty_soundfont/preset.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter/material.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

import 'package:dart_melty_soundfont/synthesizer.dart';
import 'package:dart_melty_soundfont/synthesizer_settings.dart';
import 'package:dart_melty_soundfont/audio_renderer_ex.dart';
import 'package:dart_melty_soundfont/array_int16.dart';

String asset = 'assets/TimGM6mbEdit.sf2';
int sampleRate = 44100;

void main() => runApp(const MeltyApp());

class MeltyApp extends StatefulWidget {
  const MeltyApp({Key? key}) : super(key: key);

  @override
  State<MeltyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MeltyApp> {
  Synthesizer? _synth;

  bool _isPlaying = false;
  bool _pcmSoundLoaded = false;
  bool _soundFontLoaded = false;
  int _remainingFrames = 0;
  int _fedCount = 0;
  int _prevNote = 0;

  @override
  void initState() {
    super.initState();

    // DartMeltySoundfont
    _loadSoundfont().then((_) {
      _soundFontLoaded = true;
      setState(() {});
    });

    // FlutterPcmSound
    _loadPcmSound().then((_) {
      _pcmSoundLoaded = true;
      setState(() {});
    });
  }

  Future<void> _loadPcmSound() async {
    FlutterPcmSound.setFeedCallback(onFeed);
    await FlutterPcmSound.setLogLevel(LogLevel.standard);
    await FlutterPcmSound.setFeedThreshold(8000);
    await FlutterPcmSound.setup(sampleRate: sampleRate, channelCount: 1);
  }

  Future<void> _loadSoundfont() async {
    ByteData bytes = await rootBundle.load(asset);
    _synth = Synthesizer.loadByteData(bytes, SynthesizerSettings());

    // print available instruments
    List<Preset> p = _synth!.soundFont.presets;
    for (int i = 0; i < p.length; i++) {
      String instrumentName =
          p[i].regions.isNotEmpty ? p[i].regions[0].instrument.name : "N/A";
      print('[preset $i] name: ${p[i].name} instrument: $instrumentName');
    }

    return Future<void>.value(null);
  }

  @override
  void dispose() {
    FlutterPcmSound.release();
    super.dispose();
  }

  void onFeed(int remainingFrames) async {
    setState(() {
      _remainingFrames = remainingFrames;
    });
    // c major scale
    List<int> notes = [60, 62, 64, 65, 67, 69, 71, 72];
    int step = (_fedCount ~/ 16) % notes.length;
    int curNote = notes[step];
    if (curNote != _prevNote) {
      _synth!.noteOff(channel: 0, key: _prevNote);
      _synth!.noteOn(channel: 0, key: curNote, velocity: 120);
    }
    ArrayInt16 buf16 = ArrayInt16.zeros(numShorts: 1000);
    _synth!.renderMonoInt16(buf16);
    await FlutterPcmSound.feed(PcmArrayInt16(bytes: buf16.bytes));
    _fedCount++;
    _prevNote = curNote;
  }

  Future<void> _play() async {
    // start playing audio
    await FlutterPcmSound.play();

    setState(() {
      _isPlaying = true;
    });

    // turnOff all notes
    _synth!.noteOffAll();

    // select preset (i.e. instrument)
    _synth!.selectPreset(channel: 0, preset: 0);
  }

  Future<void> _pause() async {
    await FlutterPcmSound.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (!_pcmSoundLoaded || !_soundFontLoaded) {
      child = const Text("initializing...");
    } else {
      child = Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                child: Text(_isPlaying ? "Pause" : "Play"),
                onPressed: () => _isPlaying ? _pause() : _play(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Remaining Frames $_remainingFrames"),
            )
          ],
        ),
      );
    }
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(title: const Text('Soundfont')),
      body: child,
    ));
  }
}
