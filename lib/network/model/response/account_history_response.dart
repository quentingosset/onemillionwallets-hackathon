import 'package:json_annotation/json_annotation.dart';

import 'package:kalium_wallet_flutter/network/model/response/account_history_response_item.dart';

part 'account_history_response.g.dart';

/// For running in an isolate, needs to be top-level function
AccountHistoryResponse accountHistoryresponseFromJson(Map<dynamic, dynamic> json) {
  return AccountHistoryResponse.fromJson(json);
} 

@JsonSerializable()
class AccountHistoryResponse {
  @JsonKey(name:'items')
  List<AccountHistoryResponseItem> history;

  @JsonKey(ignore: true)
  String account;

  @JsonKey(ignore: true)
  String network;

  AccountHistoryResponse({List<AccountHistoryResponseItem> history, String account, String network}):super() {
    this.history = history;
    this.account = account;
    this.network = network;
  }

  factory AccountHistoryResponse.fromJson(Map<String, dynamic> json) => _$AccountHistoryResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AccountHistoryResponseToJson(this);
}


TransactionHistoryResponse transactionHistoryresponseFromJson(Map<dynamic, dynamic> json) {
  return TransactionHistoryResponse.fromJson(json);
}


class TransactionHistoryResponse {
  String contract_ticker_symbol;
  String delta;
  String transfer_type;
  int contract_decimals;
  String to_address;
  String from_address;
  String block_signed_at;

  TransactionHistoryResponse({String contract_ticker_symbol, String transfer_type, String delta, int contract_decimals, String to_address, String from_address, String block_signed_at}):super() {
    this.contract_ticker_symbol = contract_ticker_symbol;
    this.transfer_type = transfer_type;
    this.delta = delta;
    this.contract_decimals = contract_decimals;
    this.to_address = to_address;
    this.from_address = from_address;
    this.block_signed_at = block_signed_at;
  }

  factory TransactionHistoryResponse.fromJson(Map<String, dynamic> json) => _$TransactionHistoryResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionHistoryResponseToJson(this);
}

class TransactionList {
  final List<TransactionHistoryResponse> transactions;

  TransactionList({this.transactions});

  factory TransactionList.fromJson(List<dynamic> parsedJson) {

    List<TransactionHistoryResponse> transactions = new List<TransactionHistoryResponse>();
    transactions = parsedJson.map((i)=>TransactionHistoryResponse.fromJson(i)).toList();
    return new TransactionList(
      transactions: transactions,
    );
  }
}