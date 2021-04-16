// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_history_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountHistoryResponse _$AccountHistoryResponseFromJson(
    Map<String, dynamic> json) {
  return AccountHistoryResponse(
    account: json['address'],
    network: json['chain_id'].toString(),
    history: (json['items'] as List)
        ?.map((e) => e == null
            ? null
            : AccountHistoryResponseItem.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$AccountHistoryResponseToJson(AccountHistoryResponse instance) =>
    <String, dynamic>{
      'history': instance.history,
    };


TransactionHistoryResponse _$TransactionHistoryResponseFromJson(Map<String, dynamic> json) {
  return new TransactionHistoryResponse(
    contract_ticker_symbol: json['contract_ticker_symbol'],
    transfer_type: json['transfer_type'],
    delta: json['delta'],
    contract_decimals: json['contract_decimals'],
    to_address: json['to_address'],
    from_address: json['from_address'],
    block_signed_at: json['block_signed_at'],
  );
}

Map<String, dynamic> _$TransactionHistoryResponseToJson(TransactionHistoryResponse instance) =>
    <String, dynamic>{
      //'history': instance.history,
    };
