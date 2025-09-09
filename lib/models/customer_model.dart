class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int coins;
  final String aadhaarNo;
  final String panNumber;
  final String address;
  final String bank;
  final String ifsc;
  final String acc;
  final String branch;
  final String city;
  final String state;
  final String addrass;
  final String pin;
  final double amount;
  final DateTime date;
  final String customerId;
  final DateTime joinDate;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.coins,
    required this.aadhaarNo,
    required this.panNumber,
    required this.address,
    required this.bank,
    required this.ifsc,
    required this.acc,
    required this.branch,
    required this.city,
    required this.state,
    required this.addrass,
    required this.pin,
    required this.amount,
    required this.date,
    required this.customerId,
    required this.joinDate,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email']?.toLowerCase() ?? '',
      phone: json['phone'] ?? '',
      coins: json['coins'] ?? 0,
      aadhaarNo: json['adharcard'] ?? '',
      panNumber: json['pancard'] ?? '',
      address: json['address'] ?? '',
      bank: json['Bank'] ?? '',
      ifsc: json['IFSC'] ?? '',
      acc: json['acc'] ?? '',
      branch: json['branch'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      addrass: json['addrass'] ?? '',
      pin: json['pin'] ?? '',
      amount:
          (json['amount'] is int)
              ? (json['amount'] as int).toDouble()
              : (json['amount']?.toDouble() ?? 0.0),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      customerId: json['customerId'] ?? '',
      joinDate: DateTime.parse(
        json['joinDate'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // Computed properties to match your existing UI
  String get fullName => name;
  String get firstName => name.split(' ').first;
  String get lastName =>
      name.split(' ').length > 1 ? name.split(' ').sublist(1).join(' ') : '';
  String get phoneNumber => phone;
  double get schemeAmount => amount;
  DateTime get schemeDate => date;
  String get location => '$city, $state';
}
