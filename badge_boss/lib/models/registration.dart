/// Registration and Ticket models for Badge Boss

/// Ticket type/tier for an event
class TicketType {
  final String id;
  final String eventId;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final int quantity; // Total available
  final int sold; // Number sold
  final DateTime? salesStartDate;
  final DateTime? salesEndDate;
  final bool isActive;
  final int maxPerOrder;
  final List<String> includedCategories; // Badge categories this ticket gets
  final Map<String, dynamic> customBadgeFields;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketType({
    required this.id,
    required this.eventId,
    required this.name,
    this.description,
    this.price = 0,
    this.currency = 'USD',
    this.quantity = 0,
    this.sold = 0,
    this.salesStartDate,
    this.salesEndDate,
    this.isActive = true,
    this.maxPerOrder = 10,
    this.includedCategories = const ['general'],
    this.customBadgeFields = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isFree => price == 0;
  bool get isSoldOut => quantity > 0 && sold >= quantity;
  int get remaining => quantity > 0 ? quantity - sold : -1; // -1 = unlimited

  bool get isOnSale {
    final now = DateTime.now();
    if (!isActive) return false;
    if (salesStartDate != null && now.isBefore(salesStartDate!)) return false;
    if (salesEndDate != null && now.isAfter(salesEndDate!)) return false;
    return !isSoldOut;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'eventId': eventId,
        'name': name,
        'description': description,
        'price': price,
        'currency': currency,
        'quantity': quantity,
        'sold': sold,
        'salesStartDate': salesStartDate?.toIso8601String(),
        'salesEndDate': salesEndDate?.toIso8601String(),
        'isActive': isActive,
        'maxPerOrder': maxPerOrder,
        'includedCategories': includedCategories,
        'customBadgeFields': customBadgeFields,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TicketType.fromMap(Map<String, dynamic> map, String docId) {
    return TicketType(
      id: docId,
      eventId: map['eventId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      price: (map['price'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      quantity: map['quantity'] ?? 0,
      sold: map['sold'] ?? 0,
      salesStartDate: map['salesStartDate'] != null
          ? DateTime.parse(map['salesStartDate'])
          : null,
      salesEndDate: map['salesEndDate'] != null
          ? DateTime.parse(map['salesEndDate'])
          : null,
      isActive: map['isActive'] ?? true,
      maxPerOrder: map['maxPerOrder'] ?? 10,
      includedCategories:
          List<String>.from(map['includedCategories'] ?? ['general']),
      customBadgeFields:
          Map<String, dynamic>.from(map['customBadgeFields'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  TicketType copyWith({
    String? id,
    String? eventId,
    String? name,
    String? description,
    double? price,
    String? currency,
    int? quantity,
    int? sold,
    DateTime? salesStartDate,
    DateTime? salesEndDate,
    bool? isActive,
    int? maxPerOrder,
    List<String>? includedCategories,
    Map<String, dynamic>? customBadgeFields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TicketType(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      quantity: quantity ?? this.quantity,
      sold: sold ?? this.sold,
      salesStartDate: salesStartDate ?? this.salesStartDate,
      salesEndDate: salesEndDate ?? this.salesEndDate,
      isActive: isActive ?? this.isActive,
      maxPerOrder: maxPerOrder ?? this.maxPerOrder,
      includedCategories: includedCategories ?? this.includedCategories,
      customBadgeFields: customBadgeFields ?? this.customBadgeFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Registration form field definition
class RegistrationField {
  final String id;
  final String label;
  final String
      type; // 'text', 'email', 'phone', 'select', 'checkbox', 'textarea'
  final bool isRequired;
  final List<String>? options; // For select fields
  final String? placeholder;
  final String? helpText;
  final int order;
  final bool showOnBadge;

  RegistrationField({
    required this.id,
    required this.label,
    this.type = 'text',
    this.isRequired = false,
    this.options,
    this.placeholder,
    this.helpText,
    this.order = 0,
    this.showOnBadge = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'type': type,
        'isRequired': isRequired,
        'options': options,
        'placeholder': placeholder,
        'helpText': helpText,
        'order': order,
        'showOnBadge': showOnBadge,
      };

  factory RegistrationField.fromMap(Map<String, dynamic> map) {
    return RegistrationField(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      type: map['type'] ?? 'text',
      isRequired: map['isRequired'] ?? false,
      options:
          map['options'] != null ? List<String>.from(map['options']) : null,
      placeholder: map['placeholder'],
      helpText: map['helpText'],
      order: map['order'] ?? 0,
      showOnBadge: map['showOnBadge'] ?? false,
    );
  }
}

/// Registration record
class Registration {
  final String id;
  final String eventId;
  final String ticketTypeId;
  final String ticketTypeName;
  final String email;
  final String firstName;
  final String lastName;
  final Map<String, dynamic> customFields;
  final RegistrationStatus status;
  final double amountPaid;
  final String currency;
  final String? paymentId; // Stripe payment ID
  final String? promoCode;
  final double discount;
  final String? confirmationCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? attendeeId; // Linked attendee after approval

  Registration({
    required this.id,
    required this.eventId,
    required this.ticketTypeId,
    required this.ticketTypeName,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.customFields = const {},
    this.status = RegistrationStatus.pending,
    this.amountPaid = 0,
    this.currency = 'USD',
    this.paymentId,
    this.promoCode,
    this.discount = 0,
    this.confirmationCode,
    required this.createdAt,
    required this.updatedAt,
    this.attendeeId,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() => {
        'id': id,
        'eventId': eventId,
        'ticketTypeId': ticketTypeId,
        'ticketTypeName': ticketTypeName,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'customFields': customFields,
        'status': status.name,
        'amountPaid': amountPaid,
        'currency': currency,
        'paymentId': paymentId,
        'promoCode': promoCode,
        'discount': discount,
        'confirmationCode': confirmationCode,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'attendeeId': attendeeId,
      };

  factory Registration.fromMap(Map<String, dynamic> map, String docId) {
    return Registration(
      id: docId,
      eventId: map['eventId'] ?? '',
      ticketTypeId: map['ticketTypeId'] ?? '',
      ticketTypeName: map['ticketTypeName'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
      status: RegistrationStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => RegistrationStatus.pending,
      ),
      amountPaid: (map['amountPaid'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      paymentId: map['paymentId'],
      promoCode: map['promoCode'],
      discount: (map['discount'] ?? 0).toDouble(),
      confirmationCode: map['confirmationCode'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      attendeeId: map['attendeeId'],
    );
  }

  Registration copyWith({
    String? id,
    String? eventId,
    String? ticketTypeId,
    String? ticketTypeName,
    String? email,
    String? firstName,
    String? lastName,
    Map<String, dynamic>? customFields,
    RegistrationStatus? status,
    double? amountPaid,
    String? currency,
    String? paymentId,
    String? promoCode,
    double? discount,
    String? confirmationCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? attendeeId,
  }) {
    return Registration(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      ticketTypeId: ticketTypeId ?? this.ticketTypeId,
      ticketTypeName: ticketTypeName ?? this.ticketTypeName,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      customFields: customFields ?? this.customFields,
      status: status ?? this.status,
      amountPaid: amountPaid ?? this.amountPaid,
      currency: currency ?? this.currency,
      paymentId: paymentId ?? this.paymentId,
      promoCode: promoCode ?? this.promoCode,
      discount: discount ?? this.discount,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attendeeId: attendeeId ?? this.attendeeId,
    );
  }
}

enum RegistrationStatus {
  pending, // Awaiting payment or approval
  confirmed, // Payment received, registration confirmed
  cancelled, // Cancelled by user or admin
  refunded, // Payment refunded
  waitlisted, // On waitlist
}

/// Promo code for discounts
class PromoCode {
  final String id;
  final String eventId;
  final String code;
  final String? description;
  final PromoType type;
  final double value; // Percentage or fixed amount
  final int? maxUses;
  final int usedCount;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final List<String>? applicableTicketIds;
  final bool isActive;
  final DateTime createdAt;

  PromoCode({
    required this.id,
    required this.eventId,
    required this.code,
    this.description,
    this.type = PromoType.percentage,
    required this.value,
    this.maxUses,
    this.usedCount = 0,
    this.validFrom,
    this.validUntil,
    this.applicableTicketIds,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isValid {
    if (!isActive) return false;
    if (maxUses != null && usedCount >= maxUses!) return false;
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    return true;
  }

  double calculateDiscount(double originalPrice, String? ticketId) {
    if (!isValid) return 0;
    if (applicableTicketIds != null &&
        ticketId != null &&
        !applicableTicketIds!.contains(ticketId)) {
      return 0;
    }

    if (type == PromoType.percentage) {
      return originalPrice * (value / 100);
    } else {
      return value > originalPrice ? originalPrice : value;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'eventId': eventId,
        'code': code,
        'description': description,
        'type': type.name,
        'value': value,
        'maxUses': maxUses,
        'usedCount': usedCount,
        'validFrom': validFrom?.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
        'applicableTicketIds': applicableTicketIds,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PromoCode.fromMap(Map<String, dynamic> map, String docId) {
    return PromoCode(
      id: docId,
      eventId: map['eventId'] ?? '',
      code: map['code'] ?? '',
      description: map['description'],
      type: PromoType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => PromoType.percentage,
      ),
      value: (map['value'] ?? 0).toDouble(),
      maxUses: map['maxUses'],
      usedCount: map['usedCount'] ?? 0,
      validFrom:
          map['validFrom'] != null ? DateTime.parse(map['validFrom']) : null,
      validUntil:
          map['validUntil'] != null ? DateTime.parse(map['validUntil']) : null,
      applicableTicketIds: map['applicableTicketIds'] != null
          ? List<String>.from(map['applicableTicketIds'])
          : null,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

enum PromoType {
  percentage, // e.g., 20% off
  fixed, // e.g., $10 off
}
