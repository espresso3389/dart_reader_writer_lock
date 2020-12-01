# NOTE

This package has serious issues on its design and discontinued now. Please don't use it.

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

If you want to do some [Test-and-Set](https://en.wikipedia.org/wiki/Test-and-set) operation,
you can use `readerLockUpgradable` method to do so. It has a parameter, named `upgrade` and you can call the function
to upgrader reader-lock to writer-lock.

```dart
import 'package:reader_writer_lock/reader_writer_lock.dart';

final rwlock = ReaderWriterLock();

// reader-lock
await rwlock.readerLockUpgradable((upgrade) async {
    // Do reader task here

    // Upgrade reader-lock to writer-lock
    await upgrade();

    // Do writer task here
});
