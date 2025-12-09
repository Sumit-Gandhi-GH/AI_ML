import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/badge_template.dart';

/// Badge element for the designer
class DesignerElement {
  String id;
  BadgeElementType type;
  Offset position;
  Size size;
  String? field;
  String? staticText;
  double fontSize;
  String color;
  String backgroundColor;
  int zIndex;

  DesignerElement({
    String? id,
    required this.type,
    this.position = Offset.zero,
    this.size = const Size(100, 30),
    this.field,
    this.staticText,
    this.fontSize = 24,
    this.color = '#000000',
    this.backgroundColor = 'transparent',
    this.zIndex = 0,
  }) : id = id ?? const Uuid().v4();
}

class BadgeDesignerScreen extends StatefulWidget {
  final BadgeTemplate? existingTemplate;
  final String organizationId;

  const BadgeDesignerScreen({
    super.key,
    this.existingTemplate,
    required this.organizationId,
  });

  @override
  State<BadgeDesignerScreen> createState() => _BadgeDesignerScreenState();
}

class _BadgeDesignerScreenState extends State<BadgeDesignerScreen> {
  final _nameController = TextEditingController();
  final List<DesignerElement> _elements = [];
  DesignerElement? _selectedElement;
  
  // Canvas settings
  double _canvasWidth = 400; // 100mm at 4px/mm
  double _canvasHeight = 280; // 70mm at 4px/mm
  String _backgroundColor = '#FFFFFF';

  // Available dynamic fields
  final List<Map<String, String>> _dynamicFields = [
    {'key': 'firstName', 'label': 'First Name'},
    {'key': 'lastName', 'label': 'Last Name'},
    {'key': 'fullName', 'label': 'Full Name'},
    {'key': 'company', 'label': 'Company'},
    {'key': 'title', 'label': 'Title'},
    {'key': 'email', 'label': 'Email'},
    {'key': 'category', 'label': 'Category'},
    {'key': 'qrCode', 'label': 'QR Code'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingTemplate != null) {
      _loadTemplate(widget.existingTemplate!);
    } else {
      _createDefaultTemplate();
    }
  }

  void _loadTemplate(BadgeTemplate template) {
    _nameController.text = template.name;
    _backgroundColor = template.backgroundColor;
    _canvasWidth = template.widthMm * 4.0;
    _canvasHeight = template.heightMm * 4.0;
    
    for (final element in template.elements) {
      _elements.add(DesignerElement(
        id: element.id,
        type: element.type,
        position: Offset(element.x * 4, element.y * 4),
        size: Size(element.width * 4, element.height * 4),
        field: element.field,
        staticText: element.staticText,
        fontSize: element.textStyle?.fontSize ?? 24,
        color: element.textStyle?.color ?? '#000000',
      ));
    }
  }

  void _createDefaultTemplate() {
    _nameController.text = 'New Badge Template';
    
    // Add default elements
    _elements.addAll([
      DesignerElement(
        type: BadgeElementType.dynamicField,
        field: 'firstName',
        position: const Offset(20, 20),
        size: const Size(200, 40),
        fontSize: 32,
      ),
      DesignerElement(
        type: BadgeElementType.dynamicField,
        field: 'lastName',
        position: const Offset(20, 65),
        size: const Size(200, 40),
        fontSize: 32,
      ),
      DesignerElement(
        type: BadgeElementType.dynamicField,
        field: 'company',
        position: const Offset(20, 115),
        size: const Size(250, 30),
        fontSize: 22,
      ),
      DesignerElement(
        type: BadgeElementType.qrCode,
        field: 'qrCode',
        position: const Offset(300, 20),
        size: const Size(80, 80),
      ),
      DesignerElement(
        type: BadgeElementType.categoryBand,
        position: const Offset(0, 230),
        size: const Size(400, 50),
        backgroundColor: '#6366F1',
      ),
    ]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addElement(BadgeElementType type) {
    setState(() {
      final element = DesignerElement(
        type: type,
        position: const Offset(50, 50),
        size: type == BadgeElementType.qrCode 
            ? const Size(80, 80)
            : type == BadgeElementType.categoryBand
                ? Size(_canvasWidth, 50)
                : const Size(150, 30),
        zIndex: _elements.length,
      );

      if (type == BadgeElementType.text) {
        element.staticText = 'Text';
      } else if (type == BadgeElementType.dynamicField) {
        element.field = 'firstName';
      }

      _elements.add(element);
      _selectedElement = element;
    });
  }

  void _deleteSelectedElement() {
    if (_selectedElement != null) {
      setState(() {
        _elements.remove(_selectedElement);
        _selectedElement = null;
      });
    }
  }

  BadgeTemplate _buildTemplate() {
    final elements = _elements.map((e) => BadgeElement(
      id: e.id,
      type: e.type,
      x: e.position.dx / 4,
      y: e.position.dy / 4,
      width: e.size.width / 4,
      height: e.size.height / 4,
      field: e.field,
      staticText: e.staticText,
      textStyle: TextStyle(
        fontSize: e.fontSize,
        color: e.color,
      ),
      color: e.backgroundColor,
      zIndex: e.zIndex,
    )).toList();

    return BadgeTemplate(
      id: widget.existingTemplate?.id ?? const Uuid().v4(),
      name: _nameController.text,
      organizationId: widget.organizationId,
      widthMm: (_canvasWidth / 4).round(),
      heightMm: (_canvasHeight / 4).round(),
      backgroundColor: _backgroundColor,
      elements: elements,
      zplTemplate: _generateZpl(elements),
      createdAt: widget.existingTemplate?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  String _generateZpl(List<BadgeElement> elements) {
    final buffer = StringBuffer();
    buffer.writeln('^XA');
    buffer.writeln('^CF0,30');

    for (final element in elements) {
      buffer.writeln(element.toZpl({}));
    }

    buffer.writeln('^XZ');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badge Designer'),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Preview badge
              _showPreview();
            },
            icon: const Icon(Icons.preview),
            label: const Text('Preview'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              final template = _buildTemplate();
              Navigator.pop(context, template);
            },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Toolbox
          _buildToolbox(theme),
          // Canvas
          Expanded(
            child: _buildCanvas(theme),
          ),
          // Properties panel
          if (_selectedElement != null)
            _buildPropertiesPanel(theme),
        ],
      ),
    );
  }

