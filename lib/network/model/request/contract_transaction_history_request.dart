import 'package:json_annotation/json_annotation.dart';
import 'package:kalium_wallet_flutter/model/db/account.dart';
import 'package:kalium_wallet_flutter/network/model/request/actions.dart';
import 'package:kalium_wallet_flutter/network/model/base_request.dart';

part 'contract_transaction_history_request.g.dart';

@JsonSerializable()
class ContractTransactionHistoryRequest extends BaseRequest {
  @JsonKey(name:'action')
  String action;
  
  Account account;

  String params;

  @JsonKey(name:'count', includeIfNull: false)
  int count;

  ContractTransactionHistoryRequest({String action, Account account, int count, String params}):super() {
    this.action = Actions.CONTRACT_TRANSACTION_HISTORY;
    this.account = account;
    this.params = params;
    this.count = count ?? 3000;
  }

  factory ContractTransactionHistoryRequest.fromJson(Map<String, dynamic> json) => _$ContractTransactionHistoryRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ContractTransactionHistoryRequestToJson(this);
}