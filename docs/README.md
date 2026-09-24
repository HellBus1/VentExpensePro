# VentExpensePro Technical Documentation Portal

Welcome to the **VentExpensePro** documentation portal. This repository is structured according to the **[Diátaxis Framework](https://diataxis.fr/)**, organizing technical guides across four quadrants: **Tutorials**, **How-to Guides**, **Reference**, and **Explanation**.

---

## 🧭 Diátaxis Documentation Map

```mermaid
quadrantChart
    title Documentation Architecture (Diátaxis Framework)
    x-axis Practical (Action) --> Theoretical (Knowledge)
    y-axis Acquisition (Learning) --> Application (Work)
    quadrant-1 Reference
    quadrant-2 How-to Guides
    quadrant-3 Tutorials
    quadrant-4 Explanation
    "Quick Start Walkthrough": [0.25, 0.25]
    "Manual QA Checklist": [0.35, 0.75]
    "OAuth Setup Guide": [0.40, 0.85]
    "Settle Debt Flow": [0.30, 0.65]
    "Architecture Overview": [0.85, 0.85]
    "Database Schema & ERD": [0.90, 0.70]
    "Drive Sync Protocol": [0.80, 0.60]
    "Clean Architecture Design": [0.75, 0.35]
    "Credit Cycle Mathematics": [0.85, 0.25]
    "RCA Google Auth": [0.70, 0.15]
```

---

## 1. 📚 Reference (Information-Oriented)
*Technical specifications, database schemas, and architectural designs.*

| Document | Description |
|---|---|
| **[Architecture Overview & System Design](ARCHITECTURE_OVERVIEW.md)** | Full architectural layout, Clean Architecture layer responsibilities, SQLite schema and v1 $\to$ v2 migrations, ERD, and dependency injection graph. |
| **[Google Drive Sync Architecture](GOOGLE_DRIVE_SYNC_ARCHITECTURE.md)** | Technical design of the cloud backup engine, AppData sandbox isolation, JSON database serialization, version migration, and retention policy. |
| **[Manual QA Test Checklist](MANUAL_QA_TEST_CHECKLIST.md)** | Comprehensive test matrix spanning 9 test suites with step-by-step procedures, assertions, and pass/fail checkboxes for manual verification. |

---

## 2. 🛠️ How-to Guides (Problem-Oriented)
*Step-by-step recipes to accomplish specific operational goals.*

| Document | Description |
|---|---|
| **[Smart Ledger & 7-D Filter Guide](FEATURE_SMART_LEDGER_AND_FILTERS.md)** | How to log transactions, inspect receipt groups, and apply multi-dimensional filters with real-time match counting. |
| **[Accounts & Personal Debt Guide](FEATURE_ACCOUNTS_AND_PERSONAL_DEBTS.md)** | How to create accounts, track loans/borrowings (*piutang/hutang*), and execute partial or full debt settlements. |
| **[Credit Cards & Billing Cycles Guide](FEATURE_CREDIT_CARDS_AND_BILLING_CYCLES.md)** | How to configure statement cutoff days, inspect billed vs unbilled balances, and pay credit card bills via one-touch settlement. |
| **[Reports & PDF Statement Guide](FEATURE_REPORTS_AND_PDF_GENERATION.md)** | How to filter financial periods, inspect expense charts, and generate multi-page archival PDF statements. |
| **[Google OAuth Setup Guide](GOOGLE_OAUTH_SETUP_GUIDE.md)** | Step-by-step instructions for configuring Google Cloud Console, OAuth consent screens, Android SHA-1 fingerprints, and iOS URL schemes. |

---

## 3. 💡 Explanation (Understanding-Oriented)
*Discussions and background context clarifying core concepts and past decisions.*

| Document | Description |
|---|---|
| **[Root Cause Analysis: Google Sign-In](RCA_GOOGLE_SIGNIN_ISSUES.md)** | In-depth post-mortem and resolution for `ApiException: null null` and Google verification warnings during cloud sync setup. |
| **[Credit Card Transfer Restrictions](FEATURE_CREDIT_CARDS_AND_BILLING_CYCLES.md#1-credit-card-liability-model)** | Architectural rationale for preventing generic transfers out of or into credit cards to protect double-entry invariants. |
| **[Personal Debt Accounting Convention](FEATURE_ACCOUNTS_AND_PERSONAL_DEBTS.md#2-personal-debt-tracking-architecture)** | Explanation of the positive/negative debt balance sign convention and the Zero Debt settlement philosophy. |

---

## 4. 🚀 Tutorials (Learning-Oriented)
*Hands-on guidance for onboarding and validating the complete user journey.*

- **Running the Application**: Follow the [Quick Start Guide](../README.md#getting-started) in the main project README.
- **Executing the Manual Verification Suite**: Walk through the [Manual QA Test Checklist](MANUAL_QA_TEST_CHECKLIST.md) to test every core flow on an emulator or physical device.
- **Generating Screenshots**: See [Screenshot Generator Test](../integration_test/screenshot_generator_test.dart) to capture automated Play Store assets.
