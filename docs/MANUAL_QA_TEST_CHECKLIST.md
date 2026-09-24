# VentExpensePro 2.0.0 — Comprehensive Manual QA Test Checklist

This document is an exhaustive manual testing checklist and verification matrix for **VentExpensePro v2.0.0**. It is structured for QA engineers, developers, and manual testers executing regression testing across real devices (Android / iOS) and emulators.

---

## 📋 Test Execution Summary

| Module | Test Suite Name | Test Cases | Execution Status |
|:---:|---|:---:|:---:|
| **TS-01** | Account Management & Classifications | 8 | `[ ]` Not Started |
| **TS-02** | Smart Ledger & Transaction Entries | 8 | `[ ]` Not Started |
| **TS-03** | 7-Dimensional Transaction Filters | 10 | `[ ]` Not Started |
| **TS-04** | Personal Debt Tracking (*Piutang / Hutang*) | 9 | `[ ]` Not Started |
| **TS-05** | Credit Card Billing Cycles & Pay Bill | 8 | `[ ]` Not Started |
| **TS-06** | In-App Reports & Visual Analytics | 8 | `[ ]` Not Started |
| **TS-07** | Bank-Ready Multi-Page PDF Statements | 7 | `[ ]` Not Started |
| **TS-08** | Google Drive AppData Cloud Sync | 6 | `[ ]` Not Started |
| **TS-09** | Edge Cases, Invariants & Persistence | 5 | `[ ]` Not Started |
| **TOTAL** | **9 Test Suites** | **69 Test Cases** | |

---

## 🏷️ Test Results Legend
- `[ ]` **Untested**: Test case not yet executed.
- `[x]` **Pass**: Actual result matched expected outcome with zero errors.
- `[!]` **Fail**: Behavior differed from expected outcome or caused application crash.
- `[-]` **Blocked / Skipped**: Cannot execute due to external dependency or preceding failure.

---

## TS-01: Account Setup & Management

| Test ID | Scenario | Pre-conditions | Step-by-Step Procedure | Expected Outcome | Status | Notes |
|---|---|---|---|---|:---:|---|
| **TS-01-01** | Create Debit Account | App opened on Accounts screen | 1. Tap `+` FAB.<br>2. Select type: **Debit**.<br>3. Enter name: `"Bank Mandiri"`.<br>4. Enter initial balance: `10000000`.<br>5. Tap Save. | Account appears under **ASSETS** section with balance `+Rp 10.000.000`. Net Position increases by Rp 10.000.000. | `[ ]` | |
| **TS-01-02** | Create Cash Wallet Account | Accounts screen open | 1. Tap `+` FAB.<br>2. Select type: **Cash**.<br>3. Enter name: `"Cash Wallet"`.<br>4. Enter initial balance: `500000`.<br>5. Tap Save. | Account appears under **ASSETS** with balance `+Rp 500.000`. Added to Total Assets. | `[ ]` | |
| **TS-01-03** | Create Credit Card without Statement Close Day | Accounts screen open | 1. Tap `+` FAB.<br>2. Select type: **Credit**.<br>3. Enter name: `"BCA Card"`.<br>4. Leave Statement Close Day blank.<br>5. Enter initial balance: `0`.<br>6. Tap Save. | Account appears under **LIABILITIES**. No billing cycle badge is rendered. | `[ ]` | |
| **TS-01-04** | Create Credit Card with Statement Close Day | Accounts screen open | 1. Tap `+` FAB.<br>2. Select type: **Credit**.<br>3. Enter name: `"BCA Everyday"`.<br>4. Enter Statement Close Day: `20`.<br>5. Enter balance: `1850000`.<br>6. Tap Save. | Card appears under **LIABILITIES** with badge `"Closes 20th"`. Added to Total Liabilities. | `[ ]` | |
| **TS-01-05** | Create Personal Debt Account | Accounts screen open | 1. Tap `+` FAB.<br>2. Select type: **Debt**.<br>3. Enter name: `"Budi"`.<br>4. Enter balance: `0`.<br>5. Tap Save. | Account appears under **PERSONAL DEBTS** with balance `Rp 0` and **"SETTLED"** zero debt stamp. | `[ ]` | |
| **TS-01-06** | Edit Account Details | Existing account exists | 1. Tap on `"Bank Mandiri"`.<br>2. Change name to `"Bank Mandiri Main"`.<br>3. Tap Save. | Name updates instantly on Accounts screen and in transaction dropdowns. | `[ ]` | |
| **TS-01-07** | Soft-Archive Account | Account with existing transactions | 1. Long-press account card.<br>2. Confirm archive in dialog. | Account is hidden from active list; historical transactions remain intact in Ledger. | `[ ]` | |
| **TS-01-08** | Currency Switching | Mixed accounts created | 1. Tap Currency selector dropdown at top of Accounts.<br>2. Select `USD` then `IDR`. | Currency symbol and formatting dynamically switch across all cards and ledger items. | `[ ]` | |

