# DartMeltySoundFont

DartMeltySoundFont is a SoundFont synthesizer written in Dart.

It is a port of MeltySynth (C#) written by Nobuaki Tanaka, to Dart.
https://github.com/sinshu/meltysynth


Example code to synthesize a simple chord:

```

// Necessary Imports
import 'DartMeltySoundFont/synthesizer.dart';
import 'DartMeltySoundFont/synthesizer_settings.dart';
import 'DartMeltySoundFont/audio_renderer_ex.dart';
import 'DartMeltySoundFont/array_int16.dart';
import 'package:flutter/services.dart' show rootBundle;

// Create the synthesizer.
ByteData bytes = await rootBundle.load('assets/akai_steinway.sf2');

Synthesizer synth = Synthesizer.loadByteData(bytes, 
    SynthesizerSettings(
        sampleRate: 44100, 
        blockSize: 64, 
        maximumPolyphony: 64, 
        enableReverbAndChorus: true,
    ));

// Turn on some notes
synth.noteOn(channel: 0, key: 72, velocity: 120);
synth.noteOn(channel: 0, key: 76, velocity: 120);
synth.noteOn(channel: 0, key: 79, velocity: 120);
synth.noteOn(channel: 0, key: 82, velocity: 127);

// Render the waveform (3 seconds)
ArrayInt16 buf16 = ArrayInt16.zeros(numShorts: 44100 * 3);

synth.renderMonoInt16(buf16);
```

## Features

* No dependencies
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
    - [x] Loop extension support
    - [x] Performace optimization


## Todo

- MIDI file support. 

Feel free to port MIDI file support to Dart and make a pull request. 

Its usage would look like this when implemented:

```
// Create the synthesizer.
var sampleRate = 44100;
var synthesizer = new Synthesizer("TimGM6mb.sf2", sampleRate);

// Read the MIDI file.
var midiFile = MidiFile("flourish.mid");
var sequencer = MidiFileSequencer(synthesizer);
sequencer.play(midiFile, false);

// Render the waveform (3 seconds)
ArrayInt16 buf16 = ArrayInt16.zeros(numShorts: 44100 * 3);

sequencer.renderMonoInt16(buf16);
```


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