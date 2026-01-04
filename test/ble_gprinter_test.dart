import 'package:flutter_test/flutter_test.dart';
import 'package:ble_gprinter/ble_gprinter.dart';
import 'package:ble_gprinter/ble_gprinter_platform_interface.dart';
import 'package:ble_gprinter/ble_gprinter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBleGprinterPlatform
    with MockPlatformInterfaceMixin
    implements BleGprinterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BleGprinterPlatform initialPlatform = BleGprinterPlatform.instance;

  test('$MethodChannelBleGprinter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBleGprinter>());
  });

  test('getPlatformVersion', () async {
    BleGprinter bleGprinterPlugin = BleGprinter();
    MockBleGprinterPlatform fakePlatform = MockBleGprinterPlatform();
    BleGprinterPlatform.instance = fakePlatform;

    expect(await bleGprinterPlugin.getPlatformVersion(), '42');
  });
}
