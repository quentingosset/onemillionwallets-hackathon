import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:kalium_wallet_flutter/network/model/response/account_history_response_item.dart';
import 'package:kalium_wallet_flutter/ui/portefolio_nfts_page.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';

import '../../appstate_container.dart';
import '../../service_locator.dart';
import '../../styles.dart';

class NftDetail extends StatelessWidget {
  final NftChildren nft;
  final int id;

  const NftDetail({Key key, this.nft, this.id}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: StateContainer.of(context).curTheme.background,
        body: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                          ),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Hero(
                        tag: '$id',
                        child: Image.network(
                          nft.nft.external_data.image,
                          width: MediaQuery.of(context).size.width * .7,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: StateContainer.of(context).curTheme.backgroundDark,
                  /*borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25.0),
                    topRight: Radius.circular(25.0),
                  ),*/
                ),
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          nft.nft.external_data.name?? "NO-NAME",
                            style: TextStyle(
                              color: StateContainer.of(context).curTheme.backgroundWhite,
                              fontSize: AppFontSizes.larger,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'NunitoSans',
                            )
                        ),
                      ],
                    ),
                    Text(
                      nft.nft.external_data.description?? "NO-DESCRIPTION",
                        style: TextStyle(
                          color: StateContainer.of(context).curTheme.backgroundWhite,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'NunitoSans',
                        )
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        //Counter(),
                        Text(
                          "Category : "+(nft.contract_name ?? "NO-CATEGORY"),
                            style: TextStyle(
                              color: StateContainer.of(context).curTheme.backgroundWhite,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'NunitoSans',
                            )
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      child: RaisedButton(
                        child: Text(
                          "Voir plus",
                            style: TextStyle(
                              color: StateContainer.of(context).curTheme.backgroundWhite,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'NunitoSans',
                            )
                        ),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (BuildContext context) {
                                return sl.get<UIUtil>().showNftWebview(
                                    context, nft.nft.external_data.external_url);
                              }));
                        },
                        color: StateContainer.of(context).curTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

}