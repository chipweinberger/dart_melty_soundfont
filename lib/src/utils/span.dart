class Span<T> {
  final List<T> _list;
  final int _start;
  final int _length;

  Span(
    List<T> list, [
    int? start,
    int? length,
  ])  : this._list = list,
        this._start = start ?? 0,
        this._length = length ?? list.length,
        assert(start == null || start >= 0),
        assert(length == null || length >= 0);

  factory Span.fromList(List<T> list) {
    return Span<T>(list);
  }

  factory Span.filled(int length, T fill) {
    return Span<T>(List<T>.filled(length, fill));
  }

  T operator [](int index) {
    return _list[this.index(index)];
  }

  void operator []=(int index, T value) {
    _list[this.index(index)] = value;
  }

  int get length => _length;
  int get end => _start + _length;
  int index(int index) => _start + index;

  @override
  String toString() {
    return _list.sublist(_start, end).toString();
  }

  Span<T> span(int start, [int? length]) {
    return Span<T>(_list, this.index(start), length);
  }

  Span<T> slice(int start, [int? length]) {
    return span(start, length);
  }

  List<T> list() => _list;
}

extension ListUtils<T> on List<T> {
  Span<T> span(int start, [int? length]) {
    if (length == null) length = this.length;
    return Span<T>(this, start, length);
  }

  Span<T> toSpan() {
    return Span<T>.fromList(this);
  }
}
