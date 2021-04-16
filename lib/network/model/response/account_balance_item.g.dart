// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_balance_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountBalanceItem _$AccountBalanceItemFromJson(Map<String, dynamic> json) {
  return AccountBalanceItem(
    balance: "40" as String,
    pending: json['pending'] as String,
  );
}

Map<String, dynamic> _$AccountBalanceItemToJson(AccountBalanceItem instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'pending': instance.pending,
    };
