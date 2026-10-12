import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:testapp/api/api_client.dart';
import 'package:testapp/main.dart';
import 'package:testapp/models.dart';
import 'package:testapp/state/app_state.dart';
import 'package:testapp/theme.dart';

/// Fake of the VUE & OR REST API with the same response shapes as the backend.
class FakeBackend {
  final requests = <http.Request>[];
  final products = [
    {
      '_id': 'p1',
      'name': 'Model 01',
      'description':
          'Wearable Eyewear. Opens into eyewear with slender temples that rest on the ears. The signature piece.',
      'price': 9800,
      'category': 'wearable-eyewear',
      'stock': 25,
    },
    {
      '_id': 'p2',
      'name': 'Model 02',
      'description':
          'Handheld Eyewear. Opens into a lens held gracefully to the eyes, then closes, and becomes jewelry again.',
      'price': 6900,
      'category': 'handheld-eyewear',
      'stock': 3,
    },
  ];
  final cartItems = <Map<String, dynamic>>[];

  Map<String, dynamic> get cart => {
    'items': [
      for (final i in cartItems)
        {
          'product': i['product'],
          'quantity': i['quantity'],
          'lineTotal': (i['product']['price'] as int) * (i['quantity'] as int),
        },
    ],
    'totalItems': cartItems.fold<int>(0, (s, i) => s + (i['quantity'] as int)),
    'totalAmount': cartItems.fold<int>(0, (s, i) => s + (i['product']['price'] as int) * (i['quantity'] as int)),
  };

  http.Response _json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

  late final client = MockClient((req) async {
    requests.add(req);
    final path = req.url.path.replaceFirst('/api', '');
    final authed = req.headers['Authorization'] == 'Bearer tok123';
    final body = req.body.isEmpty ? <String, dynamic>{} : jsonDecode(req.body) as Map<String, dynamic>;

    switch ((req.method, path)) {
      case ('GET', '/products'):
        return _json({'status': 'OK', 'products': products, 'total': 2});
      case ('POST', '/users/login'):
        if (body['password'] != 'secret1') {
          return _json({'status': 'Error', 'message': 'Invalid Email Or Password'}, 401);
        }
        return _json({
          'status': 'OK',
          'token': 'tok123',
          'user': {'_id': 'u1', 'name': 'Sara Ahmed', 'email': body['email']},
        });
      case ('GET', '/cart'):
        return authed ? _json({'status': 'OK', 'cart': cart}) : _json({'message': 'Not authorized'}, 401);
      case ('POST', '/cart'):
        if (!authed) return _json({'message': 'Not authorized'}, 401);
        final p = products.firstWhere((p) => p['_id'] == body['productId']);
        cartItems.add({'product': p, 'quantity': body['quantity'] ?? 1});
        return _json({'status': 'OK', 'cart': cart}, 201);
      case ('POST', '/orders/checkout'):
        return _json({
          'status': 'OK',
          'order': {
            '_id': '6ac3d37c203c9935c49c0aaa',
            'items': [
              {'product': 'p1', 'name': 'Model 01', 'price': 9800, 'quantity': 1},
            ],
            'shippingAddress': body['shippingAddress'],
            'totalAmount': 9800,
            'currency': 'AED',
            'status': 'pending',
            'fulfillment': 'processing',
          },
          'paymentUrl': 'https://secure.2checkout.com/checkout/buy?test=1',
        }, 201);
      case ('POST', '/newsletter'):
        return _json({'status': 'OK', 'message': "Thank you, you're subscribed."}, 201);
    }
    return _json({'status': 'Error', 'message': 'Route not found: ${req.method} $path'}, 404);
  });
}

class FakeGoogle implements GoogleAuth {
  @override
  Future<String> idToken() async => throw ApiException('Google sign-in was cancelled.');

  @override
  Future<void> signOut() async {}
}

AppState newState(FakeBackend backend, {String? savedToken, KeyValueStore? storage}) => AppState(
  api: ApiClient(client: backend.client, baseUrl: 'https://test.local/api'),
  tokens: MemoryTokenStore(savedToken),
  google: FakeGoogle(),
  storage: storage ?? MemoryKeyValueStore(),
);

/// Pumps the app past the splash onto the welcome film (which loops, so no
/// pumpAndSettle while it is on screen).
Future<AppState> openWelcome(WidgetTester tester, FakeBackend backend) async {
  // A 390 x 844 phone, like the emulator.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final state = newState(backend);
  await tester.runAsync(state.start);
  await tester.pumpWidget(MyApp(state: state));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(seconds: 1));
  return state;
}

