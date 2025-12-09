import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Printer connection type
enum PrinterConnectionType {
  bluetooth,
  wifi,
  usb,
}

/// Printer model configuration
class PrinterModel {
  final String id;
  final String name;
  final String manufacturer; // 'zebra' or 'brother'
  final int dpi;
  final double labelWidthMm;
  final double labelHeightMm;

  const PrinterModel({
    required this.id,
    required this.name,
    required this.manufacturer,
    this.dpi = 203,
    this.labelWidthMm = 100,
    this.labelHeightMm = 70,
  });

  static const zebraZd420 = PrinterModel(
    id: 'zebra_zd420',
    name: 'Zebra ZD420',
    manufacturer: 'zebra',
    dpi: 203,
  );

  static const zebraZd621 = PrinterModel(
    id: 'zebra_zd621',
    name: 'Zebra ZD621',
    manufacturer: 'zebra',
    dpi: 300,
  );

  static const brotherQl820 = PrinterModel(
    id: 'brother_ql820',
    name: 'Brother QL-820NWB',
    manufacturer: 'brother',
    dpi: 300,
    labelWidthMm: 62,
    labelHeightMm: 100,
  );

  static const brotherQl1110 = PrinterModel(
    id: 'brother_ql1110',
    name: 'Brother QL-1110NWB',
    manufacturer: 'brother',
    dpi: 300,
    labelWidthMm: 102,
    labelHeightMm: 152,
  );

  static List<PrinterModel> get supportedModels => [
    zebraZd420,
    zebraZd621,
    brotherQl820,
    brotherQl1110,
  ];
}

/// Discovered printer
class DiscoveredPrinter {
  final String id;
  final String name;
  final PrinterConnectionType connectionType;
  final String? macAddress;
  final String? ipAddress;
  final PrinterModel? model;

  DiscoveredPrinter({
    required this.id,
    required this.name,
    required this.connectionType,
    this.macAddress,
    this.ipAddress,
    this.model,
  });
}

/// Print job status
enum PrintJobStatus {
  queued,
  printing,
  completed,
  failed,
}

/// Print job
class PrintJob {
  final String id;
  final String attendeeId;
  final String badgeData;
  PrintJobStatus status;
  int retryCount;
  String? errorMessage;
  final DateTime createdAt;
  DateTime? completedAt;

  PrintJob({
    required this.id,
    required this.attendeeId,
    required this.badgeData,
    this.status = PrintJobStatus.queued,
    this.retryCount = 0,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });
}

/// Printer service for Zebra and Brother thermal printers
class PrinterService {
  DiscoveredPrinter? _connectedPrinter;
  final List<PrintJob> _printQueue = [];
  bool _isPrinting = false;
  Timer? _queueTimer;

  // Callbacks
  Function(PrintJob)? onPrintComplete;
  Function(PrintJob, String)? onPrintError;
  Function(List<DiscoveredPrinter>)? onPrintersDiscovered;

  DiscoveredPrinter? get connectedPrinter => _connectedPrinter;
  List<PrintJob> get printQueue => List.unmodifiable(_printQueue);
  bool get isConnected => _connectedPrinter != null;
  bool get isPrinting => _isPrinting;
  int get queueLength => _printQueue.length;

  /// Discover available printers
  Future<List<DiscoveredPrinter>> discoverPrinters({
    PrinterConnectionType? type,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final printers = <DiscoveredPrinter>[];

    // TODO: Implement actual Bluetooth/WiFi discovery
    // For now, return mock printers for testing
    
    // Simulate discovery delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock discovered printers
    printers.add(DiscoveredPrinter(
      id: 'mock_zebra_1',
      name: 'Zebra ZD420 (Mock)',
      connectionType: PrinterConnectionType.bluetooth,
      macAddress: 'AA:BB:CC:DD:EE:FF',
      model: PrinterModel.zebraZd420,
    ));

    printers.add(DiscoveredPrinter(
      id: 'mock_brother_1',
      name: 'Brother QL-820 (Mock)',
      connectionType: PrinterConnectionType.wifi,
      ipAddress: '192.168.1.100',
      model: PrinterModel.brotherQl820,
    ));

    onPrintersDiscovered?.call(printers);
    return printers;
  }

  /// Connect to a printer
  Future<bool> connect(DiscoveredPrinter printer) async {
    try {
      // TODO: Implement actual connection logic
      // For Zebra: Use Zebra Link-OS SDK
      // For Brother: Use Brother Print SDK
      
      await Future.delayed(const Duration(seconds: 1));
      
      _connectedPrinter = printer;
      _startQueueProcessor();
      
      return true;
    } catch (e) {
      debugPrint('Failed to connect to printer: $e');
      return false;
    }
  }

  /// Disconnect from current printer
  Future<void> disconnect() async {
    _stopQueueProcessor();
    _connectedPrinter = null;
  }

  /// Add a print job to the queue
  Future<String> queuePrint({
    required String attendeeId,
    required String zplData,
  }) async {
    final jobId = 'job_${DateTime.now().millisecondsSinceEpoch}';
    
    final job = PrintJob(
      id: jobId,
      attendeeId: attendeeId,
      badgeData: zplData,
      createdAt: DateTime.now(),
    );

    _printQueue.add(job);
    
    // Trigger immediate processing if not already printing
    if (!_isPrinting && isConnected) {
      _processQueue();
    }

    return jobId;
  }

  /// Print immediately (skip queue)
  Future<bool> printNow({
    required String attendeeId,
    required String zplData,
  }) async {
    if (!isConnected) return false;

    final jobId = await queuePrint(attendeeId: attendeeId, zplData: zplData);
    final job = _printQueue.firstWhere((j) => j.id == jobId);
    
    // Move to front of queue
    _printQueue.remove(job);
    _printQueue.insert(0, job);

    return true;
  }

  /// Generate ZPL from template and attendee data
  String generateZpl({
    required String template,
    required Map<String, dynamic> data,
  }) {
    var zpl = template;
    
    // Replace placeholders with actual data
    data.forEach((key, value) {
      zpl = zpl.replaceAll('{{$key}}', value?.toString() ?? '');
    });

    return zpl;
  }

  /// Standard badge ZPL template
  static String get standardBadgeTemplate => '''
^XA
^CF0,60
^FO50,30^FD{{firstName}} {{lastName}}^FS
^CF0,35
^FO50,100^FD{{company}}^FS
^CF0,25
^FO50,145^FD{{title}}^FS
^FO580,30^BQN,2,6^FDQA,{{qrCode}}^FS
^FO0,190^GB800,40,40,B^FS
^CF0,25
^FO300,200^FR^FD{{category}}^FS
^XZ
''';

  void _startQueueProcessor() {
    _queueTimer?.cancel();
    _queueTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _processQueue(),
    );
  }

