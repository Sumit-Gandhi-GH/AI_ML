import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QR Scanner service for camera-based barcode scanning
class QrScannerService {
  MobileScannerController? _controller;
  StreamSubscription<BarcodeCapture>? _subscription;
  
  // Callbacks
  Function(String)? onBarcodeDetected;
  Function(String)? onError;
  
  bool _isInitialized = false;
  bool _isScanning = false;
  DateTime? _lastScanTime;
  
  // Debounce to prevent duplicate scans
  static const int _scanCooldownMs = 1500;

  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  MobileScannerController? get controller => _controller;

  /// Initialize the scanner
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
        formats: [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.code39],
      );

      _subscription = _controller!.barcodes.listen(_handleBarcodeCapture);
      
      await _controller!.start();
      _isInitialized = true;
      _isScanning = true;
    } catch (e) {
      onError?.call('Failed to initialize scanner: $e');
    }
  }

  void _handleBarcodeCapture(BarcodeCapture capture) {
    // Debounce duplicate scans
    final now = DateTime.now();
    if (_lastScanTime != null) {
      final diff = now.difference(_lastScanTime!).inMilliseconds;
      if (diff < _scanCooldownMs) return;
    }

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        _lastScanTime = now;
        onBarcodeDetected?.call(value);
        break; // Only process first valid barcode
      }
    }
  }

  /// Toggle the torch/flashlight
  Future<void> toggleTorch() async {
    await _controller?.toggleTorch();
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    await _controller?.switchCamera();
  }

  /// Pause scanning
  Future<void> pause() async {
    if (_isScanning) {
      await _controller?.stop();
      _isScanning = false;
    }
  }

  /// Resume scanning
  Future<void> resume() async {
    if (!_isScanning && _isInitialized) {
      await _controller?.start();
      _isScanning = true;
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isScanning = false;
  }
}
