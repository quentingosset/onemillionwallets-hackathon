class Actions {
  static const String SUBSCRIBE = 'account_subscribe';
  static const String ACCOUNTS_HISOTRY = 'balances_v2/?nft=true';
  static const String ACCOUNTS_BALANCES = 'balances_v2/?nft=false';
  static const String ACCOUNTS_BALANCES_HISTORY = 'portfolio_v2/?';
  static const String CONTRACT_TRANSACTION_HISTORY = 'transfers_v2/?contract-address={CONTRACT_ADDRESS}&page-size=100';
  static const String PROCESS = 'process';
  static const String BLOCK_INFO = 'block_info';
  static const String PENDING = "pending";
  //static const String ACCOUNTS_BALANCES = 'balances_v2';
  static const String FCM_UPDATE = 'fcm_update';
  static const String INFO = "account_info";
}