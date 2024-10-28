<p align="center">
<img src="https://github.com/chipweinberger/dart_melty_soundfont/blob/main/logo.png?raw=true" />
</p>

**dart_melty_soundfont** is a SoundFont synthesizer (i.e. '.sf2' player) written in pure Dart.

It is a port of MeltySynth (C#, MIT License) written by Nobuaki Tanaka, to Dart.

https://github.com/sinshu/meltysynth

## Dependencies

This package has no dependencies.

## Maintanence

This project was specifically designed to not require maintanence, in large part by not having any dependencies. Apart from breaking changes to the Dart language (rare), it should be solid code that works for decades. It will work on any Dart SDK sdk>=2.12 indefinitely. 

This package was written against Dart SDK 2.16.1.

## Example

Synthesize a simple chord:

```dart
// Necessary Imports
import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';
import 'package:flutter/services.dart' show rootBundle;

// load sf2
ByteData bytes = await rootBundle.load('assets/akai_steinway.sf2');

// Create the synthesizer.
Synthesizer synth = Synthesizer.loadByteData(bytes, 
    SynthesizerSettings(
        sampleRate: 44100, 
        blockSize: 64, 
        maximumPolyphony: 64, 
        enableReverbAndChorus: true,
    ));

// optional: print available instruments (aka presets)
List<Preset> p = synth.soundFont.presets;
for (int i = 0; i < p.length; i++) {
  String instrumentName = p[i].regions.isNotEmpty ? p[i].regions[0].instrument.name : "N/A";
  print('[preset $i] name: ${p[i].name} instrument: $instrumentName');
}

//  optional: select first instrument (aka preset)
synth.selectPreset(channel: 0, preset: 0);

// turn on some notes
synth.noteOn(channel: 0, key: 72, velocity: 120);
synth.noteOn(channel: 0, key: 76, velocity: 120);
synth.noteOn(channel: 0, key: 79, velocity: 120);
synth.noteOn(channel: 0, key: 82, velocity: 120);

// create a pcm buffer
ArrayInt16 buf16 = ArrayInt16.zeros(numShorts: 44100 * 3);

// render the waveform (1 second)
synth.renderMonoInt16(buf16);

// turn off a note
synth.noteOff(channel: 0, key: 72, velocity: 120);

// render another second
synth.renderMonoInt16(buf16);
```

Synthesize notes from a MIDI file playback:

```dart
// Necessary imports
import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';
import 'package:flutter/services.dart' show rootBundle;

// Load the soundfont file
ByteData bytes = await rootBundle.load('assets/akai_steinway.sf2');

// Create the synthesizer
Synthesizer synth = Synthesizer.loadByteData(bytes);

// Load MIDI file from asset
ByteData midiBytes = await rootBundle.load('assets/arabesque.mid');
MidiFile midiFile = MidiFile.fromByteData(midiBytes);

// Start MIDI playback
MidiFileSequencer sequencer = MidiFileSequencer(synth);
sequencer.play(midiFile, loop: false);

// Change the playback speed.
sequencer.speed = 1.5;

// Render 10 seconds of playback into PCM buffer
ArrayInt16 buf16 = ArrayInt16.zeros(numShorts: 44100 * 10);
synth.renderMonoInt16(buf16);

```


## Playing Sound

This library does not audibly make sound, it only generates the PCM waveform. 

To actually hear something, you need to pass the generated PCM waveform to your device's speakers using PCM.

See the [Example App](/example/lib/main.dart) for a **flutter_pcm_sound** + **dart_melty_soundfont** example.

## Isolates

It is recommended to do your audio rendering in isolates or using [`compute`](https://api.flutter.dev/flutter/foundation/compute.html). This will keep your UI fast & prevent audio stuttering. 

## Features

* No memory allocation in the rendering process.

* __Wave synthesis__
    - [x] SoundFont reader
    - [x] Waveform generator
    - [x] Envelope generator
    - [x] Low-pass filter
    - [x] Vibrato LFO
    - [x] Modulation LFO
* __MIDI message processing__
    - [x] Note on/off
    - [x] Bank selection
    - [x] Modulation
    - [x] Volume control
    - [x] Pan
    - [x] Expression
    - [x] Hold pedal
    - [x] Program change
    - [x] Pitch bend
    - [x] Tuning
* __Effects__
    - [x] Reverb
    - [x] Chorus
* __Other things__
    - [x] Standard MIDI file support
    - [x] Loop extension support
    - [x] Performance optimization

## License

DartMeltySoundFont is available under [the MIT license](LICENSE.txt).


## References

* __SoundFont&reg; Technical Specification__  
http://www.synthfont.com/SFSPEC21.PDF

* __Polyphone Soundfont Editor__  
Some of the test cases were generated with Polyphone.  
https://www.polyphone-soundfonts.com/

* __Freeverb by Jezar at Dreampoint__  
The implementation of the reverb effect is based on Freeverb.  
https://music.columbia.edu/pipermail/music-dsp/2001-October/045433.html