---

## TS-02: Smart Ledger & Transaction Entries

| Test ID | Scenario | Pre-conditions | Step-by-Step Procedure | Expected Outcome | Status | Notes |
|---|---|---|---|---|:---:|---|
| **TS-02-01** | Log Cash Expense | Cash account with balance $\ge 50000$ | 1. On Ledger screen, tap `+` FAB.<br>2. Select **Expense**.<br>3. Amount: `50000`.<br>4. Category: **Food**.<br>5. Account: **Cash Wallet**.<br>6. Note: `"Lunch"`.<br>7. Tap Save. | ReceiptCard appears under today's date with `-Rp 50.000`. Cash balance reduces by Rp 50.000. Quick stats update. | `[ ]` | |
| **TS-02-02** | Log Bank Income | Debit account exists | 1. Open Quick Add.<br>2. Select **Income**.<br>3. Amount: `5000000`.<br>4. Category: **Salary / Other**.<br>5. Account: **Bank Mandiri**.<br>6. Tap Save. | Income appears in ledger as `+Rp 5.000.000` in green. Bank balance increases by Rp 5.000.000. | `[ ]` | |
| **TS-02-03** | Log Standard Transfer (Bank $\to$ Cash) | Bank Mandiri has sufficient balance | 1. Open Quick Add.<br>2. Select **Transfer**.<br>3. Amount: `200000`.<br>4. From: **Bank Mandiri**.<br>5. To: **Cash Wallet**.<br>6. Tap Save. | Bank balance reduces by 200.000; Cash increases by 200.000. Net position remains unchanged. | `[ ]` | |
| **TS-02-04** | Validation: Zero or Negative Amount | Quick Add open | 1. Enter amount `0` or negative.<br>2. Tap Save. | Form shows validation error; submission is blocked. | `[ ]` | |
| **TS-02-05** | Validation: Transfer to Same Account | Quick Add open | 1. Select Transfer.<br>2. Choose From: **Bank Mandiri**, To: **Bank Mandiri**.<br>3. Tap Save. | Error banner displayed: `"Source and destination accounts must be different"`. | `[ ]` | |
| **TS-02-06** | Validation: Insufficient Balance | Bank balance is 100.000 | 1. Attempt transfer of `500000` from Bank to Cash. | Error displayed: `"Insufficient balance"`. Transaction is rejected. | `[ ]` | |
| **TS-02-07** | Net Position Reactive Sync | Several transactions logged | 1. Note Net Position.<br>2. Log an expense of `100000`. | Net Position card immediately drops by exactly Rp 100.000 without app restart. | `[ ]` | |
| **TS-02-08** | Quick Stats Strip Accuracy | Today is active | 1. Log two expenses today (30.000 and 20.000). | QuickStatsStrip displays **Today's Spending: Rp 50.000**. | `[ ]` | |

---

## TS-03: 7-Dimensional Transaction Filters

