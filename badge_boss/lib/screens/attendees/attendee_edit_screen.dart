import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/attendee.dart';
import '../../providers/attendee_provider.dart';
import '../../providers/event_provider.dart';

class AttendeeEditScreen extends StatefulWidget {
  final Attendee? attendee;

  const AttendeeEditScreen({super.key, this.attendee});

  @override
  State<AttendeeEditScreen> createState() => _AttendeeEditScreenState();
}

class _AttendeeEditScreenState extends State<AttendeeEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _companyController;
  late TextEditingController _titleController;
  late TextEditingController _phoneController;

  String _category = 'general';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final a = widget.attendee;
    _firstNameController = TextEditingController(text: a?.firstName ?? '');
    _lastNameController = TextEditingController(text: a?.lastName ?? '');
    _emailController = TextEditingController(text: a?.email ?? '');
    _companyController = TextEditingController(text: a?.company ?? '');
    _titleController = TextEditingController(text: a?.title ?? '');
    _phoneController = TextEditingController(text: a?.phone ?? '');
    _category = a?.category ?? 'general';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _titleController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final eventId = context.read<EventProvider>().selectedEvent?.id;
      final organizationId =
          context.read<EventProvider>().selectedEvent?.organizationId ??
              'default_org';

      if (eventId == null) throw Exception('No event selected');

      final provider = context.read<AttendeeProvider>();

      if (widget.attendee != null) {
        // Update
        final updated = widget.attendee!.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          company: _companyController.text.trim(),
          title: _titleController.text.trim(),
          phone: _phoneController.text.trim(),
          category: _category,
          updatedAt: DateTime.now(),
        );
        await provider.updateAttendee(updated);
      } else {
        // Create
        final newAttendee = Attendee(
          id: const Uuid().v4(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          company: _companyController.text.trim(),
          title: _titleController.text.trim(),
          phone: _phoneController.text.trim(),
          category: _category,
          qrCode: const Uuid().v4(),
          eventId: eventId,
          organizationId: organizationId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          registrationSource: 'manual',
        );
        await provider.addAttendee(newAttendee);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendee saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.attendee == null ? 'Add Attendee' : 'Edit Attendee'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _save,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                                labelText: 'First Name *'),
                            validator: (v) =>
                                v?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration:
                                const InputDecoration(labelText: 'Last Name *'),
                            validator: (v) =>
                                v?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email *'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(labelText: 'Company'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Job Title'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    const Text('Category',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'general', child: Text('General')),
                        DropdownMenuItem(value: 'vip', child: Text('VIP')),
                        DropdownMenuItem(
                            value: 'speaker', child: Text('Speaker')),
                        DropdownMenuItem(
                            value: 'sponsor', child: Text('Sponsor')),
                        DropdownMenuItem(value: 'staff', child: Text('Staff')),
                        DropdownMenuItem(value: 'media', child: Text('Media')),
                        DropdownMenuItem(
                            value: 'exhibitor', child: Text('Exhibitor')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _category = v);
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
