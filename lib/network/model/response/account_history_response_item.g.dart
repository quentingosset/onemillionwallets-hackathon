// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_history_response_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountHistoryResponseItem _$AccountHistoryResponseItemFromJson(Map<String, dynamic> json) {
  var list = json['nft_data'] as List;
  List<Nft> nftList = list == null? null : list.map((i) => Nft.fromJson(i)).toList();

  return AccountHistoryResponseItem(
    type: json['type'] as String,
    contract_address: json['contract_address'] as String,
    contract_decimals: json['contract_decimals'] as int,
    logo: json['logo_url'] as String,
    contract_ticker_symbol: json['contract_ticker_symbol'] as String,
    amount: json['balance'] as String,
    contract_name: json['contract_name'] as String,
    quote_rate: json['quote_rate'] as double,
    quote: json['quote'] as double,
    nft_data: nftList,
  );

}

Map<String, dynamic> _$AccountHistoryResponseItemToJson(
        AccountHistoryResponseItem instance) =>
    <String, dynamic>{
      'type': instance.type,
      'contract_decimals': instance.contract_decimals,
      'logo_url': instance.logo,
      'contract_ticker_symbol': instance.contract_ticker_symbol,
      'balance': instance.amount,
      'contract_name': instance.contract_name,
      'quote_rate': instance.quote_rate,
      'quote': instance.quote,
      'nft_data': instance.nft_data,
    };

Nft _$NftFromJson(Map<String, dynamic> json) {
  return Nft(
    token_id: json['token_id'] as String,
    token_url: json['token_url'] as String,
    external_data: NftExternalData.fromJson(json['external_data'])
  );
}

Map<String, dynamic> _$NftToJson(Nft instance) => <String, dynamic>{
      'token_id': instance.token_id,
      'token_url': instance.token_url,
};

NftExternalData _$NftExternalDataFromJson(Map<String, dynamic> json) {
  return NftExternalData(
    name: json['name'] as String,
    description: json['description'] as String,
    image: json['image'] as String,
    external_url: json['external_url'] as String,
  );
}

Map<String, dynamic> _$NftExternalDataToJson(NftExternalData instance) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'image': instance.image,
  'external_url': instance.external_url,
};
