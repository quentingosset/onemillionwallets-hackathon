import 'package:kalium_wallet_flutter/model/db/account.dart';

abstract class BaseRequest {
  Account get account;

  String get action => null;

  String get params => null;

  Map<String, dynamic> toJson();

}