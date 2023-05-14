import 'package:dart_melty_soundfont/soundfont.dart';
import 'package:dart_melty_soundfont/soundfont_io.dart';

class TestSettings {
  static List<Map<String, SoundFont>> soundFonts = [
    {'TimGM6mb': soundFontFromPath('./test/test_data/TimGM6mb.sf2')},
  ];

  static List<Map<String, SoundFont>> lightSoundFonts = [
    {'TimGM6mb': soundFontFromPath('./test/test_data/TimGM6mb.sf2')},
  ];

  static SoundFont defaultSoundFont = soundFonts[0].values.first;
}
