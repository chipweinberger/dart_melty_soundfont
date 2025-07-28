import 'synthesizer.dart';
import 'voice.dart';
import 'instrument_region.dart';

class VoiceCollection extends Iterable<Voice> {
  final Synthesizer synthesizer;

  final List<Voice> voices;

  int _activeVoiceCount = 0;

  VoiceCollection({required this.synthesizer, required this.voices});

  factory VoiceCollection.create(Synthesizer synthesizer, int maxActiveVoiceCount) {
    List<Voice> voices = [];

    for (int i = 0; i < maxActiveVoiceCount; i++) {
      voices.add(Voice(synthesizer));
    }

    return VoiceCollection(synthesizer: synthesizer, voices: voices);
  }

  Voice? requestNew(InstrumentRegion region, int channel) {
    // If the voice is an exclusive class, reuse the existing one so that only one note
    // will be played at a time.
    int exclusiveClass = region.exclusiveClass();

    if (exclusiveClass != 0) {
      for (var i = 0; i < _activeVoiceCount; i++) {
        var voice = voices[i];

        if (voice.exclusiveClass() == exclusiveClass && voice.channel() == channel) {
          return voice;
        }
      }
    }

    if (_activeVoiceCount < voices.length) {
      var free = voices[_activeVoiceCount];
      _activeVoiceCount++;
      return free;
    }

    // Too many active voices...
    // Find one which has the lowest priority.
    Voice? low = null;
    var lowestPriority = double.maxFinite;
    for (int i = 0; i < _activeVoiceCount; i++) {
      var voice = voices[i];
      var priority = voice.priority();
      if (priority < lowestPriority) {
        lowestPriority = priority;
        low = voice;
      } else if (priority == lowestPriority) {
        // Same priority...
        // The older one should be more suitable for reuse.
        if (low == null || voice.voiceLength() > low.voiceLength()) {
          low = voice;
        }
      }
    }
    return low;
  }

  void process() {
    var i = 0;

    while (true) {
      if (i == _activeVoiceCount) {
        return;
      }

      if (voices[i].process()) {
        i++;
      } else {
        _activeVoiceCount--;

        var tmp = voices[i];
        voices[i] = voices[_activeVoiceCount];
        voices[_activeVoiceCount] = tmp;
      }
    }
  }

  void clear() {
    _activeVoiceCount = 0;
  }

  @override
  VoiceIterator get iterator {
    return VoiceIterator(collection: this);
  }

  int activeVoiceCount() => _activeVoiceCount;
}

class VoiceIterator implements Iterator<Voice> {
  final VoiceCollection collection;

  int _index = 0;
  Voice? _current;

  VoiceIterator({required this.collection});

  @override
  bool moveNext() {
    if (_index < collection.activeVoiceCount()) {
      _current = collection.voices[_index];
      _index++;

      return true;
    } else {
      return false;
    }
  }

  @override
  Voice get current => _current!;
}
