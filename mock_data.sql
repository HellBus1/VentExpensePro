-- Clear existing data
DELETE FROM transactions;
DELETE FROM accounts;

-- Accounts
INSERT INTO accounts (id, name, type, balance, currency, is_archived, created_at) VALUES 
('acc_bca_1', 'BCA Payroll', 0, 15000000, 'IDR', 0, 1772217934680), 
('acc_mandiri_1', 'Mandiri Savings', 0, 8000000, 'IDR', 0, 1772217934680), 
('acc_cash_1', 'Main Wallet', 1, 500000, 'IDR', 0, 1772217934680), 
('acc_cash_2', 'Emergency Stash', 1, 1500000, 'IDR', 0, 1772217934680), 
('acc_credit_1', 'Tokopedia Card', 2, 2500000, 'IDR', 0, 1772217934680),
('acc_credit_2', 'Traveloka PayLater', 2, 800000, 'IDR', 0, 1772217934680);

-- Transactions
-- Categories available: 'food', 'transport', 'bills', 'shopping', 'entertainment', 'health', 'education', 'other', 'settlement'
INSERT INTO transactions (id, amount, type, category_id, account_id, to_account_id, note, is_settlement, date_time) VALUES
('txn_001', 12000000, 1, 'other', 'acc_bca_1', NULL, 'Monthly Salary', 0, 1769922000000),
('txn_002', 20000, 0, 'transport', 'acc_cash_1', NULL, 'Bus Ticket', 0, 1770008400000),
('txn_003', 650000, 0, 'shopping', 'acc_credit_1', NULL, 'Grocery at Superindo', 0, 1770094800000),
('txn_004', 35000, 0, 'food', 'acc_cash_2', NULL, 'Nasi Goreng', 0, 1770094800000),
('txn_005', 450000, 0, 'bills', 'acc_mandiri_1', NULL, 'Electricity Token', 0, 1770267600000),
('txn_006', 150000, 0, 'health', 'acc_bca_1', NULL, 'Pharmacy - Vitamins', 0, 1770354000000),
('txn_007', 350000, 0, 'education', 'acc_credit_2', NULL, 'Udemy Course', 0, 1770440400000),
('txn_008', 50000, 0, 'transport', 'acc_cash_1', NULL, 'GoRide to Office', 0, 1770526800000),
('txn_009', 2500000, 1, 'other', 'acc_bca_1', NULL, 'Freelance Project', 0, 1770613200000),
('txn_010', 300000, 0, 'bills', 'acc_mandiri_1', NULL, 'Water Bill PDAM', 0, 1770699600000),
('txn_011', 180000, 0, 'food', 'acc_credit_1', NULL, 'Sushi Tei Lunch', 0, 1770786000000),
('txn_012', 30000, 0, 'transport', 'acc_cash_2', NULL, 'Parking Fee', 0, 1770872400000),
('txn_013', 120000, 0, 'entertainment', 'acc_bca_1', NULL, 'Movie Tickets', 0, 1770958800000),
('txn_014', 500000, 0, 'other', 'acc_cash_1', NULL, 'Gift for Mom', 0, 1771045200000),
('txn_015', 750000, 0, 'shopping', 'acc_credit_2', NULL, 'New Shoes', 0, 1771131600000),
('txn_016', 500000, 2, 'other', 'acc_bca_1', 'acc_cash_1', 'ATM Withdrawal', 0, 1771218000000),
('txn_017', 220000, 0, 'food', 'acc_mandiri_1', NULL, 'Dinner at Pizza Hut', 0, 1771304400000),
('txn_018', 450000, 0, 'health', 'acc_credit_1', NULL, 'Dental Checkup', 0, 1771390800000),
('txn_019', 1500000, 0, 'entertainment', 'acc_credit_2', NULL, 'Concert Ticket', 0, 1771477200000),
('txn_020', 25000, 0, 'food', 'acc_cash_1', NULL, 'Coffee', 0, 1771563600000),
('txn_021', 100000, 0, 'transport', 'acc_bca_1', NULL, 'Toll Top Up', 0, 1771650000000),
('txn_022', 150000, 0, 'education', 'acc_mandiri_1', NULL, 'Book Purchase', 0, 1771736400000),
('txn_023', 80000, 0, 'bills', 'acc_cash_2', NULL, 'Mobile Prepard Credit', 0, 1771822800000),
('txn_024', 169000, 0, 'entertainment', 'acc_credit_1', NULL, 'Netflix Subscription', 0, 1771909200000),
('txn_025', 1000000, 1, 'other', 'acc_mandiri_1', NULL, 'Bonus', 0, 1771995600000),
('txn_026', 1500000, 2, 'settlement', 'acc_bca_1', 'acc_credit_1', 'Pay CC Bill', 1, 1772082000000);
