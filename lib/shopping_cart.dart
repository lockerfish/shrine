// Copyright 2018-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:square_in_app_payments/in_app_payments.dart';

import 'colors.dart';
import 'expanding_bottom_sheet.dart';
import 'model/app_state_model.dart';
import 'model/payment_repository.dart';
import 'model/product.dart';

const _leftColumnWidth = 60.0;

class ShoppingCartPage extends StatefulWidget {
  @override
  _ShoppingCartPageState createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  List<Widget> _createShoppingCartRows(AppStateModel model) {
    return model.productsInCart.keys
        .map(
          (id) => ShoppingCartRow(
            product: model.getProductById(id),
            quantity: model.productsInCart[id],
            onPressed: () {
              model.removeItemFromCart(id);
            },
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final localTheme = Theme.of(context);

    return Scaffold(
      backgroundColor: kShrinePink50,
      body: SafeArea(
        child: Container(
          child: ScopedModelDescendant<AppStateModel>(
            builder: (context, child, model) {
              return Stack(
                children: [
                  ListView(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: _leftColumnWidth,
                            child: IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down),
                                onPressed: () =>
                                    ExpandingBottomSheet.of(context).close()),
                          ),
                          Text(
                            'CART',
                            style: localTheme.textTheme.subhead
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 16.0),
                          Text('${model.totalCartQuantity} ITEMS'),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Column(
                        children: _createShoppingCartRows(model),
                      ),
                      ShoppingCartSummary(model: model),
                      const SizedBox(height: 100.0),
                    ],
                  ),
                  Positioned(
                    bottom: 16.0,
                    left: 16.0,
                    right: 16.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        buildCartButton(
                            model, context, 'TAKE MY MONEY', _payment),
                        buildCartButton(
                            model, context, 'CLEAR CART', _clearCart),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  RaisedButton buildCartButton(
      AppStateModel model, BuildContext context, String text, Function action) {
    return RaisedButton(
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(7.0)),
      ),
      color: kShrinePink100,
      splashColor: kShrineBrown600,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Text(text),
      ),
      onPressed: () => action(model, context),
    );
  }
}

void _clearCart(AppStateModel model, BuildContext context) {
  model.clearCart();
  ExpandingBottomSheet.of(context).close();
}

Future<Null> _payment(AppStateModel model, BuildContext context) async {
  print('payment');

  await InAppPayments.setSquareApplicationId('APPLICATION_ID');
  await InAppPayments.startCardEntryFlow(
      onCardNonceRequestSuccess: (result) async {
    try {
      // take payment with the card nonce details
      // you can take a charge
      // await chargeCard(result);
      var chargeResult = PaymentsRepository.actuallyMakeTheCharge(result);
      if (chargeResult != 'Success') throw Exception(chargeResult);
      // payment finished successfully
      // you must call this method to close card entry
      await InAppPayments.completeCardEntry(onCardEntryComplete: () {
        // Update UI to notify user that the payment flow is finished successfully
        print('onCardEntryComplete');
        _clearCart(model, context);
      });
    } on Exception catch (ex) {
      // payment failed to complete due to error
      // notify card entry to show processing error
      print('error: $ex');
      await InAppPayments.showCardNonceProcessingError(ex.toString());
    }
  }, onCardEntryCancel: () {
    /// Handle the cancel callback
    print('onCardEntryCancel');
  });
}

class ShoppingCartSummary extends StatelessWidget {
  ShoppingCartSummary({this.model});

  final AppStateModel model;

  @override
  Widget build(BuildContext context) {
    final smallAmountStyle =
        Theme.of(context).textTheme.body1.copyWith(color: kShrineBrown600);
    final largeAmountStyle = Theme.of(context).textTheme.display1;
    final formatter = NumberFormat.simpleCurrency(
        decimalDigits: 2, locale: Localizations.localeOf(context).toString());

    return Row(
      children: [
        SizedBox(width: _leftColumnWidth),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text('TOTAL'),
                    ),
                    Text(
                      formatter.format(model.totalCost),
                      style: largeAmountStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Subtotal:'),
                    ),
                    Text(
                      formatter.format(model.subtotalCost),
                      style: smallAmountStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Shipping:'),
                    ),
                    Text(
                      formatter.format(model.shippingCost),
                      style: smallAmountStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Tax:'),
                    ),
                    Text(
                      formatter.format(model.tax),
                      style: smallAmountStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ShoppingCartRow extends StatelessWidget {
  ShoppingCartRow(
      {@required this.product, @required this.quantity, this.onPressed});

  final Product product;
  final int quantity;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.simpleCurrency(
        decimalDigits: 0, locale: Localizations.localeOf(context).toString());
    final localTheme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        key: ValueKey(product.id),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _leftColumnWidth,
            child: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onPressed,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        product.assetName,
                        package: product.assetPackage,
                        fit: BoxFit.cover,
                        width: 75.0,
                        height: 75.0,
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Quantity: $quantity'),
                                ),
                                Text('x ${formatter.format(product.price)}'),
                              ],
                            ),
                            Text(
                              product.name,
                              style: localTheme.textTheme.subhead
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  const Divider(
                    color: kShrineBrown900,
                    height: 10.0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
