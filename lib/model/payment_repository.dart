import 'dart:math';

import 'package:square_in_app_payments/models.dart';

class PaymentsRepository {
  static Random random = Random();

  /// this call should be to our own server
  /// where we can safely process the payment
  /// by passing our token and nonce to square
  static String actuallyMakeTheCharge(CardDetails card) {
    print('card: $card');
    // simulating results
    if (!random.nextBool()) {
      // failure
      return 'Something went wrong processing your payment';
    }
    return 'Success';
  }
}
