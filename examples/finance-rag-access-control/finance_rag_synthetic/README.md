# Synthetic Finance Dataset — Virgool Luxembourg RAG Demo

**Status:** Fully synthetic training/demo data  
**Company represented:** Fictionalized Virgool Luxembourg entity  
**Employees:** 50  
**Period:** Financial year 2026  
**Currency:** EUR  
**Purpose:** Demonstrate role-based RAG retrieval and access control in Open WebUI.

> No row in this package represents a real employee, client, salary, project, contract, supplier, or financial result.

## Access model

| Group | Intended access |
|---|---|
| Finance | Detailed salaries, payroll, revenue, expenses, receivables, budgets and project financials |
| Project Management | Time tracking and project-delivery cost datasets created in a later phase |
| C-Level | Aggregated company and project profitability, without employee-level salary detail |
| Normal Employees | No restricted knowledge base; general LLM only |

## Files

1. `01_employee_compensation_master.csv` — employee-level salary and benefits master.
2. `02_monthly_payroll_2026.csv` — monthly payroll and employer cost for all 50 synthetic employees.
3. `03_project_financials_2026.csv` — contract value, revenue, costs, profit and margin by project.
4. `04_revenue_ledger_2026.csv` — monthly recognized, billed and unbilled revenue.
5. `05_operating_expenses_2026.csv` — detailed corporate operating expenses.
6. `06_accounts_receivable_aging_2026.csv` — client receivables and overdue aging.
7. `07_company_pnl_monthly_2026.csv` — monthly company P&L.
8. `08_budget_vs_actual_2026.csv` — monthly revenue and cost variance.
9. `09_balance_sheet_2026.csv` — year-end synthetic balance sheet.
10. `10_finance_executive_summary.md` — narrative finance summary optimized for RAG.
11. `11_finance_policies_and_definitions.md` — definitions, access rules and financial interpretation.
12. `12_data_dictionary.md` — field-by-field description.
13. `finance_dataset_2026.xlsx` — consolidated workbook containing the CSV datasets as sheets.

## Annual headline values

- Recognized revenue: **€10,140,300**
- Total operating cost: **€10,084,049**
- Operating profit: **€56,251**
- Operating margin: **0.6%**
- Total outstanding receivables: **€1,644,856**

## Recommended RAG knowledge bases

Create at least two restricted knowledge bases:

- **Finance Detailed**: files 01–12; Finance group only.
- **Executive Finance**: files 03, 07, 08, 09 and 10; C-Level and Finance groups.

Do not put employee-level salary files in the Executive knowledge base if the goal is to demonstrate data minimization.