| Test ID | Scenario | Pre-conditions | Step-by-Step Procedure | Expected Outcome | Status | Notes |
|---|---|---|---|---|:---:|---|
| **TS-03-01** | Free-Text Search | Ledger contains `"Dinner"` and `"Fuel"` | 1. Tap Filter button.<br>2. Enter `"din"` in Search input.<br>3. Tap Apply. | Only transactions with `"Dinner"` in note appear. Non-matching transactions hidden. | `[ ]` | |
| **TS-03-02** | Filter by Transaction Type | Multiple types exist | 1. Open Filter modal.<br>2. Select only **Expense** chip.<br>3. Apply. | Income and Transfer transactions are excluded from feed. | `[ ]` | |
| **TS-03-03** | Filter by Specific Account | Multiple accounts active | 1. Open Filter modal.<br>2. Select only **Cash Wallet**.<br>3. Apply. | Feed displays only transactions involving Cash Wallet. | `[ ]` | |
| **TS-03-04** | Filter by Account Category | Bank, Cash, Credit, Debt active | 1. Open Filter modal.<br>2. Select Account Type: **Credit**.<br>3. Apply. | Only transactions involving credit card accounts render. | `[ ]` | |
| **TS-03-05** | Filter by Category | Multiple categories exist | 1. Open Filter modal.<br>2. Select **Food** and **Transport**.<br>3. Apply. | Transactions matching either Food OR Transport render. | `[ ]` | |
| **TS-03-06** | Filter by Amount Range | Wide range of amounts exist | 1. Open Filter modal.<br>2. Min: `50000`, Max: `200000`.<br>3. Apply. | Only transactions between Rp 50.000 and Rp 200.000 appear. | `[ ]` | |
| **TS-03-07** | Filter by Date Range | Transactions spread across months | 1. Open Filter modal.<br>2. Select Custom Date Range (last 7 days).<br>3. Apply. | Transactions outside the 7-day window are filtered out. | `[ ]` | |
| **TS-03-08** | Real-Time Match Preview Badge | Filter modal open | 1. Type search query or toggle category chips. | Bottom button updates text dynamically: `"Show X Transactions"`. If 0 matches, button is disabled. | `[ ]` | |
| **TS-03-09** | Filter Chips & Surgical Removal | Active filter applied with 3 dimensions | 1. Observe Ledger header.<br>2. Tap `[x]` on Category chip. | Category filter is removed; other 2 active filters remain active. Filter badge decrements. | `[ ]` | |
| **TS-03-10** | Reset All Filters | Active filters present | 1. Open Filter modal.<br>2. Tap **Reset** at top right.<br>3. Apply. | All criteria cleared; complete ledger feed restored. | `[ ]` | |

---

## TS-04: Personal Debt Tracking (*Piutang / Hutang*)

