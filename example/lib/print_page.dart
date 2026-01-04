import 'package:flutter/material.dart';
import 'package:ble_gprinter/ble_gprinter.dart';
import 'package:file_picker/file_picker.dart';

class PrintPage extends StatefulWidget {
  const PrintPage({super.key});

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  final _bleGprinterPlugin = BleGprinter();
  int _width = 70;
  int _height = 50;
  int _dpi = 300;
  int _density = 11;
  int _speed = 2;
  int _paperType = 1;
  int _instruction = 1;

  Future<void> _pickAndPrintPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final pdfPath = result.files.single.path!;

        // 显示加载对话框
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        final printResult = await _bleGprinterPlugin.printPdf(
          pdfPath,
          width: _width,
          height: _height,
          dpi: _dpi,
          density: _density,
          speed: _speed,
          paperType: _paperType,
          instruction: _instruction,
        );

        Navigator.of(context).pop(); // 关闭加载对话框

        if (printResult['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('打印成功，共${printResult['pageCount']}页')),
          );
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // 关闭加载对话框
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('打印失败: $e')));
    }
  }

  Future<void> _getPrinterStatus() async {
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
    return Scaffold(
      appBar: AppBar(title: const Text('打印设置')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '标签尺寸',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '宽度 (mm)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: _width.toString()),
                    onChanged: (value) => _width = int.tryParse(value) ?? 80,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '高度 (mm)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: _height.toString()),
                    onChanged: (value) => _height = int.tryParse(value) ?? 120,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '打印参数',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'DPI',
                border: OutlineInputBorder(),
              ),
              value: _dpi,
              items: const [
                DropdownMenuItem(value: 203, child: Text('203 DPI')),
                DropdownMenuItem(value: 300, child: Text('300 DPI')),
              ],
              onChanged: (value) => setState(() => _dpi = value ?? 203),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: '浓度 (1-15)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: _density.toString()),
              onChanged: (value) => _density = int.tryParse(value) ?? 8,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: '速度 (1-6)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: _speed.toString()),
              onChanged: (value) => _speed = int.tryParse(value) ?? 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: '纸张类型',
                border: OutlineInputBorder(),
              ),
              value: _paperType,
              items: const [
                DropdownMenuItem(value: 0, child: Text('连续纸')),
                DropdownMenuItem(value: 1, child: Text('间隙纸')),
                DropdownMenuItem(value: 2, child: Text('黑标纸')),
              ],
              onChanged: (value) => setState(() => _paperType = value ?? 1),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: '指令集',
                border: OutlineInputBorder(),
              ),
              value: _instruction,
              items: const [
                DropdownMenuItem(value: 0, child: Text('ESC')),
                DropdownMenuItem(value: 1, child: Text('TSC')),
                DropdownMenuItem(value: 2, child: Text('ZPL')),
                DropdownMenuItem(value: 3, child: Text('CPCL')),
              ],
              onChanged: (value) => setState(() => _instruction = value ?? 1),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickAndPrintPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('选择并打印PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _getPrinterStatus,
                  icon: const Icon(Icons.info),
                  label: const Text('打印机状态'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
