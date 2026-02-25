#!/bin/bash

# --- VentExpensePro Mock Data Seeding Script ---
# This script forcefully overwrites the app's SQLite database
# with a fresh set of realistic ledger mock data mapped to the current month and year.
# 
# Usage: ./seed_mock_data.sh

echo "=> Generating mock_data.sql with dynamically accurate timestamps..."
cat << 'EOF' > generate_mock.dart
import 'dart:io';

void main() {
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  int year = DateTime.now().year;
  int month = DateTime.now().month;
  
  int time(int day) => DateTime(year, month, day, 12, 0).millisecondsSinceEpoch;

  final sql = """
-- Clear existing data
DELETE FROM transactions;
DELETE FROM accounts;

-- Accounts
INSERT INTO accounts (id, name, type, balance, currency, is_archived, created_at) VALUES 
('acc_bca_1', 'BCA Payroll', 0, 15000000, 'IDR', 0, $nowMs), 
('acc_mandiri_1', 'Mandiri Savings', 0, 8000000, 'IDR', 0, $nowMs), 
('acc_cash_1', 'Main Wallet', 1, 500000, 'IDR', 0, $nowMs), 
('acc_cash_2', 'Emergency Stash', 1, 1500000, 'IDR', 0, $nowMs), 
('acc_credit_1', 'Tokopedia Card', 2, 2500000, 'IDR', 0, $nowMs),
('acc_credit_2', 'Traveloka PayLater', 2, 800000, 'IDR', 0, $nowMs);

-- Transactions
INSERT INTO transactions (id, amount, type, category_id, account_id, to_account_id, note, is_settlement, date_time) VALUES
('txn_001', 12000000, 0, 'other', 'acc_bca_1', NULL, 'Monthly Salary', 0, ${time(1)}),
('txn_002', 45000, 1, 'food', 'acc_cash_1', NULL, 'Starbucks', 0, ${time(2)}),
('txn_003', 350000, 1, 'shopping', 'acc_bca_1', NULL, 'Monthly Groceries at Superindo', 0, ${time(3)}),
('txn_004', 120000, 1, 'entertainment', 'acc_credit_1', NULL, 'Cinema Weekend', 0, ${time(4)}),
('txn_005', 450000, 1, 'bills', 'acc_mandiri_1', NULL, 'Electricity and Water PLN/PDAM', 0, ${time(5)}),
('txn_006', 250000, 1, 'health', 'acc_credit_1', NULL, 'Fitness First Monthly', 0, ${time(6)}),
('txn_007', 150000, 1, 'education', 'acc_bca_1', NULL, 'Programming Books', 0, ${time(7)}),
('txn_008', 150000, 1, 'transport', 'acc_cash_2', NULL, 'Fuel Pertamax', 0, ${time(8)}),
('txn_009', 85000, 1, 'health', 'acc_cash_1', NULL, 'Vitamins & Medicine', 0, ${time(9)}),
('txn_010', 320000, 1, 'bills', 'acc_mandiri_1', NULL, 'Home Internet Provider', 0, ${time(10)}),
('txn_011', 180000, 1, 'food', 'acc_bca_1', NULL, 'Sushi Tei', 0, ${time(11)}),
('txn_012', 250000, 1, 'food', 'acc_credit_2', NULL, 'Dinner with friends', 0, ${time(12)}),
('txn_013', 450000, 1, 'education', 'acc_credit_1', NULL, 'Udemy Course Purchase', 0, ${time(13)}),
('txn_014', 500000, 1, 'other', 'acc_bca_1', NULL, 'Flowers and Chocolates', 0, ${time(14)}),
('txn_015', 850000, 1, 'shopping', 'acc_credit_2', NULL, 'New shoes', 0, ${time(15)}),
('txn_016', 200000, 2, 'other', 'acc_bca_1', 'acc_cash_1', 'GoPay Topup', 0, ${time(16)}),
('txn_017', 45000, 1, 'transport', 'acc_cash_1', NULL, 'GoRide to Office', 0, ${time(17)}),
('txn_018', 500000, 2, 'other', 'acc_mandiri_1', 'acc_cash_2', 'ATM Withdrawal', 0, ${time(18)}),
('txn_019', 1500000, 1, 'entertainment', 'acc_credit_1', NULL, 'Coldplay Presale', 0, ${time(19)}),
('txn_020', 45000, 1, 'food', 'acc_cash_2', NULL, 'Coffee and snacks', 0, ${time(20)}),
('txn_021', 120000, 1, 'food', 'acc_cash_1', NULL, 'Late night dinner delivery', 0, ${time(21)}),
('txn_022', 450000, 1, 'shopping', 'acc_mandiri_1', NULL, 'Uniqlo Shirts', 0, ${time(22)}),
('txn_023', 150000, 1, 'bills', 'acc_bca_1', NULL, 'Postpaid Mobile', 0, ${time(23)}),
('txn_024', 169000, 1, 'entertainment', 'acc_credit_2', NULL, 'Netflix Premium', 0, ${time(24)}),
('txn_025', 2000000, 0, 'other', 'acc_mandiri_1', NULL, 'Project Bonus', 0, ${time(25)}),
('txn_026', 1500000, 2, 'settlement', 'acc_bca_1', 'acc_credit_1', 'Pay Tokopedia CC Bill', 1, ${time(26)});
""";

  File('mock_data.sql').writeAsStringSync(sql);
}
EOF

# Run Dart script to construct the exact mock SQL file for this moment in time
dart generate_mock.dart
rm generate_mock.dart

echo "=> Force stopping VentExpensePro to clear SQL WAL memory locks..."
adb shell am force-stop com.digiventure.ventexpensepro

echo "=> Pulling the latest local database natively from the Android emulator..."
adb shell "run-as com.digiventure.ventexpensepro cat databases/vent_expense.db > /data/local/tmp/vent_expense.db"
adb pull /data/local/tmp/vent_expense.db temp_db.sqlite

echo "=> Injecting dynamic mock data into SQLite via CLI..."
sqlite3 temp_db.sqlite < mock_data.sql

echo "=> Pushing populated database back to the emulator architecture..."
adb push temp_db.sqlite /data/local/tmp/vent_expense.db
adb shell "run-as com.digiventure.ventexpensepro cp /data/local/tmp/vent_expense.db databases/vent_expense.db"

echo "=> Cleaning up temporary files..."
rm temp_db.sqlite

echo ""
echo "✅ Seeding Complete! You can now launch VentExpensePro natively on your emulator."
echo "   (Or press 'r' / hot restart in your fluttering running console)"
