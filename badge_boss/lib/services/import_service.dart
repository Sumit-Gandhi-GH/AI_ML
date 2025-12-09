import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class ImportResult {
  final List<String> headers;
  final List<List<dynamic>> rows;
  final String fileName;

  ImportResult({
    required this.headers,
    required this.rows,
    required this.fileName,
  });
}

class ImportService {
  Future<ImportResult?> pickAndParseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;
    final name = file.name;

    if (bytes == null) return null;

    if (name.endsWith('.csv')) {
      return _parseCsv(bytes, name);
    } else if (name.endsWith('.xlsx') || name.endsWith('.xls')) {
      return _parseExcel(bytes, name);
    }

    return null;
  }

  ImportResult _parseCsv(Uint8List bytes, String fileName) {
    // Decode bytes to string
    final content = utf8.decode(bytes);
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) {
      return ImportResult(headers: [], rows: [], fileName: fileName);
    }

    final headers = rows.first.map((e) => e.toString()).toList();
    final dataRows = rows.skip(1).toList();

    return ImportResult(
      headers: headers,
      rows: dataRows,
      fileName: fileName,
    );
  }

  ImportResult _parseExcel(Uint8List bytes, String fileName) {
    var excel = Excel.decodeBytes(bytes);

    // Use first sheet
    if (excel.tables.isEmpty) {
      return ImportResult(headers: [], rows: [], fileName: fileName);
    }

    final table = excel.tables.values.first;
    if (table.rows.isEmpty) {
      return ImportResult(headers: [], rows: [], fileName: fileName);
    }

    // Get headers from first row
    final headers =
        table.rows.first.map((cell) => cell?.value.toString() ?? '').toList();

    // Get data
    final dataRows = table.rows.skip(1).map((row) {
      return row.map((cell) {
        return cell?.value ?? '';
      }).toList();
    }).toList();

    return ImportResult(
      headers: headers,
      rows: dataRows,
      fileName: fileName,
    );
  }
}
