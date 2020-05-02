import 'dart:async';

import 'package:rapido/src/document.dart';
import 'package:rapido/src/document_list.dart';
import 'persistence.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SqlLitePersistence implements PersistenceProvider {
  final String databaseName;

  SqlLitePersistence(this.databaseName);

  @override
  Future deleteDocument(Document doc) {
    // TODO: implement deleteDocument
    return null;
  }

  @override
  Future loadDocuments(DocumentList documentList,
      {Function onChangedListener}) async {
    List<Map<String, dynamic>> maps =
        await _getDocuments(documentList.documentType);
    maps.forEach((Map<String, dynamic> map) {
      Document loadedDoc = Document.fromMap(map);
      loadedDoc.addListener(documentList.notifyListeners);
      documentList.add(loadedDoc, saveOnAdd: false);
    });
  }

  Future<List<Map<String, dynamic>>> _getDocuments(String docType) async {
    Database database = await _getDatabase();
    List<Map<String, dynamic>> maps = await database.query(docType);
    return maps;
  }

  Future<bool> _checkDocumentTypeExists(String docType) async {
    Database database = await _getDatabase();
    List<Map<String, dynamic>> maps = await database.rawQuery("SHOW TABLES;");
    print(maps);
    return true;
  }

  Future<Database> _getDatabase() async {
    final Database database = await openDatabase(
      join(await getDatabasesPath(), this.databaseName),
    );
    return database;
  }

  @override
  saveDocument(Document doc) async {
    if (!await _checkDocumentTypeExists(doc.documentType)) {
      print("table does not exist");
    }
    // check if the document exists
    
    // create or insert the document
    // select * from documentType WHERE id = doc.id

    return null;
  }
}
