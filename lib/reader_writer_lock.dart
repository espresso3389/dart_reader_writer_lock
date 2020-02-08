library reader_writer_lock;

import 'dart:async';

import 'package:mutex/mutex.dart';

/// Providing easy-to-use reader-writer-lock wrapper on [ReadWriteMutex].
class ReaderWriterLock {
  /// For direct access though it is discouraged.
  final readWriteLock = ReadWriteMutex();

  /// Acquire reader lock during executing [readerRoutine].
  Future<T> readerLock<T>(FutureOr<T> readerRoutine()) async {
    await readWriteLock.acquireRead();
    try {
      return await readerRoutine();
    } finally {
      readWriteLock.release();
    }
  }

  /// Acquire writer lock during executing [writerRoutine].
  Future<T> writerLock<T>(FutureOr<T> writerRoutine()) async {
    await readWriteLock.acquireWrite();
    try {
      return await writerRoutine();
    } finally {
      readWriteLock.release();
    }
  }
}
