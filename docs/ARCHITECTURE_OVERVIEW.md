# Architecture Overview & System Design

**VentExpensePro** is an analog-digital personal finance management application built with Flutter. It combines the privacy, tactile clarity, and intentionality of a physical paper ledger with modern automated financial calculations, multi-dimensional search filtering, credit card billing cycle modeling, personal debt tracking, bank-ready PDF export, and sandboxed Google Drive cloud synchronization.

---

## 1. Architectural Pattern: Clean Architecture

The application strictly enforces **Clean Architecture** principles to achieve separation of concerns, testability, and independence from external frameworks and persistence mechanisms.

```mermaid
graph TD
    subgraph Presentation ["Presentation Layer (Flutter / UI)"]
        UI_Screens["Screens\n(Ledger, Accounts, Reports, Filters)"]
        UI_Widgets["Widgets\n(Cards, Sheets, Carousel, Chips)"]
        State_Providers["ChangeNotifier Providers\n(Transaction, Account, Reports, Sync)"]
    end

    subgraph Domain ["Domain Layer (Pure Dart / Business Logic)"]
        Entities["Entities & Value Objects\n(Account, Transaction, Money, TransactionFilter, BillingBreakdown)"]
        UseCases["Use Cases\n(ManageTransaction, SettleDebt, SettleCreditBill, CalculateBillingBreakdown, GenerateReport, SyncData)"]
        Repo_Interfaces["Repository Interfaces\n(AccountRepository, TransactionRepository, ReportRepository, SyncRepository)"]
    end

    subgraph Data ["Data Layer (Data Sources & Persistence)"]
        Repo_Impls["Repository Implementations\n(AccountRepositoryImpl, TransactionRepositoryImpl, ReportRepositoryImpl, SyncRepositoryImpl)"]
        Local_DB["Local SQLite DB\n(LocalDatabase / Sqflite)"]
        PDF_Service["PDF Engine\n(PdfReportService)"]
        Drive_Service["Cloud Sync Service\n(GoogleDriveService / AppData Scope)"]
    end

    subgraph Core ["Core Layer (Cross-Cutting Concerns)"]
        DI["Service Locator\n(GetIt / sl)"]
        Theme["Theme & Design System\n(AppColors, AppTypography, PaperCanvas)"]
    end

    Presentation --> Domain
    Data --> Domain
    Presentation -.-> Core
    Data -.-> Core
```

### Dependency Inversion & Invariant Boundaries
1. **Domain Layer (Center of System)**: Contains zero dependencies on Flutter UI (`package:flutter` is only referenced where standard value types like `DateTimeRange` or `ChangeNotifier` are essential for integration). All entities, use cases, and repository interfaces reside here.
2. **Data Layer**: Implements domain repository interfaces. Handles SQLite database interactions via `sqflite`, PDF document generation via `pdf`, and Google Drive API serialization.
3. **Presentation Layer**: Built with Flutter widgets, custom canvas painters (`PaperBackground`), and `Provider` state management. UI widgets observe providers and dispatch user actions directly through domain use cases.
4. **Core Layer**: Manages the dependency injection registry (`sl`), shared constants, themes, and utility mappers.

---

## 2. Directory Layout & Module Structure

