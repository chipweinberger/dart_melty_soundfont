import 'dart:typed_data'; // for Uint8List

import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter/material.dart';
import 'package:raw_sound/raw_sound_player.dart';

import 'package:dart_melty_soundfont/preset.dart';
import 'package:dart_melty_soundfont/synthesizer.dart';
import 'package:dart_melty_soundfont/synthesizer_settings.dart';
import 'package:dart_melty_soundfont/audio_renderer_ex.dart';
import 'package:dart_melty_soundfont/array_int16.dart';


String asset = 'assets/akai_steinway.sf2';
int sampleRate = 44100;

void main() => runApp(const MeltyApp());

class MeltyApp extends StatefulWidget {
  const MeltyApp({Key? key}) : super(key: key);

  @override
  State<MeltyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MeltyApp> {

  final _rawSound = RawSoundPlayer();

  Synthesizer? _synth;

  bool _soundFontLoaded = false;

  @override
  void initState() {
    super.initState();

    // DartMeltySoundfont
    _loadSoundfont()
    .then((_) {
      _soundFontLoaded = true;
      setState(() {});
    });

    // RawSound
    _rawSound.initialize(
      bufferSize: 4096 << 4,
      nChannels: 1,
      sampleRate: sampleRate,
      pcmType: RawSoundPCMType.PCMI16,
    ).then((value) {
      setState(() {});
    });
  }

  Future<void> _loadSoundfont() async {
    ByteData bytes = await rootBundle.load(asset);
    _synth = Synthesizer.loadByteData(bytes, SynthesizerSettings());
    return Future<void>.value(null);
  }

  @override
  void dispose() {
    _rawSound.release();
    super.dispose();
  }

  Future<void> _play() async {
    if (_rawSound.isPlaying) {
      return;
    }

    // start playing audio
    await _rawSound.play();
    setState(() {});

    // turnOff all notes
    _synth!.noteOffAll();

    // turnOn some notes
    int ch = 0;
    for (Preset p in _synth!.soundFont.presets){
      // 0xC0 = Program Change
      _synth!.processMidiMessage(channel:ch % 16, command:0xC0, data1:p.patchNumber, data2:0);
      _synth!.noteOn(channel: ch % 16, key: 76, velocity: 120);
      ch++;
    }

    // feed 2 seconds of audio
    int seconds = 2;
    ArrayInt16 buf16 = ArrayInt16.zeros(numShorts: sampleRate * seconds);
    _synth!.renderMonoInt16(buf16);
    await _rawSound.feed(buf16.bytes.buffer.asUint8List());
    await Future.delayed(Duration(seconds: seconds));
    await _stop();
  }

  Future<void> _stop() async {
    if (_rawSound.isPlaying == false) {
        return;
    }
    await _rawSound.stop();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (!_rawSound.isInited || !_soundFontLoaded) {
      child = const Text("initializing...");
    } else {
      IconData icon = _rawSound.isPlaying ? Icons.stop : Icons.play_arrow;
      child = Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(icon, color: Colors.black),
                onPressed: () => _rawSound.isPlaying ? _stop() : _play(),
              ),
              const Text('Test PCMI16 (16-bit Integer)'),
            ],
          ),
        ],
      );
    }
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Day Selector')),
        body: child,
      )
    );
  }
}
