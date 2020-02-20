library reader_writer_lock;

import 'dart:async';

typedef CriticalSectionRoutine<T> = FutureOr<T> Function();
typedef UpgradeToWriterLock = Future<void> Function();
typedef CriticalSectionRoutineUpgradable<T> = Future<T> Function(UpgradeToWriterLock upgrade);

/// Providing easy-to-use reader-writer-lock wrapper on [ReadWriteMutex].
class ReaderWriterLock {
  /// For direct access though it is discouraged.
  final readWriteLock = ReadWriteMutex();

  /// Acquire reader lock during executing [readerRoutine].
  Future<T> readerLock<T>(CriticalSectionRoutine<T> readerRoutine) async {
    await readWriteLock.acquireRead();
    try {
      return await readerRoutine();
    } finally {
      readWriteLock.release();
    }
  }

  /// Acquire writer lock during executing [writerRoutine].
  Future<T> writerLock<T>(CriticalSectionRoutine<T> writerRoutine) async {
    await readWriteLock.acquireWrite();
    try {
      return await writerRoutine();
    } finally {
      readWriteLock.release();
    }
  }

  /// Acquire upgradable reader lock during executing [readerRoutine].
  /// You can call [upgrade] function to upgrade reader lock to writer lock.
  Future<T> readerLockUpgradable<T>(CriticalSectionRoutineUpgradable<T> readerRoutine) async {
    await readWriteLock.acquireRead();
    try {
      return await readerRoutine(readWriteLock.upgradeToWriteLock);
    } finally {
      readWriteLock.release();
    }
  }
}

/***********************************************************************************************
 * The following code is from https://github.com/hoylen/dart-mutex and modified to support
 * upgrading reader-lock to writer-lock.
 ***********************************************************************************************/

/// Represents a request for a lock.
///
/// This is instantiated for each acquire and, if necessary, it is added
/// to the waiting queue.
///
class _ReadWriteMutexRequest {
  /// Internal constructor.
  ///
  /// The [isRead] indicates if this is a read lock (true) or a write lock (false).

  _ReadWriteMutexRequest({this.isRead});

  /// Indicates if this is a read or write lock.

  final bool isRead; // true = read lock requested; false = write lock requested

  /// The job's completer.
  ///
  /// This [Completer] will complete when the job has acquired a lock.
  ///
  /// This should be defined as Completer<void>, but void is not supported in
  /// Dart 1 (it only appeared in Dart 2). A type must be defined, otherwise
  /// the Dart 2 dartanalyzer complains.

  final Completer<int> completer = Completer<int>();
}

/// Mutual exclusion that supports read and write locks.
///
/// Multiple read locks can be simultaneously acquired, but at most only
/// one write lock can be acquired at any one time.
///
/// Create the mutex:
///
///     m = new ReadWriteMutex();
///
/// Some code can acquire a write lock:
///
///     await m.acquireWrite();
///     try {
///       // critical write section
///       assert(m.isWriteLocked);
///     }
///     finally {
///       m.release();
///     }
///
/// Other code can acquire a read lock.
///
///     await m.acquireRead();
///     try {
///       // critical read section
///       assert(m.isReadLocked);
///     }
///     finally {
///       m.release();
///     }
///
/// The current implementation lets locks be acquired in first-in-first-out
/// order. This ensures there will not be any lock starvation, which can
/// happen if some locks are prioritised over others. Submit a feature
/// request issue, if there is a need for another scheduling algorithm.
///
class ReadWriteMutex {
  final _waiting = <_ReadWriteMutexRequest>[];

  int _state = 0; // -1 = write lock, +ve = number of read locks; 0 = no lock

  /// Indicates if a lock (read or write) has currently been acquired.
  bool get isLocked => (_state != 0);

  /// Indicates if a write lock has currently been acquired.
  bool get isWriteLocked => (_state == -1);

  /// Indicates if a read lock has currently been acquired.
  bool get isReadLocked => (0 < _state);

  /// Acquire a read lock
  ///
  /// Returns a future that will be completed when the lock has been acquired.
  ///
  Future acquireRead() => _acquire(true);

  /// Acquire a write lock
  ///
  /// Returns a future that will be completed when the lock has been acquired.
  ///
  Future acquireWrite() => _acquire(false);

  /// Upgrade an existing read lock to write lock
  ///
  /// Returns a future that will be completed when the lock has been upgraded.
  ///
  Future upgradeToWriteLock() {
    final newLock = _acquire(false, priority: true);
    release();
    return newLock;
  }

  /// Release a lock.
  ///
  /// Release a lock that has been acquired.
  ///
  void release() {
    if (_state == -1) {
      // Write lock released
      _state = 0;
    } else if (0 < _state) {
      // Read lock released
      _state--;
    } else if (_state == 0) {
      throw StateError('no lock to release');
    } else {
      assert(false);
    }

    // Let all jobs that can now acquire a lock do so.

    while (_waiting.isNotEmpty) {
      final nextJob = _waiting.first;
      if (_jobAcquired(nextJob)) {
        _waiting.removeAt(0);
      } else {
        break; // no more can be acquired
      }
    }
  }

  /// Internal acquire method.
  ///
  Future _acquire(bool isRead, {bool priority}) {
    final newJob = _ReadWriteMutexRequest(isRead: isRead);
    if (!_jobAcquired(newJob)) {
      if (priority) {
        _waiting.insert(0, newJob);
      } else {
        _waiting.add(newJob);
      }
    }
    return newJob.completer.future;
  }

  /// Determine if the [job] can now acquire the lock.
  ///
  /// If it can acquire the lock, the job's completer is completed, the
  /// state updated, and true is returned. If not, false is returned.
  ///
  bool _jobAcquired(_ReadWriteMutexRequest job) {
    assert(-1 <= _state);
    if (_state == 0 || (0 < _state && job.isRead)) {
      // Can acquire
      _state = (job.isRead) ? (_state + 1) : -1;
      job.completer.complete(0); // dummy value
      return true;
    } else {
      return false;
    }
  }
}