```text
lib/
├── core/
│   ├── di/
│   │   └── service_locator.dart       # GetIt registry configuring singletons & factories
│   ├── theme/
│   │   ├── app_colors.dart            # Paper, ink, stamp, and ledger color palette
│   │   └── app_typography.dart        # Lora (serif) & JetBrains Mono (monospace) type styles
│   └── utils/
│       └── category_icon_mapper.dart  # Icon resolver for standard and custom categories
├── data/
│   ├── datasources/
│   │   ├── google_drive_service.dart  # OAuth2 authentication & AppData Drive file storage
│   │   ├── local_database.dart        # SQLite schema definition, migrations, and seeding
│   │   └── pdf_report_service.dart    # Multi-page PDF generation engine with ink-and-paper theme
│   ├── models/
│   │   ├── account_model.dart         # SQLite map serialization for accounts
│   │   ├── category_model.dart        # SQLite map serialization for categories
│   │   └── transaction_model.dart     # SQLite map serialization for transactions
│   └── repositories/
│       ├── account_repository_impl.dart
│       ├── category_repository_impl.dart
│       ├── report_repository_impl.dart
│       ├── sync_repository_impl.dart
│       └── transaction_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── account.dart               # Account entity (Asset, Liability, Personal Debt)
│   │   ├── category.dart              # Category entity
│   │   ├── enums.dart                 # AccountType (debit, cash, credit, debt) & TransactionType
│   │   ├── sync_exception.dart        # Custom sync failure domain exceptions
│   │   ├── sync_status.dart           # Cloud sync state model
│   │   └── transaction.dart           # Financial transaction entity
│   ├── repositories/                  # Pure repository contracts
│   │   ├── account_repository.dart
│   │   ├── category_repository.dart
│   │   ├── report_repository.dart
│   │   ├── sync_repository.dart
│   │   └── transaction_repository.dart
│   ├── usecases/                      # Encapsulated business operations
│   │   ├── calculate_billing_breakdown.dart
│   │   ├── calculate_net_position.dart
│   │   ├── generate_report.dart
│   │   ├── log_transaction.dart
│   │   ├── manage_account.dart
│   │   ├── manage_transaction.dart
│   │   ├── settle_credit_bill.dart
│   │   ├── settle_debt.dart
│   │   └── sync_data.dart
│   └── value_objects/
│       ├── billing_breakdown.dart     # Unbilled vs billed calculation model
│       ├── money.dart                 # Fixed-point currency formatting (cents/sen)
│       └── transaction_filter.dart    # Immutable 7-dimensional search criteria
└── presentation/
    ├── painters/
    │   └── paper_background.dart      # Custom painter rendering textured paper background
    ├── providers/
    │   ├── account_provider.dart      # Account state, balances, and Net Position breakdown
    │   ├── category_provider.dart     # Category management state
    │   ├── currency_provider.dart     # Active currency symbol & code state
    │   ├── reports_provider.dart      # Analytics caching, debt summary & PDF generation state
    │   ├── sync_provider.dart         # Google Drive authentication & backup lifecycle state
    │   └── transaction_provider.dart  # Transaction feed, 7-D filtering, and stats state
    ├── screens/
    │   ├── accounts_screen.dart       # Account cards, liabilities, and personal debts feed
    │   ├── ledger_screen.dart         # Main receipt feed, filter bar, and billing carousel
    │   ├── reports_screen.dart        # In-app charts, debt/credit reports, and PDF exporter
    │   └── transaction_filter_screen.dart # Full-screen 7-D filter configuration modal
    └── widgets/                       # Modular UI components (ReceiptCard, SettleDebtSheet, etc.)
```

---

## 3. Database Schema & Migration Model

VentExpensePro uses **SQLite** via `sqflite` for local persistence. Monetary values are stored as integers representing the smallest unit of currency (cents / sen) to avoid floating-point rounding errors.

### Entity Relationship Diagram (ERD)

```mermaid
erDiagram
    ACCOUNTS ||--o{ TRANSACTIONS : "source account"
    ACCOUNTS ||--o{ TRANSACTIONS : "destination account"
    CATEGORIES ||--o{ TRANSACTIONS : "categorizes"

    ACCOUNTS {
        TEXT id PK "UUID string"
        TEXT name "Display name (e.g. BCA, Wallet, John)"
        INTEGER type "Enum index: 0=debit, 1=cash, 2=credit, 3=debt"
        INTEGER balance "Balance in smallest currency unit (cents)"
        TEXT currency "ISO-4217 code (default: IDR)"
        INTEGER is_archived "0 = active, 1 = archived (soft delete)"
        INTEGER created_at "Unix epoch millisecond timestamp"
        INTEGER statement_close_day "1 to 28 (Credit cards only, NULL otherwise)"
    }

    TRANSACTIONS {
        TEXT id PK "UUID string"
        INTEGER amount "Positive integer in smallest currency unit"
        INTEGER type "Enum index: 0=expense, 1=income, 2=transfer"
        TEXT category_id FK "References categories(id)"
        TEXT account_id FK "Source account (or target for income)"
        TEXT to_account_id FK "Destination account (transfers / settlements)"
        TEXT note "User description or notes"
        INTEGER is_settlement "0 = standard, 1 = debt or credit settlement"
        INTEGER date_time "Unix epoch millisecond timestamp"
    }

    CATEGORIES {
        TEXT id PK "Slug identifier (food, bills, settlement, etc.)"
        TEXT name "Display label"
        TEXT icon "Icon identifier string"
        INTEGER is_custom "0 = system default, 1 = user created"
    }
```

