import 'package:flutter/material.dart';
import 'attendee_provider.dart';

class AnalyticsData {
  final int totalAttendees;
  final int checkedInCount;
  final double totalRevenue;
  final Map<String, int> ticketDistribution; // Category -> Count
  final List<DailyRegistration> dailyRegistrations;

  AnalyticsData({
    required this.totalAttendees,
    required this.checkedInCount,
    required this.totalRevenue,
    required this.ticketDistribution,
    required this.dailyRegistrations,
  });

  double get checkInRate =>
      totalAttendees == 0 ? 0 : checkedInCount / totalAttendees;
}

class DailyRegistration {
  final DateTime date;
  final int count;

  DailyRegistration(this.date, this.count);
}

class AnalyticsProvider with ChangeNotifier {
  AnalyticsData? _data;
  bool _isLoading = false;

  AnalyticsData? get data => _data;
  bool get isLoading => _isLoading;

  Future<void> loadAnalytics(
      String eventId, AttendeeProvider attendeeProvider) async {
    _isLoading = true;
    notifyListeners();

    // Simulate extensive calculation
    await Future.delayed(const Duration(milliseconds: 800));

    final attendees = attendeeProvider.attendees;
    final total = attendees.length;
    final checkedIn = attendees.where((a) => a.isCheckedIn).length;

    // Calculate mock revenue and distribution
    // In a real app, this would come from a comprehensive backend aggregation
    double revenue = 0;
    final distribution = <String, int>{};

    for (var a in attendees) {
      // Mock ticket prices based on category
      double price = 0;
      final category = a.category.toLowerCase();

      if (category.contains('vip')) {
        price = 299.0;
      } else if (category.contains('speaker') || category.contains('staff')) {
        price = 0.0;
      } else {
        price = 99.0; // General Admission
      }
      revenue += price;

      // Capitalize first letter for display
      final displayCategory = a.category.isNotEmpty
          ? '${a.category[0].toUpperCase()}${a.category.substring(1)}'
          : 'General';

      distribution[displayCategory] = (distribution[displayCategory] ?? 0) + 1;
    }

    // Mock daily registrations (last 7 days)
    final now = DateTime.now();
    final daily = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      // Random-ish curve
      final count = (index + 1) * 3 + (total % (index + 1)) + 2;
      return DailyRegistration(date, count);
    });

    _data = AnalyticsData(
      totalAttendees: total,
      checkedInCount: checkedIn,
      totalRevenue: revenue,
      ticketDistribution: distribution,
      dailyRegistrations: daily,
    );

    _isLoading = false;
    notifyListeners();
  }
}
