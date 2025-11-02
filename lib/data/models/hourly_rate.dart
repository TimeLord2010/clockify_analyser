class HourlyRate {
  num amount;

  HourlyRate({required this.amount});

  factory HourlyRate.fromMap(Map<String, dynamic> map) {
    return HourlyRate(amount: map['amount'] ?? 0);
  }

  Map<String, dynamic> get toMap {
    return {'amount': amount};
  }
}
