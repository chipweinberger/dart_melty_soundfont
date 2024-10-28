import 'dart:collection';

/// Minimal implementation of C# list slices in Dart
/// Allows reading and writing to the backed list
class ListSlice<E> extends ListBase<E> {
  final List<E> _list;
  final int start;
  final int _length;

  ListSlice(this._list, this.start, int length)
      : assert(start + length <= _list.length, "Slice length must be less than list length"),
        _length = length;

  @override
  int get length => _length;

  set length(int value) => throw UnsupportedError('Setting length is not supported on list slice');

  @override
  E operator [](int index) {
    if (index < 0 || index >= length) {
      throw RangeError.index(index, this); // Check bounds
    }
    return _list[index + start];
  }

  @override
  void operator []=(int index, E value) {
    if (index < 0 || index >= length) {
      throw RangeError.index(index, this); // Check bounds
    }
    _list[index + start] = value;
  }
}


extension ListSliceExtension<E> on List<E> {
  ListSlice<E> slice(int start, int length) {
    return ListSlice(this, start, length);
  }
}