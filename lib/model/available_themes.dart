import 'package:flutter/material.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/themes.dart';
import 'package:kalium_wallet_flutter/model/setting_item.dart';

import '../themes.dart';

enum ThemeOptions { AVALANCHE, DEFAULT, KALIUM, TITANIUM, IRIDIUM, RADIUM, BERYLLIUM }

/// Represent notification on/off setting
class ThemeSetting extends SettingSelectionItem {
  ThemeOptions theme;

  ThemeSetting(this.theme);

  String getDisplayName(BuildContext context) {
    switch (theme) {
      case ThemeOptions.TITANIUM:
        return "Titanium";
      case ThemeOptions.IRIDIUM:
        return "Iridium";
      case ThemeOptions.BERYLLIUM:
        return "Beryllium";
      case ThemeOptions.RADIUM:
        return "Radium";
      case ThemeOptions.KALIUM:
        return "Kalium";
      case ThemeOptions.AVALANCHE:
        return "Avalanche";
      case ThemeOptions.DEFAULT:
      default:
        return "Default";
    }
  }

  BaseTheme getTheme() {
    switch (theme) {
      case ThemeOptions.TITANIUM:
        return TitaniumTheme();
      case ThemeOptions.IRIDIUM:
        return IridiumTheme();
      case ThemeOptions.BERYLLIUM:
        return BerylliumTheme();
      case ThemeOptions.RADIUM:
        return RadiumTheme();
      case ThemeOptions.KALIUM:
        return KaliumTheme();
      case ThemeOptions.AVALANCHE:
        return AvalancheTheme();
      case ThemeOptions.AVALANCHE:
      default:
        return DefaultTheme();
    }
  }

  // For saving to shared prefs
  int getIndex() {
    return theme.index;
  }
}
