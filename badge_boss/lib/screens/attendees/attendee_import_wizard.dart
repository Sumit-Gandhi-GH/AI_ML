import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/attendee.dart';
import '../../providers/attendee_provider.dart';
import '../../providers/event_provider.dart';
import '../../services/import_service.dart';

class AttendeeImportWizard extends StatefulWidget {
  const AttendeeImportWizard({super.key});

  @override
  State<AttendeeImportWizard> createState() => _AttendeeImportWizardState();
}

class _AttendeeImportWizardState extends State<AttendeeImportWizard> {
  final ImportService _importService = ImportService();
  int _currentStep = 0;
  ImportResult? _importResult;
  Map<String, String?> _columnMapping = {};
  bool _isImporting = false;
  int _importCount = 0;

  // Required and optional fields to map
  final Map<String, String> _targetFields = {
    'firstName': 'First Name *',
    'lastName': 'Last Name *',
    'email': 'Email *',
    'company': 'Company',
    'title': 'Job Title',
    'phone': 'Phone',
    'category': 'Category (VIP, Speaker...)',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Attendees'),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              children: [
                if (_currentStep < 3)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child:
                        Text(_currentStep == 2 ? 'Start Import' : 'Continue'),
                  ),
                if (_currentStep > 0 && _currentStep < 3) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Upload'),
            content: _buildUploadStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Preview'),
            content: _buildPreviewStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Map Columns'),
            content: _buildMappingStep(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Import'),
            content: _buildImportStep(),
            isActive: _currentStep >= 3,
            state: _currentStep == 3
                ? StepState.indexed
                : StepState.disabled, // Fix for Stepper state logic
          ),
        ],
      ),
    );
  }

  Widget _buildUploadStep() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border:
            Border.all(color: Colors.grey.shade400, style: BorderStyle.none),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload, size: 48, color: Colors.blue),
          const SizedBox(height: 16),
          const Text('Upload CSV or Excel file'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _pickFile,
            child: const Text('Select File'),
          ),
          if (_importResult != null) ...[
            const SizedBox(height: 16),
            Text('Selected: ${_importResult!.fileName}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewStep() {
    if (_importResult == null) return const Text('No file loaded');

    // Show first 5 rows
    final headers = _importResult!.headers;
    final rows = _importResult!.rows.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('File: ${_importResult!.fileName}'),
        Text('${_importResult!.rows.length} rows found'),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
            rows: rows.map((row) {
              return DataRow(
                cells:
                    row.map((cell) => DataCell(Text(cell.toString()))).toList(),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMappingStep() {
    if (_importResult == null) return const SizedBox();

    return Column(
      children: _targetFields.entries.map((entry) {
        final fieldKey = entry.key;
        final label = entry.value;
        final headers = _importResult!.headers;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.bold))),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    hintText: 'Select Column',
                    isDense: true,
                  ),
                  value: _columnMapping[fieldKey],
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Ignore')),
                    ...headers
                        .map((h) => DropdownMenuItem(value: h, child: Text(h))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _columnMapping[fieldKey] = value;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImportStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isImporting) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Importing attendees...'),
          ] else ...[
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text('Successfully imported $_importCount attendees!'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Return to Dashboard'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await _importService.pickAndParseFile();
    if (result != null) {
      setState(() {
        _importResult = result;
        _autoMapColumns();
      });
    }
  }

  void _autoMapColumns() {
    if (_importResult == null) return;
    final headers = _importResult!.headers;

    // Simple heuristic for auto-mapping
    for (var header in headers) {
      final h = header.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

      _targetFields.forEach((key, label) {
        if (_columnMapping[key] != null) return; // Already mapped

        if (h.contains(key.toLowerCase()) ||
            (key == 'firstName' && h.contains('first')) ||
            (key == 'lastName' && h.contains('last')) ||
            (key == 'email' && h.contains('mail'))) {
          _columnMapping[key] = header;
        }
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_importResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a file')));
        return;
      }
    } else if (_currentStep == 2) {
      // Validate required mappings
      if (_columnMapping['firstName'] == null ||
          _columnMapping['lastName'] == null ||
          _columnMapping['email'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please map all required fields (*).')));
        return;
      }

      // Start import
      _runImport();
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _runImport() async {
    setState(() => _isImporting = true);

    try {
      final rows = _importResult!.rows;
      final headers = _importResult!.headers;
      final eventId = context.read<EventProvider>().selectedEvent?.id;
      final organizationId =
          context.read<EventProvider>().selectedEvent?.organizationId ??
              'default_org';

      if (eventId == null) throw Exception('No event selected');

      final attendees = <Attendee>[];
      final now = DateTime.now();

      for (var row in rows) {
        // Helper to get value by mapped column
        String? getValue(String fieldKey) {
          final colName = _columnMapping[fieldKey];
          if (colName == null) return null;
          final index = headers.indexOf(colName);
          if (index == -1 || index >= row.length) return null;
          return row[index].toString();
        }

        final firstName = getValue('firstName') ?? '';
        final lastName = getValue('lastName') ?? '';
        final email = getValue('email') ?? '';

        if (email.isEmpty) continue; // Skip if no email

        attendees.add(Attendee(
          id: const Uuid().v4(),
          firstName: firstName,
          lastName: lastName,
          email: email,
          company: getValue('company'),
          title: getValue('title'),
          phone: getValue('phone'),
          category: getValue('category') ?? 'general',
          qrCode: const Uuid().v4(), // Generate unique QR
          eventId: eventId,
          organizationId: organizationId,
          createdAt: now,
          updatedAt: now,
          registrationSource: 'import',
        ));
      }

      final count =
          await context.read<AttendeeProvider>().bulkCreateAttendees(attendees);

      setState(() {
        _importCount = count;
        _isImporting = false;
      });
    } catch (e) {
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Import error: $e')));
    }
  }
}
