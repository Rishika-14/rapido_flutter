import 'dart:collection';
import 'dart:async';
import 'dart:convert';
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

  /// The document's unique id. Typically used to manage persistence,
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
  Document({
    required Map<String, dynamic> initialValues,
    required this.persistenceProvider,
  }) {
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

  dynamic operator [](Object? fieldName) =>
      fieldName == null ? null : _map[fieldName];

  void operator []=(String fieldName, dynamic value) {
    _map[fieldName] = value;
    save();
  }

  void clear() {
    _map.clear();
    notifyListeners();
  }

  void remove(Object? key) {
    if (key != null) {
      _map.remove(key);
      notifyListeners();
    }
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

  /// Creates a Rapido Document from a Map<String, dynamic>.
  /// This is typically used by PersistenceProviders to convert load data from their sourse.
  /// This is where a lot of complexity is concentrated related to translating between different
  /// data stores and Rapido.
  ///
  /// This function is not typically used during application development.
  Document.fromMap(Map loadedData,
      {this.persistenceProvider = const LocalFilePersistence()}) {
    if (loadedData == null) return;

    // create a copy of the loaded data in case the source map is read only
    // such as from sqlite
    Map newData = Map.from(loadedData);

    // iterate through and apply special cases
    newData.keys.forEach((dynamic k) {
      String key = k.toString();
      // convert latlongs to the corret type
      // some backends persist as json encoded strings
      // they are typically Map<string, double> when decoded
      if (key.endsWith("latlong") && newData[key] != null) {
        if (newData[key] is String) {
          newData[key] = jsonDecode(newData[key]);
        }
        newData[key] = Map<String, double>.from(newData[key]);
      }

      // convert ints to booleans
      // some backends don't support boolean, only ints
      if (key.endsWith("?") && newData[key] != null) {
        if (newData[key] is int) {
          newData[key] = newData[key] == 1;
        }
      }
      _map[key] = newData[key];
    });

    // if the document is newly created it may not have an id set
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
