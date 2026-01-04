import 'dart:async';
import 'ble_gprinter_platform_interface.dart';

class BleGprinter {
  Future<String?> getPlatformVersion() {
    return BleGprinterPlatform.instance.getPlatformVersion();
  }

  /// 搜索打印机设备
  Future<bool> searchPrinters() {
    return BleGprinterPlatform.instance.searchPrinters();
  }

  /// 停止搜索打印机设备
  Future<bool> stopSearch() {
    return BleGprinterPlatform.instance.stopSearch();
  }

  /// 连接打印机
  /// [deviceAddress] 设备地址（蓝牙MAC地址或IP地址）
  /// [deviceName] 设备名称
  Future<bool> connectPrinter(String deviceAddress, String deviceName) {
    return BleGprinterPlatform.instance.connectPrinter(
      deviceAddress,
      deviceName,
    );
  }

  /// 断开打印机连接
  Future<bool> disconnectPrinter() {
    return BleGprinterPlatform.instance.disconnectPrinter();
  }

  /// 检查打印机是否已连接
  Future<bool> isConnected() {
    return BleGprinterPlatform.instance.isConnected();
  }

  /// 打印PDF文件
  /// [pdfPath] PDF文件路径
  /// [width] 标签宽度（单位：mm）
  /// [height] 标签高度（单位：mm）
  /// [dpi] 打印机DPI（203或300）
  /// [density] 打印浓度（1-15）
  /// [speed] 打印速度（1-5）
  /// [paperType] 纸张类型（0=连续纸，1=间隔纸，2=黑标纸）
  /// [instruction] 指令集（0=ESC，1=TSC，2=ZPL，3=CPCL）
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
    return BleGprinterPlatform.instance.printPdf(
      pdfPath,
      width: width,
      height: height,
      dpi: dpi,
      density: density,
      speed: speed,
      paperType: paperType,
      instruction: instruction,
    );
  }

  /// 获取打印机状态
  Future<Map<String, dynamic>> getPrinterStatus() {
    return BleGprinterPlatform.instance.getPrinterStatus();
  }

  /// 监听打印机事件
  Stream<Map<String, dynamic>> get onPrinterEvent {
    return BleGprinterPlatform.instance.onPrinterEvent;
  }
}
