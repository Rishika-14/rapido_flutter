import 'dart:async';

import 'package:rapido/src/document.dart';
import 'package:rapido/src/document_list.dart';
import 'persistence.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SqlLitePersistence implements PersistenceProvider {
  final String databaseName;
  Database _database;
  SqlLitePersistence(this.databaseName);

  @override
  Future deleteDocument(Document doc) {
    // TODO: implement deleteDocument
    return null;
  }

  @override
  Future loadDocuments(DocumentList documentList,
      {Function onChangedListener}) async {
    if (await _checkDocumentTypeExists(documentList.documentType)) {
      List<Map<String, dynamic>> maps =
          await _getDocuments(docType: documentList.documentType);
      maps.forEach((Map<String, dynamic> map) {
        Document loadedDoc = Document.fromMap(map);
        loadedDoc.addListener(documentList.notifyListeners);
        documentList.add(loadedDoc, saveOnAdd: false);
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getDocuments({String docType}) async {
    Database database = await _getDatabase();
    List<Map<String, dynamic>> maps = await database.query(docType);
    return maps;
  }

  Future<bool> _checkDocumentTypeExists(String docType) async {
    Database database = await _getDatabase();
    String q =
        "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='$docType';";

    List<Map<String, dynamic>> maps = await database.rawQuery(q);
    return maps[0]["count(*)"] == 1;
  }

  Future<Database> _getDatabase() async {
    if (this._database == null) {
      _database = await openDatabase(
        join(await getDatabasesPath(), this.databaseName),
      );
    }
    return _database;
  }

  String _createTableSql(Document doc) {
    String s = "CREATE TABLE ${doc.documentType}(_id TEXT PRIMARY KEY";
    doc.keys.forEach((String key) {
      if (key != "_id") {
        s += ", '$key' BLOB";
      }
    });
    s += ")";
    return s;
  }

  Future _createTableFromDoc({Document doc}) async {
    Database database = await _getDatabase();
    await database.execute(_createTableSql(doc));
  }

  @override
  saveDocument(Document doc) async {
    if (!await _checkDocumentTypeExists(doc.documentType)) {
      print(" ------- creating table");
      await _createTableFromDoc(doc: doc);
    } else {
        print(" ----- table exists");
    }

    // create or insert the document
    // select * from documentType WHERE id = doc.id

    return null;
  }
}
