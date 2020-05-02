import 'dart:collection';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'persistence.dart';

/// A Document is a persisted Map of type <String, dynamic>.
/// It is used by DocumentList amd all related UI widgets.
class Document extends MapBase<String, dynamic> with ChangeNotifier {
  Map<String, dynamic> _map = {};

  /// The Documents type, typically used to organize documents
  /// typically used to organize documents, for example in a DocumentList
  String get documentType => _map["_docType"];
  set documentType(String v) => _map["docType"] = v;

  /// The documents unique id. Typically used to manage persistence,
  /// such as in Document.save()
  String get id => _map["_id"];
  set id(String v) => _map["_id"] = v;

  /// How to provide persistence. Defaults to LocalFileProvider
  /// which will save the documents as files on the device.
  /// Use ParseProvider to persist to a Parse server.
  /// Set to null if no persistence is desired.
  PersistenceProvider persistenceProvider;

  /// Create a Document. Optionally include a map of type
  /// Map<String, dynamic> to initially populate the Document with data.
  /// Will default to local file persistence if persistenceProvider is null.
  Document({Map<String, dynamic> initialValues, this.persistenceProvider}) {
    // default persistence
    if (persistenceProvider == null) {
      persistenceProvider = LocalFilePersistence();
    }
    // initial values if provided
    if (initialValues != null) {
      initialValues.keys.forEach((String key) {
        _map[key] = initialValues[key];
      });
    }
    // if there is no id yet, create one
    if (_map["_id"] == null) {
      _map["_id"] = randomFileSafeId(24);
    }
  }

  dynamic operator [](Object fieldName) => _map[fieldName];

  void operator []=(String fieldName, dynamic value) {
    _map[fieldName] = value;
    save();
  }

  void clear() {
    _map.clear();
    notifyListeners();
  }

  void remove(Object key) {
    _map.remove(key);
    notifyListeners();
  }

  List<String> get keys {
    return _map.keys.toList();
  }

  updateValues(Map<String, dynamic> values) {
    for (String key in values.keys) {
      _map[key] = values[key];
    }
    save();
  }

  Future save() async {
    if (persistenceProvider != null) {
      await persistenceProvider.saveDocument(this);
      notifyListeners();
    }
  }

  delete() {
    if (persistenceProvider != null) {
      persistenceProvider.deleteDocument(this);
    }
  }

  Document.fromMap(Map newData,
      {this.persistenceProvider = const LocalFilePersistence()}) {
    if (newData == null) return;
    newData.keys.forEach((dynamic key) {
      if (key == "latlong" && newData[key] != null) {
        // convert latlongs to the correct type
        newData[key] = Map<String, double>.from(newData[key]);
      }
      _map[key] = newData[key];
    });
    if (newData["_id"] == null) {
      _map["_id"] = randomFileSafeId(24);
    } else {
      _map["_id"] = newData["_id"];
    }
    notifyListeners();
  }

  static String randomFileSafeId(int length) {
    var rand = new Random();
    var codeUnits = new List.generate(length, (index) {
      List<int> illegalChars = [34, 39, 44, 96];
      int randChar = rand.nextInt(33) + 89;
      while (illegalChars.contains(randChar)) {
        randChar = rand.nextInt(33) + 89;
      }
      return randChar;
    });

    return new String.fromCharCodes(codeUnits);
  }
}
