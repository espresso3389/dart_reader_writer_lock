# reader_writer_lock

Simple reader-writer-lock implementation upon [mutex](https://pub.dev/packages/mutex) package.

## Usage

The package realizes [synchronized](https://pub.dev/packages/synchronized) like syntax to reduce use of `try-finally` for releasing locks.

```dart
import 'package:reader_writer_lock/reader_writer_lock.dart';

final rwlock = ReaderWriterLock();

// reader-lock
await rwlock.readerLock(() async {
    // Do reader task here
});

// writer-lock
await rwlock.writerLock(() async {
    // Do writer task here
});
```
