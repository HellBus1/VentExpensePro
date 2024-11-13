import 'package:flutter/material.dart';
import 'package:vent_expense_pro/commons/util/hex_color.dart';
import 'package:vent_expense_pro/models/wallet_model.dart';

class WalletBtn extends StatelessWidget {
  final WalletModel wallet;

  const WalletBtn({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    final baseColor = HexColor(wallet.icon?.iconColor ?? "");
    final backgroundColor = baseColor.withOpacity(0.8);
    final iconColor = baseColor.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 4, vertical: 2),
              child: Icon(
                IconData(wallet.icon?.iconCode ?? 0,
                    fontFamily: 'MaterialIcons'),
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            wallet.name,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            wallet.balance.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