### Schema Migrations (`local_database.dart`)
- **Version 1**: Initial release schema (`accounts`, `transactions`, `categories`).
- **Version 2**: Added `statement_close_day INTEGER` to `accounts` to support credit card billing cycle cutoffs (closes on day 1–28).
- **Sequential Migration Strategy**: Each version bump uses an isolated `if (oldVersion < N)` block to allow sequential upgrades from any previous version.

```dart
static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE accounts ADD COLUMN statement_close_day INTEGER');
  }
}
```

---

## 4. End-to-End Data Flow

The following sequence diagram demonstrates the flow of data from a user action in the presentation layer down through use cases, repositories, and persistence, followed by reactive UI state notification.

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant UI as QuickAddTransactionSheet
    participant TxnProv as TransactionProvider
    participant AccProv as AccountProvider
    participant ManageTxn as ManageTransaction (Use Case)
    participant TxnRepo as TransactionRepositoryImpl
    participant AccRepo as AccountRepositoryImpl
    participant DB as SQLite (LocalDatabase)

    User->>UI: Enter amount, select category, account & save
    UI->>TxnProv: addTransaction(Transaction)
    TxnProv->>ManageTxn: create(Transaction)
    
    rect rgb(240, 245, 255)
        Note over ManageTxn,AccRepo: Balance Invariant & Verification
        ManageTxn->>AccRepo: getById(accountId)
        AccRepo->>DB: SELECT * FROM accounts WHERE id = ?
        DB-->>AccRepo: Account row
        AccRepo-->>ManageTxn: Account entity
        ManageTxn->>ManageTxn: Verify credit/transfer rules & calculate new balance
        ManageTxn->>AccRepo: updateBalance(accountId, newBalance)
        AccRepo->>DB: UPDATE accounts SET balance = ? WHERE id = ?
    end

    rect rgb(245, 255, 245)
        Note over ManageTxn,TxnRepo: Record Persistence
        ManageTxn->>TxnRepo: insert(Transaction)
        TxnRepo->>DB: INSERT INTO transactions VALUES (...)
        DB-->>TxnRepo: Success
        TxnRepo-->>ManageTxn: Inserted Transaction
    end

    ManageTxn-->>TxnProv: Created Transaction
    TxnProv->>TxnProv: Prepend to local list & recompute stats
    TxnProv->>AccProv: Refresh balances
    AccProv->>AccRepo: getAll()
    AccRepo-->>AccProv: Updated accounts
    AccProv->>AccProv: Recompute Net Position & notifyListeners()
    TxnProv->>TxnProv: notifyListeners()
    TxnProv-->>UI: Success callback
    UI-->>User: Close sheet & animate new ReceiptCard into feed
```

---

## 5. Security & Privacy Sandbox Model

1. **Local-First Zero-Knowledge**: No custom backend servers, analytics trackers, or third-party ad networks exist in VentExpensePro. All transactional data remains exclusively on the client device.
2. **Google Drive AppData Sandbox**: Cloud backup and synchronization uses the `https://www.googleapis.com/auth/drive.appdata` OAuth scope. Files stored in this folder are invisible in the user's regular Google Drive file list and cannot be accessed by other applications.
3. **Production Obfuscation (R8/ProGuard)**: Release builds for Android strip all debug metadata and obfuscate class and method symbols to protect local schema logic and cryptographic implementations.
