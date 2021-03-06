import 'package:flutter/material.dart';

// Represent user-account
class Account {
  int id; // Primary Key
  int index; // Index on the seed
  String name; // Account nickname
  int lastAccess; // Last Accessed incrementor
  bool selected; // Whether this is the currently selected account
  String address;
  int network;
  String balance; // Last known balance in RAW
  Widget monKey;

  Account({this.id, this.index, this.name, this.lastAccess, this.selected = false, this.address, this.network, this.balance});

  String getShortName() {
    List<String> splitName = name.split(" ");
    if (splitName.length > 1 && splitName[0].length >= 1 && splitName[1].length >= 1) {
      String firstChar = splitName[0].substring(0, 1);
      String secondPart = splitName[1].substring(0, 1);
      try {
        if (int.parse(splitName[1]) >= 10) {
          secondPart = splitName[1].substring(0, 2);
        }
      } catch (e) {}
      return firstChar + secondPart;
    } else if (name.length >= 2) {
      return name.substring(0, 2);
    } else {
      return name.substring(0, 1);
    }
  }
}