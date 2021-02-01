import 'dart:async';

abstract class ComplexChunkedConverter<S, T> {
  Sink<S> startChunkedConversion(Sink<T> sink);
}

/// This class implements the logic for a chunked conversion as a
/// stream transformer.
///
/// It is a copy of the [ConverterStreamEventSink].
class ComplexConverterStreamEventSink<S, T> implements EventSink<S> {
  /// The output sink for the converter.
  final EventSink<T> _eventSink;

  /// The input sink for new data. All data that is received with
  /// [handleData] is added into this sink.
  final Sink<S> _chunkedSink;

  ComplexConverterStreamEventSink(
      ComplexChunkedConverter<S, T> converter, EventSink<T> sink)
      : this._eventSink = sink,
        _chunkedSink = converter.startChunkedConversion(sink);

  void add(S o) {
    _chunkedSink.add(o);
  }

  void addError(Object error, [StackTrace? stackTrace]) {
    _eventSink.addError(error, stackTrace);
  }

  void close() {
    _chunkedSink.close();
  }
}
