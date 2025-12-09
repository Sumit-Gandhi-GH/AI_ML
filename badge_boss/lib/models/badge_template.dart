/// Badge template model with ZPL support
class BadgeTemplate {
  final String id;
  final String name;
  final String organizationId;
  final int widthMm;
  final int heightMm;
  final String backgroundColor;
  final List<BadgeElement> elements;
  final Map<String, CategoryStyle> categoryStyles;
  final String? zplTemplate;
  final DateTime createdAt;
  final DateTime updatedAt;

  BadgeTemplate({
    required this.id,
    required this.name,
    required this.organizationId,
    this.widthMm = 100,
    this.heightMm = 70,
    this.backgroundColor = '#FFFFFF',
    this.elements = const [],
    this.categoryStyles = const {},
    this.zplTemplate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'organizationId': organizationId,
    'widthMm': widthMm,
    'heightMm': heightMm,
    'backgroundColor': backgroundColor,
    'elements': elements.map((e) => e.toMap()).toList(),
    'categoryStyles': categoryStyles.map((k, v) => MapEntry(k, v.toMap())),
    'zplTemplate': zplTemplate,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory BadgeTemplate.fromMap(Map<String, dynamic> map, String docId) {
    return BadgeTemplate(
      id: docId,
      name: map['name'] ?? '',
      organizationId: map['organizationId'] ?? '',
      widthMm: map['widthMm'] ?? 100,
      heightMm: map['heightMm'] ?? 70,
      backgroundColor: map['backgroundColor'] ?? '#FFFFFF',
      elements: (map['elements'] as List?)
              ?.map((e) => BadgeElement.fromMap(e))
              .toList() ??
          [],
      categoryStyles: (map['categoryStyles'] as Map?)?.map(
            (k, v) => MapEntry(k as String, CategoryStyle.fromMap(v)),
          ) ??
          {},
      zplTemplate: map['zplTemplate'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  /// Generate ZPL code for an attendee
  String generateZpl(Map<String, dynamic> attendeeData) {
    if (zplTemplate != null) {
      String zpl = zplTemplate!;
      attendeeData.forEach((key, value) {
        zpl = zpl.replaceAll('{{$key}}', value?.toString() ?? '');
      });
      return zpl;
    }
    // Generate ZPL from elements if no template exists
    return _generateZplFromElements(attendeeData);
  }

  String _generateZplFromElements(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('^XA'); // Start ZPL
    buffer.writeln('^CF0,30'); // Default font
    
    for (final element in elements) {
      buffer.writeln(element.toZpl(data));
    }
    
    buffer.writeln('^XZ'); // End ZPL
    return buffer.toString();
  }
}

/// Badge design element
class BadgeElement {
  final String id;
  final BadgeElementType type;
  final double x;
  final double y;
  final double width;
  final double height;
  final String? field; // Dynamic field name like 'firstName', 'lastName'
  final String? staticText;
  final TextStyle? textStyle;
  final String? imageUrl;
  final String? color;
  final int zIndex;

  BadgeElement({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.field,
    this.staticText,
    this.textStyle,
    this.imageUrl,
    this.color,
    this.zIndex = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'field': field,
    'staticText': staticText,
    'textStyle': textStyle?.toMap(),
    'imageUrl': imageUrl,
    'color': color,
    'zIndex': zIndex,
  };

  factory BadgeElement.fromMap(Map<String, dynamic> map) {
    return BadgeElement(
      id: map['id'] ?? '',
      type: BadgeElementType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => BadgeElementType.text,
      ),
      x: (map['x'] ?? 0).toDouble(),
      y: (map['y'] ?? 0).toDouble(),
      width: (map['width'] ?? 0).toDouble(),
      height: (map['height'] ?? 0).toDouble(),
      field: map['field'],
      staticText: map['staticText'],
      textStyle: map['textStyle'] != null 
          ? TextStyle.fromMap(map['textStyle']) 
          : null,
      imageUrl: map['imageUrl'],
      color: map['color'],
      zIndex: map['zIndex'] ?? 0,
    );
  }

  /// Convert element to ZPL command
  String toZpl(Map<String, dynamic> data) {
    final xPos = (x * 8).round(); // Convert mm to dots (8 dots/mm)
    final yPos = (y * 8).round();
    
    switch (type) {
      case BadgeElementType.text:
      case BadgeElementType.dynamicField:
        final text = field != null ? (data[field] ?? '') : (staticText ?? '');
        final fontSize = textStyle?.fontSize ?? 30;
        return '^FO$xPos,$yPos^A0N,$fontSize,$fontSize^FD$text^FS';
      
      case BadgeElementType.qrCode:
        final qrData = data['qrCode'] ?? '';
        return '^FO$xPos,$yPos^BQN,2,5^FDQA,$qrData^FS';
      
      case BadgeElementType.image:
      case BadgeElementType.photo:
        // Images need to be pre-processed for ZPL
        return '^FO$xPos,$yPos^GFA,...^FS'; // Placeholder
      
      case BadgeElementType.rectangle:
        final w = (width * 8).round();
        final h = (height * 8).round();
        return '^FO$xPos,$yPos^GB$w,$h,2^FS';
      
      case BadgeElementType.categoryBand:
        final w = (width * 8).round();
        final h = (height * 8).round();
        return '^FO$xPos,$yPos^GB$w,$h,$h,B^FS';
    }
  }
}

/// Badge element types
enum BadgeElementType {
  text,
  dynamicField,
  qrCode,
  image,
  photo,
  rectangle,
  categoryBand,
}

/// Text style for badge elements
class TextStyle {
  final double fontSize;
  final String fontFamily;
  final String fontWeight;
  final String color;
  final String alignment;

  TextStyle({
    this.fontSize = 24,
    this.fontFamily = 'Arial',
    this.fontWeight = 'normal',
    this.color = '#000000',
    this.alignment = 'left',
  });

  Map<String, dynamic> toMap() => {
    'fontSize': fontSize,
    'fontFamily': fontFamily,
    'fontWeight': fontWeight,
    'color': color,
    'alignment': alignment,
  };

  factory TextStyle.fromMap(Map<String, dynamic> map) {
    return TextStyle(
      fontSize: (map['fontSize'] ?? 24).toDouble(),
      fontFamily: map['fontFamily'] ?? 'Arial',
      fontWeight: map['fontWeight'] ?? 'normal',
      color: map['color'] ?? '#000000',
      alignment: map['alignment'] ?? 'left',
    );
  }
}

/// Category-specific styling
class CategoryStyle {
  final String bandColor;
  final String textColor;
  final String? iconUrl;

  CategoryStyle({
    required this.bandColor,
    this.textColor = '#FFFFFF',
    this.iconUrl,
  });

  Map<String, dynamic> toMap() => {
    'bandColor': bandColor,
    'textColor': textColor,
    'iconUrl': iconUrl,
  };

  factory CategoryStyle.fromMap(Map<String, dynamic> map) {
    return CategoryStyle(
      bandColor: map['bandColor'] ?? '#6366F1',
      textColor: map['textColor'] ?? '#FFFFFF',
      iconUrl: map['iconUrl'],
    );
  }
}
