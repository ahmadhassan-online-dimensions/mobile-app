import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/api_client.dart';
import '../config.dart';
import '../models.dart';
import 'prefs.dart';

export 'prefs.dart';

/// Where the JWT is kept between launches.
abstract class TokenStore {
  Future<String?> read();
  Future<void> write(String? token);
}

class SecureTokenStore implements TokenStore {
  static const _key = 'vueor_token';
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String? token) =>
      token == null ? _storage.delete(key: _key) : _storage.write(key: _key, value: token);
}

class MemoryTokenStore implements TokenStore {
  String? token;
  MemoryTokenStore([this.token]);

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String? t) async => token = t;
}

/// Gets a Google ID token for `POST /users/google`.
abstract class GoogleAuth {
  Future<String> idToken();
  Future<void> signOut();
}

class PluginGoogleAuth implements GoogleAuth {
  bool _ready = false;

  @override
  Future<String> idToken() async {
    final google = GoogleSignIn.instance;
    if (!_ready) {
      await google.initialize(serverClientId: AppConfig.googleServerClientId);
      _ready = true;
    }
    try {
      final account = await google.authenticate();
      final token = account.authentication.idToken;
      if (token == null) throw ApiException('Google did not return an ID token.');
      return token;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw ApiException('Google sign-in was cancelled.');
      }
      throw ApiException(
        'Google sign-in is not available on this build yet (${e.code.name}). '
        'Use your email for now.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (_ready) await GoogleSignIn.instance.signOut();
  }
}

/// Session, products, bag and orders, all backed by the VUE & OR REST API.
class AppState extends ChangeNotifier {
  final ApiClient api;
  final TokenStore tokens;
  final GoogleAuth google;

  final Prefs prefs;

  AppState({ApiClient? api, TokenStore? tokens, GoogleAuth? google, KeyValueStore? storage})
    : api = api ?? ApiClient(),
      tokens = tokens ?? SecureTokenStore(),
      google = google ?? PluginGoogleAuth(),
      prefs = Prefs(storage ?? SecureKeyValueStore());

  AppUser? user;
  Cart cart = Cart.empty;
  List<Product> products = [];
  bool productsLoading = false;
  String? productsError;

  /// True once the saved session (if any) has been checked.
  bool sessionChecked = false;

  bool get signedIn => user != null;
  int get bagCount => cart.totalItems;

  // ---- on-device preferences (not stored by the API) -------------------

  bool isWishlisted(Product p) => prefs.wishlist.contains(p.id);

  Future<void> toggleWishlist(Product p) async {
    if (!prefs.wishlist.remove(p.id)) prefs.wishlist.add(p.id);
    notifyListeners();
    await prefs.saveWishlist();
  }

  List<Product> get wishlistProducts => products.where(isWishlisted).toList();

  PieceOptions optionsFor(Product p) => prefs.options[p.id] ?? const PieceOptions();

  Future<void> setOptions(Product p, PieceOptions o) async {
    prefs.options[p.id] = o;
    notifyListeners();
    await prefs.saveOptions();
  }

  Prescription? get prescription => prefs.prescription;

  Future<void> savePrescription(Prescription? p) async {
    prefs.prescription = (p == null || p.isEmpty) ? null : p;
    notifyListeners();
    await prefs.savePrescription();
  }

  ShippingAddress? get savedAddress => prefs.address;

  Future<void> saveAddress(ShippingAddress a) async {
    prefs.address = a;
    await prefs.saveAddress();
  }

  Product? productByModel({required bool wearable}) {
    for (final p in products) {
      if (p.isWearable == wearable) return p;
    }
    return null;
  }

  // ---- start-up --------------------------------------------------------

  /// Restores a saved session and loads the catalogue. Never throws.
  Future<void> start() async {
    await Future.wait([_restoreSession(), loadProducts(), prefs.load()]);
    notifyListeners();
  }

