import 'dart:core';
import 'dart:io';

Future<void> main() async {
  final content = await File('/home/maxiro/Temporal/index.html').readAsString();
  final formated = extractTableDataWithoutHtmlPackage(content);
  print(formated);
}

// Función para extraer los datos de la tabla del HTML
List<List<String>> extractTableDataWithoutHtmlPackage(String htmlContent) {
  // Expresión regular para encontrar una tabla
  final RegExp tableRegExp = RegExp(r'<table[^>]*>(.*?)<\/table>', dotAll: true);
  // Expresión regular para encontrar filas (tr)
  final RegExp rowRegExp = RegExp(r'<tr[^>]*>(.*?)<\/tr>', dotAll: true);
  // Expresión regular para encontrar celdas (td y th)
  final RegExp cellRegExp = RegExp(r'<(td|th)[^>]*>(.*?)<\/(td|th)>', dotAll: true);

  // Buscar la tabla en el HTML
  final tableMatch = tableRegExp.firstMatch(htmlContent);
  if (tableMatch == null) {
    return []; // Si no se encuentra la tabla, devolver lista vacía
  }

  String tableContent = tableMatch.group(1)!;

  // Lista para almacenar los datos de la tabla
  List<List<String>> tableData = [];

  // Buscar todas las filas en la tabla
  Iterable<RegExpMatch> rowMatches = rowRegExp.allMatches(tableContent);

  for (RegExpMatch rowMatch in rowMatches) {
    String rowContent = rowMatch.group(1)!;
    List<String> rowData = [];

    // Buscar todas las celdas en la fila
    Iterable<RegExpMatch> cellMatches = cellRegExp.allMatches(rowContent);

    for (RegExpMatch cellMatch in cellMatches) {
      // Extraer el contenido de la celda (ignorar etiquetas)
      String cellData = cellMatch.group(2)!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      rowData.add(cellData);
    }

    // Añadir la fila extraída a los datos de la tabla
    tableData.add(rowData);
  }

  return tableData;
}
