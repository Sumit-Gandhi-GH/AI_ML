import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';

class EventCreateScreen extends StatefulWidget {
  final Event? event;

  const EventCreateScreen({super.key, this.event});

  @override
  State<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends State<EventCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _venueController;
  late TextEditingController _descriptionController;
  late TextEditingController _capacityController;

  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;

  bool _isSubmitting = false;
  bool _allowDuplicateScans = false;
  bool _autoPrintOnCheckin = true;
  bool _requirePhotoVerification = false;

  bool get isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      final event = widget.event!;
      _nameController = TextEditingController(text: event.name);
      _venueController = TextEditingController(text: event.venue ?? '');
      _descriptionController =
          TextEditingController(text: event.description ?? '');
      _capacityController = TextEditingController(
        text: event.settings.maxCapacity > 0
            ? event.settings.maxCapacity.toString()
            : '',
      );
      _startDate = event.startDate;
      _startTime = TimeOfDay.fromDateTime(event.startDate);
      _endDate = event.endDate;
      _endTime = TimeOfDay.fromDateTime(event.endDate);
      _allowDuplicateScans = event.settings.allowDuplicateScans;
      _autoPrintOnCheckin = event.settings.autoPrintOnCheckin;
      _requirePhotoVerification = event.settings.requirePhotoVerification;
    } else {
      _nameController = TextEditingController();
      _venueController = TextEditingController();
      _descriptionController = TextEditingController();
      _capacityController = TextEditingController();
      _startDate = DateTime.now().add(const Duration(days: 7));
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endDate = DateTime.now().add(const Duration(days: 7));
      _endTime = const TimeOfDay(hour: 18, minute: 0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Event' : 'Create Event'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _saveEvent,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isEditing ? 'Save' : 'Create'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Event Details',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Event Name *',
                  hintText: 'e.g., Tech Conference 2024'),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter an event name'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Brief description of your event'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _venueController,
              decoration: const InputDecoration(
                  labelText: 'Venue',
                  hintText: 'e.g., Convention Center, San Francisco',
                  prefixIcon: Icon(Icons.location_on)),
            ),
            const SizedBox(height: 24),
            Text('Date & Time',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _DateTimeField(
                        label: 'Start',
                        date: _startDate,
                        time: _startTime,
                        onDateTap: () => _selectDate(true),
                        onTimeTap: () => _selectTime(true))),
                const SizedBox(width: 16),
                Expanded(
                    child: _DateTimeField(
                        label: 'End',
                        date: _endDate,
                        time: _endTime,
                        onDateTap: () => _selectDate(false),
                        onTimeTap: () => _selectTime(false))),
              ],
            ),
            const SizedBox(height: 24),
            Text('Capacity',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(
                  labelText: 'Maximum Attendees',
                  hintText: 'Leave empty for unlimited',
                  prefixIcon: Icon(Icons.people)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Text('Check-in Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Allow Duplicate Check-in'),
                    subtitle:
                        const Text('Attendees can check in multiple times'),
                    value: _allowDuplicateScans,
                    onChanged: (value) =>
                        setState(() => _allowDuplicateScans = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Print Badge on Check-in'),
                    subtitle:
                        const Text('Automatically trigger badge printing'),
                    value: _autoPrintOnCheckin,
                    onChanged: (value) =>
                        setState(() => _autoPrintOnCheckin = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Require Photo Verification'),
                    subtitle: const Text('Show attendee photo during check-in'),
                    value: _requirePhotoVerification,
                    onChanged: (value) =>
                        setState(() => _requirePhotoVerification = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _saveEvent,
                child: Text(isEditing ? 'Save Changes' : 'Create Event',
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final currentDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final currentTime = isStart ? _startTime : _endTime;
    final picked =
        await showTimePicker(context: context, initialTime: currentTime);
    if (picked != null) {
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final eventProvider = context.read<EventProvider>();

      final startDateTime = _combineDateTime(_startDate, _startTime);
      final endDateTime = _combineDateTime(_endDate, _endTime);

      final settings = EventSettings(
        allowDuplicateScans: _allowDuplicateScans,
        autoPrintOnCheckin: _autoPrintOnCheckin,
        requirePhotoVerification: _requirePhotoVerification,
        maxCapacity: int.tryParse(_capacityController.text) ?? 0,
      );

      if (isEditing) {
        final updated = widget.event!.copyWith(
          name: _nameController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          venue: _venueController.text.isEmpty ? null : _venueController.text,
          startDate: startDateTime,
          endDate: endDateTime,
          settings: settings,
          updatedAt: DateTime.now(),
        );
        await eventProvider.updateEvent(updated);
      } else {
        final event = Event(
          id: const Uuid().v4(),
          name: _nameController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          organizationId: authProvider.organizationId,
          venue: _venueController.text.isEmpty ? null : _venueController.text,
          startDate: startDateTime,
          endDate: endDateTime,
          settings: settings,
          stats: EventStats(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: authProvider.currentUser?.id ?? 'demo',
        );
        await eventProvider.createEvent(event);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEditing ? 'Event updated!' : 'Event created!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime date;
  final TimeOfDay time;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  const _DateTimeField(
      {required this.label,
      required this.date,
      required this.time,
      required this.onDateTap,
      required this.onTimeTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onDateTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 8),
              Text(dateFormat.format(date))
            ]),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTimeTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.access_time, size: 18),
              const SizedBox(width: 8),
              Text(time.format(context))
            ]),
          ),
        ),
      ],
    );
  }
}