/// Welcome -> "ENTER THE COLLECTION" -> Home.
Future<AppState> openApp(WidgetTester tester, FakeBackend backend) async {
  final state = await openWelcome(tester, backend);
  await tester.tap(find.text('ENTER THE COLLECTION'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return state;
}

Future<void> goTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(Semantics), matching: find.text(label)).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => AppText.useGoogleFonts = false);

  group('API state', () {
    test('loads products from GET /products', () async {
      final state = newState(FakeBackend());
      await state.loadProducts();

      expect(state.products.map((p) => p.name), ['Model 01', 'Model 02']);
      expect(state.products.first.categoryLabel, 'Wearable Eyewear');
      expect(state.products.first.story, startsWith('Opens into eyewear'));
      expect(state.productByModel(wearable: false)!.price, 6900);
    });

    test('sign in stores the JWT and sends it on later calls', () async {
      final backend = FakeBackend();
      final state = newState(backend);
      await state.signIn('sara@example.com', 'secret1');

      expect(state.user!.firstName, 'Sara');
      expect(await state.tokens.read(), 'tok123');

      await state.loadProducts();
      await state.addToBag(state.products.first, quantity: 2);
      expect(backend.requests.last.headers['Authorization'], 'Bearer tok123');
      expect(state.bagCount, 2);
      expect(state.cart.totalAmount, 19600);
    });

    test('wrong password surfaces the server message', () async {
      final state = newState(FakeBackend());
      expect(
        () => state.signIn('sara@example.com', 'nope'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Invalid Email Or Password')),
      );
    });

    test('checkout returns the pending order and the payment page', () async {
      final state = newState(FakeBackend());
      await state.signIn('sara@example.com', 'secret1');
      final (order, url) = await state.checkout(
        const ShippingAddress(
          fullName: 'Sara Ahmed',
          address: 'Villa 12, Jumeirah 1',
          city: 'Dubai',
          country: 'United Arab Emirates',
        ),
      );

      expect(order.isPending, isTrue);
      expect(order.statusLabel, 'Awaiting payment');
      expect(order.number, 'C49C0AAA');
      expect(url, startsWith('https://secure.2checkout.com/'));
    });

    test('saved session is restored on start', () async {
      final state = newState(FakeBackend(), savedToken: 'tok123');
      // /users/profile isn't faked: a 404 must not crash start-up.
      await state.start();
      expect(state.products, hasLength(2));
    });
  });

  test('formatAed groups thousands', () {
    expect(formatAed(9800), 'AED 9,800');
    expect(formatAed(1234567), 'AED 1,234,567');
    expect(formatAed(690), 'AED 690');
  });

  group('on-device preferences', () {
    test('wishlist, piece options and prescription are saved and reloaded', () async {
      final storage = MemoryKeyValueStore();
      final state = newState(FakeBackend(), storage: storage);
      await state.loadProducts();
      final m1 = state.products.first;

      await state.toggleWishlist(m1);
      await state.setOptions(
        m1,
        const PieceOptions(finish: Finish.goldPlated, lens: LensType.reading, strength: '+1.50'),
      );
      await state.savePrescription(const Prescription(rightSph: '-1.25', leftSph: '-1.00', pd: '62'));

      final reopened = newState(FakeBackend(), storage: storage);
      await reopened.start();
      final again = reopened.products.first;

      expect(reopened.isWishlisted(again), isTrue);
      expect(reopened.optionsFor(again).summary, 'Gold Plated · Reading +1.50');
      expect(reopened.prescription!.pd, '62');
    });

    test('defaults are Solid Gold with plain lenses', () {
      expect(const PieceOptions().summary, 'Solid Gold · Plain lenses');
    });
  });

  testWidgets('welcome film leads into the collection', (tester) async {
    await openWelcome(tester, FakeBackend());
    expect(find.text('ENTER THE COLLECTION'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('ENTER THE COLLECTION'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('DISCOVER'), findsOneWidget);
    expect(find.text('THE CONVERTIBLE COLLECTION'), findsOneWidget);
  });

  testWidgets('shop lists live products and the wishlist heart works', (tester) async {
    final state = await openApp(tester, FakeBackend());
    await goTab(tester, 'Shop');

    expect(find.text('From AED 9,800'), findsOneWidget);
    expect(find.text('2 pieces'), findsOneWidget);

    await tester.tap(find.byTooltip('Save to wishlist').first);
    await tester.pumpAndSettle();
    expect(state.wishlistProducts.single.name, 'Model 01');

    await tester.tap(find.text('HANDHELD'));
    await tester.pumpAndSettle();
    expect(find.text('1 piece'), findsOneWidget);
  });

  testWidgets('product page: choose reading lenses, guests must sign in to add', (tester) async {
    final state = await openApp(tester, FakeBackend());
    await goTab(tester, 'Shop');

    final card = find.text('Model 01').first;
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('ADD TO BAG'), findsOneWidget);

    final reading = find.text('Reading');
    await tester.ensureVisible(reading);
    await tester.pumpAndSettle();
    await tester.tap(reading);
    await tester.pumpAndSettle();
    await tester.tap(find.text('+1.75'));
    await tester.pumpAndSettle();

    expect(state.optionsFor(state.products.first).summary, 'Solid Gold · Reading +1.75');
    expect(find.text('Solid Gold · Reading +1.75'), findsOneWidget);

    await tester.tap(find.text('ADD TO BAG'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Sign in to add pieces to your bag.'), findsOneWidget);
  });

  testWidgets('lens guide applies a reading strength to the collection', (tester) async {
    final state = await openApp(tester, FakeBackend());
    await goTab(tester, 'Lenses');

    await tester.scrollUntilVisible(find.text('+2.50'), 200, scrollable: find.byType(Scrollable).hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('+2.50'));
    await tester.pumpAndSettle();
    final apply = find.text('SHOP WITH READING +2.50');
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();

    for (final p in state.products) {
      expect(state.optionsFor(p).lensLabel, 'Reading +2.50');
    }
    expect(find.text('2 pieces'), findsOneWidget); // landed on Shop
  });
}
