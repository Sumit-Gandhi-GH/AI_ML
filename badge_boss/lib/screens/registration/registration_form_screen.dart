import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/registration.dart';
import '../../models/event.dart';
import '../../providers/registration_provider.dart';
import '../../providers/event_provider.dart';

/// Public-facing registration form for attendees
class RegistrationFormScreen extends StatefulWidget {
  final String? eventId;

  const RegistrationFormScreen({super.key, this.eventId});

  @override
  State<RegistrationFormScreen> createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _companyController;
  late TextEditingController _titleController;
  late TextEditingController _promoCodeController;

  TicketType? _selectedTicket;
  int _quantity = 1;
  double _discount = 0;
  PromoCode? _appliedPromo;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _companyController = TextEditingController();
    _titleController = TextEditingController();
    _promoCodeController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final eventId =
        widget.eventId ?? context.read<EventProvider>().selectedEvent?.id;
    if (eventId != null) {
      await context.read<RegistrationProvider>().loadTicketTypes(eventId);
      await context.read<RegistrationProvider>().loadPromoCodes(eventId);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _titleController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = context.watch<EventProvider>().selectedEvent;

    return Scaffold(
      appBar: AppBar(title: Text(event?.name ?? 'Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event header
              if (event != null) _buildEventHeader(theme, event),
              const SizedBox(height: 24),

              // Ticket selection
              Text('Select Ticket',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Consumer<RegistrationProvider>(
                builder: (context, provider, _) {
                  final tickets =
                      provider.activeTickets.where((t) => t.isOnSale).toList();
                  if (tickets.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.event_busy,
                                  size: 48,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.3)),
                              const SizedBox(height: 12),
                              Text('No tickets available',
                                  style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6))),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: tickets
                        .map((ticket) => _TicketOption(
                              ticket: ticket,
                              isSelected: _selectedTicket?.id == ticket.id,
                              onTap: () => setState(() {
                                _selectedTicket = ticket;
                                _applyPromoCode();
                              }),
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Quantity
              if (_selectedTicket != null &&
                  _selectedTicket!.maxPerOrder > 1) ...[
                Row(
                  children: [
                    Text('Quantity', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_quantity',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: _quantity < _selectedTicket!.maxPerOrder
                          ? () => setState(() => _quantity++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Personal Information
              Text('Personal Information',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration:
                          const InputDecoration(labelText: 'First Name *'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration:
                          const InputDecoration(labelText: 'Last Name *'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Email *', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                    labelText: 'Company/Organization',
                    prefixIcon: Icon(Icons.business)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'Job Title', prefixIcon: Icon(Icons.work)),
              ),
              const SizedBox(height: 24),

              // Promo Code
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _promoCodeController,
                      decoration: InputDecoration(
                        labelText: 'Promo Code',
                        prefixIcon: const Icon(Icons.local_offer),
                        suffixIcon: _appliedPromo != null
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                      onPressed: _applyPromoCode, child: const Text('Apply')),
                ],
              ),
              if (_discount > 0) ...[
                const SizedBox(height: 8),
                Text('Discount applied: -\$${_discount.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: Colors.green[700], fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 32),

              // Order Summary
              if (_selectedTicket != null) ...[
                Card(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Summary',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_selectedTicket!.name} x $_quantity'),
                            Text(
                                '\$${(_selectedTicket!.price * _quantity).toStringAsFixed(2)}'),
                          ],
                        ),
                        if (_discount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount'),
                              Text('-\$${_discount.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.green)),
                            ],
                          ),
                        ],
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text('\$${_calculateTotal().toStringAsFixed(2)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _selectedTicket == null || _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          _calculateTotal() == 0
                              ? 'Complete Registration'
                              : 'Proceed to Payment',
                          style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventHeader(ThemeData theme, Event event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12)),
              child:
                  Icon(Icons.event, color: theme.colorScheme.primary, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (event.venue != null)
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(event.venue!,
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6))),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyPromoCode() {
    if (_promoCodeController.text.isEmpty || _selectedTicket == null) {
      setState(() {
        _appliedPromo = null;
        _discount = 0;
      });
      return;
    }

    final promo = context.read<RegistrationProvider>().validatePromoCode(
          _promoCodeController.text,
          _selectedTicket!.id,
        );

    if (promo != null) {
      setState(() {
        _appliedPromo = promo;
        _discount = promo.calculateDiscount(
            _selectedTicket!.price * _quantity, _selectedTicket!.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Promo code applied!'),
            backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invalid promo code'), backgroundColor: Colors.red),
      );
    }
  }

  double _calculateTotal() {
    if (_selectedTicket == null) return 0;
    return (_selectedTicket!.price * _quantity) - _discount;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedTicket == null) return;

    setState(() => _isSubmitting = true);

    try {
      final eventId = widget.eventId ??
          context.read<EventProvider>().selectedEvent?.id ??
          '';
      final total = _calculateTotal();

      final registration = Registration(
        id: const Uuid().v4(),
        eventId: eventId,
        ticketTypeId: _selectedTicket!.id,
        ticketTypeName: _selectedTicket!.name,
        email: _emailController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        customFields: {
          'company': _companyController.text,
          'title': _titleController.text,
        },
        status: total == 0
            ? RegistrationStatus.confirmed
            : RegistrationStatus.pending,
        amountPaid: total,
        promoCode: _appliedPromo?.code,
        discount: _discount,
        confirmationCode:
            'BB-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await context
          .read<RegistrationProvider>()
          .createRegistration(registration);

      if (mounted) {
        if (total == 0) {
          // Free registration - show confirmation
          _showConfirmation(registration);
        } else {
          // Paid registration - would normally redirect to Stripe
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Payment integration coming soon! Registration saved as pending.')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showConfirmation(Registration reg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 32),
            const SizedBox(width: 12),
            const Text('Registration Confirmed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thank you, ${reg.firstName}!'),
            const SizedBox(height: 16),
            Text('Confirmation Code:',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6))),
            Text(reg.confirmationCode ?? '',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(height: 16),
            const Text('A confirmation email will be sent to your address.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _TicketOption extends StatelessWidget {
  final TicketType ticket;
  final bool isSelected;
  final VoidCallback onTap;

  const _TicketOption(
      {required this.ticket, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: isSelected,
                onChanged: (_) => onTap(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (ticket.description != null)
                      Text(ticket.description!,
                          style: TextStyle(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 13)),
                    if (ticket.quantity > 0)
                      Text('${ticket.remaining} remaining',
                          style: TextStyle(
                              color: Colors.orange[700], fontSize: 12)),
                  ],
                ),
              ),
              Text(
                ticket.isFree ? 'FREE' : '\$${ticket.price.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ticket.isFree
                        ? Colors.green
                        : theme.colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
