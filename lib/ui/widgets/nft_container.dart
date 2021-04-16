import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:kalium_wallet_flutter/network/model/response/account_history_response_item.dart';
import 'package:kalium_wallet_flutter/ui/widgets/nft_detail.dart';

import '../../appstate_container.dart';
import '../portefolio_nfts_page.dart';
import 'auto_resize_text.dart';

class NftContainer extends StatelessWidget {
  final int id;
  final NftChildren item;

  const NftContainer({Key key, this.id, this.item}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NftDetail(nft: item, id: this.id)),
      ),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Hero(
                tag: '$id',
                child: Image.network(
                  item.nft.external_data.image,
                  fit: BoxFit.cover,
                  // width: double.infinity,
                ),
              ),
            ),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(15.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: StateContainer.of(context).curTheme.backgroundDark,
                /*borderRadius: BorderRadius.all(
                  Radius.circular(9.0),
                ),*/
              ),
              child: AutoSizeText(
                item.nft.external_data.name?? item.nft.token_id,
                style: TextStyle(
                  color:
                  StateContainer.of(context).curTheme.backgroundWhite,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'NunitoSans',
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}