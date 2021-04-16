import 'package:json_annotation/json_annotation.dart';
import 'package:kalium_wallet_flutter/model/db/account.dart';
import 'package:kalium_wallet_flutter/network/model/request/actions.dart';
import 'package:kalium_wallet_flutter/network/model/base_request.dart';

part 'accounts_balances_request.g.dart';

@JsonSerializable()
class AccountsBalancesRequest extends BaseRequest {
  @JsonKey(name:'action')
  String action;

  @JsonKey(name:'accounts')
  List<String> accounts;

  AccountsBalancesRequest({List<String> accounts}) {
    this.action = Actions.ACCOUNTS_BALANCES;
    this.accounts = accounts ?? [];
  }

  factory AccountsBalancesRequest.fromJson(Map<String, dynamic> json) => _$AccountsBalancesRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AccountsBalancesRequestToJson(this);

  @override
  // TODO: implement account
  Account get account => throw UnimplementedError();
}


@JsonSerializable()
class AccountsBalancesHistoryRequest extends BaseRequest {
  @JsonKey(name:'action')
  String action;

  @JsonKey(name:'accounts')
  Account account;

  AccountsBalancesHistoryRequest({Account account}) {
    this.action = Actions.ACCOUNTS_BALANCES_HISTORY;
    this.account = account;
  }

  factory AccountsBalancesHistoryRequest.fromJson(Map<String, dynamic> json) => _$AccountsBalancesHistoryRequestFromJson(json);
  //Map<String, dynamic> toJson() => _$AccountsBalancesHistoryRequestToJson(this);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}