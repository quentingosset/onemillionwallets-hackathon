// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_transaction_history_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContractTransactionHistoryRequest _$ContractTransactionHistoryRequestFromJson(
    Map<String, dynamic> json) {
  return ContractTransactionHistoryRequest(
    action: json['action'] as String,
    //account: json['account'] as String,
    count: json['count'] as int,
  );
}

Map<String, dynamic> _$ContractTransactionHistoryRequestToJson(
    ContractTransactionHistoryRequest instance) {
  final val = <String, dynamic>{
    'action': instance.action,
    'account': instance.account,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('count', instance.count);
  return val;
}
