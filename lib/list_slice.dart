import 'dart:collection';

/// Minimal implementation of C# list slices in Dart
/// Allows reading and writing to the backed list
class ListSlice<E> extends ListBase<E> {
  final List<E> _list;
  final int start;

  @override
  int length;

  ListSlice(this._list, this.start, this.length): assert(start + length <= _list.length, "Slice length must be less than list length");

  @override
  E operator [](int index) {
    return _list[index + start];
  }

  @override
  void operator []=(int index, E value) {
    _list[index + start] = value;
  }
}

extension ListSliceExtension<E> on List<E> {
  ListSlice<E> slice(int start, int length) {
    return ListSlice(this, start, length);
  }
}