  Widget _buildToolbox(ThemeData theme) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elements',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _ToolboxItem(
            icon: Icons.text_fields,
            label: 'Static Text',
            onTap: () => _addElement(BadgeElementType.text),
          ),
          _ToolboxItem(
            icon: Icons.data_object,
            label: 'Dynamic Field',
            onTap: () => _addElement(BadgeElementType.dynamicField),
          ),
          _ToolboxItem(
            icon: Icons.qr_code,
            label: 'QR Code',
            onTap: () => _addElement(BadgeElementType.qrCode),
          ),
          _ToolboxItem(
            icon: Icons.image,
            label: 'Image',
            onTap: () => _addElement(BadgeElementType.image),
          ),
          _ToolboxItem(
            icon: Icons.person,
            label: 'Photo',
            onTap: () => _addElement(BadgeElementType.photo),
          ),
          _ToolboxItem(
            icon: Icons.rectangle,
            label: 'Rectangle',
            onTap: () => _addElement(BadgeElementType.rectangle),
          ),
          _ToolboxItem(
            icon: Icons.linear_scale,
            label: 'Category Band',
            onTap: () => _addElement(BadgeElementType.categoryBand),
          ),
          const Divider(height: 32),
          Text(
            'Template',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Template Name',
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Center(
        child: Container(
          width: _canvasWidth,
          height: _canvasHeight,
          decoration: BoxDecoration(
            color: _hexToColor(_backgroundColor),
            border: Border.all(
              color: theme.colorScheme.outline,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: _elements.map((element) {
              return Positioned(
                left: element.position.dx,
                top: element.position.dy,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedElement = element);
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      element.position += details.delta;
                    });
                  },
                  child: _buildElementWidget(element, theme),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildElementWidget(DesignerElement element, ThemeData theme) {
    final isSelected = _selectedElement?.id == element.id;
    
    Widget content;
    switch (element.type) {
      case BadgeElementType.text:
        content = Text(
          element.staticText ?? 'Text',
          style: TextStyle(
            fontSize: element.fontSize,
            color: _hexToColor(element.color),
          ),
        );
        break;
      case BadgeElementType.dynamicField:
        content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.5),
              style: BorderStyle.solid,
            ),
          ),
          child: Text(
            '{{${element.field}}}',
            style: TextStyle(
              fontSize: element.fontSize * 0.6,
              color: theme.colorScheme.primary,
              fontFamily: 'monospace',
            ),
          ),
        );
        break;
      case BadgeElementType.qrCode:
        content = Container(
          width: element.size.width,
          height: element.size.height,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black),
          ),
          child: const Icon(Icons.qr_code, size: 40),
        );
        break;
      case BadgeElementType.image:
      case BadgeElementType.photo:
        content = Container(
          width: element.size.width,
          height: element.size.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            border: Border.all(color: Colors.grey),
          ),
          child: Icon(
            element.type == BadgeElementType.photo 
                ? Icons.person 
                : Icons.image,
            size: 30,
            color: Colors.grey.shade600,
          ),
        );
        break;
      case BadgeElementType.rectangle:
        content = Container(
          width: element.size.width,
          height: element.size.height,
          decoration: BoxDecoration(
            color: _hexToColor(element.backgroundColor),
            border: Border.all(color: _hexToColor(element.color), width: 2),
          ),
        );
        break;
      case BadgeElementType.categoryBand:
        content = Container(
          width: element.size.width,
          height: element.size.height,
          color: _hexToColor(element.backgroundColor),
          alignment: Alignment.center,
          child: Text(
            '{{category}}',
            style: TextStyle(
              color: Colors.white,
              fontSize: element.fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        break;
    }

    return Container(
      decoration: isSelected
          ? BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            )
          : null,
      child: content,
    );
  }

  Widget _buildPropertiesPanel(ThemeData theme) {
    final element = _selectedElement!;

    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Properties',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteSelectedElement,
                tooltip: 'Delete',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Element type
          Text(
            element.type.name.toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          // Dynamic field selector
          if (element.type == BadgeElementType.dynamicField) ...[
            DropdownButtonFormField<String>(
              value: element.field,
              decoration: const InputDecoration(
                labelText: 'Field',
                isDense: true,
              ),
              items: _dynamicFields.map((f) {
                return DropdownMenuItem(
                  value: f['key'],
                  child: Text(f['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => element.field = value);
              },
            ),
            const SizedBox(height: 16),
          ],
          // Static text input
          if (element.type == BadgeElementType.text) ...[
            TextField(
              controller: TextEditingController(text: element.staticText),
              decoration: const InputDecoration(
                labelText: 'Text',
                isDense: true,
              ),
              onChanged: (value) {
                setState(() => element.staticText = value);
              },
            ),
            const SizedBox(height: 16),
          ],
          // Font size slider
          if (element.type == BadgeElementType.text ||
              element.type == BadgeElementType.dynamicField) ...[
            Text('Font Size: ${element.fontSize.round()}'),
            Slider(
              value: element.fontSize,
              min: 10,
              max: 60,
              onChanged: (value) {
                setState(() => element.fontSize = value);
              },
            ),
          ],
          // Size inputs
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(
                    text: element.size.width.round().toString(),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Width',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final w = double.tryParse(value);
                    if (w != null) {
                      setState(() {
                        element.size = Size(w, element.size.height);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: TextEditingController(
                    text: element.size.height.round().toString(),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final h = double.tryParse(value);
                    if (h != null) {
                      setState(() {
                        element.size = Size(element.size.width, h);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPreview() {
    final template = _buildTemplate();
    
    // Sample data for preview
    final sampleData = {
      'firstName': 'John',
      'lastName': 'Doe',
      'fullName': 'John Doe',
      'company': 'Tech Corp',
      'title': 'Software Engineer',
      'email': 'john@example.com',
      'category': 'VIP',
      'qrCode': 'BB-12345',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Badge Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _canvasWidth * 0.8,
              height: _canvasHeight * 0.8,
              decoration: BoxDecoration(
                color: _hexToColor(_backgroundColor),
                border: Border.all(color: Colors.grey),
              ),
              child: Stack(
                children: _elements.map((e) {
                  String displayText = '';
                  if (e.type == BadgeElementType.dynamicField && e.field != null) {
                    displayText = sampleData[e.field] ?? e.field!;
                  } else if (e.type == BadgeElementType.text) {
                    displayText = e.staticText ?? '';
                  }
                  
                  return Positioned(
                    left: e.position.dx * 0.8,
                    top: e.position.dy * 0.8,
                    child: e.type == BadgeElementType.categoryBand
                        ? Container(
                            width: e.size.width * 0.8,
                            height: e.size.height * 0.8,
                            color: _hexToColor(e.backgroundColor),
                            alignment: Alignment.center,
                            child: Text(
                              sampleData['category'] ?? 'CATEGORY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: e.fontSize * 0.8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : e.type == BadgeElementType.qrCode
                            ? SizedBox(
                                width: e.size.width * 0.8,
                                height: e.size.height * 0.8,
                                child: const Icon(Icons.qr_code_2, size: 50),
                              )
                            : Text(
                                displayText,
                                style: TextStyle(
                                  fontSize: e.fontSize * 0.8,
                                  color: _hexToColor(e.color),
                                ),
                              ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ZPL Output Preview',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Container(
              height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  template.zplTemplate ?? 'No ZPL generated',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    if (hex == 'transparent') return Colors.transparent;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}

class _ToolboxItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolboxItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}