  void _stopQueueProcessor() {
    _queueTimer?.cancel();
    _queueTimer = null;
  }

  Future<void> _processQueue() async {
    if (_isPrinting || _printQueue.isEmpty || !isConnected) return;

    _isPrinting = true;

    while (_printQueue.isNotEmpty && isConnected) {
      final job = _printQueue.first;
      job.status = PrintJobStatus.printing;

      try {
        await _sendToPrinter(job.badgeData);
        
        job.status = PrintJobStatus.completed;
        job.completedAt = DateTime.now();
        _printQueue.remove(job);
        
        onPrintComplete?.call(job);
      } catch (e) {
        job.retryCount++;
        job.errorMessage = e.toString();

        if (job.retryCount >= 3) {
          job.status = PrintJobStatus.failed;
          _printQueue.remove(job);
          onPrintError?.call(job, e.toString());
        } else {
          // Move to end of queue for retry
          _printQueue.remove(job);
          _printQueue.add(job);
        }
      }

      // Small delay between prints
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _isPrinting = false;
  }

  Future<void> _sendToPrinter(String zplData) async {
    if (_connectedPrinter == null) {
      throw Exception('No printer connected');
    }

    final printer = _connectedPrinter!;
    
    // TODO: Implement actual printer communication
    if (printer.model?.manufacturer == 'zebra') {
      await _sendToZebraPrinter(zplData, printer);
    } else if (printer.model?.manufacturer == 'brother') {
      await _sendToBrotherPrinter(zplData, printer);
    }

    // Simulate print time
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _sendToZebraPrinter(String zplData, DiscoveredPrinter printer) async {
    // TODO: Implement Zebra Link-OS SDK integration
    // Example using zsdk package or direct socket connection:
    //
    // if (printer.connectionType == PrinterConnectionType.bluetooth) {
    //   final connection = BluetoothConnection(printer.macAddress!);
    //   await connection.open();
    //   await connection.write(Uint8List.fromList(zplData.codeUnits));
    //   await connection.close();
    // } else if (printer.connectionType == PrinterConnectionType.wifi) {
    //   final socket = await Socket.connect(printer.ipAddress!, 9100);
    //   socket.add(Uint8List.fromList(zplData.codeUnits));
    //   await socket.flush();
    //   await socket.close();
    // }
    
    debugPrint('Sending to Zebra printer: ${zplData.length} bytes');
  }

  Future<void> _sendToBrotherPrinter(String zplData, DiscoveredPrinter printer) async {
    // TODO: Implement Brother Print SDK integration
    // Brother uses different command language (ESC/P or raster)
    // May need to convert ZPL to Brother-compatible format
    
    debugPrint('Sending to Brother printer: ${zplData.length} bytes');
  }

  /// Cancel a print job
  void cancelJob(String jobId) {
    _printQueue.removeWhere((job) => job.id == jobId);
  }

  /// Clear all queued jobs
  void clearQueue() {
    _printQueue.clear();
  }

  /// Test print
  Future<bool> testPrint() async {
    if (!isConnected) return false;

    const testZpl = '''
^XA
^CF0,40
^FO50,50^FDBadge Boss^FS
^CF0,30
^FO50,100^FDTest Print^FS
^CF0,20
^FO50,140^FD{{timestamp}}^FS
^FO500,50^BQN,2,5^FDQA,BADGEBOSS_TEST^FS
^XZ
''';

    final zpl = testZpl.replaceAll(
      '{{timestamp}}',
      DateTime.now().toIso8601String(),
    );

    await queuePrint(attendeeId: 'test', zplData: zpl);
    return true;
  }

  void dispose() {
    _stopQueueProcessor();
    _printQueue.clear();
  }
}
