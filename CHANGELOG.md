## 0.0.1

- 佳博打印机蓝牙打印 flutter sdk（android only）

## 0.0.2
- **FIX**: 修复 ContentProvider authority 冲突问题
  - 使用 `${applicationId}` 确保每个应用的 provider 唯一
  - 现在可以与其他使用本 SDK 的应用共存
- 增加 onlyGprinter 字段，用来只搜索佳博打印机

## 0.0.3
- 如果没有已经缓存的设备，就构造一个蓝牙设备去连接，方便自动连接 
- getPrinterStatus 增加`instruction` 指令集（0=ESC，1=TSC，2=ZPL，3=CPCL）字段