import 'package:json_annotation/json_annotation.dart';
import 'package:kalium_wallet_flutter/model/db/account.dart';
import 'package:kalium_wallet_flutter/network/model/request/actions.dart';
import 'package:kalium_wallet_flutter/network/model/base_request.dart';

part 'account_info_request.g.dart';

@JsonSerializable()
class AccountInfoRequest extends BaseRequest {
  @JsonKey(name:'action')
  String action;

  @JsonKey(name:'account')
  Account account;


  AccountInfoRequest({String action, Account account}):super() {
    this.action = Actions.INFO;
    this.account = account;
  }

  factory AccountInfoRequest.fromJson(Map<String, dynamic> json) => _$AccountInfoRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AccountInfoRequestToJson(this);
}