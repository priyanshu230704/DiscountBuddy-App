/// Wallet model
class Wallet {
  final int id;
  final String balance;

  Wallet({
    required this.id,
    required this.balance,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as int,
      balance: json['balance'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balance': balance,
    };
  }

  /// Get balance as double
  double get balanceAsDouble {
    try {
      return double.parse(balance);
    } catch (e) {
      return 0.0;
    }
  }
}
