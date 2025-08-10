# 2.0.0
- Perf: use Float32List instead of List<double>

# 1.1.16
- Fix: resetAllControllers should also reset volume, pan, sostenuto, pitch bend range, tuning

# 1.1.15
- Feature: add sostenuto support

# 1.1.14
- Fix: sustained notes could have weird fade-out artifacts

# 1.1.13
- Fix: stereo rendering

# 1.1.12
- docs: update readme

# 1.1.11
- fix: small warning

# 1.1.10
- Example: switch to flutter_pcm_sound

# 1.1.9
- Fix: remove null characters from names
- Synth: add selectPreset function for convenience
- Example: make it more easily runnable

# 1.1.8

- added RawSound example

# 1.1.7

- remove pubspec.lock and dart_tool/package_config.json and add them to gitignore

# 1.1.6

- Updated github repo name to match pub.dev name
- Fixed potential issue where loading a file would fail (thanks @sinshu)

# 1.1.5

'setModulationFine' would not always work, due to typo.

# 1.1.4

Readme.

# 1.1.3

Fixed bug in Oscillator code that could cause out of bounds write error.

# 1.1.2

Readme

# 1.1.1

Relax SampleEndLoop check, as some non-spec-compliant SoundFonts use a value of zero as a special case.

# 1.1.0

Fixed bug that caused negative SoundFont parameters to be interpreted as large integers. Some SoundFonts would throw errors due to this, or sound very odd.

# 1.0.10

Readme

# 1.0.9

Readme

# 1.0.8

Make example code select an instrument.

# 1.0.7

Missing import 'dart:typed_data' 

# 1.0.6

Add package header. Update Readme. again rename lib->src. Seems to not have been comitted. 

# 1.0.5

Fix imports in example.

# 1.0.4

Files need to go in 'lib' folder. Not a 'src' folder.

# 1.0.3

Update readme.

# 1.0.2

Update readme.

# 1.0.1

Update readme.

# 1.0.0

Ported MeltySynth from C# to Dart. Tested.

https://github.com/sinshu/meltysynth

