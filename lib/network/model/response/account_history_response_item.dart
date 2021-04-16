import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/model/address.dart';
import 'package:kalium_wallet_flutter/util/numberutil.dart';

part 'account_history_response_item.g.dart';

@JsonSerializable()
class AccountHistoryResponseItem {
  @JsonKey(name:'type')
  String type;

  @JsonKey(name:'contract_address')
  String contract_address;

  @JsonKey(name:'contract_decimals')
  int contract_decimals;

  @JsonKey(name:'logo_url')
  String logo;

  @JsonKey(name:'contract_ticker_symbol')
  String contract_ticker_symbol;

  @JsonKey(name:'balance')
  String amount;

  @JsonKey(name:'contract_name')
  String contract_name;

  @JsonKey(name:'quote_rate')
  double quote_rate;

  @JsonKey(name:'quote')
  double quote;

  @JsonKey(name:'nft_data')
  List<Nft> nft_data;

  String network;
  String walletAddress;

  AccountHistoryResponseItem({String type, String contract_address, int contract_decimals, String logo , String contract_ticker_symbol, String amount, String contract_name, double quote_rate, double quote, List<Nft> nft_data}) {
    this.type = type;
    this.contract_address = contract_address;
    this.contract_decimals = contract_decimals;
    this.logo = logo;
    this.contract_ticker_symbol = contract_ticker_symbol;
    this.amount = amount != null ? amount : 0;
    this.contract_name = contract_name;
    this.quote_rate = quote_rate != null ? quote_rate : 0;
    this.quote = quote != null ? quote : 0;
    this.nft_data = nft_data;
  }

  String getShortString() {
    return new Address(this.contract_ticker_symbol).getShortString();
  }

  String getShorterString() {
    return new Address(this.contract_ticker_symbol).getShorterString();
  }

  /**
   * Return amount formatted for use in the UI
   */
  String getFormattedAmount() {
    return NumberUtil.getRawAsUsableStringMaxDecimal(amount,contract_decimals);
  }

  factory AccountHistoryResponseItem.fromJson(Map<String, dynamic> json) => _$AccountHistoryResponseItemFromJson(json);
  Map<String, dynamic> toJson() => _$AccountHistoryResponseItemToJson(this);

  bool operator ==(o) => o is AccountHistoryResponseItem && o.contract_name == contract_name && o.walletAddress == walletAddress;
  int get hashCode => contract_name.hashCode;
}

@JsonSerializable()
class Nft {
  @JsonKey(name:'token_id')
  String token_id;

  @JsonKey(name:'token_url')
  String token_url;

  @JsonKey(name:'external_data')
  NftExternalData external_data;

  Nft({String token_id, String token_url, NftExternalData external_data}){
    this.token_id = token_id;
    this.token_url = token_url;
    this.external_data = external_data;
  }

  factory Nft.fromJson(Map<String, dynamic> json) => _$NftFromJson(json);
  Map<String, dynamic> toJson() => _$NftToJson(this);

  bool operator ==(o) => o is Nft && o.token_id == token_id;
  int get hashCode => token_id.hashCode;
}

@JsonSerializable()
class NftExternalData{
  @JsonKey(name:'name')
  String name;

  @JsonKey(name:'description')
  String description;

  @JsonKey(name:'external_url')
  String external_url;

  @JsonKey(name:'image')
  String image;

  NftExternalData({String name, String description, String image, String external_url}){
    this.name = name;
    this.description = description;
    this.image = image;
    this.external_url = external_url;
  }

  factory NftExternalData.fromJson(Map<String, dynamic> json) => _$NftExternalDataFromJson(json);
  Map<String, dynamic> toJson() => _$NftExternalDataToJson(this);
}