| Test ID | Scenario | Pre-conditions | Step-by-Step Procedure | Expected Outcome | Status | Notes |
|---|---|---|---|---|:---:|---|
| **TS-04-01** | Lend Money to Friend (*Piutang*) | Debt account `"Budi"` created (balance 0) | 1. Open Quick Add.<br>2. Transfer: From **Cash Wallet** $\to$ To **Budi**.<br>3. Amount: `250000`.<br>4. Tap Save. | Budi's balance becomes `+Rp 250.000`. Renders under **"THEY OWE YOU"** in green. Counted as Asset. | `[ ]` | |
| **TS-04-02** | Borrow Money from Friend (*Hutang*) | Debt account `"Alex"` created (balance 0) | 1. Open Quick Add.<br>2. Transfer: From **Alex** $\to$ To **Cash Wallet**.<br>3. Amount: `150000`.<br>4. Tap Save. | Alex's balance becomes `-Rp 150.000`. Renders under **"YOU OWE"** in stamp red. Counted as Liability. | `[ ]` | |
| **TS-04-03** | Verify Debt Summary Strip | Budi (+250k) and Alex (-150k) exist | 1. Navigate to Accounts screen.<br>2. Inspect Debt Summary Strip. | Shows **THEY OWE YOU: Rp 250.000** and **YOU OWE: Rp 150.000**. | `[ ]` | |
| **TS-04-04** | Settle Debt: Full Repayment of Receivable | Budi owes 250.000 | 1. Tap **"Settle Debt"** on Budi's card.<br>2. Select asset: **Cash Wallet**.<br>3. Amount: `250000`.<br>4. Confirm Settlement. | Cash Wallet increases by 250.000; Budi's balance becomes `Rp 0`. Budi's card displays **"SETTLED"** stamp. | `[ ]` | |
| **TS-04-05** | Settle Debt: Partial Repayment | Budi owes 250.000 | 1. Tap **"Settle Debt"** on Budi's card.<br>2. Enter amount: `100000`.<br>3. Confirm. | Cash increases by 100.000; Budi's remaining debt is `+Rp 150.000`. No settled stamp yet. | `[ ]` | |
| **TS-04-06** | Settle Debt: Paying Back Payable (*Hutang*) | You owe Alex 150.000 | 1. Tap **"Settle Debt"** on Alex's card.<br>2. Select asset: **Bank Mandiri**.<br>3. Amount: `150000`.<br>4. Confirm. | Bank balance decreases by 150.000; Alex's balance becomes `Rp 0` (**"SETTLED"** stamp renders). | `[ ]` | |
| **TS-04-07** | Zero Debt Visual Stamp | Debt balance is 0 | 1. Inspect settled debt account card. | `ZeroDebtStamp` renders rotated red border with text **"SETTLED"**; "Settle Debt" button hidden. | `[ ]` | |
| **TS-04-08** | Invariant: Overpayment Attempt | Budi owes 150.000 | 1. Attempt to settle `200000` on Budi's account. | Input validation / use case throws ArgumentError: `"Settlement amount exceeds outstanding debt"`. | `[ ]` | |
| **TS-04-09** | Invariant: Settle via Credit Card Blocked | Credit card exists | 1. Open Settle Debt sheet. | Asset selector **only** shows Debit and Cash accounts. Credit cards are strictly omitted from options. | `[ ]` | |

---

## TS-05: Credit Card Billing Cycles & Pay Bill

| Test ID | Scenario | Pre-conditions | Step-by-Step Procedure | Expected Outcome | Status | Notes |
|---|---|---|---|---|:---:|---|
| **TS-05-01** | Billing Carousel Display | Credit card configured with close day = 20 | 1. Navigate to Ledger screen. | Carousel shows card name, `"Closes 20th"`, billed amount, unbilled amount, and ratio bar. | `[ ]` | |
| **TS-05-02** | Cutoff Day Calculation | Close day = 20 | 1. Verify period when today $\le 20$.<br>2. Verify period when today $> 20$. | Billed period is correctly set to previous month's statement; current cycle is active ongoing period. | `[ ]` | |
| **TS-05-03** | Segregation of Billed vs Unbilled | Expenses logged in both previous and current cycle | 1. Log expense dated in previous period.<br>2. Log expense dated in current period.<br>3. Inspect card. | Billed amount matches sum of previous period expenses; unbilled matches current period expenses. | `[ ]` | |
| **TS-05-04** | Invariant: Block Outbound Generic Transfer | Credit card exists | 1. Open Quick Add.<br>2. Transfer: From **Credit Card** $\to$ To **Bank**.<br>3. Tap Save. | Error banner displayed: `"Credit accounts cannot participate in transfers. Use settlement flow."` | `[ ]` | |
| **TS-05-05** | Invariant: Block Inbound Generic Transfer | Credit card exists | 1. Open Quick Add.<br>2. Transfer: From **Bank** $\to$ To **Credit Card**.<br>3. Tap Save. | Error displayed: `"Cannot transfer to a credit account. Use settlement flow."` | `[ ]` | |
| **TS-05-06** | Pay Bill One-Touch Settlement | Card has billed balance of 1.850.000 | 1. Tap **"Pay Bill"** on card.<br>2. Source: **Bank Mandiri**.<br>3. Amount: `1850000`.<br>4. Confirm Payment. | Bank balance deducted by 1.850.000; Credit card liability reduced by 1.850.000. Settlement record logged. | `[ ]` | |
| **TS-05-07** | Partial Bill Payment | Card balance 1.850.000 | 1. Pay `1000000` via Pay Bill. | Bank deducted by 1.000.000; Card liability reduces to 850.000. | `[ ]` | |
| **TS-05-08** | All Caught Up Indicator | Billed balance is 0 | 1. Inspect card when billed charges = 0. | Card shows green checkmark `Rp 0` and badge label `"All caught up!"`. | `[ ]` | |

