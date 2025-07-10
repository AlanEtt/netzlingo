import 'package:flutter/widgets.dart';

/// Helper untuk menangani operasi asynchronous dengan aman di StatefulWidget
class AsyncHelper {
  /// Menjalankan operasi async dan melakukan setState jika widget masih mounted
  ///
  /// Parameter:
  /// - state: State<StatefulWidget> saat ini
  /// - operation: Fungsi async yang akan dijalankan
  /// - onComplete: Callback yang dipanggil dengan hasil operasi jika berhasil
  /// - onError: Callback yang dipanggil jika terjadi error
  static Future<void> runWithMounted<T>({
    required State state,
    required Future<T> Function() operation,
    required void Function(T result) onComplete,
    void Function(Object error)? onError,
  }) async {
    // Periksa dulu apakah state sudah tidak mounted
    if (!state.mounted) return;

    try {
      final result = await operation();

      // Periksa kembali setelah operasi async selesai
      if (state.mounted) {
        onComplete(result);
      }
    } catch (e) {
      print("AsyncHelper error: $e");

      // Panggil onError jika disediakan dan widget masih mounted
      if (state.mounted && onError != null) {
        onError(e);
      }
    }
  }

  /// Menjalankan operasi setState dengan aman setelah operasi async
  ///
  /// Parameter:
  /// - state: State<StatefulWidget> saat ini
  /// - operation: Fungsi async yang akan dijalankan
  /// - setStateCallback: Callback untuk setState jika operasi berhasil
  static Future<void> safeSetState<T>({
    required State state,
    required Future<T> Function() operation,
    required void Function(T result) setStateCallback,
    void Function(Object error)? onError,
  }) async {
    await runWithMounted(
      state: state,
      operation: operation,
      onComplete: (result) {
        state.setState(() {
          setStateCallback(result);
        });
      },
      onError: onError != null
          ? (error) {
              state.setState(() {
                onError(error);
              });
            }
          : null,
    );
  }
}
