import 'package:flutter/material.dart';

class AddWalletBtn extends StatelessWidget {
  const AddWalletBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.add,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  }
}
