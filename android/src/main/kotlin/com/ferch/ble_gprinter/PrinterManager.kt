package com.ferch.ble_gprinter

import android.content.Context
import android.util.Log
import com.gainscha.sdk2.ConnectionListener
import com.gainscha.sdk2.Printer
import com.gainscha.sdk2.PrinterFinder

object PrinterManager : ConnectionListener, PrinterFinder.SearchPrinterResultListener {
    private const val TAG = "PrinterManager"
    
    private var context: Context? = null
    private var currentPrinter: Printer? = null
    private val finder = PrinterFinder()
    
    // 回调接口
    interface PrinterCallback {
        fun onPrinterConnected(printer: Printer)
        fun onPrinterConnectFail(printer: Printer)
        fun onPrinterDisconnect(printer: Printer)
        fun onDeviceFound(device: com.gainscha.sdk2.model.PrinterDevice)
        fun onSearchCompleted()
    }
    
    private var callback: PrinterCallback? = null
    
    fun initialize(appContext: Context) {
        if (context != null) {
            Log.d(TAG, "PrinterManager already initialized")
            return
        }
        context = appContext
        Printer.setLogEnable(true, null)
        Printer.addConnectionListener(this)
        Log.d(TAG, "PrinterManager initialized")
    }
    
    fun startSearch() {
        Log.d(TAG, "startSearch: finder=$finder")
        finder.searchPrinters(this)
    }
    
    fun stopSearch() {
        Log.d(TAG, "stopSearch: finder=$finder")
        finder.stopSearchDevice()
    }
    
    fun setCallback(cb: PrinterCallback?) {
        callback = cb
        Log.d(TAG, "Callback set: ${cb != null}")
    }
    
    fun getCurrentPrinter(): Printer? = currentPrinter
    
    // ConnectionListener
    override fun onPrinterConnected(printer: Printer) {
        currentPrinter = printer
        printer.setAutoReConnect(true, 3)
        Log.d(TAG, "onPrinterConnected: 打印机连接成功，已启用自动重连")
        callback?.onPrinterConnected(printer)
    }
    
    override fun onPrinterConnectFail(printer: Printer) {
        currentPrinter = null
        Log.e(TAG, "onPrinterConnectFail: 打印机连接失败")
        callback?.onPrinterConnectFail(printer)
    }
    
    override fun onPrinterDisconnect(printer: Printer) {
        if (currentPrinter == printer) {
            currentPrinter = null
        }
        Log.d(TAG, "onPrinterDisconnect: 打印机已断开")
        callback?.onPrinterDisconnect(printer)
    }
    
    // SearchPrinterResultListener
    override fun onSearchBluetoothPrinter(device: com.gainscha.sdk2.model.BluetoothPrinterDevice?) {
        Log.d(TAG, "onSearchBluetoothPrinter: CALLED, device=$device")
        if (device != null) {
            Log.d(TAG, "onSearchBluetoothPrinter: 发现蓝牙设备 ${device.bluetoothDevice?.name}")
            callback?.onDeviceFound(device)
        } else {
            Log.w(TAG, "onSearchBluetoothPrinter: device is null")
        }
    }
    
    override fun onSearchUsbPrinter(device: com.gainscha.sdk2.model.UsbPrinterDevice) {
        Log.d(TAG, "onSearchUsbPrinter: 发现USB设备 ${device.printerName}")
        callback?.onDeviceFound(device)
    }
    
    override fun onSearchUsbPrinter(device: com.gainscha.sdk2.model.UsbAccessoryPrinterDevice) {
        Log.d(TAG, "onSearchUsbPrinter: 发现USB Accessory设备 ${device.printerName}")
        callback?.onDeviceFound(device)
    }
    
    override fun onSearchNetworkPrinter(device: com.gainscha.sdk2.model.WifiPrinterDevice) {
        Log.d(TAG, "onSearchNetworkPrinter: 发现WiFi设备 ${device.printerName}")
        callback?.onDeviceFound(device)
    }
    
    override fun onSearchSerialPortPrinter(device: com.gainscha.sdk2.model.SerialPortPrinterDevice) {
        Log.d(TAG, "onSearchSerialPortPrinter: 发现串口设备 ${device.printerName}")
        callback?.onDeviceFound(device)
    }
    
    override fun onSearchCompleted() {
        Log.d(TAG, "onSearchCompleted: 搜索完成")
        callback?.onSearchCompleted()
    }
    
    fun cleanup() {
        Printer.removeConnectionListener(this)
        finder.stopSearchDevice()
        callback = null
        currentPrinter = null
        Log.d(TAG, "PrinterManager cleaned up")
    }
}
