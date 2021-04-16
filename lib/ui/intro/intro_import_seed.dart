import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:kalium_wallet_flutter/model/db/account.dart';
import 'package:kalium_wallet_flutter/model/db/appdb.dart';
import 'package:kalium_wallet_flutter/model/vault.dart';
import 'package:kalium_wallet_flutter/ui/widgets/security.dart';
import 'package:kalium_wallet_flutter/util/util.dart';
import 'package:keyboard_avoider/keyboard_avoider.dart';
import 'package:flutter_nano_ffi/flutter_nano_ffi.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/app_icons.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/ui/util/formatters.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';
import 'package:kalium_wallet_flutter/ui/widgets/app_text_field.dart';
import 'package:kalium_wallet_flutter/ui/widgets/tap_outside_unfocus.dart';
import 'package:kalium_wallet_flutter/util/sharedprefsutil.dart';

class IntroImportSeedPage extends StatefulWidget {
  @override
  _IntroImportSeedState createState() => _IntroImportSeedState();
}

class _IntroImportSeedState extends State<IntroImportSeedPage> {
  GlobalKey _scaffoldKey = GlobalKey<ScaffoldState>();

  // Plaintext seed
  FocusNode _seedInputFocusNode = FocusNode();
  TextEditingController _seedInputController = TextEditingController();
  // Mnemonic Phrase
  FocusNode _mnemonicFocusNode = FocusNode();
  TextEditingController _addressController = TextEditingController();

  bool _seedMode = false; // False if restoring phrase, true if restoring seed

