import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/attendee.dart';
import '../../providers/checkin_provider.dart';
import '../../providers/attendee_provider.dart';
import '../../widgets/common/attendee_card.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final _searchController = TextEditingController();
  final _qrController = TextEditingController();
  bool _showScanner = true;

  @override
  void dispose() {
    _searchController.dispose();
    _qrController.dispose();
    super.dispose();
  }

  void _showCheckinResult(CheckinResponse response) {
    final theme = Theme.of(context);

    // Vibration feedback
    if (response.result == CheckinResult.success) {
      Vibration.vibrate(duration: 100);
    } else {
      Vibration.vibrate(duration: 50);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CheckinResultSheet(response: response),
    );
  }

  Future<void> _handleQrScan(String code) async {
    if (code.isEmpty) return;

    final checkinProvider = context.read<CheckinProvider>();
    final response = await checkinProvider.processQrScan(code);
    _showCheckinResult(response);
    _qrController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildStatsBar(theme),
        _buildModeToggle(theme),
        Expanded(
          child:
              _showScanner ? _buildScannerView(theme) : _buildSearchView(theme),
        ),
      ],
    );
  }

  Widget _buildStatsBar(ThemeData theme) {
    return Consumer<AttendeeProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Checked In',
                  value: '${provider.checkedInCount}',
                  total: '/ ${provider.totalCount}',
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'Percentage',
                  value: '${provider.checkinPercentage.toStringAsFixed(1)}%',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'Remaining',
                  value: '${provider.totalCount - provider.checkedInCount}',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeToggle(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              icon: Icons.qr_code_scanner,
              label: 'Scan',
              isSelected: _showScanner,
              onTap: () => setState(() => _showScanner = true),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              icon: Icons.search,
              label: 'Search',
              isSelected: !_showScanner,
              onTap: () => setState(() => _showScanner = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  MobileScanner(
                    controller: MobileScannerController(
                      detectionSpeed: DetectionSpeed.noDuplicates,
                      facing: CameraFacing.back,
                      torchEnabled: false,
                    ),
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          _handleQrScan(barcode.rawValue!);
                          break; // Only process first code
                        }
                      }
                    },
                  ),
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: theme.colorScheme.primary, width: 4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 2,
                                    )
                                  ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Point camera at attendee badge',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _qrController,
            decoration: InputDecoration(
              hintText: 'Or enter code manually...',
              prefixIcon: const Icon(Icons.keyboard),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleQrScan(_qrController.text),
              ),
            ),
            onSubmitted: _handleQrScan,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchView(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              context.read<AttendeeProvider>().searchAttendees(value);
            },
            decoration: InputDecoration(
              hintText: 'Search by name, email, or company...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<AttendeeProvider>().clearSearch();
                      },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: Consumer<AttendeeProvider>(
            builder: (context, provider, _) {
              final results = _searchController.text.isEmpty
                  ? provider.attendees.where((a) => !a.isCheckedIn).toList()
                  : provider.searchResults;

              if (results.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'All attendees checked in!'
                            : 'No results found',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final attendee = results[index];
                  return AttendeeCard(
                    attendee: attendee,
                    onTap: () async {
                      final response = await context
                          .read<CheckinProvider>()
                          .processManualCheckin(attendee);
                      _showCheckinResult(response);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? total;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              if (total != null)
                Text(total!,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton(
      {required this.icon,
      required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withOpacity(0.6)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _CheckinResultSheet extends StatelessWidget {
  final CheckinResponse response;

  const _CheckinResultSheet({required this.response});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color color;
    IconData icon;
    String title;
    String subtitle;

    switch (response.result) {
      case CheckinResult.success:
        color = Colors.green;
        icon = Icons.check_circle;
        title = 'Check-in Successful!';
        subtitle = response.attendee?.fullName ?? '';
        break;
      case CheckinResult.alreadyCheckedIn:
        color = Colors.orange;
        icon = Icons.warning_amber;
        title = 'Already Checked In';
        subtitle =
            'Previously checked in at ${_formatTime(response.previousCheckinTime)}';
        break;
      case CheckinResult.attendeeNotFound:
        color = Colors.red;
        icon = Icons.error;
        title = 'Attendee Not Found';
        subtitle = 'QR code not recognized';
        break;
      case CheckinResult.error:
        color = Colors.red;
        icon = Icons.error;
        title = 'Error';
        subtitle = response.errorMessage ?? 'An error occurred';
        break;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: color)),
          const SizedBox(height: 16),
          Text(title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 16)),
          if (response.attendee != null) ...[
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                          child: Text(
                              response.attendee!.firstName.substring(0, 1),
                              style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(response.attendee!.fullName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        if (response.attendee!.company != null)
                          Text(response.attendee!.company!,
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6))),
                        const SizedBox(height: 4),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(
                                response.attendee!.category.toUpperCase(),
                                style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'))),
                if (response.result == CheckinResult.success) ...[
                  const SizedBox(width: 16),
                  Expanded(
                      child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.print),
                          label: const Text('Print Badge'))),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Unknown time';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
