// ignore_for_file: avoid_print

import 'dart:typed_data'; // for Uint8List

import 'package:dart_melty_soundfont/preset.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter/material.dart';
import 'package:raw_sound/raw_sound_player.dart';

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
  final _rawSound = RawSoundPlayer();

  Synthesizer? _synth;

  bool _soundFontLoaded = false;

  @override
  void initState() {
    super.initState();

    // DartMeltySoundfont
    _loadSoundfont().then((_) {
      _soundFontLoaded = true;
      setState(() {});
    });

    // RawSound
    _rawSound
        .initialize(
      bufferSize: 4096 << 4,
      nChannels: 1,
      sampleRate: sampleRate,
      pcmType: RawSoundPCMType.PCMI16,
    )
        .then((value) {
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

  void selectInstrumentPreset(int preset) {
    _synth!.processMidiMessage(
        channel: 0,
        command: 0xC0, // program change
        data1: _synth!.soundFont.presets[preset].patchNumber,
        data2: 0);

    _synth!.processMidiMessage(
      channel: 0,
      command: 0xB0, // control change
      data1: 0x00, // bank select
      data2: _synth!.soundFont.presets[preset].bankNumber,
    );
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

    // print available preset instruments
    List<Preset> p = _synth!.soundFont.presets;
    for (int i = 0; i < p.length; i++) {
      String instrumentName = p[i].regions.isNotEmpty ? p[i].regions[0].instrument.name : "N/A";
      print('[preset $i] name: ${p[i].name} instrument: $instrumentName');
    }

    // select preset (i.e. instrument)
    _synth!.selectPreset(channel: 0, preset: 0);

    // c major scale
    List<int> notes = [60, 62, 64, 65, 67, 69, 71, 72];
    int samplesPerNote = sampleRate ~/ 2;
    ArrayInt16 buf16 = ArrayInt16.zeros(numShorts: samplesPerNote * notes.length);
    for (int i = 0; i < notes.length; i++) {
      if (i > 0) {
        _synth!.noteOff(channel: 0, key: notes[i - 1]);
      }
      _synth!.noteOn(channel: 0, key: notes[i], velocity: 120);
      _synth!.renderMonoInt16(buf16, length: samplesPerNote, offset: samplesPerNote * i);
    }

    int seconds = (buf16.bytes.lengthInBytes / 2) ~/ sampleRate;
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
      child = Center(
        child: IconButton(
          icon: Icon(icon, color: Colors.black),
          onPressed: () => _rawSound.isPlaying ? _stop() : _play(),
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
