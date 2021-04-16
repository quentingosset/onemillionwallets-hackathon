import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nano_ffi/flutter_nano_ffi.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/dimens.dart';
import 'package:kalium_wallet_flutter/model/vault.dart';
import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/ui/widgets/auto_resize_text.dart';
import 'package:kalium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:kalium_wallet_flutter/util/util.dart';
import 'package:rive/rive.dart';

class IntroWelcomePage extends StatefulWidget {
  @override
  _IntroWelcomePageState createState() => _IntroWelcomePageState();
}

class _IntroWelcomePageState extends State<IntroWelcomePage> {
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  final riveFileName = 'assets/heart.riv';
  Artboard _artboard;

  @override
  void initState() {
    _loadRiveFile();
    super.initState();
  }

  // loads a Rive file
  void _loadRiveFile() async {
    final bytes = await rootBundle.load(riveFileName);
    final file = RiveFile();

    if (file.import(bytes)) {
      // Select an animation by its name
      setState(() => _artboard = file.mainArtboard
        ..addController(
          SimpleAnimation('idle'),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      backgroundColor: StateContainer.of(context).curTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) => SafeArea(
              minimum: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.035,
                top: MediaQuery.of(context).size.height * 0.10,
              ),
              child: Column(
                children: <Widget>[
                  //A widget that holds welcome animation + paragraph
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        //Container for the animation
                        Container(
                          //Width/Height ratio for the animation is needed because BoxFit is not working as expected
                          width: double.infinity,
                          height: MediaQuery.of(context).size.width * 5 / 8,
                          child: Stack(
                            children: <Widget>[
                              Center(
                                  child: Image(
                                    image :  AssetImage("assets/onemillionwallets.png"),
                                    width: MediaQuery.of(context).size.width / 2,
                                    color: null,
                                    alignment: Alignment.center
                                  )
                              )
                            ],
                          ),
                        ),
                        //Container for the paragraph
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                          child: AutoSizeText(
                            AppLocalization.of(context).welcomeText,
                            textAlign: TextAlign.center,
                            style: AppStyles.textStyleParagraphPrimary(context),
                            //
                            // maxLines: 4,
                           // stepGranularity: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  //A column with "Add Address" button
                  Column(
                    children: <Widget>[
                      /*Row(
                        children: <Widget>[
                          // New Wallet Button
                          AppButton.buildAppButton(
                              context,
                              AppButtonType.PRIMARY,
                              AppLocalization.of(context).newWallet,
                              Dimens.BUTTON_TOP_DIMENS, onPressed: () {
                            sl.get<Vault>().setSeed(NanoSeeds.generateSeed()).then((result) {
                              // Update wallet
                              NanoUtil().loginAccount(context).then((_) {
                                StateContainer.of(context).requestUpdate();
                                Navigator.of(context)
                                    .pushNamed('/intro_backup_safety');
                              });
                            });
                          }),
                        ],
                      ),*/
                      Row(
                        children: <Widget>[
                          // Import Wallet Button
                          AppButton.buildAppButton(
                              context,
                              AppButtonType.PRIMARY,
                              AppLocalization.of(context).addAccount,
                              Dimens.BUTTON_BOTTOM_DIMENS, onPressed: () {
                            Navigator.of(context).pushNamed('/intro_import');
                          }),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
