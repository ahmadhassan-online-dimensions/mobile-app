import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models.dart';

/// Small on-device key/value storage for things the REST API doesn't keep:
/// wishlist, chosen finish and lenses, saved prescription, delivery address.
abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
}

class SecureKeyValueStore implements KeyValueStore {
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: 'vueor_$key');

  @override
  Future<void> write(String key, String? value) =>
      value == null ? _storage.delete(key: 'vueor_$key') : _storage.write(key: 'vueor_$key', value: value);
}

class MemoryKeyValueStore implements KeyValueStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String? value) async => value == null ? values.remove(key) : values[key] = value;
}

enum Finish {
  solidGold('Solid Gold', '18k solid gold. The heirloom expression.'),
  goldPlated('Gold Plated', 'Gold plated. The everyday expression.');

  final String label;
  final String line;
  const Finish(this.label, this.line);
}

enum LensType {
  plain('Plain', 'Clear lenses, no prescription'),
  prescription('Prescription', 'Upload or enter your prescription'),
  reading('Reading', 'Choose a magnification strength');

  final String label;
  final String description;
  const LensType(this.label, this.description);
}

const readingStrengths = ['+1.00', '+1.25', '+1.50', '+1.75', '+2.00', '+2.25', '+2.50', '+2.75', '+3.00'];

/// The customer's choices for one piece.
class PieceOptions {
  final Finish finish;
  final LensType lens;
  final String strength;

  const PieceOptions({this.finish = Finish.solidGold, this.lens = LensType.plain, this.strength = '+2.00'});

  PieceOptions copyWith({Finish? finish, LensType? lens, String? strength}) =>
      PieceOptions(finish: finish ?? this.finish, lens: lens ?? this.lens, strength: strength ?? this.strength);

  String get lensLabel => switch (lens) {
    LensType.plain => 'Plain lenses',
    LensType.prescription => 'Prescription lenses',
    LensType.reading => 'Reading $strength',
  };

  /// "Solid Gold · Plain lenses"
  String get summary => '${finish.label} · $lensLabel';

  Map<String, dynamic> toJson() => {'finish': finish.name, 'lens': lens.name, 'strength': strength};

  factory PieceOptions.fromJson(Map<String, dynamic> j) => PieceOptions(
    finish: Finish.values.asNameMap()[j['finish']] ?? Finish.solidGold,
    lens: LensType.values.asNameMap()[j['lens']] ?? LensType.plain,
    strength: (j['strength'] as String?) ?? '+2.00',
  );
}

/// Optometrist values, per eye, plus pupillary distance.
class Prescription {
  final String rightSph, rightCyl, rightAxis;
  final String leftSph, leftCyl, leftAxis;
  final String pd;

  const Prescription({
    this.rightSph = '',
    this.rightCyl = '',
    this.rightAxis = '',
    this.leftSph = '',
    this.leftCyl = '',
    this.leftAxis = '',
    this.pd = '',
  });

  bool get isEmpty => [rightSph, leftSph, pd].every((v) => v.trim().isEmpty);

  Map<String, dynamic> toJson() => {
    'rightSph': rightSph,
    'rightCyl': rightCyl,
    'rightAxis': rightAxis,
    'leftSph': leftSph,
    'leftCyl': leftCyl,
    'leftAxis': leftAxis,
    'pd': pd,
  };

  factory Prescription.fromJson(Map<String, dynamic> j) => Prescription(
    rightSph: '${j['rightSph'] ?? ''}',
    rightCyl: '${j['rightCyl'] ?? ''}',
    rightAxis: '${j['rightAxis'] ?? ''}',
    leftSph: '${j['leftSph'] ?? ''}',
    leftCyl: '${j['leftCyl'] ?? ''}',
    leftAxis: '${j['leftAxis'] ?? ''}',
    pd: '${j['pd'] ?? ''}',
  );
}

/// Loads and saves the on-device preferences.
class Prefs {
  final KeyValueStore store;

  Prefs(this.store);

  Set<String> wishlist = {};
  Map<String, PieceOptions> options = {};
  Prescription? prescription;
  ShippingAddress? address;

  Future<void> load() async {
    try {
      final w = await store.read('wishlist');
      if (w != null) wishlist = (jsonDecode(w) as List).cast<String>().toSet();
      final o = await store.read('options');
      if (o != null) {
        options = (jsonDecode(o) as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, PieceOptions.fromJson(v as Map<String, dynamic>)),
        );
      }
      final p = await store.read('prescription');
      if (p != null) prescription = Prescription.fromJson(jsonDecode(p) as Map<String, dynamic>);
      final a = await store.read('address');
      if (a != null) address = ShippingAddress.fromJson(jsonDecode(a) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt or unavailable storage: start fresh.
    }
  }

  Future<void> saveWishlist() => store.write('wishlist', jsonEncode(wishlist.toList()));

  Future<void> saveOptions() => store.write('options', jsonEncode(options.map((k, v) => MapEntry(k, v.toJson()))));

  Future<void> savePrescription() =>
      store.write('prescription', prescription == null ? null : jsonEncode(prescription!.toJson()));

  Future<void> saveAddress() => store.write('address', address == null ? null : jsonEncode(address!.toJson()));
}
