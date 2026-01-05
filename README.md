# ble_gprinter

Flutter插件，用于通过蓝牙连接佳博(Gprinter)打印机并打印PDF文件。基于佳博Android SDK2实现TSC指令集打印。

## 功能特性

- ✅ 搜索蓝牙打印机设备
- ✅ 连接/断开打印机
- ✅ 打印PDF文件（自动转换为位图）
- ✅ 获取打印机状态
- ✅ 支持多种打印机配置（DPI、浓度、速度等）
- ✅ 支持TSC、ESC、ZPL、CPCL指令集

## 支持的平台

- Android (minSdk 24+)

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  ble_gprinter: ^0.0.2
```

## Android配置

在 `android/app/src/main/AndroidManifest.xml` 中添加权限：

```xml
<!-- 蓝牙权限 -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- 文件访问权限 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```
在 `android/build.gradle.kts` 中添加佳博maven库：

```
allprojects {
    repositories {
         //佳博SDK仓库
        maven {
            url = uri("http://118.31.6.84:8081/repository/maven-public/")
            isAllowInsecureProtocol = true
        }
        google {
            url = uri("https://maven.aliyun.com/repository/google")
        }
        maven {
            url = uri("https://maven.aliyun.com/repository/public")
        }
        maven {
            url = uri("https://jitpack.io")
        }
    }
}
```
## 使用方法

### 1. 初始化插件

```dart
import 'package:ble_gprinter/ble_gprinter.dart';

final bleGprinter = BleGprinter();
```

### 2. 监听打印机事件

```dart
bleGprinter.onPrinterEvent.listen((event) {
  final eventType = event['event'];
  
  switch (eventType) {
    case 'onDeviceFound':
      // 发现设备
      print('发现设备: ${event['deviceName']} - ${event['deviceAddress']}');
      break;
    case 'onPrinterConnected':
      // 打印机已连接
      print('打印机连接成功');
      break;
    case 'onPrinterConnectFail':
      // 连接失败
      print('打印机连接失败');
      break;
    case 'onPrinterDisconnect':
      // 打印机断开
      print('打印机已断开');
      break;
    case 'onSearchCompleted':
      // 搜索完成
      print('搜索完成');
      break;
  }
});
```

### 3. 搜索打印机

```dart
await bleGprinter.searchPrinters();
```

### 4. 连接打印机

```dart
await bleGprinter.connectPrinter(deviceAddress, deviceName);
```

### 5. 打印PDF

```dart
final result = await bleGprinter.printPdf(
  '/path/to/file.pdf',
  width: 80,        // 标签宽度（mm）
  height: 120,      // 标签高度（mm）
  dpi: 203,         // DPI (203或300)
  density: 8,       // 打印浓度 (1-15)
  speed: 2,         // 打印速度 (1-5)
  paperType: 1,     // 纸张类型: 0=连续纸, 1=间隔纸, 2=黑标纸
  instruction: 1,   // 指令集: 0=ESC, 1=TSC, 2=ZPL, 3=CPCL
);

if (result['success'] == true) {
  print('打印成功，共${result['pageCount']}页');
}
```

### 6. 获取打印机状态

```dart
final status = await bleGprinter.getPrinterStatus();

print('状态码: ${status['status']}');
print('缺纸: ${status['isOutOfPaper']}');
print('开盖: ${status['isOpenCover']}');
print('卡纸: ${status['isJampPaper']}');
print('暂停: ${status['isPausePrint']}');
print('其他错误: ${status['isOtherError']}');
```

### 7. 检查连接状态

```dart
bool connected = await bleGprinter.isConnected();
```

### 8. 断开连接

```dart
await bleGprinter.disconnectPrinter();
```

## 完整示例

参考 `example/lib/main.dart` 文件，其中包含一个完整的使用示例，展示了如何：
- 搜索并连接打印机
- 选择并打印PDF文件
- 监听打印机事件
- 显示打印机状态

## API参考

### 方法

| 方法 | 说明 | 参数 | 返回值 |
|-----|------|-----|-------|
| `searchPrinters()` | 搜索打印机设备 | 无 | `Future<bool>` |
| `stopSearch()` | 停止搜索 | 无 | `Future<bool>` |
| `connectPrinter()` | 连接打印机 | `String deviceAddress, String deviceName` | `Future<bool>` |
| `disconnectPrinter()` | 断开连接 | 无 | `Future<bool>` |
| `isConnected()` | 检查连接状态 | 无 | `Future<bool>` |
| `printPdf()` | 打印PDF文件 | 见下表 | `Future<Map<String, dynamic>>` |
| `getPrinterStatus()` | 获取打印机状态 | 无 | `Future<Map<String, dynamic>>` |

### printPdf 参数

| 参数 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| `pdfPath` | String | 必填 | PDF文件路径 |
| `width` | int | 80 | 标签宽度（mm）|
| `height` | int | 120 | 标签高度（mm）|
| `dpi` | int | 203 | 打印机DPI (203或300) |
| `density` | int | 8 | 打印浓度 (1-15) |
| `speed` | int | 2 | 打印速度 (1-5) |
| `paperType` | int | 1 | 纸张类型: 0=连续纸, 1=间隔纸, 2=黑标纸 |
| `instruction` | int | 1 | 指令集: 0=ESC, 1=TSC, 2=ZPL, 3=CPCL |

### 事件类型

| 事件 | 说明 | 数据字段 |
|-----|------|---------|
| `onDeviceFound` | 发现设备 | `deviceType`, `deviceName`, `deviceAddress` |
| `onSearchCompleted` | 搜索完成 | 无 |
| `onPrinterConnected` | 打印机已连接 | `message` |
| `onPrinterConnectFail` | 连接失败 | `message` |
| `onPrinterDisconnect` | 打印机断开 | `message` |

## 注意事项

1. Android 12 (API 31) 及以上需要动态请求蓝牙权限
2. 打印PDF前确保打印机已连接
3. 根据实际打印机型号调整DPI、浓度等参数
4. TSC指令集适用于标签打印机

## 许可证

MIT License

## 技术支持

如有问题，请查看佳博官方文档或提交Issue。
