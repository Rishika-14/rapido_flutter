import 'package:rapido/rapido.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class PersistenceProvider {
  saveDocument(Document doc);
  Future loadDocuments(DocumentList documentList, {Function onChangedListener});
  Future deleteDocument(Document doc);
}

class LocalFilePersistence implements PersistenceProvider {
  const LocalFilePersistence();

  saveDocument(Document doc) async {
    final file = await _localFile(doc["_id"]);
    String mapString = json.encode(doc);
    file.writeAsStringSync(mapString);
  }

  Future loadDocuments(DocumentList documentList,
      {Function onChangedListener}) async {
    // final List<Document> _documents = [];
    Directory appDir = await getApplicationDocumentsDirectory();

    appDir
        .listSync(recursive: true, followLinks: true)
        .forEach((FileSystemEntity f) {
      if (f.path.endsWith('.json')) {
        Document doc = _readDocumentFromFile(
            f, documentList.documentType, documentList.notifyListeners);
        if (doc != null) documentList.add(doc, saveOnAdd: false);
      }
    });
  }

  Document _readDocumentFromFile(
      FileSystemEntity f, String documentType, Function notifyListeners) {
    Map m = _loadMapFromFilePath(f);
    Document loadedDoc = Document.fromMap(m);
    if (loadedDoc["_docType"] == documentType) {
      loadedDoc.addListener(notifyListeners);
      return loadedDoc;
    }
    return null;
  }

  Map _loadMapFromFilePath(FileSystemEntity f) {
    String j = new File(f.path).readAsStringSync();
    if (j.length != 0) {
      Map newData = json.decode(j);
      newData.keys.forEach((dynamic key) {
        if (key == "latlong" && newData[key] != null) {
          // convert latlongs to the correct type
          newData[key] = Map<String, double>.from(newData[key]);
        }
      });
      return newData;
    }
    return null;
  }

  Future<File> _localFile(String id) async {
    final path = await _localPath;
    return File('$path/$id.json');
  }

  Future deleteDocument(Document doc) async {
    final file = await _localFile(doc.id);
    file.delete();
    return null;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    String path = directory.path;
    return path;
  }
}

class SecretsPercistence implements PersistenceProvider {
  final storage = new FlutterSecureStorage();
  @override
  Future deleteDocument(Document doc) async {
    throw UnimplementedError();
  }

  @override
  Future loadDocuments(DocumentList documentList,
      {Function onChangedListener}) async {
    Map<String, String> docMaps = await storage.readAll();
    print("**** $docMaps");
    // I'm following the rule of 2 here, duplicating this code
    // It does seem like handling turning strings of json into
    // documents should be done in one place
    docMaps.forEach((String key, String value) {
      if (value.length != 0) {
        Map newData = json.decode(value);
        if (newData["_docType"] == documentList.documentType) {
          newData.keys.forEach((dynamic key) {
            if (key == "latlong" && newData[key] != null) {
              // convert latlongs to the correct type
              newData[key] = Map<String, double>.from(newData[key]);
            }
          });

          Document loadedDoc = Document.fromMap(newData);
          loadedDoc.addListener(documentList.notifyListeners);
          documentList.add(loadedDoc, saveOnAdd: false);
        }
      }
    });
  }

  @override
  saveDocument(Document doc) {
    String mapString = json.encode(doc);
    storage.write(key: doc.id, value: mapString);
  }
}
