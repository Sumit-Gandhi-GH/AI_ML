import 'package:flutter/material.dart';
import '../../services/printer_service.dart';

class PrinterSetupScreen extends StatefulWidget {
  const PrinterSetupScreen({super.key});

  @override
  State<PrinterSetupScreen> createState() => _PrinterSetupScreenState();
}

class _PrinterSetupScreenState extends State<PrinterSetupScreen> {
  final _printerService = PrinterService();
  List<DiscoveredPrinter> _discoveredPrinters = [];
  bool _isDiscovering = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _printerService.onPrintersDiscovered = (printers) {
      setState(() => _discoveredPrinters = printers);
    };
  }

  Future<void> _discoverPrinters() async {
    setState(() {
      _isDiscovering = true;
      _discoveredPrinters = [];
    });

    try {
      final printers = await _printerService.discoverPrinters();
      setState(() => _discoveredPrinters = printers);
    } finally {
      setState(() => _isDiscovering = false);
    }
  }

  Future<void> _connectToPrinter(DiscoveredPrinter printer) async {
    setState(() => _isConnecting = true);

    try {
      final success = await _printerService.connect(printer);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${printer.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, printer);
      } else {
        _showError('Failed to connect to printer');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supported Printers',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _PrinterBrand(
                          name: 'Zebra',
                          models: ['ZD420', 'ZD621'],
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _PrinterBrand(
                          name: 'Brother',
                          models: ['QL-820', 'QL-1110'],
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Discover button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isDiscovering ? null : _discoverPrinters,
                icon: _isDiscovering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _isDiscovering ? 'Discovering...' : 'Discover Printers',
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Discovered printers
            if (_discoveredPrinters.isNotEmpty) ...[
              Text(
                'Available Printers',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _discoveredPrinters.length,
                  itemBuilder: (context, index) {
                    final printer = _discoveredPrinters[index];
                    return _PrinterListItem(
                      printer: printer,
                      isConnecting: _isConnecting,
                      onConnect: () => _connectToPrinter(printer),
                    );
                  },
                ),
              ),
            ] else if (!_isDiscovering) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.print_disabled,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No printers found',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Discover Printers" to search',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // Manual connection
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.wifi,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: const Text('Connect via IP Address'),
              subtitle: const Text('Enter printer IP manually'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showManualConnectDialog(),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualConnectDialog() {
    final ipController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.100',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PrinterModel>(
              decoration: const InputDecoration(
                labelText: 'Printer Model',
              ),
              items: PrinterModel.supportedModels.map((model) {
                return DropdownMenuItem(
                  value: model,
                  child: Text(model.name),
                );
              }).toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Connect with manual IP
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class _PrinterBrand extends StatelessWidget {
  final String name;
  final List<String> models;
  final Color color;

  const _PrinterBrand({
    required this.name,
    required this.models,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            models.join(', '),
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrinterListItem extends StatelessWidget {
  final DiscoveredPrinter printer;
  final bool isConnecting;
  final VoidCallback onConnect;

  const _PrinterListItem({
    required this.printer,
    required this.isConnecting,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    IconData connectionIcon;
    Color connectionColor;
    
    switch (printer.connectionType) {
      case PrinterConnectionType.bluetooth:
        connectionIcon = Icons.bluetooth;
        connectionColor = Colors.blue;
        break;
      case PrinterConnectionType.wifi:
        connectionIcon = Icons.wifi;
        connectionColor = Colors.green;
        break;
      case PrinterConnectionType.usb:
        connectionIcon = Icons.usb;
        connectionColor = Colors.orange;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: connectionColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(connectionIcon, color: connectionColor),
        ),
        title: Text(printer.name),
        subtitle: Text(
          printer.connectionType == PrinterConnectionType.wifi
              ? printer.ipAddress ?? 'Unknown IP'
              : printer.macAddress ?? 'Unknown MAC',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: isConnecting ? null : onConnect,
          child: isConnecting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Connect'),
        ),
      ),
    );
  }
}
