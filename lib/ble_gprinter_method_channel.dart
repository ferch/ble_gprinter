import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ble_gprinter_platform_interface.dart';

/// An implementation of [BleGprinterPlatform] that uses method channels.
class MethodChannelBleGprinter extends BleGprinterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ble_gprinter');

  /// The event channel used to receive printer events.
  @visibleForTesting
  final eventChannel = const EventChannel('ble_gprinter/events');

  Stream<Map<String, dynamic>>? _onPrinterEvent;

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<bool> searchPrinters({bool onlyGprinter = true}) async {
    final result = await methodChannel.invokeMethod<bool>('searchPrinters', {
      'onlyGprinter': onlyGprinter,
    });
    return result ?? false;
  }

  @override
  Future<bool> stopSearch() async {
    final result = await methodChannel.invokeMethod<bool>('stopSearch');
    return result ?? false;
  }

  @override
  Future<bool> connectPrinter(String deviceAddress, String deviceName) async {
    final result = await methodChannel.invokeMethod<bool>('connectPrinter', {
      'deviceAddress': deviceAddress,
      'deviceName': deviceName,
    });
    return result ?? false;
  }

  @override
  Future<bool> disconnectPrinter() async {
    final result = await methodChannel.invokeMethod<bool>('disconnectPrinter');
    return result ?? false;
  }

  @override
  Future<bool> isConnected() async {
    final result = await methodChannel.invokeMethod<bool>('isConnected');
    return result ?? false;
  }

  @override
  Future<Map<String, dynamic>> printPdf(
    String pdfPath, {
    int width = 70,
    int height = 50,
    int dpi = 300,
    int density = 11,
    int speed = 2,
    int paperType = 1,
    int instruction = 1,
  }) async {
    final result = await methodChannel.invokeMethod('printPdf', {
      'pdfPath': pdfPath,
      'width': width,
      'height': height,
      'dpi': dpi,
      'density': density,
      'speed': speed,
      'paperType': paperType,
      'instruction': instruction,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<Map<String, dynamic>> getPrinterStatus({int instruction = 1}) async {
    final result = await methodChannel.invokeMethod('getPrinterStatus', {
      'instruction': instruction,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Stream<Map<String, dynamic>> get onPrinterEvent {
    _onPrinterEvent ??= eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event as Map);
    });
    return _onPrinterEvent!;
  }
}
