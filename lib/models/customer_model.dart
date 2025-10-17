class LedgerEntry {
  final double amount;
  final String note;
  final String name;
  final String? paymentId;
  final DateTime createdAt;

  LedgerEntry({
    required this.amount,
    required this.note,
    required this.name,
    this.paymentId,
    required this.createdAt,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      amount: (json['amount'] ?? 0).toDouble(),
      note: json['note'] ?? '',
      name: json['name'] ?? '',
      paymentId: json['payment'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String nomineeName;
  final String nomineePhone;
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
  final String pin;
  final double amount;
  final DateTime date;
  final double walletBalance;
  final List<LedgerEntry> walletLedger; // ✅ added full wallet
  final String customerId;
  final DateTime joinDate;
  final DateTime emaidate; // ✅ added
  final DateTime creditedAt; // ✅ added
  final String createdBy; // ✅ added (User ref id)
  final String? manager; // ✅ optional (User ref id)

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.nomineeName,
    required this.nomineePhone,
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
    required this.pin,
    required this.amount,
    required this.date,
    this.walletBalance = 0.0,
    this.walletLedger = const [],
    required this.customerId,
    required this.joinDate,
    required this.emaidate,
    required this.creditedAt,
    required this.createdBy,
    this.manager,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    DateTime _safeParse(dynamic value) {
      if (value == null) return DateTime.now();

      // Check if it's a JS Date string like "Sat Oct 11 2025 01:33:04 GMT+0530 ..."
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        // Force conversion via DateTime.tryParse
        return DateTime.tryParse(value.toString()) ?? DateTime.now();
      }
    }

    return Customer(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email']?.toLowerCase() ?? '',
      phone: json['phone'] ?? '',
      nomineeName: json['nominee'] ?? '',
      nomineePhone: json['nomineePhone'] ?? '',
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
      pin: json['pin'] ?? '',
      amount:
          (json['amount'] is int)
              ? (json['amount'] as int).toDouble()
              : (json['amount']?.toDouble() ?? 0.0),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      walletBalance: (json['wallet']?['balance'] ?? 0).toDouble(),
      walletLedger:
          (json['wallet']?['ledger'] as List<dynamic>? ?? [])
              .map((e) => LedgerEntry.fromJson(e))
              .toList(),
      customerId: json['customerId'] ?? '',
      joinDate: _safeParse(json['joinDate']),
      emaidate: _safeParse(json['emaidate']),
      creditedAt: _safeParse(json['creditedAt']),
      createdBy: json['createdBy'] ?? '',
      manager: json['manager'],
    );
  }

  // ✅ Computed properties
  String get fullName => name;
  String get firstName => name.split(' ').first;
  String get lastName =>
      name.split(' ').length > 1 ? name.split(' ').sublist(1).join(' ') : '';
  String get phoneNumber => phone;
  double get schemeAmount => amount;
  DateTime get schemeDate => date;
  String get location => '$city, $state';
}
