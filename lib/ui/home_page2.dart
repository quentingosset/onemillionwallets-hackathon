import 'dart:async';
import 'package:flare_flutter/flare.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:event_taxi/event_taxi.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kalium_wallet_flutter/ui/balance_history_page.dart';
import 'package:kalium_wallet_flutter/ui/portefolio_nfts_page.dart';
import 'package:kalium_wallet_flutter/ui/widgets/auto_resize_text.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/dimens.dart';
import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/model/address.dart';
import 'package:kalium_wallet_flutter/model/list_model.dart';
import 'package:kalium_wallet_flutter/model/db/account.dart';
import 'package:kalium_wallet_flutter/model/db/contact.dart';
import 'package:kalium_wallet_flutter/model/db/appdb.dart';
import 'package:kalium_wallet_flutter/network/model/block_types.dart';
import 'package:kalium_wallet_flutter/network/model/response/account_history_response_item.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/app_icons.dart';
import 'package:kalium_wallet_flutter/ui/contacts/add_contact.dart';
import 'package:kalium_wallet_flutter/ui/send/send_sheet.dart';
import 'package:kalium_wallet_flutter/ui/send/send_confirm_sheet.dart';
import 'package:kalium_wallet_flutter/ui/receive/receive_sheet.dart';
import 'package:kalium_wallet_flutter/ui/settings/settings_drawer.dart';
import 'package:kalium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:kalium_wallet_flutter/ui/widgets/sheet_util.dart';
import 'package:kalium_wallet_flutter/ui/widgets/list_slidable.dart';
import 'package:kalium_wallet_flutter/ui/util/routes.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';
import 'package:kalium_wallet_flutter/util/sharedprefsutil.dart';
import 'package:kalium_wallet_flutter/bus/events.dart';
import 'package:logger/logger.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'portefolio_tokens_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with
        WidgetsBindingObserver,
        TickerProviderStateMixin,
        FlareController {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final Logger log = sl.get<Logger>();

  // Controller for placeholder card animations
  AnimationController _placeholderCardAnimationController;
  Animation<double> _opacityAnimation;
  bool _animationDisposed;

  // Receive card instance
  ReceiveSheet receive;

  // A separate unfortunate instance of this list, is a little unfortunate
  // but seems the only way to handle the animations
  final Map<String, GlobalKey<AnimatedListState>> _listKeyMap = Map();
  final Map<String, ListModel<AccountHistoryResponseItem>> _historyListMap = Map();

  // List of contacts (Store it so we only have to query the DB once for transaction cards)
  List<Contact> _contacts = List();

  // Price conversion state (BTC, NANO, NONE)
  PriceConversion _priceConversion;
  bool _pricesHidden = false;

  bool _isRefreshing = false;

  bool _lockDisabled = false; // whether we should avoid locking the app

  // FCM instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  // Animation for swiping to send
  ActorAnimation _sendSlideAnimation;
  ActorAnimation _sendSlideReleaseAnimation;
  double _fanimationPosition;
  bool releaseAnimation = false;


  int tabIndex = 0;
  List<Widget> listScreens;

  void initialize(FlutterActorArtboard actor) {
    _fanimationPosition = 0.0;
    _sendSlideAnimation = actor.getAnimation("pull");
    _sendSlideReleaseAnimation = actor.getAnimation("release");
  }

  void setViewTransform(Mat2D viewTransform) {}

  bool advance(FlutterActorArtboard artboard, double elapsed) {
    if (releaseAnimation) {
      _sendSlideReleaseAnimation.apply(
          _sendSlideReleaseAnimation.duration * (1 - _fanimationPosition),
          artboard,
          1.0);
    } else {
      _sendSlideAnimation.apply(
          _sendSlideAnimation.duration * _fanimationPosition, artboard, 1.0);
    }
    return true;
  }

  Future<void> _switchToAccount(String account) async {
    List<Account> accounts = await sl.get<DBHelper>().getAccounts();
    for (Account a in accounts) {
      if (a.address == account &&
          a.address != StateContainer.of(context).wallet.address) {
        await sl.get<DBHelper>().changeAccount(a);
        EventTaxiImpl.singleton()
            .fire(AccountChangedEvent(account: a, delayPop: true));
      }
    }
  }

  /// Notification includes which account its for, automatically switch to it if they're entering app from notification
  Future<void> _chooseCorrectAccountFromNotification(dynamic message) async {
    if (message.containsKey("account")) {
      String account = message['account'];
      if (account != null) {
        await _switchToAccount(account);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _registerBus();
    WidgetsBinding.instance.addObserver(this);
    sl.get<SharedPrefsUtil>().getPriceConversion().then((result) {
      _priceConversion = result;
    });
    _addSampleContact();
    _updateContacts();
    // Setup placeholder animation and start
    _animationDisposed = false;
    _placeholderCardAnimationController = new AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _placeholderCardAnimationController
        .addListener(_animationControllerListener);
    _opacityAnimation = new Tween(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(
        parent: _placeholderCardAnimationController,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut,
      ),
    );
    _opacityAnimation.addStatusListener(_animationStatusListener);
    _placeholderCardAnimationController.forward();
    // Register push notifications
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {},
      onLaunch: (Map<String, dynamic> message) async {
        if (message.containsKey('data')) {
          await _chooseCorrectAccountFromNotification(message['data']);
        }
      },
      onResume: (Map<String, dynamic> message) async {
        if (message.containsKey('data')) {
          await _chooseCorrectAccountFromNotification(message['data']);
        }
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      if (settings.alert || settings.badge || settings.sound) {
        sl.get<SharedPrefsUtil>().getNotificationsSet().then((beenSet) {
          if (!beenSet) {
            sl.get<SharedPrefsUtil>().setNotificationsOn(true);
          }
        });
        _firebaseMessaging.getToken().then((String token) {
          if (token != null) {
            EventTaxiImpl.singleton().fire(FcmUpdateEvent(token: token));
          }
        });
      } else {
        sl.get<SharedPrefsUtil>().setNotificationsOn(false).then((_) {
          _firebaseMessaging.getToken().then((String token) {
            EventTaxiImpl.singleton().fire(FcmUpdateEvent(token: token));
          });
        });
      }
    });
    _firebaseMessaging.getToken().then((String token) {
      if (token != null) {
        EventTaxiImpl.singleton().fire(FcmUpdateEvent(token: token));
      }
    });

    listScreens = [
      PortefolioTokensPage(),
      PortefolioNftPage(),
      //BalanceHistory(),
      SettingsSheet(),
      //AppHomePage(),
      //AppHomePage(),
    ];
  }

  void _animationStatusListener(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
        _placeholderCardAnimationController.forward();
        break;
      case AnimationStatus.completed:
        _placeholderCardAnimationController.reverse();
        break;
      default:
        return null;
    }
  }

  void _animationControllerListener() {
    setState(() {});
  }

  void _startAnimation() {
    if (_animationDisposed) {
      _animationDisposed = false;
      _placeholderCardAnimationController
          .addListener(_animationControllerListener);
      _opacityAnimation.addStatusListener(_animationStatusListener);
      _placeholderCardAnimationController.forward();
    }
  }

  void _disposeAnimation() {
    if (!_animationDisposed) {
      _animationDisposed = true;
      _opacityAnimation.removeStatusListener(_animationStatusListener);
      _placeholderCardAnimationController
          .removeListener(_animationControllerListener);
      _placeholderCardAnimationController.stop();
    }
  }

  /// Add donations contact if it hasnt already been added
  Future<void> _addSampleContact() async {
    bool contactAdded = await sl.get<SharedPrefsUtil>().getFirstContactAdded();
    if (!contactAdded) {
      bool addressExists = await sl.get<DBHelper>().contactExistsWithAddress(
          "ban_1ka1ium4pfue3uxtntqsrib8mumxgazsjf58gidh1xeo5te3whsq8z476goo");
      if (addressExists) {
        return;
      }
      bool nameExists =
      await sl.get<DBHelper>().contactExistsWithName("@KaliumDonations");
      if (nameExists) {
        return;
      }
      await sl.get<SharedPrefsUtil>().setFirstContactAdded(true);
      Contact c = Contact(
          name: "@KaliumDonations",
          address:
          "ban_1ka1ium4pfue3uxtntqsrib8mumxgazsjf58gidh1xeo5te3whsq8z476goo");
      await sl.get<DBHelper>().saveContact(c);
    }
  }

  void _updateContacts() {
    sl.get<DBHelper>().getContacts().then((contacts) {
      setState(() {
        _contacts = contacts;
      });
    });
  }

  StreamSubscription<HistoryHomeEvent> _historySub;
  StreamSubscription<ContactModifiedEvent> _contactModifiedSub;
  StreamSubscription<DisableLockTimeoutEvent> _disableLockSub;
  StreamSubscription<AccountChangedEvent> _switchAccountSub;

  void _registerBus() {
    _historySub = EventTaxiImpl.singleton()
        .registerTo<HistoryHomeEvent>()
        .listen((event) {
      diffAndUpdateHistoryList(event.items);
      setState(() {
        _isRefreshing = true;
      });
      if (StateContainer.of(context).initialDeepLink != null) {
        handleDeepLink(StateContainer.of(context).initialDeepLink);
        StateContainer.of(context).initialDeepLink = null;
      }
    });

    _contactModifiedSub = EventTaxiImpl.singleton()
        .registerTo<ContactModifiedEvent>()
        .listen((event) {
      _updateContacts();
    });
    // Hackish event to block auto-lock functionality
    _disableLockSub = EventTaxiImpl.singleton()
        .registerTo<DisableLockTimeoutEvent>()
        .listen((event) {
      if (event.disable) {
        cancelLockEvent();
      }
      _lockDisabled = event.disable;
    });
    // User changed account
    _switchAccountSub = EventTaxiImpl.singleton()
        .registerTo<AccountChangedEvent>()
        .listen((event) {
      setState(() {
        StateContainer.of(context).wallet.loading = true;
        StateContainer.of(context).wallet.historyLoading = true;
        _startAnimation();
        StateContainer.of(context).updateWallet(account: event.account);
      });
      /*paintQrCode(address: event.account.address);*/
      if (event.delayPop) {
        Future.delayed(Duration(milliseconds: 300), () {
          Navigator.of(context).popUntil(RouteUtils.withNameLike("/home"));
        });
      } else if (!event.noPop) {
        Navigator.of(context).popUntil(RouteUtils.withNameLike("/home"));
      }
    });
  }

  @override
  void dispose() {
    _destroyBus();
    WidgetsBinding.instance.removeObserver(this);
    _placeholderCardAnimationController.dispose();
    super.dispose();
  }

  void _destroyBus() {
    if (_historySub != null) {
      _historySub.cancel();
    }
    if (_contactModifiedSub != null) {
      _contactModifiedSub.cancel();
    }
    if (_disableLockSub != null) {
      _disableLockSub.cancel();
    }
    if (_switchAccountSub != null) {
      _switchAccountSub.cancel();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle websocket connection when app is in background
    // terminate it to be eco-friendly
    switch (state) {
      case AppLifecycleState.paused:
        setAppLockEvent();
        StateContainer.of(context).disconnect();
        super.didChangeAppLifecycleState(state);
        break;
      case AppLifecycleState.resumed:
        cancelLockEvent();
        StateContainer.of(context).reconnect();
        if (!StateContainer.of(context).wallet.loading &&
            StateContainer.of(context).initialDeepLink != null) {
          handleDeepLink(StateContainer.of(context).initialDeepLink);
          StateContainer.of(context).initialDeepLink = null;
        }
        super.didChangeAppLifecycleState(state);
        break;
      default:
        super.didChangeAppLifecycleState(state);
        break;
    }
  }

  // To lock and unlock the app
  StreamSubscription<dynamic> lockStreamListener;

  Future<void> setAppLockEvent() async {
    if (await sl.get<SharedPrefsUtil>().getLock() && !_lockDisabled) {
      if (lockStreamListener != null) {
        lockStreamListener.cancel();
      }
      Future<dynamic> delayed = new Future.delayed(
          (await sl.get<SharedPrefsUtil>().getLockTimeout()).getDuration());
      delayed.then((_) {
        return true;
      });
      lockStreamListener = delayed.asStream().listen((_) {
        Navigator.of(context).pushReplacementNamed('/');
      });
    }
  }

  Future<void> cancelLockEvent() async {
    if (lockStreamListener != null) {
      lockStreamListener.cancel();
    }
  }

  // Used to build list items that haven't been removed.
  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    String displayName = smallScreen(context)
        ? _historyListMap[StateContainer.of(context).wallet.address][index]
        .getShorterString()
        : /*_historyListMap[StateContainer.of(context).wallet.address][index]
            .getShortString()*/_historyListMap[StateContainer.of(context).wallet.address][index].amount;
    _contacts.forEach((contact) {
      if (contact.address ==
          _historyListMap[StateContainer.of(context).wallet.address][index]
              .contract_ticker_symbol) {
        displayName = contact.name;
      }
    });
    return _buildTransactionCard(
        _historyListMap[StateContainer.of(context).wallet.address][index],
        animation,
        displayName,
        context);
  }
  ///
  /// Because there's nothing convenient like DiffUtil, some manual logic
  /// to determine the differences between two lists and to add new items.
  ///
  /// Depends on == being overriden in the AccountHistoryResponseItem class
  ///
  /// Required to do it this way for the animation
  ///
  void diffAndUpdateHistoryList(List<AccountHistoryResponseItem> newList) {
    if (newList == null ||
        newList.length == 0 ||
        _historyListMap[StateContainer.of(context).wallet.address] == null)
      return;
    // Get items not in current list, and add them from top-down
    newList.reversed
        .where((item) =>
    !_historyListMap[StateContainer.of(context).wallet.address]
        .items
        .contains(item))
        .forEach((historyItem) {
      setState(() {
        _historyListMap[StateContainer.of(context).wallet.address]
            .insertAtTop(historyItem);
      });
    });
    // Re-subscribe if missing data
    if (StateContainer.of(context).wallet.loading) {
      StateContainer.of(context).requestSubscribe();
    }
  }

  void handleDeepLink(link) {
    Address address = Address(link);
    if (!address.isValid()) {
      return;
    }
    String amount;
    String contactName;
    if (address.amount != null) {
      // Require minimum 1 BANOSHI to send
      if (BigInt.parse(address.amount) >= BigInt.from(10).pow(27)) {
        amount = address.amount;
      }
    }
    // See if a contact
    sl.get<DBHelper>().getContactWithAddress(address.address).then((contact) {
      if (contact != null) {
        contactName = contact.name;
      }
      // Remove any other screens from stack
      Navigator.of(context).popUntil(RouteUtils.withNameLike('/home'));
      if (amount != null) {
        // Go to send confirm with amount
        Sheets.showAppHeightNineSheet(
            context: context,
            widget: SendConfirmSheet(
                amountRaw: amount,
                destination: address.address,
                contactName: contactName));
      } else {
        // Go to send with address
        Sheets.showAppHeightNineSheet(
            context: context,
            widget: SendSheet(
                localCurrency: StateContainer.of(context).curCurrency,
                contact: contact,
                address: address.address));
      }
    });
  }

  void paintQrCode({String address}) {
    QrPainter painter = QrPainter(
      data:
      address == null ? StateContainer.of(context).wallet.address : address,
      version: 6,
      errorCorrectionLevel: QrErrorCorrectLevel.Q,
    );
    painter.toImageData(MediaQuery.of(context).size.width).then((byteData) {
      setState(() {
        receive = ReceiveSheet(
          qrWidget: Container(
              width: MediaQuery.of(context).size.width / 2.675,
              child: Image.memory(byteData.buffer.asUint8List())),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Create QR ahead of time because it improves performance this way
    /*if (receive == null && StateContainer.of(context).wallet != null) {
      paintQrCode();
    }*/
    return Scaffold(
        drawerEdgeDragWidth: 200,
        resizeToAvoidBottomInset: false,
        key: _scaffoldKey,
        backgroundColor: StateContainer.of(context).curTheme.backgroundDark,
        bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
          backgroundColor: StateContainer.of(context).curTheme.backgroundDark,
            currentIndex: tabIndex,
            selectedItemColor:  StateContainer.of(context).curTheme.primary,
            onTap: (int index) {
              setState(() {
                tabIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Tokens',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fit_screen),
                label: 'NFTs',
              ),
              /*BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart),
                label: 'Stats',
              ),*/
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ]),
        body: IndexedStack(index: tabIndex, children: listScreens)
    );
  }
  // Transaction Card/List Item
  Widget _buildTransactionCard(AccountHistoryResponseItem item,
      Animation<double> animation, String displayName, BuildContext context) {
    String text;
    IconData icon;
    Color iconColor;
    if (item.type == BlockTypes.SEND) {
      text = AppLocalization.of(context).sent;
      icon = AppIcons.sent;
      iconColor = StateContainer.of(context).curTheme.text60;
    } else {
      text = AppLocalization.of(context).received;
      icon = AppIcons.received;
      iconColor = StateContainer.of(context).curTheme.primary60;
    }
    return Slidable(
      delegate: SlidableScrollDelegate(),
      actionExtentRatio: 0.35,
      movementDuration: Duration(milliseconds: 300),
      enabled: StateContainer.of(context).wallet != null &&
          StateContainer.of(context).wallet.accountBalance > 0,
      onTriggered: (preempt) {
        if (preempt) {
          setState(() {
            releaseAnimation = true;
          });
        } else {
          // See if a contact
          sl
              .get<DBHelper>()
              .getContactWithAddress(item.contract_ticker_symbol)
              .then((contact) {
            // Go to send with address
            Sheets.showAppHeightNineSheet(
                context: context,
                widget: SendSheet(
                  localCurrency: StateContainer.of(context).curCurrency,
                  contact: contact,
                  address: item.contract_ticker_symbol,
                  quickSendAmount: item.amount,
                ));
          });
        }
      },
      onAnimationChanged: (animation) {
        if (animation != null) {
          _fanimationPosition = animation.value;
          if (animation.value == 0.0 && releaseAnimation) {
            setState(() {
              releaseAnimation = false;
            });
          }
        }
      },
      secondaryActions: <Widget>[
        SlideAction(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),
            margin: EdgeInsetsDirectional.only(
                end: MediaQuery.of(context).size.width * 0.15,
                top: 4,
                bottom: 4),
            child: Container(
              alignment: AlignmentDirectional(-0.5, 0),
              constraints: BoxConstraints.expand(),
              child: FlareActor("assets/pulltosend_animation.flr",
                  animation: "pull",
                  fit: BoxFit.contain,
                  controller: this,
                  color: StateContainer.of(context).curTheme.primary),
            ),
          ),
        ),
      ],
      child: _SizeTransitionNoClip(
        sizeFactor: animation,
        child: Container(
          margin: EdgeInsetsDirectional.fromSTEB(4.0, 4.0, 4.0, 4.0),
          decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 0.25, color: StateContainer.of(context).curTheme.background),
              )
            //boxShadow: [StateContainer.of(context).curTheme.boxShadow],
          ),
          child: TextButton(
            /*highlightColor: StateContainer.of(context).curTheme.text15,
            splashColor: StateContainer.of(context).curTheme.text15,
            color: StateContainer.of(context).curTheme.backgroundWhite,
            padding: EdgeInsets.all(0.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),*/
            onPressed: () {
              Sheets.showAppHeightEightSheet(
                  context: context,
                  widget: TransactionDetailsSheet(
                      hash: item.contract_name,
                      address: item.contract_ticker_symbol,
                      displayName: displayName),
                  animationDurationMs: 175);
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 0, horizontal: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                            margin: EdgeInsetsDirectional.only(end: 8.0),
                            child: FadeInImage.assetNetwork(placeholder: 'assets/empty-token.png', image: item.logo, width: 28,height: 28)
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width / 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              RichText(
                                textAlign: TextAlign.start,
                                text: TextSpan(
                                  text: '',
                                  children: [
                                    TextSpan(
                                      text: item.contract_ticker_symbol,
                                      style:
                                      AppStyles.textStyleTransactionType(context),
                                    ),
                                    TextSpan(
                                      text: " - ",
                                      style: AppStyles.textStyleTransactionAmount(
                                          context),
                                    ),
                                    TextSpan(
                                      text: item.contract_name,
                                      style: AppStyles.textStyleTransactionAmount(
                                          context),
                                    ),
                                  ],
                                ),
                              ),

                              RichText(
                                textAlign: TextAlign.start,
                                text: TextSpan(
                                  text: '',
                                  children: [
                                    TextSpan(
                                      text: item.getFormattedAmount(),
                                      style:
                                      AppStyles.textStyleTransactionAmount(
                                          context),
                                    ),
                                    TextSpan(
                                      text: " | ",
                                      style: AppStyles.textStyleTransactionAmount(
                                          context),
                                    ),
                                    TextSpan(
                                      text: StateContainer.of(context).wallet.getLocalCurrencyPriceAmount(
                                          locale: StateContainer.of(context).currencyLocale, amount: item.quote_rate),
                                      style: AppStyles.textStyleTransactionAmount(
                                          context),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 4,
                      child: Text(
                        StateContainer.of(context).wallet.getLocalCurrencyPriceAmount(
                            locale: StateContainer.of(context).currencyLocale, amount: item.quote),
                        textAlign: TextAlign.end,
                        style: AppStyles.textStyleTransactionAddress(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  } //Transaction Card End

  // Dummy Transaction Card
  Widget _buildDummyTransactionCard(
      String tokens, String tokens_short, String amount, BuildContext context) {
    String text;
    IconData icon;
    Color iconColor;
    return Container(
      margin: EdgeInsetsDirectional.fromSTEB(14.0, 4.0, 14.0, 4.0),
      decoration: BoxDecoration(
        color: StateContainer.of(context).curTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [StateContainer.of(context).curTheme.boxShadow],
      ),
      child: FlatButton(
        onPressed: () {
          return null;
        },
        highlightColor: StateContainer.of(context).curTheme.text15,
        splashColor: StateContainer.of(context).curTheme.text15,
        color: StateContainer.of(context).curTheme.backgroundWhite,
        padding: EdgeInsets.all(0.0),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: Center(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                        margin: EdgeInsetsDirectional.only(end: 16.0),
                        child: new Image(
                            image :  AssetImage("assets/"+tokens_short+".png"), width: 28,
                            height: 28,
                            color: null,
                            alignment: Alignment.center)),
                    Container(
                      width: MediaQuery.of(context).size.width / 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            tokens,
                            textAlign: TextAlign.start,
                            style: AppStyles.textStyleTransactionType(context),
                          ),
                          RichText(
                            textAlign: TextAlign.start,
                            text: TextSpan(
                              text: '',
                              children: [
                                TextSpan(
                                  text: StateContainer.of(context).wallet.getLocalCurrencyPrice(
                                      locale: StateContainer.of(context).currencyLocale),
                                  style: AppStyles.textStyleTransactionAmount(
                                      context),
                                ),
                                TextSpan(
                                  text: "  +10.00%",
                                  style: AppStyles.textStyleTransactionUnit(
                                      context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  width: MediaQuery.of(context).size.width / 2.4,
                  child: Text(
                    amount+" "+tokens_short,
                    textAlign: TextAlign.end,
                    style: AppStyles.textStyleTransactionAddress(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  } //Dummy Transaction Card End

  // Welcome Card
  TextSpan _getExampleHeaderSpan(BuildContext context) {
    String workingStr;
    if (StateContainer.of(context).selectedAccount == null ||
        StateContainer.of(context).selectedAccount.index == 0) {
      workingStr = AppLocalization.of(context).exampleCardIntroKal;
    } else {
      workingStr = AppLocalization.of(context).newAccountIntroKal;
    }
    if (!workingStr.contains("BANANO")) {
      return TextSpan(
        text: workingStr,
        style: AppStyles.textStyleTransactionWelcome(context),
      );
    }
    // Colorize BANANO
    List<String> splitStr = workingStr.split("BANANO");
    if (splitStr.length != 2) {
      return TextSpan(
        text: workingStr,
        style: AppStyles.textStyleTransactionWelcome(context),
      );
    }
    return TextSpan(
      text: '',
      children: [
        TextSpan(
          text: splitStr[0],
          style: AppStyles.textStyleTransactionWelcome(context),
        ),
        TextSpan(
          text: "BANANO",
          style: AppStyles.textStyleTransactionWelcomePrimary(context),
        ),
        TextSpan(
          text: splitStr[1],
          style: AppStyles.textStyleTransactionWelcome(context),
        ),
      ],
    );
  }

  Widget _buildWelcomeTransactionCard(BuildContext context) {
    return Container(
      margin: EdgeInsetsDirectional.fromSTEB(14.0, 4.0, 14.0, 4.0),
      decoration: BoxDecoration(
        color: StateContainer.of(context).curTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [StateContainer.of(context).curTheme.boxShadow],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              width: 7.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    bottomLeft: Radius.circular(10.0)),
                color: StateContainer.of(context).curTheme.textRed,
                boxShadow: [StateContainer.of(context).curTheme.boxShadow],
              ),
            ),
            /*Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 14.0, horizontal: 15.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: _getExampleHeaderSpan(context),
                ),
              ),
            ),*/
            Container(
              width: 7.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10.0),
                    bottomRight: Radius.circular(10.0)),
                color: StateContainer.of(context).curTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  } // Welcome Card End

  // Loading Transaction Card
  Widget _buildLoadingTransactionCard(
      String type, String amount, String address, BuildContext context) {
    String text;
    IconData icon;
    Color iconColor;
    if (type == "Sent") {
      text = "Senttt";
      icon = AppIcons.dotfilled;
      iconColor = StateContainer.of(context).curTheme.text20;
    } else {
      text = "Receiveddd";
      icon = AppIcons.dotfilled;
      iconColor = StateContainer.of(context).curTheme.primary20;
    }
    return Container(
      margin: EdgeInsetsDirectional.fromSTEB(14.0, 4.0, 14.0, 4.0),
      decoration: BoxDecoration(
        color: StateContainer.of(context).curTheme.backgroundDark,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [StateContainer.of(context).curTheme.boxShadow],
      ),
      child: FlatButton(
        onPressed: () {
          return null;
        },
        highlightColor: StateContainer.of(context).curTheme.text15,
        splashColor: StateContainer.of(context).curTheme.text15,
        color: StateContainer.of(context).curTheme.backgroundRed,
        padding: EdgeInsets.all(0.0),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: Center(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    // Transaction Icon
                    Opacity(
                      opacity: _opacityAnimation.value,
                      child: Container(
                          margin: EdgeInsetsDirectional.only(end: 16.0),
                          child: Icon(icon, color: iconColor, size: 20)),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Transaction Type Text
                          Container(
                            child: Stack(
                              alignment: AlignmentDirectional(-1, 0),
                              children: <Widget>[
                                Text(
                                  text,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontFamily: "NunitoSans",
                                    fontSize: AppFontSizes.small,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.transparent,
                                  ),
                                ),
                                Opacity(
                                  opacity: _opacityAnimation.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: StateContainer.of(context)
                                          .curTheme
                                          .text45,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      text,
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontFamily: "NunitoSans",
                                        fontSize: AppFontSizes.small - 4,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Amount Text
                          Container(
                            child: Stack(
                              alignment: AlignmentDirectional(-1, 0),
                              children: <Widget>[
                                Text(
                                  amount,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      fontFamily: "NunitoSans",
                                      color: Colors.transparent,
                                      fontSize: AppFontSizes.smallest,
                                      fontWeight: FontWeight.w600),
                                ),
                                Opacity(
                                  opacity: _opacityAnimation.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: StateContainer.of(context)
                                          .curTheme
                                          .primary20,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      amount,
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          fontFamily: "NunitoSans",
                                          color: Colors.transparent,
                                          fontSize: AppFontSizes.smallest - 3,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Address Text
                Container(
                  width: MediaQuery.of(context).size.width / 2.4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        child: Stack(
                          alignment: AlignmentDirectional(1, 0),
                          children: <Widget>[
                            Text(
                              address,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: AppFontSizes.smallest,
                                fontFamily: 'OverpassMono',
                                fontWeight: FontWeight.w100,
                                color: Colors.transparent,
                              ),
                            ),
                            Opacity(
                              opacity: _opacityAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: StateContainer.of(context)
                                      .curTheme
                                      .text20,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  address,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontSize: AppFontSizes.smallest - 3,
                                    fontFamily: 'OverpassMono',
                                    fontWeight: FontWeight.w100,
                                    color: Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  } // Loading Transaction Card End

  //Main Card
  Widget _buildMainCard(BuildContext context, _scaffoldKey) {
    return Container(
      decoration: BoxDecoration(
        color: StateContainer.of(context).curTheme.backgroundDark,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [StateContainer.of(context).curTheme.boxShadow],
      ),
      margin: EdgeInsets.only(
          left: 14.0,
          right: 14.0,
          top: MediaQuery.of(context).size.height * 0.005),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            width: 90.0,
            height: 120,
            alignment: AlignmentDirectional(-1, -1),
            child: Container(
              margin: EdgeInsetsDirectional.only(top: 5, start: 5),
              height: 50,
              width: 50,
              child: FlatButton(
                  highlightColor: StateContainer.of(context).curTheme.text15,
                  splashColor: StateContainer.of(context).curTheme.text15,
                  onPressed: () {
                    _scaffoldKey.currentState.openDrawer();
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0)),
                  padding: EdgeInsets.all(0.0),
                  child: Icon(AppIcons.settings,
                      color: StateContainer.of(context).curTheme.text,
                      size: 24)),
            ),
          ),
          _getBalanceWidget(context),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 74,
            height: 74,
            margin: EdgeInsets.only(right: 2),
            alignment: Alignment(0, 0),
            child: Stack(
              children: <Widget>[
                Center(
                  child: Container(
                    // natricon
                    child: Hero(
                      tag: "avatar",
                      child: SvgPicture.network(
                        UIUtil.getMonkeyURL(
                            StateContainer.of(context).selectedAccount.address),
                        key: Key(UIUtil.getMonkeyURL(StateContainer.of(context)
                            .selectedAccount
                            .address)),
                        placeholderBuilder: (BuildContext context) => Container(
                          child: FlareActor(
                            "assets/monkey_placeholder_animation.flr",
                            animation: "main",
                            fit: BoxFit.contain,
                            color: StateContainer.of(context).curTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    color: Colors.transparent,
                    child: FlatButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/avatar_page');
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100.0)),
                      highlightColor:
                      StateContainer.of(context).curTheme.text15,
                      splashColor: StateContainer.of(context).curTheme.text15,
                      padding: EdgeInsets.all(0.0),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  } //Main Card

  // Get balance display
  Widget _getBalanceWidget(BuildContext context) {
    if (StateContainer.of(context).wallet == null ||
        StateContainer.of(context).wallet.loading) {
      // Placeholder for balance text
      return Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              child: Stack(
                alignment: AlignmentDirectional(0, 0),
                children: <Widget>[
                  Text(
                    "1234567",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: "NunitoSans",
                        fontSize: AppFontSizes.small,
                        fontWeight: FontWeight.w600,
                        color: Colors.transparent),
                  ),
                  Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: StateContainer.of(context).curTheme.text20,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        "1234567",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: "NunitoSans",
                            fontSize: AppFontSizes.small - 3,
                            fontWeight: FontWeight.w600,
                            color: Colors.transparent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 225),
              child: Stack(
                alignment: AlignmentDirectional(0, 0),
                children: <Widget>[
                  AutoSizeText(
                    "1234567",
                    style: TextStyle(
                        fontFamily: "NunitoSans",
                        fontSize: AppFontSizes.largestc,
                        fontWeight: FontWeight.w900,
                        color: Colors.transparent),
                    maxLines: 1,
                    stepGranularity: 0.1,
                    minFontSize: 1,
                  ),
                  Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: StateContainer.of(context).curTheme.primary60,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: AutoSizeText(
                        "1234567",
                        style: TextStyle(
                            fontFamily: "NunitoSans",
                            fontSize: AppFontSizes.largestc - 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.transparent),
                        maxLines: 1,
                        stepGranularity: 0.1,
                        minFontSize: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              child: Stack(
                alignment: AlignmentDirectional(0, 0),
                children: <Widget>[
                  Text(
                    "1234567",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: "NunitoSans",
                        fontSize: AppFontSizes.small,
                        fontWeight: FontWeight.w600,
                        color: Colors.transparent),
                  ),
                  Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: StateContainer.of(context).curTheme.text20,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        "1234567",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: "NunitoSans",
                            fontSize: AppFontSizes.small - 3,
                            fontWeight: FontWeight.w600,
                            color: Colors.transparent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        if (_priceConversion == PriceConversion.BTC) {
          // Cycle to NANO price
          setState(() {
            _pricesHidden = false;
            _priceConversion = PriceConversion.NANO;
          });
          sl.get<SharedPrefsUtil>().setPriceConversion(PriceConversion.NANO);
        } else if (_priceConversion == PriceConversion.NANO) {
          // Hide prices
          setState(() {
            _pricesHidden = true;
            _priceConversion = PriceConversion.NONE;
          });
          sl.get<SharedPrefsUtil>().setPriceConversion(PriceConversion.NONE);
        } else {
          // Cycle to BTC price
          setState(() {
            _pricesHidden = false;
            _priceConversion = PriceConversion.BTC;
          });
          sl.get<SharedPrefsUtil>().setPriceConversion(PriceConversion.BTC);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
                StateContainer.of(context).wallet.getLocalCurrencyPrice(
                    locale: StateContainer.of(context).currencyLocale),
                textAlign: TextAlign.center,
                style: _pricesHidden
                    ? AppStyles.textStyleCurrencyAltHidden(context)
                    : AppStyles.textStyleCurrencyAlt(context)),
            Container(
              margin: EdgeInsetsDirectional.only(end: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 225),
                    child: AutoSizeText.rich(
                      TextSpan(
                        children: [
                          // Currency Icon
                          TextSpan(
                            text: "\u{e80a}",
                            style: TextStyle(
                              fontFamily: 'AppIcons',
                              color:
                              StateContainer.of(context).curTheme.primary,
                              fontSize: 23.0,
                            ),
                          ),
                          // Main balance text
                          TextSpan(
                            text: StateContainer.of(context)
                                .wallet
                                .getAccountBalanceDisplay(),
                            style: AppStyles.textStyleCurrency(context),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      style: TextStyle(fontSize: 28.0),
                      stepGranularity: 0.1,
                      minFontSize: 1,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                Icon(
                    _priceConversion == PriceConversion.BTC
                        ? AppIcons.btc
                        : AppIcons.nanocurrency,
                    color: _priceConversion == PriceConversion.NONE
                        ? Colors.transparent
                        : StateContainer.of(context).curTheme.text60,
                    size: 14),
                Text(
                    _priceConversion == PriceConversion.BTC
                        ? StateContainer.of(context).wallet.btcPrice
                        : StateContainer.of(context).wallet.nanoPrice,
                    textAlign: TextAlign.center,
                    style: _pricesHidden
                        ? AppStyles.textStyleCurrencyAltHidden(context)
                        : AppStyles.textStyleCurrencyAlt(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionDetailsSheet extends StatefulWidget {
  final String hash;
  final String address;
  final String displayName;

  TransactionDetailsSheet({this.hash, this.address, this.displayName})
      : super();

  _TransactionDetailsSheetState createState() =>
      _TransactionDetailsSheetState();
}

class _TransactionDetailsSheetState extends State<TransactionDetailsSheet> {
  // Current state references
  bool _addressCopied = false;
  // Timer reference so we can cancel repeated events
  Timer _addressCopiedTimer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.035,
      ),
      child: Container(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Column(
              children: <Widget>[
                // A stack for Copy Address and Add Contact buttons
                Stack(
                  children: <Widget>[
                    // A row for Copy Address Button
                    Row(
                      children: <Widget>[
                        AppButton.buildAppButton(
                            context,
                            // Share Address Button
                            _addressCopied
                                ? AppButtonType.SUCCESS
                                : AppButtonType.PRIMARY,
                            _addressCopied
                                ? AppLocalization.of(context).addressCopied
                                : AppLocalization.of(context).copyAddress,
                            Dimens.BUTTON_TOP_EXCEPTION_DIMENS, onPressed: () {
                          Clipboard.setData(
                              new ClipboardData(text: widget.address));
                          if (mounted) {
                            setState(() {
                              // Set copied style
                              _addressCopied = true;
                            });
                          }
                          if (_addressCopiedTimer != null) {
                            _addressCopiedTimer.cancel();
                          }
                          _addressCopiedTimer =
                          new Timer(const Duration(milliseconds: 800), () {
                            if (mounted) {
                              setState(() {
                                _addressCopied = false;
                              });
                            }
                          });
                        }),
                      ],
                    ),
                    // A row for Add Contact Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          margin: EdgeInsetsDirectional.only(
                              top: Dimens.BUTTON_TOP_EXCEPTION_DIMENS[1],
                              end: Dimens.BUTTON_TOP_EXCEPTION_DIMENS[2]),
                          child: Container(
                            height: 55,
                            width: 55,
                            // Add Contact Button
                            child: !widget.displayName.startsWith("@")
                                ? FlatButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Sheets.showAppHeightNineSheet(
                                    context: context,
                                    widget: AddContactSheet(
                                        address: widget.address));
                              },
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(100.0)),
                              padding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 10),
                              child: Icon(AppIcons.addcontact,
                                  size: 35,
                                  color: _addressCopied
                                      ? StateContainer.of(context)
                                      .curTheme
                                      .successDark
                                      : StateContainer.of(context)
                                      .curTheme
                                      .backgroundDark),
                            )
                                : SizedBox(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // A row for View Details button
                Row(
                  children: <Widget>[
                    AppButton.buildAppButton(
                        context,
                        AppButtonType.PRIMARY_OUTLINE,
                        AppLocalization.of(context).viewDetails,
                        Dimens.BUTTON_BOTTOM_DIMENS, onPressed: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (BuildContext context) {
                            return sl
                                .get<UIUtil>()
                                .showBlockExplorerWebview(context, widget.hash);
                          }));
                    }),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// This is used so that the elevation of the container is kept and the
/// drop shadow is not clipped.
///
class _SizeTransitionNoClip extends AnimatedWidget {
  final Widget child;

  const _SizeTransitionNoClip(
      {@required Animation<double> sizeFactor, this.child})
      : super(listenable: sizeFactor);

  @override
  Widget build(BuildContext context) {
    return new Align(
      alignment: const AlignmentDirectional(-1.0, -1.0),
      widthFactor: null,
      heightFactor: (this.listenable as Animation<double>).value,
      child: child,
    );
  }
}

class TabA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView.separated(
        separatorBuilder: (context, child) => Divider(
          height: 1,
        ),
        padding: EdgeInsets.all(0.0),
        itemCount: 30,
        itemBuilder: (context, i) {
          return Container(
            height: 100,
            width: double.infinity,
            color: Colors.red,
          );
        },
      ),
    );
  }
}