---

## TS-06: In-App Reports & Visual Analytics

| Test ID | Scenario | Pre-conditions | Step-by-Step Procedure | Expected Outcome | Status | Notes |
|---|---|---|---|---|:---:|---|
| **TS-06-01** | Period Filter Selection | Reports screen open | 1. Tap Period tile.<br>2. Select This Month.<br>3. Confirm. | Header label updates to `"01 [Month] - [End Month]"`. Metrics recompute for selected period. | `[ ]` | |
| **TS-06-02** | Single Account Filter Isolation | Reports screen open | 1. Tap Account tile.<br>2. Select `"Bank Mandiri"`. | Income, expense, and net balance reflect transactions isolated exclusively to Bank Mandiri. | `[ ]` | |
| **TS-06-03** | Income vs Expense vs Net Balance | Mixed transactions exist | 1. Inspect Statistics Summary card. | Total Income (green), Total Expense (red), Net Balance ($\text{Income} - \text{Expense}$) are mathematically exact. | `[ ]` | |
| **TS-06-04** | Expense Donut Chart & Legend | Categorized expenses exist | 1. Inspect Pie Chart.<br>2. Check color swatches and values in legend. | Chart segments correspond proportionally to category amounts. Colors match legend swatches. | `[ ]` | |
| **TS-06-05** | In-App Debt Summary Section | Active debts exist | 1. Scroll to **Debt & Lending Summary** on Reports screen. | Displays Net Debt Position, Receivable vs Payable tiles, person item counts, and settlement history. | `[ ]` | |
| **TS-06-06** | In-App Credit Billing Breakdown | Credit card configured | 1. Scroll to **Credit Card Billing Breakdown** on Reports screen. | Displays Total Credit Outstanding card, per-card unbilled/billed dates, and ratio indicators. | `[ ]` | |
| **TS-06-07** | Background Reactive Auto-Refresh | Reports open, then new expense logged | 1. Note reports total expense.<br>2. Switch to Ledger and log new 50.000 expense.<br>3. Return to Reports. | Total expense immediately increases by 50.000 via reactive token comparison without manual refresh. | `[ ]` | |
| **TS-06-08** | Pull-to-Refresh Verification | Reports screen open | 1. Drag down from top of Reports screen. | Refresh spinner appears and triggers clean reload of all reports data. | `[ ]` | |

---

## TS-07: Bank-Ready Multi-Page PDF Statements

| Test ID | Scenario | Pre-conditions | Step-by-Step Procedure | Expected Outcome | Status | Notes |
|---|---|---|---|---|:---:|---|
| **TS-07-01** | Generate All-Time PDF Statement | Reports screen open | 1. Set Period to All Time.<br>2. Tap **"Generate PDF Statement"**. | Progress indicator appears, followed by success banner: `"Ready to Save! Report generated successfully."` | `[ ]` | |
| **TS-07-02** | Generate Date-Filtered Statement | Reports screen open | 1. Set Period to Custom (e.g. Sept 1 - Sept 30).<br>2. Tap Generate. | Generated document header reflects the specified date range. | `[ ]` | |
| **TS-07-03** | Verify Main Statement Layout | PDF file opened in viewer | 1. Inspect Page 1. | Displays **VENTEXPENSE PRO**, warm cream paper (`#FFF8F0`), summary card, vector pie chart, and table. | `[ ]` | |
| **TS-07-04** | Multi-Page Ledger Pagination | $> 30$ transactions logged | 1. Generate PDF.<br>2. Inspect transaction table. | Table smoothly flows across pages with recurring table headers and `"Page X of Y"` footers. | `[ ]` | |
| **TS-07-05** | Verify Appendix 1 (Debt Summary) | Active personal debts exist | 1. Inspect appendix pages. | Dedicated page titled **DEBT & LENDING SUMMARY** containing Receivables, Payables, and Settlement history. | `[ ]` | |
| **TS-07-06** | Verify Appendix 2 (Credit Breakdown) | Configured credit card exists | 1. Inspect credit appendix page. | Dedicated page titled **CREDIT CARD BILLING SUMMARY** with total liability card and per-card breakdown. | `[ ]` | |
| **TS-07-07** | Native Share Sheet Dispatch | PDF generated successfully | 1. Tap **"Share PDF Statement"** button. | Platform native share sheet opens (AirDrop, WhatsApp, Drive, Files) with attached `.pdf` document. | `[ ]` | |