  bool _seedIsValid = false;
  bool _showSeedError = false;
  bool _AddressIsValid = false;
  int _network;
  String _address;
  String _AddressError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      backgroundColor: StateContainer.of(context).curTheme.background,
      body: TapOutsideUnfocus(
        child: LayoutBuilder(
          builder: (context, constraints) => SafeArea(
            minimum: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.035,
                top: MediaQuery.of(context).size.height * 0.075),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          // Back Button
                          Container(
                            margin: EdgeInsetsDirectional.only(
                                start: smallScreen(context) ? 15 : 20),
                            height: 50,
                            width: 50,
                            child: FlatButton(
                                highlightColor: StateContainer.of(context)
                                    .curTheme
                                    .text15,
                                splashColor: StateContainer.of(context)
                                    .curTheme
                                    .text15,
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(50.0)),
                                padding: EdgeInsets.all(0.0),
                                child: Icon(AppIcons.back,
                                    color: StateContainer.of(context)
                                        .curTheme
                                        .backgroundRed,
                                    size: 24)),
                          ),
                          // Switch between Secret Phrase and Seed
                          /*Container(
                            margin: EdgeInsetsDirectional.only(
                                end: smallScreen(context) ? 15 : 20),
                            height: 50,
                            width: 50,
                            child: FlatButton(
                                highlightColor: StateContainer.of(context)
                                    .curTheme
                                    .text15,
                                splashColor: StateContainer.of(context)
                                    .curTheme
                                    .text15,
                                onPressed: () {
                                  setState(() {
                                    _seedMode = !_seedMode;
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(50.0)),
                                padding: EdgeInsets.all(0.0),
                                child: Icon(_seedMode ? Icons.vpn_key : AppIcons.seed,
                                    color: StateContainer.of(context)
                                        .curTheme
                                        .backgroundRed,
                                    size: 24)),
                          ),*/
                        ],
                      ),
                      // The header
                      Container(
                        margin: EdgeInsetsDirectional.only(
                          start: smallScreen(context) ? 30 : 40,
                          end: smallScreen(context) ? 30 : 40,
                          top: 10,
                        ),
                        alignment: AlignmentDirectional(-1, 0),
                        child: AutoSizeText(
                          _seedMode
                              ? AppLocalization.of(context).importSeed
                              : AppLocalization.of(context).addAccount,
                          style:
                              AppStyles.textStyleHeaderColored(context),
                          maxLines: 1,
                          minFontSize: 12,
                          stepGranularity: 0.1,
                        ),
                      ),
                      // The paragraph
                      Container(
                        margin: EdgeInsets.only(
                            left: smallScreen(context) ? 30 : 40, right: smallScreen(context) ? 30 : 40, top: 15.0),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _seedMode ?
                          AppLocalization.of(context).importSeedHint
                          : AppLocalization.of(context).creatAccountHint,
                          style:
                              AppStyles.textStyleParagraphPrimary(context),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      Expanded(
                        child: KeyboardAvoider(
                          duration: Duration(milliseconds: 0),
                          autoScroll: true,
                          focusPadding: 40,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              // The text field for the seed
                              _seedMode ? AppTextField(
                                leftMargin: smallScreen(context) ? 30 : 40,
                                rightMargin: smallScreen(context) ? 30 : 40,
                                topMargin: 20,
                                focusNode: _seedInputFocusNode,
                                controller: _seedInputController,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(64),
                                  UpperCaseTextFormatter()
                                ],
                                textInputAction: TextInputAction.done,
                                maxLines: null,
                                autocorrect: false,
                                /*prefixButton: TextFieldButton(
                                  icon: AppIcons.scan,
                                  onPressed: () {
                                    if (NanoSeeds.isValidSeed(
                                        _seedInputController
                                            .text)) {
                                      return;
                                    }
                                    // Scan QR for seed
                                    sl.get<UIUtil>().cancelLockEvent();
                                    BarcodeScanner.scan(StateContainer.of(context).curTheme.qrScanTheme).then((result) {
                                      if (result != null && NanoSeeds.isValidSeed(result)) {
                                        _seedInputController.text = result;
                                        setState(() {
                                          _seedIsValid = true;
                                        });
                                      } else if (result != null && NanoMnemomics.validateMnemonic(result.split(' '))) {
                                        _addressController.text = result;
                                        _mnemonicFocusNode.unfocus();
                                        _seedInputFocusNode.unfocus();
                                        setState(() {
                                          _seedMode = false;
                                          _AddressError = null;
                                          _AddressIsValid = true;
                                        });
                                      } else {
                                        sl.get<UIUtil>().showSnackbar(AppLocalization.of(context).qrInvalidSeed, context);
                                      }
                                    });
                                  },
                                ),*/
                                fadePrefixOnCondition: true,
                                prefixShowFirstCondition: !NanoSeeds.isValidSeed(_seedInputController.text),
                                suffixButton: TextFieldButton(
                                  icon: AppIcons.paste,
                                  onPressed: () {
                                    if (NanoSeeds.isValidSeed(
                                        _seedInputController
                                            .text)) {
                                      return;
                                    }
                                    Clipboard.getData("text/plain")
                                        .then((ClipboardData data) {
                                      if (data == null ||
                                          data.text == null) {
                                        return;
                                      } else if (NanoSeeds
                                          .isValidSeed(data.text)) {
                                        _seedInputController.text =
                                            data.text;
                                        setState(() {
                                          _seedIsValid = true;
                                        });
                                      } else if (NanoMnemomics.validateMnemonic(data.text.split(' '))) {
                                        _addressController.text = data.text;
                                        _mnemonicFocusNode.unfocus();
                                        _seedInputFocusNode.unfocus();
                                        setState(() {
                                          _seedMode = false;
                                          _AddressError = null;
                                          _AddressIsValid = true;
                                        });
                                      }
                                    });                            
                                  },
                                ),
                                fadeSuffixOnCondition: true,
                                suffixShowFirstCondition: !NanoSeeds.isValidSeed(_seedInputController.text),
                                keyboardType: TextInputType.text,
                                style: _seedIsValid ?AppStyles.textStyleSeed(context) : AppStyles.textStyleSeedGray(context),
                                onChanged: (text) {
                                  // Always reset the error message to be less annoying
                                  setState(() {
                                    _showSeedError = false;
                                  });
                                  // If valid seed, clear focus/close keyboard
                                  if (NanoSeeds.isValidSeed(text)) {
                                    _seedInputFocusNode.unfocus();
                                    setState(() {
                                      _seedIsValid = true;
                                    });
                                  } else {
                                    setState(() {
                                      _seedIsValid = false;
                                    });
                                  }
                                }
                              ) : // Mnemonic mode
                              AppTextField(
                                leftMargin: smallScreen(context) ? 30 : 40,
                                rightMargin: smallScreen(context) ? 30 : 40,
                                topMargin: 20,
                                focusNode: _mnemonicFocusNode,
                                controller: _addressController,
                                inputFormatters: [
                                  SingleSpaceInputFormatter(),
                                  LowerCaseTextFormatter(),
                                ],
                                textInputAction: TextInputAction.done,
                                maxLines: null,
                                autocorrect: false,
                                /*prefixButton: TextFieldButton(
                                  icon: AppIcons.scan,
                                  onPressed: () {
                                    if (NanoMnemomics.validateMnemonic(
                                        _addressController.text.split(' '))) {
                                      return;
                                    }
                                    // Scan QR for mnemonic
                                    sl.get<UIUtil>().cancelLockEvent();
                                    BarcodeScanner.scan(StateContainer.of(context).curTheme.qrScanTheme).then((result) {
                                      if (result != null && NanoMnemomics.validateMnemonic(result.split(' '))) {
                                        _addressController.text = result;
                                        setState(() {
                                          _AddressIsValid = true;
                                        });
                                      } else if (result != null && NanoSeeds.isValidSeed(result)) {
                                        _seedInputController.text = result;
                                        _mnemonicFocusNode.unfocus();
                                        _seedInputFocusNode.unfocus();
                                        setState(() {
                                          _seedMode = true;
                                          _seedIsValid = true;
                                          _showSeedError = false;
                                        });
                                      } else {
                                        sl.get<UIUtil>().showSnackbar(AppLocalization.of(context).qrMnemonicError, context);
                                      }
                                    });
                                  },
                                ),*/
                                //fadePrefixOnCondition: true,
                                //prefixShowFirstCondition: !NanoMnemomics.validateMnemonic(_addressController.text.split(' ')),
                                suffixButton: TextFieldButton(
                                  icon: AppIcons.paste,
                                  onPressed: () {
                                    if (NanoMnemomics.validateMnemonic(
                                        _addressController.text.split(' '))) {
                                      return;
                                    }
                                    Clipboard.getData("text/plain")
                                        .then((ClipboardData data) {
                                      if (data == null ||
                                          data.text == null) {
                                        return;
                                      } else /*if (NanoMnemomics.validateMnemonic(data.text.split(' '))) */{
                                        _addressController.text =
                                            data.text;
                                        setState(() {
                                          _AddressIsValid = true;
                                        });
                                      } /*else if (NanoSeeds.isValidSeed(data.text)) {
                                        _seedInputController.text = data.text;
                                        _mnemonicFocusNode.unfocus();
                                        _seedInputFocusNode.unfocus();
                                        setState(() {
                                          _seedMode = true;
                                          _seedIsValid = true;
                                          _showSeedError = false;
                                        });
                                      }*/
                                    });                           
                                  },
                                ),
                                fadeSuffixOnCondition: true,
                                suffixShowFirstCondition: !NanoMnemomics.validateMnemonic(_addressController.text.split(' ')),
                                keyboardType: TextInputType.text,
                                style: _AddressIsValid ? AppStyles.textStyleParagraphPrimary(context) : AppStyles.textStyleParagraph(context),
                                onChanged: (text) {
                                  if (_AddressError != null) {
                                    if (!text.contains(_AddressError.split(' ')[0])) {
                                      setState(() {
                                        _AddressError = null;
                                      });
                                    }
                                  }else{
                                    //_mnemonicFocusNode.unfocus();
                                    setState(() {
                                      _AddressIsValid = true;
                                      _AddressError = null;
                                    });
                                  }
                                },
                              ),
                              // "Invalid Seed" text that appears if the input is invalid
                              Container(
                                margin: EdgeInsets.only(top: 5),
                                child: Text(
                                    !_seedMode ? _AddressError == null ? "" : _AddressError
                                    : _showSeedError ? AppLocalization.of(context).seedInvalid : "",
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: _seedMode ? _showSeedError ? StateContainer.of(context).curTheme.primary : Colors.transparent : _AddressError != null ? StateContainer.of(context).curTheme.primary : Colors.transparent,
                                      fontFamily: 'NunitoSans',
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ]
                          )
                        )
                      )
                    ],
                  ),
                ),
                // Next Screen Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsetsDirectional.only(end: 30),
                      height: 50,
                      width: 50,
                      child: FlatButton(
                          highlightColor: StateContainer.of(context)
                              .curTheme
                              .primary15,
                          splashColor: StateContainer.of(context)
                              .curTheme
                              .primary30,
                          onPressed: () async {
                            /*if (_seedMode) {
                              _seedInputFocusNode.unfocus();
                              // If seed valid, log them in
                              if (NanoSeeds.isValidSeed(
                                  _seedInputController.text)) {
                                await sl.get<SharedPrefsUtil>().setSeedBackedUp(true);
                                await sl.get<Vault>().setSeed(_seedInputController.text);
                                await sl.get<DBHelper>().dropAccounts();
                                await NanoUtil().loginAccount(context);
                                String pin = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (BuildContext context) {
                                      return PinScreen(
                                          PinOverlayType.NEW_PIN,
                                          );
                                    }
                                  )
                                );
                                _pinEnteredCallback(pin);
                              } else {
                                // Display error
                                setState(() {
                                  _showSeedError = true;
                                });
                              }
                            } else {*/
                              // mnemonic mode
                              _mnemonicFocusNode.unfocus();
                              /*if (NanoMnemomics.validateMnemonic(_addressController.text.split(' '))) {
                                await sl.get<SharedPrefsUtil>().setSeedBackedUp(true);
                                await sl.get<Vault>().setSeed(NanoMnemomics.mnemonicListToSeed(_addressController.text.split(' ')));
                                await sl.get<DBHelper>().dropAccounts();
                                await Util().loginAccount(context);
                                String pin = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (BuildContext context) {
                                      return PinScreen(
                                          PinOverlayType.NEW_PIN,
                                          );
                                    }
                                  )
                                ); 
                                _pinEnteredCallback(pin);                     
                              } else {*/
                                // Show mnemonic error
                                if (_addressController.value.text.length == 0) {
                                  setState(() {
                                    _AddressIsValid = false;
                                    _AddressError = AppLocalization.of(context).AddressSizeError;
                                  });
                                }else{
                                  _network = 43114;
                                  await sl.get<DBHelper>().dropAccounts();
                                  Account selectedAcct = await sl.get<DBHelper>().getSelectedAccount();
                                  if (selectedAcct == null) {
                                    selectedAcct = Account(index: 0, lastAccess: 0, name: AppLocalization.of(context).defaultAccountName, address: _addressController.value.text,network: _network, selected: true);
                                    await sl.get<DBHelper>().saveAccount(selectedAcct);
                                  }
                                  await StateContainer.of(context).updateWallet(account: selectedAcct);
                                  String pin = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (BuildContext context) {
                                            return PinScreen(
                                              PinOverlayType.NEW_PIN,
                                            );
                                          }
                                      )
                                  );
                                  _pinEnteredCallback(pin);
                                }
                              //}
                            //}
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0)),
                          padding: EdgeInsets.all(0.0),
                          child: Icon(AppIcons.forward,
                              color: StateContainer.of(context)
                                  .curTheme
                                  .primary,
                              size: 50)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
      )
    );
  }

  void _pinEnteredCallback(String pin) {
    sl.get<Vault>().writePin(pin).then((result) {
      StateContainer.of(context).requestSubscribe();
      // Update wallet
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
    });
  }
}
