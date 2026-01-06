import 'dart:async';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ble_gprinter_method_channel.dart';

abstract class BleGprinterPlatform extends PlatformInterface {
  /// Constructs a BleGprinterPlatform.
  BleGprinterPlatform() : super(token: _token);

  static final Object _token = Object();

  static BleGprinterPlatform _instance = MethodChannelBleGprinter();

  /// The default instance of [BleGprinterPlatform] to use.
  ///
  /// Defaults to [MethodChannelBleGprinter].
  static BleGprinterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BleGprinterPlatform] when
  /// they register themselves.
  static set instance(BleGprinterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> searchPrinters({bool onlyGprinter = true}) {
    throw UnimplementedError('searchPrinters() has not been implemented.');
  }

  Future<bool> stopSearch() {
    throw UnimplementedError('stopSearch() has not been implemented.');
  }

  Future<bool> connectPrinter(String deviceAddress, String deviceName) {
    throw UnimplementedError('connectPrinter() has not been implemented.');
  }

  Future<bool> disconnectPrinter() {
    throw UnimplementedError('disconnectPrinter() has not been implemented.');
  }

  Future<bool> isConnected() {
    throw UnimplementedError('isConnected() has not been implemented.');
  }

  Future<Map<String, dynamic>> printPdf(
    String pdfPath, {
    int width = 80,
    int height = 120,
    int dpi = 203,
    int density = 8,
    int speed = 2,
    int paperType = 1,
    int instruction = 1,
  }) {
    throw UnimplementedError('printPdf() has not been implemented.');
  }

  Future<Map<String, dynamic>> getPrinterStatus({int instruction = 1}) {
    throw UnimplementedError('getPrinterStatus() has not been implemented.');
  }

  Stream<Map<String, dynamic>> get onPrinterEvent {
    throw UnimplementedError('onPrinterEvent has not been implemented.');
  }
}
