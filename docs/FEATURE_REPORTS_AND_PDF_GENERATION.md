# Feature Guide: Reports & Multi-Page PDF Generation

VentExpensePro features a dual-layer reporting architecture: **interactive in-app visual analytics** with real-time reactive state synchronization, and a **bank-ready multi-page PDF statement engine** with an analog ink-and-paper aesthetic.

---

## 1. In-App Visual Analytics (`ReportsScreen`)

The `ReportsScreen` translates raw transaction ledgers into clear financial intelligence.

### Interactive Controls & Filtering
- **Period Filter**: Interactive date range picker supporting custom dates and presets (e.g. This Month, Year to Date, All Time).
- **Account Filter**: Modal selector enabling analysis of aggregate finances ("All Accounts") or isolation of a single bank, wallet, or card.
- **Reactive Data Token Watcher (`_checkAndReloadData`)**: Compares composite token hashes of account balances and transaction collections. Any transaction added, updated, or settled on another screen immediately triggers background regeneration without requiring manual navigation refreshes.
- **Pull-to-Refresh**: Native `RefreshIndicator` allowing instantaneous on-demand re-aggregation.

### Visual Components
1. **Financial Metrics Summary**:
   - **Total Income**: Sum of all income transactions in period ($+Rp\ ...$).
   - **Total Expense**: Sum of all operational spending in period ($-Rp\ ...$).
   - **Net Balance**: Operational delta ($\text{Income} - \text{Expense}$) styled in ink green or stamp red.
2. **Category Expense Breakdown**:
   - Interactive donut chart powered by `fl_chart`.
   - Dynamic legend displaying category name, color swatch, and exact monetary total.
3. **Debt & Lending Summary Section**:
   - High-level metric tiles: **Total Receivable** (*They owe you*) vs **Total Payable** (*You owe*).
   - **Net Debt Position**: Net personal debt exposure.
   - Expandable person cards showing itemized debt count and latest transaction date.
   - Settlement History log detailing recent debt settlements.
4. **Credit Card Billing Breakdown Section**:
   - Aggregate revolving credit debt across all configured cards.
   - Per-card itemized breakdown displaying previous billed cycle charges, active unbilled cycle spend, and statement cutoff badges.

---

## 2. Bank-Ready Multi-Page PDF Engine (`PdfReportService`)

The PDF generation engine compiles comprehensive, exportable financial statements styled to resemble archival ledger documents.

```mermaid
graph TD
    Trigger[User Taps 'Generate PDF Statement'] --> UC[GenerateReport Use Case]
    
    subgraph Data Gathering
        UC --> FetchTxn[TransactionRepository.getAll]
        UC --> FetchAcc[AccountRepository.getAll]
        UC --> FetchCat[CategoryRepository.getAll]
        UC --> CalcBill[CalculateBillingBreakdown for Credit Cards]
    end

    Data Gathering --> PDFEngine[PdfReportService.generate]

    subgraph Document Assembly
        PDFEngine --> LoadFonts[Load TTF Fonts: Lora & JetBrains Mono]
        PDFEngine --> BuildP1[Main Statement:\nHeader, Summary Card, Pie Chart & Ledger Table]
        PDFEngine --> BuildApp1[Appendix 1:\nDebt & Lending Summary, Receivables, Payables, History]
        PDFEngine --> BuildApp2[Appendix 2:\nCredit Card Billing Cycles, Cutoffs & Liability Breakdown]
    end

    Document Assembly --> WriteFile[Write to File via path_provider]
    WriteFile --> ShareUI[Share / Export via share_plus]
```

### Design System & Typography
The PDF engine uses authentic typefaces and colors loaded from application bundles:
- **`Lora-Bold.ttf` & `Lora-Regular.ttf`**: Elegant serif typography for document titles, section headers, and entity descriptions.
- **`JetBrainsMono-Regular.ttf`**: Monospace typography ensuring column alignment for currency values, timestamps, and account numbers.
- **Color Palette**:
  - `_paper` (`#FFF8F0`): Warm archival cream background on every page.
  - `_inkBlue` (`#1B3A5C`): Deep navy for titles, dividers, and primary metrics.
  - `_inkDark` (`#2C2C2C`): High-contrast charcoal for body copy and table rows.
  - `_inkLight` (`#7A7570`): Muted ink for secondary metadata and table headers.
  - `_stampRed` (`#C0392B`): Visual indicator for expenses, payables, and unpaid credit bills.
  - `_inkGreen` (`#27774E`): Visual indicator for income, receivables, and settled accounts.

---

## 3. PDF Statement Multi-Page Structure

### Page 1+: Financial Statement & Transaction Ledger
1. **Document Header**:
   - Prominent brand title: `VENTEXPENSE PRO`
   - Subtitle: `FINANCIAL STATEMENT`
   - Context metadata: Account scope (`All accounts` or specific account name), Date range (`dd MMM yyyy - dd MMM yyyy`), and Generation timestamp.
2. **Executive Summary Card**:
   - Total Income, Total Expense, and Net Balance with clear numerical formatting.
3. **Category Expense Chart & Legend**:
   - Embedded vector pie chart (`pw.PieDataSet`) with categorized expense shares.
4. **Itemized Transaction Ledger Table**:
   - Automatically wraps across multiple pages as transaction volume increases (`pw.MultiPage`).
   - Columns: `DATE`, `DESCRIPTION`, `CATEGORY`, `ACCOUNT`, `AMOUNT`.
   - Running footer on every page: `"Page X of Y"`.

### Appendix 1: Debt & Lending Summary (Multi-Page Appendix)
Rendered whenever debt accounts are present:
1. **Debt Summary Card**:
   - Total Receivable (*Piutang*), Total Payable (*Hutang*), and Net Debt Position.
2. **Receivable (Piutang) Table**:
   - Itemized list of individuals owing money, amounts, and subtotal.
3. **Payable (Hutang) Table**:
   - Itemized list of individuals you owe, amounts, and subtotal.
4. **Recent Settlements Table**:
   - Chronological audit trail of repayments, settlement dates, and notes.

### Appendix 2: Credit Card Billing Breakdown (Multi-Page Appendix)
Rendered whenever credit cards with configured billing cycles exist:
1. **Total Credit Outstanding Card**:
   - Aggregate liability across all cards combined.
2. **Card Breakdown Cards**:
   - Card name and Statement Close cutoff badge (`Closes 20th of month`).
   - **Billed Amount**: Statement closed charges due for payment.
   - **Unbilled Amount**: Pending ongoing charges accumulating for next statement.
   - Total card liability.

---

## 4. Export & Sharing Workflow

1. **Generation**: The compiled `pw.Document` is saved asynchronously to the platform's temporary/document directory (`output/VentExpensePro_Report_<timestamp>.pdf`).
2. **Success Banner**: The UI displays a confirmation card with file size and timestamp details.
3. **Native Sharing**: Tapping **"Share PDF"** invokes the platform-native sharing sheet via `share_plus` (`Share.shareXFiles`), allowing the document to be:
   - Sent via email, WhatsApp, Telegram, or AirDrop.
   - Saved directly to Google Drive, iCloud Files, or device storage.
   - Printed directly to a connected air printer.
