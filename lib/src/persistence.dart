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

class FirebasePersistence implements PersistenceProvider {
  const FirebasePersistence();

  @override
  Future deleteDocument(Document doc) {
    // TODO: implement deleteDocument
    throw UnimplementedError();
  }

  @override
  Future loadDocuments(DocumentList documentList,
      {Function onChangedListener}) {
    // TODO: implement loadDocuments
    throw UnimplementedError();
  }

  @override
  saveDocument(Document doc) {
    // TODO: implement saveDocument
    throw UnimplementedError();
  }

}
