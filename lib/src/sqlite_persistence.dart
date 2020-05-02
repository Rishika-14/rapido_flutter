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

  String _keyStringFromDoc(Document doc) {
    bool first = true;
    String keysStr = "(";
    doc.keys.forEach((String key) {
      if (!first) {
        keysStr += ", ";
      }
      first = false;
      keysStr += "'$key'";
    });
    keysStr += ")";
    return keysStr;
  }

  String _valuesStringFromDoc(Document doc) {
    String vStr = ("(?");
    for (int i = 1; i < doc.length; i++) {
      vStr += ", ?";
    }
    vStr += ")";
    return vStr;
  }

  @override
  saveDocument(Document doc) async {
    if (!await _checkDocumentTypeExists(doc.documentType)) {
      await _createTableFromDoc(doc: doc);
    }
    String kStr = _keyStringFromDoc(doc);
    String vStr = _valuesStringFromDoc(doc);
    print(kStr);
    print(vStr);

    String q = "INSERT OR REPLACE INTO ${doc.documentType} $kStr VALUES $vStr";
    Database database = await _getDatabase();
    int changes  = await database.rawUpdate(q, doc.values.toList());
    print(changes);

    // INSERT OR REPLACE INTO Tasker (done?, date, title, pri count, subtitle, _id, _docType, _time_stamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?)) sql 'INSERT OR REPLACE INTO Tasker (done?, date, title, pri count, subtitle, _id, _docType, _time_stamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?)' args [false, 5/2/2020, aaaaaa, 0, , ygt\yhpcwcYyejZbdcpdYYw], Tasker, 1588446405844]}
  }
}
