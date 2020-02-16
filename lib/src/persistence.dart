import 'package:rapido/rapido.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provides functionality for storing and retreivng Documents. Typically,
/// the functions are not called directly, but rather are used by DocumentList
/// or other classes within Rapido.
abstract class PersistenceProvider {
  /// Persists the given document to storage
  saveDocument(Document doc);

  /// Loads all documents for the given DocumentList from storage
  Future loadDocuments(DocumentList documentList, {Function onChangedListener});

  /// Deletes the given Document from storage
  Future deleteDocument(Document doc);
}

/// Default Persistence Provider. Saves all Documents locally on the user's
/// device. The documents are saved in json format, and are saved in clear
/// text. Is suitable for a medium-sized DocumentList.
class LocalFilePersistence implements PersistenceProvider {
  const LocalFilePersistence();

  /// Persists the given Document in the devices default directory
  /// as json, in clear text. Each Document is saved in a file named
  /// by the Document's id.
  @override
  saveDocument(Document doc) async {
    final file = await _localFile(doc["_id"]);
    String mapString = json.encode(doc);
    file.writeAsStringSync(mapString);
  }

  /// Loads all Documents for the devices default directory
  /// that match the DocumentList's documentType property.
  @override
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

  /// Delete's the given Document from the device's default
  /// directory.
  @override
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

/// Saves all Documents locally on the user's device, using the device OS's
/// secretes store. Useful for tokens and passwords and other private data.
/// Supports smaller DocumentLists.
class SecretsPercistence implements PersistenceProvider {
  final storage = new FlutterSecureStorage();

  /// Deletes the given Document from the device's secrets store.
  @override
  Future deleteDocument(Document doc) async {
    await storage.delete(key: doc.id);
  }

  /// Loads all of the documents from the device's secrets store that
  /// match the DocumentLists's documentType property.
  @override
  Future loadDocuments(DocumentList documentList,
      {Function onChangedListener}) async {
    Map<String, String> docMaps = await storage.readAll();
    print("**** $docMaps");
    // I'm following the rule of 3 here (for now), duplicating this code
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
  /// Persists the given Document in the device's secret store
  /// as json. The key for each entry in the secret store is the
  /// Document's id property.
  @override
  saveDocument(Document doc) {
    String mapString = json.encode(doc);
    storage.write(key: doc.id, value: mapString);
  }
}