  Future<void> _restoreSession() async {
    try {
      final saved = await tokens.read();
      if (saved == null) return;
      api.token = saved;
      final data = await api.get('/users/profile');
      user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      await refreshCart();
    } on ApiException catch (e) {
      if (e.isUnauthorized) await _clearSession();
    } catch (_) {
      // Storage unavailable: start signed out.
    } finally {
      sessionChecked = true;
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    productsLoading = true;
    productsError = null;
    notifyListeners();
    try {
      final data = await api.get('/products', query: {'limit': '50'});
      products = ((data['products'] as List?) ?? []).whereType<Map<String, dynamic>>().map(Product.fromJson).toList()
        // Model 01 first, as on the website.
        ..sort((a, b) => a.name.compareTo(b.name));
    } on ApiException catch (e) {
      productsError = e.message;
    } finally {
      productsLoading = false;
      notifyListeners();
    }
  }

  Future<Product> product(String id) async {
    final data = await api.get('/products/$id');
    return Product.fromJson(data['product'] as Map<String, dynamic>);
  }

  // ---- auth --------------------------------------------------------------

  Future<void> signIn(String email, String password) =>
      _authenticate(api.post('/users/login', {'email': email.trim(), 'password': password}));

  Future<void> register(String name, String email, String password) =>
      _authenticate(api.post('/users/register', {'name': name.trim(), 'email': email.trim(), 'password': password}));

  Future<void> signInWithGoogle() async {
    final idToken = await google.idToken();
    await _authenticate(api.post('/users/google', {'credential': idToken}));
  }

  Future<void> _authenticate(Future<Map<String, dynamic>> call) async {
    final data = await call;
    final token = data['token'] as String?;
    if (token == null) throw ApiException('Sign-in failed. Please try again.');
    api.token = token;
    user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    await tokens.write(token);
    await refreshCart();
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await api.post('/users/logout');
    } catch (_) {
      // Stateless JWT: dropping the token locally is what signs out.
    }
    await google.signOut().catchError((_) {});
    await _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    api.token = null;
    user = null;
    cart = Cart.empty;
    await tokens.write(null);
  }

  // ---- bag ---------------------------------------------------------------

  Future<void> refreshCart() async {
    if (api.token == null) return;
    _setCart(await api.get('/cart'));
  }

  Future<void> addToBag(Product product, {int quantity = 1}) async {
    _setCart(await api.post('/cart', {'productId': product.id, 'quantity': quantity}));
  }

  Future<void> setQuantity(CartLine line, int quantity) async {
    _setCart(await api.put('/cart/${line.product.id}', {'quantity': quantity}));
  }

  Future<void> removeFromBag(CartLine line) async {
    _setCart(await api.delete('/cart/${line.product.id}'));
  }

  void _setCart(Map<String, dynamic> data) {
    cart = Cart.fromJson(data['cart'] as Map<String, dynamic>?);
    notifyListeners();
  }

  // ---- orders & payment -------------------------------------------------

  /// Turns the bag into a pending order. Returns the order and the 2Checkout
  /// payment page to open.
  Future<(Order, String?)> checkout(ShippingAddress address) async {
    final data = await api.post('/orders/checkout', {'shippingAddress': address.toJson()});
    final order = Order.fromJson(data['order'] as Map<String, dynamic>);
    // The server keeps the cart until payment completes; refresh our copy.
    await refreshCart().catchError((_) {});
    return (order, data['paymentUrl'] as String?);
  }

  Future<List<Order>> orders() async {
    final data = await api.get('/orders');
    return ((data['orders'] as List?) ?? []).whereType<Map<String, dynamic>>().map(Order.fromJson).toList();
  }

  Future<Order> order(String id) async {
    final data = await api.get('/orders/$id');
    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }

  /// New payment link for an order that is still pending.
  Future<String> paymentLink(String orderId) async {
    final data = await api.post('/orders/$orderId/pay');
    final url = data['paymentUrl'] as String?;
    if (url == null) throw ApiException('No payment link was returned.');
    return url;
  }

  // ---- newsletter --------------------------------------------------------

  Future<String> subscribe(String email) async {
    final data = await api.post('/newsletter', {'email': email.trim()});
    return (data['message'] as String?) ?? "Thank you, you're subscribed.";
  }
}

/// Makes [AppState] available to every screen.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read without rebuilding on changes (for callbacks).
  static AppState read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<AppScope>()!.widget as AppScope).notifier!;
}
