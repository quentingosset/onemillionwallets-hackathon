import 'package:json_annotation/json_annotation.dart';
import 'package:kalium_wallet_flutter/model/db/account.dart';
import 'package:kalium_wallet_flutter/network/model/request/actions.dart';
import 'package:kalium_wallet_flutter/network/model/base_request.dart';

part 'account_history_request.g.dart';

@JsonSerializable()
class AccountHistoryRequest extends BaseRequest {
  @JsonKey(name:'action')
  String action;
  
  Account account;

  @JsonKey(name:'count', includeIfNull: false)
  int count;

  AccountHistoryRequest({String action, Account account, int count}):super() {
    this.action = Actions.ACCOUNTS_HISOTRY;
    this.account = account;
    this.count = count ?? 3000;
  }

  factory AccountHistoryRequest.fromJson(Map<String, dynamic> json) => _$AccountHistoryRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AccountHistoryRequestToJson(this);
}