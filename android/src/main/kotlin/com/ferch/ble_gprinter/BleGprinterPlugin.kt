package com.ferch.ble_gprinter

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Rect
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.content.ContextCompat
import com.gainscha.sdk2.ConnectionListener
import com.gainscha.sdk2.Printer
import com.gainscha.sdk2.PrinterConfig
import com.gainscha.sdk2.PrinterFinder
import com.gainscha.sdk2.PrinterResponse
import com.gainscha.sdk2.model.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.reactivex.Observable
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.schedulers.Schedulers
import java.io.File
import java.io.IOException

/** BleGprinterPlugin */
class BleGprinterPlugin : FlutterPlugin, MethodCallHandler, PrinterManager.PrinterCallback {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var context: Context
    private val foundDevices = mutableMapOf<String, PrinterDevice>()

    companion object {
        private const val TAG = "BleGprinterPlugin"
        private const val CHANNEL = "ble_gprinter"
        private const val EVENT_CHANNEL = "ble_gprinter/events"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "onAttachedToEngine: START")
        context = flutterPluginBinding.applicationContext
        Log.d(TAG, "onAttachedToEngine: context 获取成功")
        
        // 初始化PrinterManager
        PrinterManager.initialize(context)
        PrinterManager.setCallback(this)
        Log.d(TAG, "onAttachedToEngine: PrinterManager 初始化完成")
        
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        Log.d(TAG, "onAttachedToEngine: MethodChannel 初始化完成")
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                Log.d(TAG, "EventChannel onListen: eventSink 已设置")
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                Log.d(TAG, "EventChannel onCancel: eventSink 已清空")
            }
        })
        Log.d(TAG, "onAttachedToEngine: EventChannel 初始化完成")
        
        Log.d(TAG, "onAttachedToEngine: END")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "searchPrinters" -> searchPrinters(result)
            "stopSearch" -> stopSearch(result)
            "connectPrinter" -> connectPrinter(call, result)
            "disconnectPrinter" -> disconnectPrinter(result)
            "isConnected" -> isConnected(result)
            "printPdf" -> printPdf(call, result)
            "getPrinterStatus" -> getPrinterStatus(result)
            else -> result.notImplemented()
        }
    }

    private fun searchPrinters(result: Result) {
        Log.d(TAG, "searchPrinters: 开始搜索打印机")
        if (!checkBluetoothPermission()) {
            Log.e(TAG, "searchPrinters: 蓝牙权限未授予")
            result.error("PERMISSION_DENIED", "蓝牙权限未授予", null)
            return
        }
        
        // 检查蓝牙是否开启
        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? android.bluetooth.BluetoothManager
        val bluetoothAdapter = bluetoothManager?.adapter
        if (bluetoothAdapter == null) {
            Log.e(TAG, "searchPrinters: 蓝牙适配器不存在")
            result.error("BLUETOOTH_NOT_AVAILABLE", "设备不支持蓝牙", null)
            return
        }
        if (!bluetoothAdapter.isEnabled) {
            Log.e(TAG, "searchPrinters: 蓝牙未开启")
            result.error("BLUETOOTH_DISABLED", "请开启蓝牙", null)
            return
        }
        Log.d(TAG, "searchPrinters: 蓝牙适配器状态 isEnabled=${bluetoothAdapter.isEnabled}")
        
        foundDevices.clear()
        Log.d(TAG, "searchPrinters: 清空设备列表，调用PrinterManager.startSearch")
        
        try {
            PrinterManager.startSearch()
            Log.d(TAG, "searchPrinters: PrinterManager.startSearch 调用成功")
        } catch (e: Exception) {
            Log.e(TAG, "searchPrinters: PrinterManager.startSearch 调用失败", e)
            result.error("SEARCH_ERROR", "搜索失败: ${e.message}", null)
            return
        }
        
        result.success(true)
    }

    private fun stopSearch(result: Result) {
        PrinterManager.stopSearch()
        result.success(true)
    }

    private fun connectPrinter(call: MethodCall, result: Result) {
        val deviceAddress = call.argument<String>("deviceAddress")
        val deviceName = call.argument<String>("deviceName")
        
        Log.d(TAG, "connectPrinter: 尝试连接设备 address=$deviceAddress, name=$deviceName")
        
        if (deviceAddress == null) {
            Log.e(TAG, "connectPrinter: 设备地址为空")
            result.error("INVALID_ARGUMENT", "设备地址不能为空", null)
            return
        }

        // 从搜索到的设备中获取PrinterDevice对象
        val printerDevice = foundDevices[deviceAddress]
        if (printerDevice != null) {
            Log.d(TAG, "connectPrinter: 找到设备，开始连接 ${printerDevice.printerName}")
            Printer.connect(printerDevice)
            result.success(true)
        } else {
            Log.e(TAG, "connectPrinter: 设备未找到在缓存中，当前缓存设备数=${foundDevices.size}")
            result.error("DEVICE_NOT_FOUND", "设备未找到，请先搜索设备", null)
        }
    }

    private fun disconnectPrinter(result: Result) {
        PrinterManager.getCurrentPrinter()?.disconnect()
        result.success(true)
    }

    private fun isConnected(result: Result) {
        val printer = PrinterManager.getCurrentPrinter()
        result.success(printer != null && printer.isConnected)
    }

    private fun printPdf(call: MethodCall, result: Result) {
        val pdfPath = call.argument<String>("pdfPath")
        val width = call.argument<Int>("width") ?: 80
        val height = call.argument<Int>("height") ?: 120
        val dpi = call.argument<Int>("dpi") ?: 203
        val density = call.argument<Int>("density") ?: 8
        val speed = call.argument<Int>("speed") ?: 2
        val paperType = call.argument<Int>("paperType") ?: 1
        val instruction = call.argument<Int>("instruction") ?: 1 // 1=TSC

        if (pdfPath == null) {
            result.error("INVALID_ARGUMENT", "PDF路径不能为空", null)
            return
        }

        val printer = PrinterManager.getCurrentPrinter()
        if (printer == null || !printer.isConnected) {
            result.error("NOT_CONNECTED", "打印机未连接", null)
            return
        }

        printPdfFile(pdfPath, width, height, dpi, density, speed, paperType, instruction, result)
    }

    private fun getPrinterStatus(result: Result) {
        val printer = PrinterManager.getCurrentPrinter()
        if (printer == null || !printer.isConnected) {
            result.error("NOT_CONNECTED", "打印机未连接", null)
            return
        }

        printer.getPrinterStatus(Instruction.TSC, object : PrinterResponse<PrinterState> {
            override fun onPrinterResponse(state: PrinterState?) {
                if (state != null) {
                    val statusMap = mapOf(
                        "status" to state.status,
                        "isOutOfPaper" to state.isOutOfPaper,
                        "isOpenCover" to state.isOpenCover,
                        "isJampPaper" to state.isJampPaper,
                        "isPausePrint" to state.isPausePrint,
                        "isOtherError" to state.isOtherError
                    )
                    result.success(statusMap)
                } else {
                    result.error("STATUS_ERROR", "无法获取打印机状态", null)
                }
            }
        })
    }

    @SuppressLint("CheckResult")
    private fun printPdfFile(
        pdfPath: String,
        labelWidth: Int,
        labelHeight: Int,
        dpi: Int,
        density: Int,
        speed: Int,
        paperType: Int,
        instruction: Int,
        result: Result
    ) {
        val file = File(pdfPath)
        if (!file.exists()) {
            result.error("FILE_NOT_FOUND", "PDF文件不存在", null)
            return
        }
        
        val printer = PrinterManager.getCurrentPrinter()
        if (printer == null) {
            result.error("NOT_CONNECTED", "打印机未连接", null)
            return
        }

        Observable.create<Int> { emitter ->
            try {
                val fd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                val pdfRenderer = PdfRenderer(fd)
                val pageCount = pdfRenderer.pageCount

                for (i in 0 until pageCount) {
                    val page = pdfRenderer.openPage(i)
                    val bitmapWidth = if (dpi == 300) labelWidth * 12 else labelWidth * 8
                    val bitmapHeight = (page.height * bitmapWidth / page.width.toFloat()).toInt()
                    
                    val bitmap = Bitmap.createBitmap(bitmapWidth, bitmapHeight, Bitmap.Config.ARGB_8888)
                    bitmap.eraseColor(Color.WHITE)
                    page.render(bitmap, Rect(0, 0, bitmap.width, bitmap.height), null, PdfRenderer.Page.RENDER_MODE_FOR_PRINT)
                    page.close()

                    val config = PrinterConfig()
                    config.dpi = if (dpi == 300) Dpi.DPI_300 else Dpi.DPI_203
                    config.density = density
                    config.labelWidth = if (dpi == 300) bitmap.width / 12 else bitmap.width / 8
                    config.labelHeight = if (dpi == 300) bitmap.height / 12 else bitmap.height / 8
                    config.paperType = when (paperType) {
                        0 -> PaperType.PAPER_TYPE_CONTINUOUS
                        1 -> PaperType.PAPER_TYPE_INTERVAL
                        2 -> PaperType.PAPER_TYPE_BLACK_LINE
                        else -> PaperType.PAPER_TYPE_INTERVAL
                    }
                    config.speed = speed.toFloat()
                    config.printMode = PrintMode.DIRECT_THERMAL
                    config.instruction = when (instruction) {
                        0 -> Instruction.ESC
                        1 -> Instruction.TSC
                        2 -> Instruction.ZPL
                        3 -> Instruction.CPCL
                        else -> Instruction.TSC
                    }
                    config.isCompressBitmap = true
                    config.printCount = 1

                    printer.print(bitmap, 1, config)
                    Thread.sleep(100)
                }

                pdfRenderer.close()
                fd.close()
                emitter.onNext(pageCount)
                emitter.onComplete()
            } catch (e: Exception) {
                emitter.onError(e)
            }
        }
            .subscribeOn(Schedulers.io())
            .observeOn(AndroidSchedulers.mainThread())
            .subscribe(
                { pageCount ->
                    result.success(mapOf("success" to true, "pageCount" to pageCount))
                },
                { error ->
                    result.error("PRINT_ERROR", error.message, null)
                }
            )
    }

    private fun checkBluetoothPermission(): Boolean {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
        } else {
            arrayOf(
                Manifest.permission.BLUETOOTH,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
        }

        val allGranted = permissions.all { 
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED 
        }
        
        Log.d(TAG, "checkBluetoothPermission: SDK_INT=${Build.VERSION.SDK_INT}, allGranted=$allGranted")
        permissions.forEach {
            val granted = ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
            Log.d(TAG, "checkBluetoothPermission: $it = $granted")
        }
        
        return allGranted
    }

    // PrinterManager.PrinterCallback
    override fun onPrinterConnected(printer: Printer) {
        Log.d(TAG, "onPrinterConnected: 打印机连接成功")
        Log.d(TAG, "onPrinterConnected: eventSink=$eventSink")
        eventSink?.success(mapOf(
            "event" to "onPrinterConnected",
            "message" to "打印机已连接"
        ))
        Log.d(TAG, "onPrinterConnected: event sent")
    }

    override fun onPrinterConnectFail(printer: Printer) {
        Log.e(TAG, "onPrinterConnectFail: 打印机连接失败")
        eventSink?.success(mapOf(
            "event" to "onPrinterConnectFail",
            "message" to "打印机连接失败"
        ))
    }

    override fun onPrinterDisconnect(printer: Printer) {
        Log.d(TAG, "onPrinterDisconnect: 打印机已断开")
        eventSink?.success(mapOf(
            "event" to "onPrinterDisconnect",
            "message" to "打印机已断开"
        ))
    }
    
    @SuppressLint("MissingPermission")
    override fun onDeviceFound(device: PrinterDevice) {
        // 过滤只显示打印机设备
        if (device is BluetoothPrinterDevice) {
            val bluetoothDevice = device.bluetoothDevice
            val name = bluetoothDevice.name
            if (name != null) {
                // 只添加Gprinter打印机
                if (!name.startsWith("Printer") && !name.startsWith("Gprinter") && !name.startsWith("GP")) {
                    Log.d(TAG, "onDeviceFound: 过滤掉非打印机设备 $name")
                    return
                }
            } else {
                Log.d(TAG, "onDeviceFound: 过滤掉无名称设备")
                return
            }
        }
        
        val key = when (device) {
            is BluetoothPrinterDevice -> device.bluetoothDevice.address
            is UsbPrinterDevice -> "usb_${device.printerName}"
            is UsbAccessoryPrinterDevice -> "usb_accessory_${device.printerName}"
            is WifiPrinterDevice -> device.ip
            is SerialPortPrinterDevice -> "serial_${device.printerName}"
            else -> device.printerName
        }
        foundDevices[key] = device
        
        val eventData = when (device) {
            is BluetoothPrinterDevice -> mapOf(
                "event" to "onDeviceFound",
                "deviceType" to "bluetooth",
                "deviceAddress" to device.bluetoothDevice.address,
                "deviceName" to (device.bluetoothDevice.name ?: "Unknown")
            )
            is UsbPrinterDevice -> mapOf(
                "event" to "onDeviceFound",
                "deviceType" to "usb",
                "deviceName" to device.printerName
            )
            is WifiPrinterDevice -> mapOf(
                "event" to "onDeviceFound",
                "deviceType" to "wifi",
                "deviceAddress" to device.ip,
                "deviceName" to device.printerName
            )
            else -> mapOf(
                "event" to "onDeviceFound",
                "deviceType" to "other",
                "deviceName" to device.printerName
            )
        }
        Log.d(TAG, "onDeviceFound: $eventData")
        eventSink?.success(eventData)
    }
    
    override fun onSearchCompleted() {
        Log.d(TAG, "onSearchCompleted: 搜索完成，共发现${foundDevices.size}个设备")
        eventSink?.success(mapOf("event" to "onSearchCompleted"))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        PrinterManager.cleanup()
    }
}
