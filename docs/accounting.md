# Accounting

Double-entry books modelled on Tally (TallyPrime), kept simple: `accounting/v1` (accounts) and
`accounting/ledger/v1` (groups, ledgers, vouchers, reports).

| Tally | Here |
|---|---|
| Company | `Account`: a set of books with an owner, currency, financial year start and lock date |
| Group | `Group`: chart of accounts; 28 predefined, custom groups under them |
| Ledger | `GeneralLedger`: under a group, opening balance, optional party, bill-wise flag |
| Voucher | `Voucher` of a `VoucherType`, with balanced `GeneralLedgerEntry` lines |
| Bill-wise details | `BillAllocation` on an entry: new reference, against reference, advance, on account |
| Trial Balance, P&L, Balance Sheet, Ledger, Outstandings | `ReportService` |

Out of scope: stock items and inventory vouchers, GST computation and returns (use ledgers under Duties & Taxes),
cost centres, multi-currency, budgets, interest, bank reconciliation, payroll, memo and optional vouchers.

## Predefined groups

Creating an account seeds these groups (`predefined = true`). "GP" is `affects_gross_profit`.

| Group | Parent | Nature | GP |
|---|---|---|---|
| Capital Account | | Liability | |
| Reserves & Surplus | Capital Account | Liability | |
| Loans (Liability) | | Liability | |
| Bank OD A/c | Loans (Liability) | Liability | |
| Secured Loans | Loans (Liability) | Liability | |
| Unsecured Loans | Loans (Liability) | Liability | |
| Current Liabilities | | Liability | |
| Duties & Taxes | Current Liabilities | Liability | |
| Provisions | Current Liabilities | Liability | |
| Sundry Creditors | Current Liabilities | Liability | |
| Suspense A/c | | Liability | |
| Branch / Divisions | | Liability | |
| Fixed Assets | | Asset | |
| Investments | | Asset | |
| Current Assets | | Asset | |
| Bank Accounts | Current Assets | Asset | |
| Cash-in-hand | Current Assets | Asset | |
| Deposits (Asset) | Current Assets | Asset | |
| Loans & Advances (Asset) | Current Assets | Asset | |
| Stock-in-hand | Current Assets | Asset | |
| Sundry Debtors | Current Assets | Asset | |
| Misc. Expenses (ASSET) | | Asset | |
| Sales Accounts | | Income | yes |
| Direct Incomes | | Income | yes |
| Indirect Incomes | | Income | |
| Purchase Accounts | | Expense | yes |
| Direct Expenses | | Expense | yes |
| Indirect Expenses | | Expense | |

Cash and bank ledgers, which Contra, Payment and Receipt vouchers require, are those under Cash-in-hand, Bank Accounts
and Bank OD A/c.

Source: [TallyPrime ledgers and groups](https://help.tallysolutions.com/ledgers-and-groups-in-tallyprime/).
