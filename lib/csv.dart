/// A high-quality, darty CSV library.
library;

export 'src/csv_codec.dart';
export 'src/csv_encoder.dart';
export 'src/csv_decoder.dart';
export 'src/quote_mode.dart';
export 'src/csv_row.dart';

import 'src/csv_codec.dart';

/// A default CSV instance with standard settings.
final Csv csv = Csv();

/// A CSV instance configured for Excel.
final Csv excel = Csv.excel();
