import 'package:flutter/material.dart';
import 'package:vent_expense_pro/models/wallet_model.dart';

class WalletBtn extends StatelessWidget {
  final WalletModel wallet;

  const WalletBtn({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    print(Icons.ac_unit.codePoint);
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconData(wallet.icon?.iconCode ?? 0, fontFamily: 'MaterialIcons'),
            color: Colors.white,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            wallet.name,
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            wallet.balance.toString(),
            style: TextStyle(color: Colors.white, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
