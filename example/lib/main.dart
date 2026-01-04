import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ble_gprinter/ble_gprinter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'print_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _bleGprinterPlugin = BleGprinter();
  final List<Map<String, dynamic>> _devices = [];
  bool _isSearching = false;
  bool _isConnected = false;
  String _connectionStatus = '未连接';
  StreamSubscription? _eventSubscription;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _listenToPrinterEvents();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  // 监听打印机事件
  void _listenToPrinterEvents() {
    _eventSubscription = _bleGprinterPlugin.onPrinterEvent.listen((event) {
      final eventType = event['event'];

      if (eventType == 'onDeviceFound') {
        setState(() {
          // 避免重复添加
          final address = event['deviceAddress'] ?? '';
          if (!_devices.any((d) => d['deviceAddress'] == address)) {
            _devices.add(event);
          }
        });
      } else if (eventType == 'onSearchCompleted') {
        setState(() {
          _isSearching = false;
        });
      } else if (eventType == 'onPrinterConnected') {
        setState(() {
          _isConnected = true;
          _connectionStatus = '已连接';
        });
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('打印机连接成功')),
        );
      } else if (eventType == 'onPrinterConnectFail') {
        setState(() {
          _isConnected = false;
          _connectionStatus = '连接失败';
        });
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('打印机连接失败')),
        );
      } else if (eventType == 'onPrinterDisconnect') {
        setState(() {
          _isConnected = false;
          _connectionStatus = '已断开';
        });
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('打印机已断开')),
        );
      }
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion =
          await _bleGprinterPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  // 请求权限
  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();

    print('Permission results: $statuses');
    return statuses.values.every((status) => status.isGranted);
  }

  // 搜索打印机
  Future<void> _searchPrinters() async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请授予蓝牙和定位权限')));
      return;
    }

    setState(() {
      _isSearching = true;
      _devices.clear();
    });

    try {
      await _bleGprinterPlugin.searchPrinters();
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('搜索失败: $e')));
    }
  }

  // 连接打印机
  Future<void> _connectPrinter(Map<String, dynamic> device) async {
    try {
      final address = device['deviceAddress'] ?? '';
      final name = device['deviceName'] ?? '';

      // 显示连接中状态
      setState(() {
        _connectionStatus = '连接中...';
      });

      await _bleGprinterPlugin.connectPrinter(address, name);
    } catch (e) {
      setState(() {
        _connectionStatus = '未连接';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('连接失败: $e')));
    }
  }

  // 断开连接
  Future<void> _disconnectPrinter() async {
    try {
      await _bleGprinterPlugin.disconnectPrinter();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('断开失败: $e')));
    }
  }

  // 选择并打印PDF
  Future<void> _pickAndPrintPdf(BuildContext navContext) async {
    if (!_isConnected) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('请先连接打印机')),
      );
      return;
    }

    // 跳转到打印页面
    Navigator.pushNamed(navContext, '/print');
  }

  // 获取打印机状态
  Future<void> _getPrinterStatus() async {
    if (!_isConnected) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('请先连接打印机')),
      );
      return;
    }

    try {
      final status = await _bleGprinterPlugin.getPrinterStatus();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('打印机状态'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('状态码: ${status['status']?.toRadixString(16)}'),
              Text('缺纸: ${status['isOutOfPaper']}'),
              Text('开盖: ${status['isOpenCover']}'),
              Text('卡纸: ${status['isJampPaper']}'),
              Text('暂停: ${status['isPausePrint']}'),
              Text('其他错误: ${status['isOtherError']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('获取状态失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      routes: {'/print': (context) => const PrintPage()},
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Gprinter TSC 打印机示例')),
          body: Builder(
            builder: (navContext) => Column(
              children: [
                // 连接状态
                Container(
                  padding: const EdgeInsets.all(16),
                  color: _isConnected ? Colors.green[100] : Colors.grey[200],
                  child: Row(
                    children: [
                      Icon(
                        _isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: _isConnected ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text('状态: $_connectionStatus'),
                      const Spacer(),
                      if (_isConnected)
                        ElevatedButton(
                          onPressed: _disconnectPrinter,
                          child: const Text('断开'),
                        )
                      else
                        ElevatedButton(
                          onPressed: _searchPrinters,
                          child: Text(_isSearching ? '搜索中...' : '搜索设备'),
                        ),
                    ],
                  ),
                ),
                // 功能按钮
                if (_isConnected)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickAndPrintPdf(navContext),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('打印PDF'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _getPrinterStatus,
                          icon: const Icon(Icons.info),
                          label: const Text('状态'),
                        ),
                      ],
                    ),
                  ),
                // 设备列表
                Expanded(
                  child: _devices.isEmpty
                      ? Center(
                          child: Text(
                            _isSearching ? '搜索中...' : '点击搜索按钮开始搜索设备',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (context, index) {
                            final device = _devices[index];
                            final deviceType = device['deviceType'] ?? '';
                            final deviceName =
                                device['deviceName'] ?? 'Unknown';
                            final deviceAddress = device['deviceAddress'] ?? '';

                            return ListTile(
                              leading: Icon(
                                deviceType == 'bluetooth'
                                    ? Icons.bluetooth
                                    : deviceType == 'wifi'
                                    ? Icons.wifi
                                    : Icons.usb,
                              ),
                              title: Text(deviceName),
                              subtitle: Text('$deviceType - $deviceAddress'),
                              trailing: ElevatedButton(
                                onPressed: () => _connectPrinter(device),
                                child: const Text('连接'),
                              ),
                            );
                          },
                        ),
                ),
                // 版本信息
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '运行在: $_platformVersion',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