---

## TS-08: Google Drive AppData Cloud Sync

| Test ID | Scenario | Pre-conditions | Step-by-Step Procedure | Expected Outcome | Status | Notes |
|---|---|---|---|---|:---:|---|
| **TS-08-01** | Google OAuth Sign-In | Device with Google Play Services | 1. Tap overflow menu $\to$ **Backup & Sync**.<br>2. Tap **Sign in with Google**.<br>3. Select Google account. | User email and avatar/name displayed. Status transitions to `"Signed in"`. | `[ ]` | |
| **TS-08-02** | Sync Status Chip Display | Signed in | 1. Inspect SyncStatusChip on Ledger screen. | Displays green cloud icon with last sync time (e.g. `"Synced 5m ago"`). | `[ ]` | |
| **TS-08-03** | Manual Cloud Backup | Signed in | 1. On Backup screen, tap **"Backup Now"**.<br>2. Wait for completion. | Progress indicator runs; timestamp updates to `"Just now"`. Encrypted JSON written to `drive.appdata`. | `[ ]` | |
| **TS-08-04** | Cloud Restore & Local Overwrite | Backup exists in cloud | 1. Tap **"Restore from Cloud"**.<br>2. Confirm overwrite in warning dialog. | Data restored from cloud backup; local accounts and transactions update to cloud snapshot. | `[ ]` | |
| **TS-08-05** | Offline Handling | Device in Airplane mode | 1. Trigger Backup Now while offline. | Graceful error banner: `"Network unavailable. Please check your connection."` No crash. | `[ ]` | |
| **TS-08-06** | Google Sign-Out | Signed in | 1. Tap **Sign Out** button. | Session revoked; UI reverts to signed-out state. Local data remains intact. | `[ ]` | |

---

## TS-09: Edge Cases, Invariants & Persistence

| Test ID | Scenario | Pre-conditions | Step-by-Step Procedure | Expected Outcome | Status | Notes |
|---|---|---|---|---|:---:|---|
| **TS-09-01** | Transaction Deletion & Balance Reversal | Expense of 50.000 logged on Cash | 1. Long-press transaction in Ledger.<br>2. Choose Delete.<br>3. Confirm. | Transaction removed from ledger; Cash balance increases by exactly 50.000 (undo effect). | `[ ]` | |
| **TS-09-02** | Transaction Edit Balance Reversal | Expense of 50.000 on Cash | 1. Edit transaction: Change amount to `80000` and Account to **Bank Mandiri**.<br>2. Save. | Cash balance refunded +50.000; Bank balance deducted -80.000. Recomputed atomically. | `[ ]` | |
| **TS-09-03** | SQLite Migration Verification | Fresh install or v1 database | 1. Launch app with v1 database. | Database upgrades to v2 without data loss; `statement_close_day` column added cleanly. | `[ ]` | |
| **TS-09-04** | App Cold Restart Persistence | Multiple accounts and transactions logged | 1. Force close app from Android/iOS task switcher.<br>2. Relaunch app. | All account balances, transactions, and settings load identically from SQLite. | `[ ]` | |
| **TS-09-05** | Extreme Large Numbers Formatting | Account with balance $> 1.000.000.000$ | 1. Create account with `2500000000` (Rp 2.5 Billion).<br>2. Inspect UI cards. | Text wraps cleanly without overflowing; thousand separators format correctly (`Rp 2.500.000.000`). | `[ ]` | |
