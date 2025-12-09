import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/registration.dart';
import '../../providers/registration_provider.dart';
import '../../providers/event_provider.dart';

class TicketTypesScreen extends StatefulWidget {
  const TicketTypesScreen({super.key});

  @override
  State<TicketTypesScreen> createState() => _TicketTypesScreenState();
}

class _TicketTypesScreenState extends State<TicketTypesScreen> {
  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final eventId = context.read<EventProvider>().selectedEvent?.id;
    if (eventId != null) {
      await context.read<RegistrationProvider>().loadTicketTypes(eventId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Types'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTickets),
        ],
      ),
      body: Consumer<RegistrationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.ticketTypes.isEmpty) {
            return _buildEmptyState(theme);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.ticketTypes.length,
            itemBuilder: (context, index) {
              final ticket = provider.ticketTypes[index];
              return _TicketCard(
                ticket: ticket,
                onEdit: () => _editTicket(ticket),
                onDelete: () => _deleteTicket(ticket),
                onToggle: () => _toggleTicket(ticket),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTicket,
        icon: const Icon(Icons.add),
        label: const Text('Add Ticket'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.confirmation_number,
              size: 80, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No ticket types configured',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 8),
          Text('Create ticket types for attendees to register',
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.4))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
              onPressed: _createTicket,
              icon: const Icon(Icons.add),
              label: const Text('Create Ticket Type')),
        ],
      ),
    );
  }

  void _createTicket() {
    _showTicketDialog(null);
  }

  void _editTicket(TicketType ticket) {
    _showTicketDialog(ticket);
  }

  Future<void> _deleteTicket(TicketType ticket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ticket Type'),
        content: Text('Are you sure you want to delete "${ticket.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<RegistrationProvider>().deleteTicketType(ticket.id);
    }
  }

  Future<void> _toggleTicket(TicketType ticket) async {
    final updated =
        ticket.copyWith(isActive: !ticket.isActive, updatedAt: DateTime.now());
    await context.read<RegistrationProvider>().updateTicketType(updated);
  }

  void _showTicketDialog(TicketType? ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _TicketFormSheet(
        ticket: ticket,
        onSave: (saved) async {
          if (ticket == null) {
            await context.read<RegistrationProvider>().createTicketType(saved);
          } else {
            await context.read<RegistrationProvider>().updateTicketType(saved);
          }
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketType ticket;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _TicketCard(
      {required this.ticket,
      required this.onEdit,
      required this.onDelete,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = ticket.isActive ? Colors.green : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.confirmation_number,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(ticket.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (ticket.isFree) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4)),
                              child: const Text('FREE',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                    ticket.isFree
                        ? 'Free'
                        : '\$${ticket.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
              ],
            ),
            if (ticket.description != null) ...[
              const SizedBox(height: 12),
              Text(ticket.description!,
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7))),
            ],
            const Divider(height: 24),
            Row(
              children: [
                _StatChip(label: 'Sold', value: '${ticket.sold}'),
                const SizedBox(width: 12),
                _StatChip(
                    label: 'Available',
                    value: ticket.quantity > 0 ? '${ticket.remaining}' : '∞'),
                const Spacer(),
                Switch(value: ticket.isActive, onChanged: (_) => onToggle()),
                IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TicketFormSheet extends StatefulWidget {
  final TicketType? ticket;
  final Function(TicketType) onSave;

  const _TicketFormSheet({this.ticket, required this.onSave});

  @override
  State<_TicketFormSheet> createState() => _TicketFormSheetState();
}

class _TicketFormSheetState extends State<_TicketFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _maxPerOrderController;
  bool _isFree = true;

  bool get isEditing => widget.ticket != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final t = widget.ticket!;
      _nameController = TextEditingController(text: t.name);
      _descriptionController = TextEditingController(text: t.description ?? '');
      _priceController = TextEditingController(text: t.price.toString());
      _quantityController = TextEditingController(
          text: t.quantity > 0 ? t.quantity.toString() : '');
      _maxPerOrderController =
          TextEditingController(text: t.maxPerOrder.toString());
      _isFree = t.isFree;
    } else {
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _priceController = TextEditingController(text: '0');
      _quantityController = TextEditingController();
      _maxPerOrderController = TextEditingController(text: '10');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _maxPerOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEditing ? 'Edit Ticket Type' : 'Create Ticket Type',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Ticket Name *',
                  hintText: 'e.g., General Admission, VIP'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What\'s included with this ticket?'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Free Ticket'),
              subtitle: const Text('No payment required'),
              value: _isFree,
              onChanged: (v) => setState(() => _isFree = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (!_isFree) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                    labelText: 'Price (\$)',
                    prefixIcon: Icon(Icons.attach_money)),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                        labelText: 'Quantity',
                        hintText: 'Leave empty for unlimited'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxPerOrderController,
                    decoration:
                        const InputDecoration(labelText: 'Max per Order'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? 'Save Changes' : 'Create Ticket'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final eventId = context.read<EventProvider>().selectedEvent?.id ?? '';
    final now = DateTime.now();

    final ticket = TicketType(
      id: widget.ticket?.id ?? const Uuid().v4(),
      eventId: eventId,
      name: _nameController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      price: _isFree ? 0 : (double.tryParse(_priceController.text) ?? 0),
      quantity: int.tryParse(_quantityController.text) ?? 0,
      sold: widget.ticket?.sold ?? 0,
      maxPerOrder: int.tryParse(_maxPerOrderController.text) ?? 10,
      isActive: widget.ticket?.isActive ?? true,
      createdAt: widget.ticket?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(ticket);
  }
}
