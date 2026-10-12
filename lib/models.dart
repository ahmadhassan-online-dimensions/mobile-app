import 'photos.dart';

double _num(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

/// A product from `GET /products`. The API has no image or label fields, so
/// photos and display labels are matched by model, like the website does.
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: '${j['_id']}',
    name: '${j['name'] ?? ''}',
    description: '${j['description'] ?? ''}',
    price: _num(j['price']),
    category: '${j['category'] ?? ''}',
    stock: _int(j['stock']),
  );

  bool get isWearable => category.contains('wearable') || name.contains('01');

  /// "wearable-eyewear" -> "Wearable Eyewear".
  String get categoryLabel => category.isEmpty
      ? (isWearable ? 'Wearable Eyewear' : 'Handheld Eyewear')
      : category.split('-').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  /// The description starts with the category ("Wearable Eyewear. Opens...").
  String get story {
    final prefix = '$categoryLabel. ';
    return description.startsWith(prefix) ? description.substring(prefix.length) : description;
  }

  bool get inStock => stock > 0;

  /// Main photo (asset) for cards, bag and orders.
  String get photo => isWearable ? Photos.model01 : Photos.model02;

  /// Necklace-mode gallery (assets).
  List<String> get gallery => isWearable
      ? const [Photos.model01, Photos.wornCollar, Photos.wornLight]
      : const [Photos.model02, Photos.wornReturn, Photos.wornLight];

  /// One line for the collection cards (from the wireframe).
  String get tagline => isWearable
      ? 'A pendant necklace that becomes a pair of glasses, worn close all day.'
      : 'A necklace that lifts into a handheld lens, held only when you need it.';
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final DateTime? createdAt;

  const AppUser({required this.id, required this.name, required this.email, this.createdAt});

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: '${j['_id']}',
    name: '${j['name'] ?? ''}',
    email: '${j['email'] ?? ''}',
    createdAt: DateTime.tryParse('${j['createdAt']}')?.toLocal(),
  );

  String get firstName => name.trim().split(' ').first;
}

class CartLine {
  final Product product;
  final int quantity;
  final double lineTotal;

  const CartLine({required this.product, required this.quantity, required this.lineTotal});

  factory CartLine.fromJson(Map<String, dynamic> j) {
    final product = Product.fromJson(j['product'] as Map<String, dynamic>);
    final qty = _int(j['quantity']);
    return CartLine(
      product: product,
      quantity: qty,
      lineTotal: j['lineTotal'] == null ? product.price * qty : _num(j['lineTotal']),
    );
  }
}

class Cart {
  final List<CartLine> items;
  final int totalItems;
  final double totalAmount;

  const Cart({required this.items, required this.totalItems, required this.totalAmount});

  static const empty = Cart(items: [], totalItems: 0, totalAmount: 0);

  factory Cart.fromJson(Map<String, dynamic>? j) {
    if (j == null) return empty;
    final items = ((j['items'] as List?) ?? [])
        .whereType<Map<String, dynamic>>()
        // A product deleted after it was added comes back as null.
        .where((i) => i['product'] is Map<String, dynamic>)
        .map(CartLine.fromJson)
        .toList();
    return Cart(items: items, totalItems: _int(j['totalItems']), totalAmount: _num(j['totalAmount']));
  }

  bool get isEmpty => items.isEmpty;
}

class ShippingAddress {
  final String fullName;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  const ShippingAddress({
    required this.fullName,
    this.phone = '',
    required this.address,
    required this.city,
    this.state = '',
    this.postalCode = '',
    required this.country,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic>? j) => ShippingAddress(
    fullName: '${j?['fullName'] ?? ''}',
    phone: '${j?['phone'] ?? ''}',
    address: '${j?['address'] ?? ''}',
    city: '${j?['city'] ?? ''}',
    state: '${j?['state'] ?? ''}',
    postalCode: '${j?['postalCode'] ?? ''}',
    country: '${j?['country'] ?? ''}',
  );

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    if (phone.isNotEmpty) 'phone': phone,
    'address': address,
    'city': city,
    if (state.isNotEmpty) 'state': state,
    if (postalCode.isNotEmpty) 'postalCode': postalCode,
    'country': country,
  };

  List<String> get lines => [
    fullName,
    address,
    [city, state, postalCode].where((s) => s.isNotEmpty).join(', '),
    country,
    if (phone.isNotEmpty) phone,
  ];
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;

  const OrderItem({required this.productId, required this.name, required this.price, required this.quantity});

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    productId: j['product'] is Map ? '${(j['product'] as Map)['_id']}' : '${j['product']}',
    name: '${j['name'] ?? ''}',
    price: _num(j['price']),
    quantity: _int(j['quantity']),
  );
}

class Order {
  final String id;
  final List<OrderItem> items;
  final ShippingAddress shippingAddress;
  final double totalAmount;
  final String currency;

  /// pending | paid | cancelled
  final String status;

  /// processing | shipped | delivered
  final String fulfillment;
  final DateTime? createdAt;
  final DateTime? paidAt;

  const Order({
    required this.id,
    required this.items,
    required this.shippingAddress,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.fulfillment,
    this.createdAt,
    this.paidAt,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: '${j['_id']}',
    items: ((j['items'] as List?) ?? []).whereType<Map<String, dynamic>>().map(OrderItem.fromJson).toList(),
    shippingAddress: ShippingAddress.fromJson(j['shippingAddress'] as Map<String, dynamic>?),
    totalAmount: _num(j['totalAmount']),
    currency: '${j['currency'] ?? 'AED'}',
    status: '${j['status'] ?? 'pending'}',
    fulfillment: '${j['fulfillment'] ?? 'processing'}',
    createdAt: DateTime.tryParse('${j['createdAt']}')?.toLocal(),
    paidAt: DateTime.tryParse('${j['paidAt']}')?.toLocal(),
  );

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isCancelled => status == 'cancelled';

  /// Short reference shown to the customer.
  String get number => id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);

  String get statusLabel {
    if (isCancelled) return 'Cancelled';
    if (isPending) return 'Awaiting payment';
    switch (fulfillment) {
      case 'shipped':
        return 'Shipped · on its way';
      case 'delivered':
        return 'Delivered';
      default:
        return 'In atelier · being prepared';
    }
  }

  /// Progress for "Placed · Atelier · Shipped · Delivered" (1–4 reached).
  int get stage {
    if (isCancelled || isPending) return 1;
    return switch (fulfillment) {
      'delivered' => 4,
      'shipped' => 3,
      _ => 2,
    };
  }
}
