enum SampleType {
  // 'none' should only be found in
  // the 'terminator' SampleHeader
  none,
  mono,
  right,
  left,
  linked,
  romMono,
  romRight,
  romLeft,
  romLinked
}

SampleType sampleTypeFromInt(int i) {
  switch (i) {
    case 0:
      return SampleType.none;
    case 1:
      return SampleType.mono;
    case 2:
      return SampleType.right;
    case 4:
      return SampleType.left;
    case 8:
      return SampleType.linked;
    case 0x8001:
      return SampleType.romMono;
    case 0x8002:
      return SampleType.romRight;
    case 0x8004:
      return SampleType.romLeft;
    case 0x8008:
      return SampleType.romLinked;
  }
  throw "invalid SampleType";
}

int sampleTypeToInt(SampleType s) {
  switch (s) {
    case SampleType.none:
      return 0;
    case SampleType.mono:
      return 1;
    case SampleType.right:
      return 2;
    case SampleType.left:
      return 4;
    case SampleType.linked:
      return 8;
    case SampleType.romMono:
      return 0x8001;
    case SampleType.romRight:
      return 0x8002;
    case SampleType.romLeft:
      return 0x8004;
    case SampleType.romLinked:
      return 0x8008;
  }
}
