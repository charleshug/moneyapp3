# MoneyApp

Use MoneyApp to track your income and expenses with categorized transactions.
Monitor your financial health and keep on track with budget to actuals and 
useful reports.

## Features

- **Budget Management**: Track budget vs actual spending with rollover balances
- **Account Management**: Organize accounts by On-Budget, Off-Budget, and Closed status
- **Transaction Tracking**: Record income, expenses, and transfers with detailed categorization
- **Split Transactions**: Handle complex transactions with multiple categories
- **CSV Import**: Bulk import transactions from bank exports
- **Financial Reports**: Net worth, spending by category, and spending by vendor analysis
- **Real-time Updates**: Modern UI with Turbo and StimulusJS for smooth interactions

## Data Model

Each Account has many Transactions. Transactions are used to record income, 
expenses, and budget activity. Every transaction requires a budget category
and Vendor. Transactions may be split into multiple Lines. Each line requires a 
budget category and the transaction will have the category "Split".

## Main Screens

MoneyApp is divided into 4 main screens: Budget, Accounts, Transactions, Reports.

Navigate to the Budget screen to view the current month Budget to Actuals.
Unused budget balances roll forward to the next month. Overspent budget balances
are deducted from the next months "Available to Budget" total. This can be 
changed on a per category basis, thereby allowing specific categories to maintain
negative balances.

The Account screen presents a list of all your accounts summarized by On Budget,
Off Budget, and Closed. Click into any account to view its associated transactions.
There you can also edit the account attributes. The list of transactions can be 
searched, sorted, and filtered. Use this to find transactions by date, vendor, ...
even memo. Click the specific transaction to view and modify it.

Create a new transaction easily with the Transaction screen. Enter an amount,
date, vendor, account, category and an optional memo and flag. Save it and the 
transaction will appear in your transaction list.

(Transactions can also be mass uploaded via CSV)

View your financial health with the Reports screen. Net Worth, Spending by
Category, and Spending by Vendor help you monitor your overall financial well-being
and to track where your money is going.

## Setup

### Prerequisites
- Ruby 3.2.0+
- PostgreSQL
- Node.js (for asset compilation)

### Installation
1. Clone the repository
2. Run `bundle install`
3. Run `rails db:create db:migrate`
4. Run `rails db:seed` (loads default categories and vendors)
5. Run `rails server`
6. Visit `http://localhost:3000`

Default Vendors and Budget categories are provided in the seed file.
Run this at first start.

## Technical Details

MoneyApp is designed with the Rails 7 / Hotwire framework in mind. Turbo and 
StimulusJS are used to create a friendly user experience.